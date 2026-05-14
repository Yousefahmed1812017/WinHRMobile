import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_provider.dart';

/// Google Maps Static API key for map preview.
const _mapsKey = 'AIzaSyA8NdDD7cUCWx_OIvDi0A8EApwA2Bll_sg';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Position? _position;
  bool _loadingLocation = true;
  bool _submitting = false;
  String? _locationError;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _timeFmt = DateFormat('HH:mm');
  final _displayTimeFmt = DateFormat('hh:mm:ss a');

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    _getLocation();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'خدمة الموقع غير مفعّلة. يرجى تفعيلها.';
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'تم رفض صلاحية الموقع.';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'صلاحية الموقع مرفوضة نهائياً. يرجى تفعيلها من الإعدادات.';
          _loadingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = pos;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'تعذّر تحديد الموقع: $e';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _checkIn() => _submit('IN');
  Future<void> _checkOut() => _submit('OUT');

  Future<void> _submit(String checkType) async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى الانتظار حتى يتم تحديد الموقع',
              style: GoogleFonts.ibmPlexSansArabic()),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = ref.read(authStateProvider);
      final dio = DioClient().dio;
      final now = DateTime.now();

      final response = await dio.post(
        ApiConstants.checkInOut,
        data: {
          'employeeId': auth.user?.employeeId ?? 0,
          'checkType': checkType,
          'actualTime': _timeFmt.format(now),
          'attendanceDate': _dateFmt.format(now),
          'latitude': _position!.latitude,
          'longitude': _position!.longitude,
          'createdBy': auth.user?.username ?? '',
          'userId': auth.user?.userId ?? 0,
          'notes': _position!.isMocked ? 'Fake GPS' : '',
        },
      );

      if (!mounted) return;
      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ??
          (isSuccess
              ? (checkType == 'IN' ? 'تم تسجيل الحضور بنجاح' : 'تم تسجيل الانصراف بنجاح')
              : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(msg, style: GoogleFonts.ibmPlexSansArabic())),
            ],
          ),
          backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map<String, dynamic>?)?['messageAr'] ??
          'تعذّر الاتصال بالسيرفر';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _mapUrl {
    if (_position == null) return '';
    final lat = _position!.latitude;
    final lng = _position!.longitude;
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=16'
        '&size=600x300'
        '&scale=2'
        '&maptype=roadmap'
        '&markers=color:red%7C$lat,$lng'
        '&key=$_mapsKey';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'الحضور والانصراف',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Clock Card ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Time
                  Text(
                    _displayTimeFmt.format(_now),
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date
                  Text(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(_now),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Map Card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMapContent(),
            ),

            const SizedBox(height: 12),

            // ── Coordinates ─────────────────────────────────────────
            if (_position != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────────────
            Row(
              children: [
                // Check IN
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _checkIn,
                      icon: const Icon(Icons.login_rounded, size: 22),
                      label: Text('حضور',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Check OUT
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _checkOut,
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      label: Text('انصراف',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_submitting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
              ),
            ],

            const SizedBox(height: 24),

            // ── Info Note ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يتم تسجيل الحضور والانصراف تلقائياً بالوقت والتاريخ الحالي مع الموقع الجغرافي.',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_loadingLocation) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('جاري تحديد الموقع...'),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded,
                  size: 36, color: AppColors.textTertiary),
              const SizedBox(height: 8),
              Text(
                _locationError!,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    // Static map image
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _mapUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2));
          },
          errorBuilder: (_, __, ___) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined,
                    size: 36, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text('تعذّر تحميل الخريطة',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        // Refresh location button
        Positioned(
          top: 8,
          left: 8,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: _getLocation,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.my_location_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

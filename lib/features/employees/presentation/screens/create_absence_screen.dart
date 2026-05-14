import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/employee_model.dart';

class CreateAbsenceScreen extends ConsumerStatefulWidget {
  final Employee employee;
  const CreateAbsenceScreen({super.key, required this.employee});

  @override
  ConsumerState<CreateAbsenceScreen> createState() =>
      _CreateAbsenceScreenState();
}

class _CreateAbsenceScreenState extends ConsumerState<CreateAbsenceScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSubmitting = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dio = DioClient().dio;

  int get _days => _endDate.difference(_startDate).inDays + 1;

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime(2020) : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final response = await _dio.post(
        ApiConstants.createAbsence,
        data: {
          'employeeId': widget.employee.employeeId,
          'absenceDate': _dateFormat.format(_startDate),
          'endDate': _dateFormat.format(_endDate),
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (!mounted) return;

      if (data['status'] == 'success') {
        _showSuccess(data['messageAr'] ?? 'تم تسجيل الغياب بنجاح');
      } else {
        _showError(data['messageAr'] ?? 'حدث خطأ');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map<String, dynamic>?)?['messageAr'] ??
          'تعذّر الاتصال بالسيرفر';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('تم',
                style: GoogleFonts.ibmPlexSansArabic(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('تسجيل غياب',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.employee.code,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.employee.fullNameAr,
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        if (widget.employee.jobTitle != null)
                          Text(widget.employee.jobTitle!,
                              style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date pickers
            Text('الفترة الزمنية',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'من',
                    date: _dateFormat.format(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateCard(
                    label: 'إلى',
                    date: _dateFormat.format(_endDate),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Days count
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_busy_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text(
                    'عدد أيام الغياب: $_days ${_days == 1 ? 'يوم' : 'أيام'}',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text('تسجيل الغياب',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateCard(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(date,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

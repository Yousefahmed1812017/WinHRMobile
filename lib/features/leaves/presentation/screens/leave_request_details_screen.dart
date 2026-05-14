import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_provider.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/leaves_provider.dart';

class LeaveRequestDetailsScreen extends ConsumerStatefulWidget {
  final LeaveRequest request;
  const LeaveRequestDetailsScreen({super.key, required this.request});

  @override
  ConsumerState<LeaveRequestDetailsScreen> createState() =>
      _LeaveRequestDetailsScreenState();
}

class _LeaveRequestDetailsScreenState
    extends ConsumerState<LeaveRequestDetailsScreen> {
  bool _submitting = false;
  final _notesController = TextEditingController();

  Future<void> _updateStatus(int statusId) async {
    setState(() => _submitting = true);
    try {
      final auth = ref.read(authStateProvider);
      final dio = DioClient().dio;

      final response = await dio.post(
        ApiConstants.updateLeaveStatus,
        data: {
          'leaveRequestId': widget.request.id,
          'statusId': statusId,
          'notes': _notesController.text.trim(),
          'createdBy': auth.user?.username ?? '',
          'userId': auth.user?.userId ?? 0,
        },
      );

      if (!mounted) return;
      
      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ??
          (isSuccess ? 'تم تحديث الحالة بنجاح' : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
          backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (isSuccess) {
        // Refresh the list to reflect new status
        ref.read(leaveRequestsListProvider.notifier).loadAll();
        context.pop(true); // Return true indicating success
      }
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(int? id) {
    switch (id) {
      case 1:
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      case 5:
        return AppColors.danger;
      case 6:
        return AppColors.textTertiary;
      default:
        return AppColors.info;
    }
  }

  String _getStatusLabel(int? id) {
    switch (id) {
      case 1: return 'جديد';
      case 2: return 'قيد الانتظار';
      case 3: return 'قيد المراجعة';
      case 4: return 'معتمد';
      case 5: return 'مرفوض';
      case 6: return 'ملغي';
      default: return 'أخرى';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final color = _getStatusColor(r.statusId);
    final label = _getStatusLabel(r.statusId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        title: Text(
          'تفاصيل الإجازة',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.event_note_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('حالة الطلب',
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13, color: AppColors.textSecondary)),
                        Text(label,
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  _DetailRow('الموظف', r.employeeName ?? 'كود: ${r.employeeCode ?? "-"}'),
                  const Divider(height: 24),
                  _DetailRow('نوع الإجازة', r.leaveType ?? '-'),
                  const Divider(height: 24),
                  _DetailRow('تاريخ الطلب', r.requestDate ?? '-'),
                  const Divider(height: 24),
                  _DetailRow('من تاريخ', r.startDate ?? '-'),
                  const Divider(height: 24),
                  _DetailRow('إلى تاريخ', r.endDate ?? '-'),
                  const Divider(height: 24),
                  _DetailRow('عدد الأيام', '${r.totalLeaveDays ?? "-"} يوم'),
                  if (r.decisionNumber != null && r.decisionNumber!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _DetailRow('رقم القرار', r.decisionNumber!),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action section if pending
            if (r.isPending) ...[
              Text('الإجراء',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظاتك هنا (اختياري)...',
                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : () => _updateStatus(4),
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: Text('اعتماد',
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : () => _updateStatus(5),
                        icon: const Icon(Icons.cancel_rounded, size: 22),
                        label: Text('رفض',
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_submitting)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(color: AppColors.primary),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

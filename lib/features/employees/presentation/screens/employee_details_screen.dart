import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/models/employee_model.dart';
import '../../../leaves/data/leaves_provider.dart';

/// Employee details screen showing all employee data in organized sections
/// plus their leave requests.
class EmployeeDetailsScreen extends ConsumerStatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  ConsumerState<EmployeeDetailsScreen> createState() =>
      _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState
    extends ConsumerState<EmployeeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load leave requests for this employee
    Future.microtask(() {
      ref
          .read(employeeLeaveRequestsProvider.notifier)
          .load(widget.employee.code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(employeeLeaveRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.background,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      // Code circle
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentSurface,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accent.withValues(alpha: 0.08),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.employee.code,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.employee.fullNameAr,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.employee.jobTitle != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.employee.jobTitle!,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status Badge
                _buildStatusHeader(),
                const SizedBox(height: 16),

                // Personal Info
                _SectionCard(
                  title: 'البيانات الشخصية',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _InfoRow(
                        label: 'الاسم بالعربي',
                        value: widget.employee.fullNameAr),
                    _InfoRow(
                        label: 'الاسم بالإنجليزي',
                        value: widget.employee.fullNameEn),
                    _InfoRow(
                        label: 'كود الموظف', value: widget.employee.code),
                  ],
                ),
                const SizedBox(height: 12),

                // Job Info
                _SectionCard(
                  title: 'البيانات الوظيفية',
                  icon: Icons.work_outline_rounded,
                  children: [
                    _InfoRow(
                        label: 'المسمى الوظيفي',
                        value: widget.employee.jobTitle ?? '-'),
                    _InfoRow(
                        label: 'الإدارة',
                        value: widget.employee.department ?? '-'),
                    _InfoRow(
                        label: 'تاريخ التعيين',
                        value: widget.employee.hireDate ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),

                // Shift Info
                _SectionCard(
                  title: 'بيانات الوردية',
                  icon: Icons.schedule_rounded,
                  children: [
                    _InfoRow(
                        label: 'نوع الوردية',
                        value: widget.employee.shiftType ?? '-'),
                    _InfoRow(
                        label: 'اسم الوردية',
                        value: widget.employee.shiftName ?? '-'),
                    _InfoRow(
                        label: 'المجموعة',
                        value: widget.employee.groupName ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),

                // Employment Status
                _SectionCard(
                  title: 'الحالة الوظيفية',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _InfoRow(
                        label: 'الحالة',
                        value: widget.employee.employeeStatus ?? '-'),
                    if (widget.employee.terminationDate != null &&
                        widget.employee.terminationDate != '-')
                      _InfoRow(
                          label: 'تاريخ إنهاء الخدمة',
                          value: widget.employee.terminationDate!),
                    if (widget.employee.decisionNumber != null)
                      _InfoRow(
                          label: 'رقم القرار',
                          value: widget.employee.decisionNumber!),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Leave Requests Section ─────────────────────────────
                _buildLeaveRequestsSection(leaveState),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (widget.employee.isActive) {
      bg = AppColors.activeBg;
      fg = AppColors.activeFg;
      icon = Icons.check_circle_outline_rounded;
      label = 'يعمل';
    } else if (widget.employee.isRetired) {
      bg = AppColors.retiredBg;
      fg = AppColors.retiredFg;
      icon = Icons.event_available_rounded;
      label = 'متقاعد';
    } else if (widget.employee.isDeceased) {
      bg = AppColors.deceasedBg;
      fg = AppColors.deceasedFg;
      icon = Icons.sentiment_dissatisfied_rounded;
      label = 'وفاة';
    } else {
      bg = AppColors.surfaceVariant;
      fg = AppColors.textSecondary;
      icon = Icons.info_outline_rounded;
      label = widget.employee.employeeStatus ?? '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Text(
            'الحالة: $label',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const Spacer(),
          if (widget.employee.hireDate != null)
            Text(
              'تاريخ التعيين: ${widget.employee.hireDate}',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: fg.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestsSection(EmployeeLeaveRequestsState leaveState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_note_rounded,
                  size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'طلبات الإجازة',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (leaveState.requests.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${leaveState.requests.length}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (leaveState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (leaveState.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'خطأ في تحميل الإجازات',
                    style: GoogleFonts.ibmPlexSansArabic(color: AppColors.danger),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(employeeLeaveRequestsProvider.notifier)
                      .load(widget.employee.code),
                  child: Text('إعادة', style: GoogleFonts.ibmPlexSansArabic()),
                ),
              ],
            ),
          )
        else if (leaveState.requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 40,
                      color: AppColors.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد طلبات إجازة لهذا الموظف',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...leaveState.requests.map(
            (req) => _SimpleLeaveCard(request: req),
          ),
      ],
    );
  }
}

class _SimpleLeaveCard extends StatelessWidget {
  final dynamic request;
  const _SimpleLeaveCard({required this.request});

  @override
  Widget build(BuildContext context) {
    Color c;
    String label;
    switch (request.statusId) {
      case 1: case 2: case 3:
        c = AppColors.warning; label = 'معلق'; break;
      case 4:
        c = AppColors.success; label = 'معتمد'; break;
      case 5:
        c = AppColors.danger; label = 'مرفوض'; break;
      default:
        c = AppColors.info; label = 'أخرى';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_note_rounded, size: 20, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.leaveType ?? '-',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                Text('${request.startDate ?? "-"} → ${request.endDate ?? "-"}',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Section Card
// ═══════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Rows
          ...children,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Info Row
// ═══════════════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

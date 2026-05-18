import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_provider.dart';
import '../../data/employees_provider.dart';
import '../../data/models/employee_model.dart';

class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(subordinatesProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(subordinatesProvider.notifier).search(value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(subordinatesProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subordinatesProvider);
    final list = state.filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              pinned: true,
              floating: true,
              snap: true,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
              title: Text(
                'الموظفين',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'بحث بالاسم أو الكود',
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textTertiary),
                        suffixIcon: state.searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: _clearSearch,
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textTertiary),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // ── Filter Tabs ───────────────────────────────────────────────
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  GestureDetector(
                    onTap: () => ref.read(subordinatesProvider.notifier).setStatusFilter('ALL'),
                    child: _FilterTab(
                      label: 'الكل',
                      count: '${state.employees.length}',
                      isActive: state.statusFilter == 'ALL',
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => ref.read(subordinatesProvider.notifier).setStatusFilter('PRESENT'),
                    child: _FilterTab(
                      label: 'حاضر',
                      count: '${state.employees.where((e) => e.attendanceStatus == 'PRESENT_COMPLETE' || e.attendanceStatus == 'PRESENT_NO_OUT').length}',
                      isActive: state.statusFilter == 'PRESENT',
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => ref.read(subordinatesProvider.notifier).setStatusFilter('LEAVE'),
                    child: _FilterTab(
                      label: 'إجازة',
                      count: '${state.employees.where((e) => e.attendanceStatus == 'LEAVE').length}',
                      isActive: state.statusFilter == 'LEAVE',
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => ref.read(subordinatesProvider.notifier).setStatusFilter('ABSENT'),
                    child: _FilterTab(
                      label: 'غائب',
                      count: '${state.employees.where((e) => e.attendanceStatus == 'ABSENT').length}',
                      isActive: state.statusFilter == 'ABSENT',
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => ref.read(subordinatesProvider.notifier).setStatusFilter('NOT_PRESENT'),
                    child: _FilterTab(
                      label: 'لم يحضر',
                      count: '${state.employees.where((e) => e.attendanceStatus == 'NOT_PRESENT').length}',
                      isActive: state.statusFilter == 'NOT_PRESENT',
                    ),
                  ),
                ],
              ),
            ),

            // ── Date Picker Row ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(), // Restrict to today max
                    locale: const Locale('ar'),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    ref.read(subordinatesProvider.notifier).load(checkDate: _dateFmt.format(picked));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'تاريخ اليومية:',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateFmt.format(_selectedDate),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
            
            // ── Employee List ───────────────────────────────────────────────
            Expanded(child: _buildBody(state, list)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SubordinatesState state, List<Employee> list) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2.5),
      );
    }

    if (state.errorMessage != null && state.employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('تعذّر الاتصال',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(subordinatesProvider.notifier).load(),
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.ibmPlexSansArabic(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          state.searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا يوجد موظفون',
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, color: AppColors.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(subordinatesProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _EmployeeCard(
          employee: list[index],
          onTap: () => _showEmployeeActionSheet(context, list[index]),
        ),
      ),
    );
  }

  void _showEmployeeActionSheet(BuildContext ctx, Employee emp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _EmployeeActionSheet(
        employee: emp,
        parentRef: ref,
        selectedDate: _selectedDate,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Employee Card (No inline actions)
// ─────────────────────────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nameParts = employee.fullNameAr.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final initials = nameParts.isEmpty ? '?' : nameParts.take(2).map((w) => w[0]).join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar (Right in RTL)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: -2,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Middle (Name & Job)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullNameAr,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (employee.jobTitle != null && employee.jobTitle != '-')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_outline_rounded, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            employee.jobTitle!,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (employee.attendanceStatusAr != null && employee.attendanceStatusAr!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (employee.checkInTime != null && employee.checkInTime != '-') ...[
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            employee.checkInTime!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(employee.attendanceStatus).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getStatusColor(employee.attendanceStatus).withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            employee.attendanceStatusAr!,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(employee.attendanceStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Left side (Code & Status)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '#${employee.code}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: employee.employeeStatus == 'يعمل' ? AppColors.success : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.employeeStatus ?? 'غير معروف',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PRESENT_COMPLETE':
        return AppColors.success;
      case 'PRESENT_NO_OUT':
        return AppColors.primary;
      case 'LEAVE':
        return AppColors.warning;
      case 'ABSENT':
        return AppColors.danger;
      case 'NOT_PRESENT':
      default:
        return AppColors.textTertiary;
    }
  }

}

// ─────────────────────────────────────────────────────────────────────────────
//  Info Row Helper
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Filter Tab
// ─────────────────────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final String count;
  final bool isActive;

  const _FilterTab({required this.label, required this.count, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 30,
            color: AppColors.primary,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Employee Action Bottom Sheet (The Redesigned Action Grid)
// ─────────────────────────────────────────────────────────────────────────────
class _EmployeeActionSheet extends StatelessWidget {
  final Employee employee;
  final WidgetRef parentRef;
  final DateTime selectedDate;

  const _EmployeeActionSheet({
    required this.employee,
    required this.parentRef,
    required this.selectedDate,
  });

  bool get _hasPunched =>
      employee.checkInTime != null &&
      employee.checkInTime != '-' &&
      employee.checkInTime!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final nameParts = employee.fullNameAr.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final initials = nameParts.isEmpty ? '?' : nameParts.take(2).map((w) => w[0]).join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header (Avatar, Name, Code/Job, Pin, Close)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Right Avatar
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Name & Job
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullNameAr,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '#${employee.code} · ${employee.jobTitle ?? "-"}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Actions (Eye, Calendar)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    GoRouter.of(context).push(RouteNames.employeeDetails, extra: employee);
                  },
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.info, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    GoRouter.of(context).push(RouteNames.employeeAttendance, extra: employee);
                  },
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // ── Past Day Guard ────────────────────────────────────────────
          Builder(builder: (context) {
            final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
            final sel = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
            final isToday = sel == today;

            if (!isToday) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded,
                        color: Color(0xFFEA580C), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('يوم منتهي',
                              style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEA580C))),
                          const SizedBox(height: 2),
                          Text(
                            'لا يمكن إضافة أي إجراء على يوم سابق.\nالإجراءات متاحة ليوم اليوم فقط.',
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: const Color(0xFF9A3412)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // ── Today: show all actions ───────────────────────────────
            return Column(
              children: [
                if (_hasPunched) ...[  
                  // Actions if employee has punched in
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _ActionGridItem(
                          icon: Icons.more_time_rounded,
                          label: 'إضافي',
                          onTap: () {
                            Navigator.pop(context);
                            _showOvertimeSheet(context, employee);
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ActionGridItem(
                          icon: Icons.beach_access_rounded,
                          label: 'سنوية (نصف يوم)',
                          onTap: () {
                            Navigator.pop(context);
                            _showLeaveSheet(context, employee, 3, 'إجازة سنوية (نصف يوم)', halfDay: true);
                          },
                        )),
                      ],
                    ),
                  ),
                ] else ...[  
                  // ── Primary Actions Row ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _ActionGridItem(
                          icon: Icons.beach_access_rounded,
                          label: 'سنوية',
                          onTap: () {
                            Navigator.pop(context);
                            _showLeaveSheet(context, employee, 3, 'إجازة سنوية');
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ActionGridItem(
                          icon: Icons.free_breakfast_rounded,
                          label: 'عارضة',
                          onTap: () {
                            Navigator.pop(context);
                            _showLeaveSheet(context, employee, 24, 'إجازة عارضة');
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ActionGridItem(
                          icon: Icons.event_busy_rounded,
                          label: 'غياب',
                          onTap: () {
                            Navigator.pop(context);
                            _showAbsenceSheet(context, employee);
                          },
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Secondary Actions Row ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _ActionGridItem(
                          icon: Icons.money_off_rounded,
                          label: 'بالخصم',
                          onTap: () {
                            Navigator.pop(context);
                            _showLeaveSheet(context, employee, 25, 'إجازة بالخصم');
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ActionGridItem(
                          icon: Icons.swap_horiz_rounded,
                          label: 'بدل يعوض',
                          onTap: () {
                            Navigator.pop(context);
                            _showLeaveSheet(context, employee, 81, 'إجازة بدل يعوض');
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ActionGridItem(
                          icon: Icons.directions_walk_rounded,
                          label: 'مأمورية',
                          onTap: () {
                            Navigator.pop(context);
                            _showMissionSheet(context, employee);
                          },
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Tertiary Actions Row ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _ActionGridItem(
                          icon: Icons.call_rounded,
                          label: 'استدعاء',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('استدعاء — قريباً')));
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ActionGridItem(
                          icon: Icons.assignment_rounded,
                          label: 'تصريح',
                          onTap: () {
                            Navigator.pop(context);
                            _showWorkPermitSheet(context, employee);
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),  // end Builder
        ],
      ),
    );
  }

  // Wrappers to call the existing bottom sheets from the global namespace or parent ref
  void _showLeaveSheet(BuildContext ctx, Employee emp, int typeId, String typeName, {bool halfDay = false}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LeaveBottomSheet(
        employee: emp,
        leaveTypeId: typeId,
        leaveTypeName: typeName,
        halfDay: halfDay,
        ref: parentRef,
      ),
    );
  }

  void _showOvertimeSheet(BuildContext ctx, Employee emp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OvertimeBottomSheet(employee: emp, ref: parentRef),
    );
  }

  void _showAbsenceSheet(BuildContext ctx, Employee emp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AbsenceBottomSheet(employee: emp, ref: parentRef),
    );
  }

  void _showMissionSheet(BuildContext ctx, Employee emp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MissionBottomSheet(employee: emp, ref: parentRef),
    );
  }

  void _showWorkPermitSheet(BuildContext ctx, Employee emp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WorkPermitBottomSheet(employee: emp, ref: parentRef),
    );
  }
}

class _ActionGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionGridItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Leave Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LeaveBottomSheet extends StatefulWidget {
  final Employee employee;
  final int leaveTypeId;
  final String leaveTypeName;
  final bool halfDay;
  final WidgetRef ref;

  const _LeaveBottomSheet({
    required this.employee,
    required this.leaveTypeId,
    required this.leaveTypeName,
    this.halfDay = false,
    required this.ref,
  });

  @override
  State<_LeaveBottomSheet> createState() => _LeaveBottomSheetState();
}

class _LeaveBottomSheetState extends State<_LeaveBottomSheet> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final _fmt = DateFormat('dd/MM/yyyy');

  int get _days => _endDate.difference(_startDate).inDays + 1;
  double get _totalLeaveDays => widget.halfDay ? 0.5 : _days.toDouble();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final first = isStart ? today : (_startDate.isAfter(today) ? _startDate : today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
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
      // Read managerId from secure storage
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '') ?? 0;
      final usernameStr = await storage.read(key: StorageKeys.username);

      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createLeaveRequestWithManager,
        data: {
          'employeeId': widget.employee.employeeId,
          'managerId': managerId,
          'leaveTypeId': widget.leaveTypeId,
          'startDate': _fmt.format(_startDate),
          'endDate': _fmt.format(_endDate),
          'totalLeaveDays': _totalLeaveDays,
          'weekendDays': 0,
          'officialHolidays': 0,
          'workingDays': 0,
          'leaveReason': widget.leaveTypeName,
          'emergencyPhone': '',
          'username': usernameStr ?? '',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ?? (isSuccess ? 'تم بنجاح' : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Leave type title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  widget.leaveTypeName,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Employee name
          Text(
            widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          // Date pickers row
          Row(
            children: [
              Expanded(child: _dateCard('من', _fmt.format(_startDate), () => _pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _dateCard('إلى', _fmt.format(_endDate), () => _pickDate(false))),
            ],
          ),
          const SizedBox(height: 8),

          // Days count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.halfDay
                  ? 'عدد الأيام: نصف يوم'
                  : 'عدد الأيام: $_days ${_days == 1 ? "يوم" : "أيام"}',
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ملاحظات (اختياري)...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('تأكيد الإجازة',
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCard(String label, String date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(date, style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Absence Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AbsenceBottomSheet extends StatefulWidget {
  final Employee employee;
  final WidgetRef ref;
  const _AbsenceBottomSheet({required this.employee, required this.ref});

  @override
  State<_AbsenceBottomSheet> createState() => _AbsenceBottomSheetState();
}

class _AbsenceBottomSheetState extends State<_AbsenceBottomSheet> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final _fmt = DateFormat('dd/MM/yyyy');

  int get _days => _endDate.difference(_startDate).inDays + 1;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final first = isStart ? today : (_startDate.isAfter(today) ? _startDate : today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
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
      final auth = widget.ref.read(authStateProvider);
      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createAbsence,
        data: {
          'employeeId': widget.employee.employeeId,
          'absenceDate': _fmt.format(_startDate),
          'endDate': _fmt.format(_endDate),
          'absenceDays': _days,
          'notes': _notesController.text.trim(),
          'status': 1,
          'createdBy': auth.user?.username ?? '',
          'userId': auth.user?.userId ?? 0,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ?? (isSuccess ? 'تم تسجيل الغياب بنجاح' : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded, size: 20, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text('تسجيل غياب',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text(widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          // Dates
          Row(
            children: [
              Expanded(child: _dateCard('من', _fmt.format(_startDate), () => _pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _dateCard('إلى', _fmt.format(_endDate), () => _pickDate(false))),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'عدد أيام الغياب: $_days ${_days == 1 ? "يوم" : "أيام"}',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ملاحظات (اختياري)...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true, fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('تسجيل الغياب',
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCard(String label, String date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(date, style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Overtime / Compensate Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _OvertimeBottomSheet extends StatefulWidget {
  final Employee employee;
  final WidgetRef ref;
  const _OvertimeBottomSheet({required this.employee, required this.ref});

  @override
  State<_OvertimeBottomSheet> createState() => _OvertimeBottomSheetState();
}

class _OvertimeBottomSheetState extends State<_OvertimeBottomSheet> {
  DateTime _date = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final _fmt = DateFormat('dd/MM/yyyy');
  
  // 1 = يعوض (compensate), 2 = إضافي (overtime)
  int _selectedType = 1;
  int _ctoHours = 4; // default 4, max 8

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Date is locked to today — no picker needed

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final auth = widget.ref.read(authStateProvider);
      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createCto,
        data: {
          'employeeId': widget.employee.employeeId,
          'ctoDate': _fmt.format(_date),
          'ctoTransactionTypeId': _selectedType,
          'ctoHours': _selectedType == 2 ? _ctoHours : 4,
          'notes': _notesController.text.trim(),
          'userId': auth.user?.userId ?? 0,
          'createdBy': auth.user?.username ?? '',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ?? (isSuccess ? 'تم تسجيل الطلب بنجاح' : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.more_time_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إضافي / بدل يعوض', style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                    Text(widget.employee.fullNameAr, style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Radio Group
          Row(
            children: [
              Expanded(
                child: RadioListTile<int>(
                  value: 1,
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val!),
                  title: Text('يعوض', style: GoogleFonts.ibmPlexSansArabic(fontSize: 14)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<int>(
                  value: 2,
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val!),
                  title: Text('إضافي', style: GoogleFonts.ibmPlexSansArabic(fontSize: 14)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hours stepper — only for إضافي
          if (_selectedType == 2) ...[            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text('عدد الساعات الإضافية:',
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _ctoHours > 4 ? () => setState(() => _ctoHours--) : null,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _ctoHours > 4 ? AppColors.primarySurface : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.remove_rounded, size: 18,
                          color: _ctoHours > 4 ? AppColors.primary : AppColors.textTertiary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_ctoHours',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: _ctoHours < 8 ? () => setState(() => _ctoHours++) : null,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _ctoHours < 8 ? AppColors.primarySurface : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_rounded, size: 18,
                          color: _ctoHours < 8 ? AppColors.primary : AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Date — locked to today only
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('التاريخ:', style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(_fmt.format(_date), style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const Spacer(),
                Text('اليوم فقط', style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _notesController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ملاحظات (اختياري)...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('حفظ وتسجيل', style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Mission Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _MissionBottomSheet extends StatefulWidget {
  final Employee employee;
  final WidgetRef ref;
  const _MissionBottomSheet({required this.employee, required this.ref});

  @override
  State<_MissionBottomSheet> createState() => _MissionBottomSheetState();
}

class _MissionBottomSheetState extends State<_MissionBottomSheet> {
  final _fmt = DateFormat('dd/MM/yyyy');
  final _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  late DateTime _startDate;
  late DateTime _endDate;
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;
  String _missionType = 'INTERNAL'; // INTERNAL or EXTERNAL

  @override
  void initState() {
    super.initState();
    _startDate = _today;
    _endDate = _today;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final first = isStart ? _today : (_startDate.isAfter(_today) ? _startDate : _today);
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
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

  int get _days => _endDate.difference(_startDate).inDays + 1;

  Future<void> _submit() async {
    final dest = _destinationController.text.trim();
    final purpose = _purposeController.text.trim();
    if (dest.isEmpty || purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('يرجى تعبئة الوجهة والغرض من المأمورية',
            style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final auth = widget.ref.read(authStateProvider);
      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createMission,
        data: {
          'employeeId': widget.employee.employeeId,
          'missionType': _missionType,
          'startDate': _fmt.format(_startDate),
          'endDate': _fmt.format(_endDate),
          'destination': dest,
          'missionPurpose': purpose,
          'username': auth.user?.username ?? '',
          'userId': auth.user?.userId ?? 0,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ?? (isSuccess ? 'تم تسجيل المأمورية بنجاح' : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map<String, dynamic>?)?['messageAr'] ??
          'تعذّر الاتصال بالسيرفر';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.directions_walk_rounded,
                      color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسجيل مأمورية',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(widget.employee.fullNameAr,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mission Type Toggle
            Text('نوع المأمورية',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _typeButton('INTERNAL', 'داخلية', Icons.location_city_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _typeButton('EXTERNAL', 'خارجية', Icons.flight_takeoff_rounded)),
              ],
            ),
            const SizedBox(height: 16),

            // Date Pickers
            Text('الفترة الزمنية',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _dateCard('من', _fmt.format(_startDate), () => _pickDate(true))),
                const SizedBox(width: 10),
                Expanded(child: _dateCard('إلى', _fmt.format(_endDate), () => _pickDate(false))),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                'مدة المأمورية: $_days ${_days == 1 ? "يوم" : "أيام"}',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.info),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            // Destination
            Text('الوجهة',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _destinationController,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'مثال: القاهرة، الإسكندرية...',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Purpose
            Text('الغرض من المأمورية',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _purposeController,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'صف غرض المأمورية...',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, color: AppColors.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('تسجيل المأمورية',
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String value, String label, IconData icon) {
    final selected = _missionType == value;
    return GestureDetector(
      onTap: () => setState(() => _missionType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF16A34A) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? const Color(0xFF16A34A)
                  : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _dateCard(String label, String date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(date,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Work Permit Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _WorkPermitBottomSheet extends StatefulWidget {
  final Employee employee;
  final WidgetRef ref;
  const _WorkPermitBottomSheet({required this.employee, required this.ref});

  @override
  State<_WorkPermitBottomSheet> createState() => _WorkPermitBottomSheetState();
}

class _WorkPermitBottomSheetState extends State<_WorkPermitBottomSheet> {
  final _fmt = DateFormat('dd/MM/yyyy');
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final DateTime _permitDate = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final auth = widget.ref.read(authStateProvider);
      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createWorkPermit,
        data: {
          'employeeId': widget.employee.employeeId,
          'permitDate': _fmt.format(_permitDate),
          'notes': _notesController.text.trim(),
          'username': auth.user?.username ?? '',
          'userId': auth.user?.userId ?? 0,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      final msg = data['messageAr'] ?? (isSuccess ? 'تم إصدار التصريح بنجاح' : 'حدث خطأ');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map<String, dynamic>?)?['messageAr'] ??
          'تعذّر الاتصال بالسيرفر';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_rounded,
                    color: Color(0xFFEA580C), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تصريح عمل',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(widget.employee.fullNameAr,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date — locked to today
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: Color(0xFFEA580C)),
                const SizedBox(width: 10),
                Text('تاريخ التصريح:',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(_fmt.format(_permitDate),
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text('اليوم فقط',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Notes
          Text('ملاحظات (اختياري)',
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أسباب إصدار التصريح...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13, color: AppColors.textTertiary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('إصدار التصريح',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

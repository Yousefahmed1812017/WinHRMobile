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
                      count: '${state.employees.where((e) => e.attendanceStatus == 'PRESENT' || e.attendanceStatus == 'PRESENT_COMPLETE' || e.attendanceStatus == 'PRESENT_NO_OUT').length}',
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
                  child: const Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: AppColors.primary,
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
      case 'PRESENT':
      case 'PRESENT_COMPLETE':
        return AppColors.success;
      case 'PRESENT_NO_OUT':
        return AppColors.primary;
      case 'LEAVE':
        return AppColors.warning;
      case 'ABSENT':
        return AppColors.danger;
      case 'DAY_OFF':
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

class _EmployeeActionSheet extends StatelessWidget {
  final Employee employee;

  const _EmployeeActionSheet({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Text(
            employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '#' + employee.code + ' · ' + (employee.jobTitle ?? '-'),
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: Text('الملف الشخصي', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push(RouteNames.employeeDetails, extra: employee);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: AppColors.primary),
            title: Text('سجل الحضور والانصراف', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push(RouteNames.employeeAttendance, extra: employee);
            },
          ),
          ListTile(
            leading: const Icon(Icons.beach_access_outlined, color: AppColors.primary),
            title: Text('سجل الإجازات', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push(RouteNames.leaveRequests);
            },
          ),
        ],
      ),
    );
  }
}

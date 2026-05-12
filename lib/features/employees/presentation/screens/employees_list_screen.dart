import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الموظفين',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (state.pagination != null && !state.isLoading)
              Text(
                '${state.pagination!.totalRecords} موظف',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الكود...',
                  hintStyle: GoogleFonts.cairo(
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(state, list),
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
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(subordinatesProvider.notifier).load(),
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          state.searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا يوجد موظفون',
          style: GoogleFonts.cairo(
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
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _EmployeeCard(
          employee: list[index],
          onTap: () => _showActions(context, list[index]),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, Employee employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActionSheet(employee: employee),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ActionSheet extends StatelessWidget {
  final Employee employee;
  const _ActionSheet({required this.employee});

  static const _actions = [
    _Action(icon: Icons.event_busy_rounded,   label: 'غياب',            color: Color(0xFFEF4444), leaveTypeId: null,  isAbsence: true),
    _Action(icon: Icons.beach_access_rounded, label: 'إجازة سنوية',     color: Color(0xFF2563EB), leaveTypeId: 3,    isAbsence: false),
    _Action(icon: Icons.free_breakfast_rounded, label: 'إجازة عارضة',   color: Color(0xFF16A34A), leaveTypeId: 24,   isAbsence: false),
    _Action(icon: Icons.money_off_rounded,    label: 'إجازة خصم',       color: Color(0xFFF59E0B), leaveTypeId: 25,   isAbsence: false),
    _Action(icon: Icons.work_outline_rounded, label: 'مأمورية',          color: Color(0xFF7C3AED), leaveTypeId: null,  isAbsence: false),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Employee name
            Text(
              employee.fullNameAr,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'كود: ${employee.code}  •  ${employee.jobTitle ?? ''}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _actions.map((action) {
                return _ActionTile(
                  action: action,
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(context, action);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, _Action action) {
    if (action.isAbsence) {
      // TODO: navigate to absence registration screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تسجيل الغياب — قريباً',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (action.leaveTypeId == null) {
      // مأمورية — TODO: navigate to mission screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المأمورية — قريباً',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.push(
      RouteNames.createLeaveRequest,
      extra: {
        'employee': employee,
        'leaveTypeId': action.leaveTypeId,
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _Action action;
  final VoidCallback onTap;
  const _ActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: action.color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 26),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final int? leaveTypeId;
  final bool isAbsence;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.leaveTypeId,
    required this.isAbsence,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Employee Card
// ─────────────────────────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  employee.code,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + job
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullNameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (employee.jobTitle != null)
                      Text(
                        employee.jobTitle!,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              const Icon(Icons.chevron_left_rounded,
                  size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

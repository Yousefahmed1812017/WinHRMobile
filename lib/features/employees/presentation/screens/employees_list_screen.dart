import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/employees_provider.dart';
import '../../data/models/employee_model.dart';

/// Employees list screen with search by code and pagination — modernized.
class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(employeesListProvider.notifier).loadEmployees();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(employeesListProvider);
      if (!state.isLoadingMore && state.hasMore && state.searchCode == null) {
        ref.read(employeesListProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final code = _searchController.text.trim();
    if (code.isNotEmpty) {
      ref.read(employeesListProvider.notifier).searchByCode(code);
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(employeesListProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'قائمة الموظفين',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (state.pagination != null && !state.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.pagination!.totalRecords} موظف',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onSearch(),
                      style: GoogleFonts.cairo(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'بحث بكود الموظف...',
                        hintStyle: GoogleFonts.cairo(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textTertiary,
                        ),
                        suffixIcon: state.searchCode != null
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textTertiary),
                                onPressed: _onClearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    child: Material(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _onSearch,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.search, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EmployeesListState state) {
    if (state.isLoading && state.employees.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (state.errorMessage != null && state.employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 32, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(employeesListProvider.notifier).loadEmployees(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 32,
                  color: AppColors.textTertiary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.employees.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.employees.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        return _EmployeeCard(
          employee: state.employees[index],
          onTap: () {
            context.push(
              RouteNames.employeeDetails,
              extra: state.employees[index],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Modernized Employee Card Widget
// ═══════════════════════════════════════════════════════════════════════════
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Avatar with gradient ──────────────────────────
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      employee.code,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullNameAr,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (employee.jobTitle != null)
                        Row(
                          children: [
                            Icon(Icons.work_outline_rounded,
                                size: 13,
                                color: AppColors.textTertiary
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employee.jobTitle!,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (employee.department != null)
                        Row(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 13,
                                color: AppColors.textTertiary
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employee.department!,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Status + Arrow ───────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(employee: employee),
                    if (employee.shiftType != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          employee.shiftType!,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(width: 4),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Employee employee;
  const _StatusBadge({required this.employee});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (employee.isActive) {
      bg = AppColors.activeBg;
      fg = AppColors.activeFg;
      label = 'يعمل';
    } else if (employee.isRetired) {
      bg = AppColors.retiredBg;
      fg = AppColors.retiredFg;
      label = 'متقاعد';
    } else if (employee.isDeceased) {
      bg = AppColors.deceasedBg;
      fg = AppColors.deceasedFg;
      label = 'وفاة';
    } else {
      bg = AppColors.surfaceVariant;
      fg = AppColors.textSecondary;
      label = employee.employeeStatus ?? '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

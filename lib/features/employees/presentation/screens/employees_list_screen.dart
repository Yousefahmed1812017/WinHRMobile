import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../leaves/data/leaves_provider.dart';
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
                  _FilterTab(label: 'الكل', count: '${state.pagination?.totalRecords ?? 0}', isActive: false),
                  const SizedBox(width: 16),
                  _FilterTab(label: 'يعمل', count: '${list.length}', isActive: true),
                  const SizedBox(width: 16),
                  _FilterTab(label: 'إجازة', count: '0', isActive: false),
                  const SizedBox(width: 16),
                  _FilterTab(label: 'غياب', count: '0', isActive: false),
                ],
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
      builder: (_) => _EmployeeActionSheet(employee: emp, parentRef: ref),
    );
  }

  void _handleAction(
      BuildContext context, Employee employee, _ActionType action) {
    // Leave actions → bottom sheet
    const leaveMap = {
      _ActionType.annualLeave:    _LeaveInfo(3,  'إجازة سنوية'),
      _ActionType.casualLeave:    _LeaveInfo(24, 'إجازة عارضة'),
      _ActionType.deductionLeave: _LeaveInfo(25, 'إجازة بالخصم'),
      _ActionType.compensatory:   _LeaveInfo(81, 'إجازة بدل يعوض'),
    };

    if (leaveMap.containsKey(action)) {
      final info = leaveMap[action]!;
      _showLeaveSheet(context, employee, info.id, info.label);
      return;
    }

    switch (action) {
      case _ActionType.absence:
        _showAbsenceSheet(context, employee);
        break;
      case _ActionType.mission:
        _showComingSoon(context, 'المأمورية');
        break;
      case _ActionType.workPermit:
        _showComingSoon(context, 'تصريح عمل');
        break;
      case _ActionType.overtime:
        _showOvertimeSheet(context, employee);
        break;
      case _ActionType.recall:
        _showComingSoon(context, 'استدعاء');
        break;
      default:
        break;
    }
  }

  void _showOvertimeSheet(BuildContext ctx, Employee emp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OvertimeBottomSheet(employee: emp, ref: ref),
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
      builder: (_) => _AbsenceBottomSheet(employee: emp, ref: ref),
    );
  }

  void _showLeaveSheet(BuildContext ctx, Employee emp, int typeId, String typeName) {
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
        ref: ref,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — قريباً', style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Types
// ─────────────────────────────────────────────────────────────────────────────
enum _ActionType {
  absence,
  annualLeave,
  casualLeave,
  deductionLeave,
  mission,
  compensatory,
  workPermit,
  overtime,
  recall,
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
    final initials = employee.fullNameAr.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();

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
                      const SizedBox(width: 6),
                      Text(
                        employee.employeeStatus ?? 'يعمل',
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

  const _EmployeeActionSheet({required this.employee, required this.parentRef});

  @override
  Widget build(BuildContext context) {
    final initials = employee.fullNameAr.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();

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

                // Actions (Pin, Close)
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.push_pin_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Primary Action: Annual Leave
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showLeaveSheet(context, employee, 3, 'إجازة سنوية');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFE53935)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Right Icon
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.beach_access_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب إجازة سنوية',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'الرصيد المتاح: 18 يوم', // Placeholder for now
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Left Chevron
                    const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Secondary Actions Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _ActionGridItem(
                  icon: Icons.free_breakfast_rounded,
                  label: 'عارضة',
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveSheet(context, employee, 24, 'إجازة عارضة');
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _ActionGridItem(
                  icon: Icons.more_time_rounded,
                  label: 'إضافي',
                  onTap: () {
                    Navigator.pop(context);
                    _showOvertimeSheet(context, employee);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _ActionGridItem(
                  icon: Icons.swap_horiz_rounded,
                  label: 'بدل يعوض',
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveSheet(context, employee, 81, 'إجازة بدل يعوض');
                  },
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _ActionGridItem(
                  icon: Icons.event_busy_rounded,
                  label: 'غياب',
                  onTap: () {
                    Navigator.pop(context);
                    _showAbsenceSheet(context, employee);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _ActionGridItem(
                  icon: Icons.money_off_rounded,
                  label: 'بالخصم',
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveSheet(context, employee, 25, 'إجازة بالخصم');
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _ActionGridItem(
                  icon: Icons.directions_walk_rounded,
                  label: 'مأمورية',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المأمورية — قريباً')));
                  },
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _ActionGridItem(
                  icon: Icons.call_rounded,
                  label: 'استدعاء',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استدعاء — قريباً')));
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _ActionGridItem(
                  icon: Icons.assignment_ind_rounded,
                  label: 'تصريح',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تصريح — قريباً')));
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: const SizedBox.shrink()), // Empty spacer for alignment
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Wrappers to call the existing bottom sheets from the global namespace or parent ref
  void _showLeaveSheet(BuildContext ctx, Employee emp, int typeId, String typeName) {
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
//  Leave Info helper
// ─────────────────────────────────────────────────────────────────────────────
class _LeaveInfo {
  final int id;
  final String label;
  const _LeaveInfo(this.id, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Leave Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LeaveBottomSheet extends StatefulWidget {
  final Employee employee;
  final int leaveTypeId;
  final String leaveTypeName;
  final WidgetRef ref;

  const _LeaveBottomSheet({
    required this.employee,
    required this.leaveTypeId,
    required this.leaveTypeName,
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime(2020) : _startDate;
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
      final repo = widget.ref.read(leavesRepositoryProvider);
      final result = await repo.createLeaveRequest(
        employeeId: widget.employee.employeeId,
        leaveTypeId: widget.leaveTypeId,
        startDate: _fmt.format(_startDate),
        endDate: _fmt.format(_endDate),
        totalLeaveDays: _days,
        notes: _notesController.text.trim(),
        username: auth.user?.username ?? '',
        userId: auth.user?.userId ?? 0,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = result;
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
              'عدد الأيام: $_days ${_days == 1 ? "يوم" : "أيام"}',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, fontWeight: FontWeight.w600,
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
    final first = isStart ? DateTime(2020) : _startDate;
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
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
    setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_selectedType == 2) return; // Should not happen since disabled
    
    setState(() => _isSubmitting = true);
    try {
      final auth = widget.ref.read(authStateProvider);
      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createCto,
        data: {
          'employeeId': widget.employee.employeeId,
          'ctoDate': _fmt.format(_date),
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
                  onChanged: null, // Disabled
                  title: Row(
                    children: [
                      Text('إضافي ', style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: AppColors.textTertiary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('قريباً', style: GoogleFonts.ibmPlexSansArabic(fontSize: 9, color: AppColors.warning)),
                      ),
                    ],
                  ),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                ],
              ),
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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../data/daily_logs_provider.dart';
import '../../data/models/daily_attendance_model.dart';

class DailyLogsScreen extends ConsumerStatefulWidget {
  const DailyLogsScreen({super.key});

  @override
  ConsumerState<DailyLogsScreen> createState() => _DailyLogsScreenState();
}

class _DailyLogsScreenState extends ConsumerState<DailyLogsScreen> {
  final _searchController = TextEditingController();
  late final ScrollController _calendarScrollController;
  late final List<DateTime> _calendarDates;

  @override
  void initState() {
    super.initState();
    _calendarDates = _generateCalendarDates();

    // Today is at index 3 (3 future days followed by Today, then 14 past days).
    // Each date card is 68.0 wide + 12.0 margin/spacing = 80.0.
    _calendarScrollController = ScrollController();

    // Animate smoothly to center "Today" after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarScrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        final targetOffset = (3 * 80.0) - (screenWidth / 2) + 34.0;
        _calendarScrollController.animateTo(
          targetOffset > 0 ? targetOffset : 0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  List<DateTime> _generateCalendarDates() {
    final today = DateTime.now();
    final todayZero = DateTime(today.year, today.month, today.day);
    List<DateTime> dates = [];

    // 3 future days (from +3 down to +1)
    for (int i = 3; i >= 1; i--) {
      dates.add(todayZero.add(Duration(days: i)));
    }
    // Today
    dates.add(todayZero);
    // 14 past days (from -1 down to -14)
    for (int i = 1; i <= 14; i++) {
      dates.add(todayZero.subtract(Duration(days: i)));
    }
    return dates;
  }

  void _onSearch(String value) {
    ref.read(dailyAttendanceProvider.notifier).search(value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(dailyAttendanceProvider.notifier).clearSearch();
  }

  Employee _toEmployee(DailyAttendanceRecord record) {
    return Employee(
      employeeId: record.employeeId,
      code: record.code,
      fullNameAr: record.fullName,
      fullNameEn: record.fullName,
      checkInTime: record.checkInTime,
      checkOutTime: record.checkOutTime,
      attendanceStatus: record.status,
      attendanceStatusAr: record.statusAr,
      jobTitle: '-',
      employeeStatus: 'يعمل',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyAttendanceProvider);
    final list = state.filtered;

    final allCount = state.records.length;
    final presentCount = state.records.where((r) => r.status == 'PRESENT').length;
    final leaveCount = state.records.where((r) => r.status == 'LEAVE').length;
    final absentCount = state.records.where((r) => r.status == 'ABSENT').length;
    final offCount = state.records.where((r) =>
        r.status == 'PUBLIC_HOLIDAY' ||
        r.status == 'WEEKLY_OFF' ||
        r.status == 'COMP_DAY').length;
    final fakeCount = state.fakeCount;

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
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اليوميات',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(state.selectedDate),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
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
                      ],
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
            // ── Horizontal Scroll Calendar Bar ──────────────────────────────
            Container(
              height: 112,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView.builder(
                  controller: _calendarScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: _calendarDates.length,
                  itemBuilder: (context, index) {
                    final date = _calendarDates[index];
                    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                    final dateZero = DateTime(date.year, date.month, date.day);
                    
                    final isFuture = dateZero.isAfter(today);
                    final isSelected = !isFuture &&
                        dateZero.year == state.selectedDate.year &&
                        dateZero.month == state.selectedDate.month &&
                        dateZero.day == state.selectedDate.day;
  
                    final dayNum = DateFormat('d').format(date);
                    final dayName = DateFormat('E', 'ar').format(date);
                    final monthName = DateFormat('MMM', 'ar').format(date);
  
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: isFuture
                            ? null
                            : () {
                                ref.read(dailyAttendanceProvider.notifier).selectDate(date);
                              },
                        child: Container(
                          width: 68,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isFuture ? Colors.grey.shade100 : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isFuture ? Colors.grey.shade200 : AppColors.border.withValues(alpha: 0.6)),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : (isFuture ? Colors.grey.shade400 : AppColors.textTertiary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayNum,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isFuture ? Colors.grey.shade400 : AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                monthName,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (isFuture ? Colors.grey.shade400 : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Stats Summary Row ─────────────────────────────────────────
            _StatsRow(
              presentCount: presentCount,
              absentCount: absentCount,
              leaveCount: leaveCount,
              offCount: offCount,
              fakeCount: fakeCount,
            ),
            const SizedBox(height: 2),

            // ── Filter Tabs ───────────────────────────────────────────────
            Container(
              height: 54,
              padding: const EdgeInsets.only(bottom: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  GestureDetector(
                    onTap: () => ref.read(dailyAttendanceProvider.notifier).setStatusFilter('ALL'),
                    child: _FilterTab(label: 'الكل', count: '$allCount', isActive: state.statusFilter == 'ALL'),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => ref.read(dailyAttendanceProvider.notifier).setStatusFilter('PRESENT'),
                    child: _FilterTab(label: 'حاضر', count: '$presentCount', isActive: state.statusFilter == 'PRESENT'),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => ref.read(dailyAttendanceProvider.notifier).setStatusFilter('LEAVE'),
                    child: _FilterTab(label: 'إجازة', count: '$leaveCount', isActive: state.statusFilter == 'LEAVE'),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => ref.read(dailyAttendanceProvider.notifier).setStatusFilter('ABSENT'),
                    child: _FilterTab(label: 'غائب', count: '$absentCount', isActive: state.statusFilter == 'ABSENT'),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => ref.read(dailyAttendanceProvider.notifier).setStatusFilter('OFF_DAYS'),
                    child: _FilterTab(label: 'عطلات', count: '$offCount', isActive: state.statusFilter == 'OFF_DAYS'),
                  ),
                  if (fakeCount > 0) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => ref.read(dailyAttendanceProvider.notifier).setStatusFilter('FAKE_LOCATION'),
                      child: _FilterTab(
                        label: 'موقع وهمي',
                        count: '$fakeCount',
                        isActive: state.statusFilter == 'FAKE_LOCATION',
                        accentColor: AppColors.warning,
                      ),
                    ),
                  ],
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

  Widget _buildBody(DailyAttendanceState state, List<DailyAttendanceRecord> list) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.errorMessage != null && state.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'تعذّر الاتصال',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(dailyAttendanceProvider.notifier).load(),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.ibmPlexSansArabic(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          state.searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد بيانات لهذا اليوم',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 15,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(dailyAttendanceProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final record = list[index];
          return _EmployeeCard(
            record: record,
            onTap: () {
              final employee = _toEmployee(record);
              _showEmployeeActionSheet(context, employee);
            },
          );
        },
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
        selectedDate: ref.read(dailyAttendanceProvider).selectedDate,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Employee Card
// ─────────────────────────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final DailyAttendanceRecord record;
  final VoidCallback onTap;

  const _EmployeeCard({required this.record, required this.onTap});

  String get _initials {
    final words = record.fullName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '؟';
    if (words.length == 1) return words.first.substring(0, 1);
    return words.first.substring(0, 1) + words[1].substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = record.getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: record.isFake == 1
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: (record.isFake == 1 ? AppColors.warning : Colors.black)
                .withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake GPS warning banner
          if (record.isFake == 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.location_off_rounded, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'موقع GPS وهمي مكتشف',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  if (record.fakeLatitude != 0.0) ...[
                    const Spacer(),
                    Text(
                      '${record.fakeLatitude.toStringAsFixed(4)}, ${record.fakeLongitude.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with initials
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.18),
                        statusColor.withValues(alpha: 0.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Employee info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              record.fullName,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              record.statusAr,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Code + day name
                      Text(
                        '#${record.code}${record.dayNameAr.isNotEmpty ? '  •  ${record.dayNameAr}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      // Times row
                      if (record.checkInTime != '-' || record.checkOutTime != '-') ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            if (record.checkInTime != '-')
                              _TimeChip(
                                time: record.checkInTime,
                                icon: Icons.login_rounded,
                                color: AppColors.success,
                              ),
                            if (record.checkInTime != '-' && record.checkOutTime != '-')
                              const SizedBox(width: 8),
                            if (record.checkOutTime != '-')
                              _TimeChip(
                                time: record.checkOutTime,
                                icon: Icons.logout_rounded,
                                color: AppColors.danger,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions button
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Filter Tab Component
// ─────────────────────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final String count;
  final bool isActive;
  final Color? accentColor;

  const _FilterTab({required this.label, required this.count, required this.isActive, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? color : AppColors.border,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? Colors.white : (accentColor ?? AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.25) : (accentColor?.withValues(alpha: 0.1) ?? AppColors.surfaceVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : (accentColor ?? AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Time Chip
// ─────────────────────────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String time;
  final IconData icon;
  final Color color;

  const _TimeChip({required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int offCount;
  final int fakeCount;

  const _StatsRow({
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.offCount,
    required this.fakeCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          _StatCard(count: presentCount, label: 'حاضر', color: AppColors.success, icon: Icons.check_circle_outline_rounded),
          _StatCard(count: absentCount, label: 'غائب', color: AppColors.danger, icon: Icons.cancel_outlined),
          _StatCard(count: leaveCount, label: 'إجازة', color: AppColors.info, icon: Icons.beach_access_rounded),
          _StatCard(count: offCount, label: 'عطلات', color: AppColors.textTertiary, icon: Icons.weekend_rounded),
          if (fakeCount > 0)
            _StatCard(count: fakeCount, label: 'موقع وهمي', color: AppColors.warning, icon: Icons.location_off_rounded),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Employee Action Bottom Sheet (Keep action buttons completely functional)
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
          
          // Header (Avatar, Name, Code)
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
                  child: const Icon(
                    Icons.person_rounded,
                    size: 26,
                    color: Colors.white,
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
                        '#${employee.code}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                    const Icon(Icons.lock_clock_rounded, color: Color(0xFFEA580C), size: 28),
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

            // ── Actions Row ───────────────────────────────────────────
            return Column(
              children: [
                if (_hasPunched) ...[  
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
          }),
        ],
      ),
    );
  }

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

  const _ActionGridItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFEBEE), // Subtle light red/rose border matching AppColors.primarySurface
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary, // Unified professional theme brand deep red
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, // Navy text
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
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '') ?? 0;
      final usernameStr = await storage.read(key: StorageKeys.username);

      final dio = DioClient().dio;
      final auth = widget.ref.read(authStateProvider);
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
          'userId': auth.user?.userId ?? 0,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      if (isSuccess) widget.ref.read(dailyAttendanceProvider.notifier).load();
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
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

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

          Text(
            widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _dateCard('من', _fmt.format(_startDate), () => _pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _dateCard('إلى', _fmt.format(_endDate), () => _pickDate(false))),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            widget.halfDay ? 'المدة: نصف يوم' : 'المدة: $_days يوم',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('إرسال الطلب', style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(date, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Overtime Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _OvertimeBottomSheet extends StatefulWidget {
  final Employee employee;
  final WidgetRef ref;

  const _OvertimeBottomSheet({required this.employee, required this.ref});

  @override
  State<_OvertimeBottomSheet> createState() => _OvertimeBottomSheetState();
}

class _OvertimeBottomSheetState extends State<_OvertimeBottomSheet> {
  double _hours = 2.0;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '') ?? 0;
      final usernameStr = await storage.read(key: StorageKeys.username);

      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createCto,
        data: {
          'employeeId': widget.employee.employeeId,
          'managerId': managerId,
          'transactionDate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
          'transactionHours': _hours,
          'notes': _notesController.text.trim().isEmpty ? 'إضافي معتمد' : _notesController.text.trim(),
          'username': usernameStr ?? '',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      if (isSuccess) widget.ref.read(dailyAttendanceProvider.notifier).load();
      final msg = data['messageAr'] ?? (isSuccess ? 'تم تسجيل الإضافي بنجاح' : 'حدث خطأ');

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

          Text(
            'طلب اعتماد ساعات إضافية',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Text(
            'عدد الساعات: ${_hours.toStringAsFixed(1)} ساعة',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          Slider(
            value: _hours,
            min: 0.5,
            max: 8.0,
            divisions: 15,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (val) => setState(() => _hours = val),
          ),

          TextField(
            controller: _notesController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ملاحظات إضافية...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('اعتماد الساعات', style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
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
  DateTime _date = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final _fmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '') ?? 0;
      final usernameStr = await storage.read(key: StorageKeys.username);

      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createAbsence,
        data: {
          'employeeId': widget.employee.employeeId,
          'managerId': managerId,
          'absenceDate': _fmt.format(_date),
          'notes': _notesController.text.trim().isEmpty ? 'غياب مسجل بعلم المدير' : _notesController.text.trim(),
          'username': usernameStr ?? '',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      if (isSuccess) widget.ref.read(dailyAttendanceProvider.notifier).load();
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
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

          Text(
            'تسجيل غياب للموظف',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'تاريخ الغياب:',
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmt.format(_date),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _notesController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'سبب الغياب أو ملاحظات...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('تسجيل الغياب الآن', style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
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
  DateTime _date = DateTime.now();
  TimeOfDay _timeFrom = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _timeTo = const TimeOfDay(hour: 16, minute: 0);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  final _fmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isFrom) async {
    final initial = isFrom ? _timeFrom : _timeTo;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _timeFrom = picked;
        } else {
          _timeTo = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hr = tod.hour.toString().padLeft(2, '0');
    final mn = tod.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '') ?? 0;
      final usernameStr = await storage.read(key: StorageKeys.username);

      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createMission,
        data: {
          'employeeId': widget.employee.employeeId,
          'managerId': managerId,
          'missionDate': _fmt.format(_date),
          'timeFrom': _formatTimeOfDay(_timeFrom),
          'timeTo': _formatTimeOfDay(_timeTo),
          'reason': _reasonController.text.trim().isEmpty ? 'مأمورية عمل خارجية' : _reasonController.text.trim(),
          'username': usernameStr ?? '',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      if (isSuccess) widget.ref.read(dailyAttendanceProvider.notifier).load();
      final msg = data['messageAr'] ?? (isSuccess ? 'تم تسجيل المأمورية بنجاح' : 'حدث خطأ');

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
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

          Text(
            'تسجيل مأمورية عمل للموظف',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: Colors.white),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('التاريخ:', style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text(_fmt.format(_date), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('من ساعة', style: GoogleFonts.ibmPlexSansArabic(fontSize: 10, color: AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(_timeFrom.format(context), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إلى ساعة', style: GoogleFonts.ibmPlexSansArabic(fontSize: 10, color: AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(_timeTo.format(context), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _reasonController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'سبب المأمورية ومكانها...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('تسجيل المأمورية', style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
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
  DateTime _date = DateTime.now();
  TimeOfDay _timeFrom = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _timeTo = const TimeOfDay(hour: 14, minute: 0);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  final _fmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isFrom) async {
    final initial = isFrom ? _timeFrom : _timeTo;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _timeFrom = picked;
        } else {
          _timeTo = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hr = tod.hour.toString().padLeft(2, '0');
    final mn = tod.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      const storage = FlutterSecureStorage();
      final idStr = await storage.read(key: StorageKeys.userEmployeeId);
      final managerId = int.tryParse(idStr ?? '') ?? 0;
      final usernameStr = await storage.read(key: StorageKeys.username);

      final dio = DioClient().dio;
      final response = await dio.post(
        ApiConstants.createWorkPermit,
        data: {
          'employeeId': widget.employee.employeeId,
          'managerId': managerId,
          'permitDate': _fmt.format(_date),
          'timeFrom': _formatTimeOfDay(_timeFrom),
          'timeTo': _formatTimeOfDay(_timeTo),
          'reason': _reasonController.text.trim().isEmpty ? 'تصريح خروج شخصي' : _reasonController.text.trim(),
          'username': usernameStr ?? '',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final isSuccess = data['status'] == 'success';
      if (isSuccess) widget.ref.read(dailyAttendanceProvider.notifier).load();
      final msg = data['messageAr'] ?? (isSuccess ? 'تم تسجيل التصريح بنجاح' : 'حدث خطأ');

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
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

          Text(
            'طلب تصريح خروج للموظف',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.employee.fullNameAr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: Colors.white),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('التاريخ:', style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text(_fmt.format(_date), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('من ساعة', style: GoogleFonts.ibmPlexSansArabic(fontSize: 10, color: AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(_timeFrom.format(context), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إلى ساعة', style: GoogleFonts.ibmPlexSansArabic(fontSize: 10, color: AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(_timeTo.format(context), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _reasonController,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'سبب التصريح ومبررات الخروج...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('إرسال طلب التصريح', style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

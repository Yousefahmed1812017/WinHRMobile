import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/data/auth_provider.dart';
import '../../data/leaves_provider.dart';
import '../../data/models/leave_request_model.dart';

class LeaveRequestsScreen extends ConsumerStatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  ConsumerState<LeaveRequestsScreen> createState() =>
      _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends ConsumerState<LeaveRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  // Tab index → statusId filter (null = all)
  // 1,2,3 = pending, 4 = approved, 5 = rejected
  static const _tabStatusMap = <int, List<int>?>{
    0: null,         // الكل
    1: [1, 2, 3],    // معلق
    2: [4],          // معتمد
    3: [5],          // مرفوض
  };

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(() {
      ref.read(leaveRequestsListProvider.notifier).loadAll();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _selectedTabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final code = _searchController.text.trim();
    if (code.isNotEmpty) {
      ref.read(leaveRequestsListProvider.notifier).searchByCode(code);
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(leaveRequestsListProvider.notifier).clearSearch();
  }

  List<LeaveRequest> _filterByTab(List<LeaveRequest> requests) {
    final statuses = _tabStatusMap[_selectedTabIndex];
    if (statuses == null) return requests;
    return requests.where((r) => statuses.contains(r.statusId)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveRequestsListProvider);
    final filtered = _filterByTab(state.requests);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createLeaveRequest),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'طلبات الإجازات',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'بحث بكود الموظف...',
                      hintStyle: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: GestureDetector(
                        onTap: _onSearch,
                        child: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textTertiary),
                      ),
                      suffixIcon: state.searchCode != null
                          ? GestureDetector(
                              onTap: _onClearSearch,
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
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                dividerHeight: 0.5,
                dividerColor: AppColors.border,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: 'الكل'),
                  Tab(text: 'معلق'),
                  Tab(text: 'معتمد'),
                  Tab(text: 'مرفوض'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(state, filtered),
    );
  }

  Widget _buildBody(LeaveRequestsListState state, List<LeaveRequest> filtered) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2.5),
      );
    }

    if (state.errorMessage != null && state.requests.isEmpty) {
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
                  ref.read(leaveRequestsListProvider.notifier).loadAll(),
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.ibmPlexSansArabic(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text('لا توجد طلبات',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15, color: AppColors.textTertiary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _LeaveCard(
        request: filtered[index],
        onTap: () => _showDetails(filtered[index]),
      ),
    );
  }

  void _showDetails(LeaveRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LeaveDetailsSheet(
        request: request,
        ref: ref,
        onStatusChanged: () {
          // Reload after status change
          ref.read(leaveRequestsListProvider.notifier).loadAll();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Status helper
// ─────────────────────────────────────────────────────────────────────────────
class _StatusInfo {
  final Color color;
  final String label;
  const _StatusInfo(this.color, this.label);
}

_StatusInfo _getStatus(int? id) {
  switch (id) {
    case 1:
      return _StatusInfo(AppColors.warning, 'جديد');
    case 2:
      return _StatusInfo(AppColors.warning, 'قيد الانتظار');
    case 3:
      return _StatusInfo(AppColors.info, 'قيد المراجعة');
    case 4:
      return _StatusInfo(AppColors.success, 'معتمد');
    case 5:
      return _StatusInfo(AppColors.danger, 'مرفوض');
    case 6:
      return _StatusInfo(AppColors.textTertiary, 'ملغي');
    default:
      return _StatusInfo(AppColors.info, 'أخرى');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Leave Card (tappable)
// ─────────────────────────────────────────────────────────────────────────────
class _LeaveCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onTap;
  const _LeaveCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _getStatus(request.statusId);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.event_note_rounded, size: 22, color: s.color),
              ),
              const SizedBox(width: 12),

              // Name + dates
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName ??
                          'كود: ${request.employeeCode ?? '-'}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.leaveType ?? '-',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.label,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Leave Details Bottom Sheet (with Approve / Reject)
// ─────────────────────────────────────────────────────────────────────────────
class _LeaveDetailsSheet extends StatefulWidget {
  final LeaveRequest request;
  final WidgetRef ref;
  final VoidCallback onStatusChanged;

  const _LeaveDetailsSheet({
    required this.request,
    required this.ref,
    required this.onStatusChanged,
  });

  @override
  State<_LeaveDetailsSheet> createState() => _LeaveDetailsSheetState();
}

class _LeaveDetailsSheetState extends State<_LeaveDetailsSheet> {
  bool _submitting = false;
  final _notesController = TextEditingController();

  Future<void> _updateStatus(int statusId) async {
    setState(() => _submitting = true);
    try {
      final auth = widget.ref.read(authStateProvider);
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
      Navigator.pop(context);

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

      if (isSuccess) widget.onStatusChanged();
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

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final s = _getStatus(r.statusId);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تفاصيل الطلب',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 16),

          // Employee Info
          Row(
            children: [
              Container(
                width: 48, height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  r.employeeCode ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.employeeName ?? '',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تاريخ الطلب', style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(r.requestDate ?? '-', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('من تاريخ', style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(r.startDate ?? '-', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('عدد الأيام', style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${r.totalLeaveDays ?? "-"} يوم', style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Month / Section Title
          Row(
            children: [
              Text(r.leaveType ?? 'طلب إجازة',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          // Detailed Request Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                // Header of box
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.leaveType ?? 'إجازة',
                                style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text(r.requestDate ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (r.isPending) ...[
                        // Reject button
                        InkWell(
                          onTap: _submitting ? null : () => _updateStatus(5),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Approve button
                        InkWell(
                          onTap: _submitting ? null : () => _updateStatus(4),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B), // Dark Navy
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                      if (!r.isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.label,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: s.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                // Body of box
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الفترة المطلوبة', style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('${r.startDate ?? "-"} — ${r.endDate ?? "-"}',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      Text('${r.totalLeaveDays ?? "-"} يوم',
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_submitting)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
              ),
            ),
            
          if (r.isPending && !_submitting) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'إضافة ملاحظة للرد...',
                hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: AppColors.textTertiary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Detail Row
// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(value,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

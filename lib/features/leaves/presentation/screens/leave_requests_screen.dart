import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
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

  static const _tabStatusMap = <int, int?>{
    0: null,
    1: 1,
    2: 4,
    3: 2,
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
    final status = _tabStatusMap[_selectedTabIndex];
    if (status == null) return requests;
    return requests.where((r) => r.statusId == status).toList();
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
          style: GoogleFonts.cairo(
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
                    style: GoogleFonts.cairo(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'بحث بكود الموظف...',
                      hintStyle: GoogleFonts.cairo(
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
                labelStyle: GoogleFonts.cairo(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
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
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(leaveRequestsListProvider.notifier).loadAll(),
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text('لا توجد طلبات',
            style: GoogleFonts.cairo(
                fontSize: 15, color: AppColors.textTertiary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          LeaveCard(request: filtered[index]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class LeaveCard extends StatelessWidget {
  final LeaveRequest request;
  const LeaveCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final s = _status(request.statusId);

    return Material(
      color: Colors.white,
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
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.startDate ?? '-'}  →  ${request.endDate ?? '-'}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textTertiary,
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
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: s.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _Status _status(int? id) {
    switch (id) {
      case 4:
        return _Status(AppColors.success, 'معتمد');
      case 1:
        return _Status(AppColors.warning, 'معلق');
      case 2:
        return _Status(AppColors.danger, 'مرفوض');
      default:
        return _Status(AppColors.info, 'أخرى');
    }
  }
}

class _Status {
  final Color color;
  final String label;
  const _Status(this.color, this.label);
}

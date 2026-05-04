import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/leaves_provider.dart';
import '../../data/models/leave_request_model.dart';

/// Leave requests list screen with search by employee code.
class LeaveRequestsScreen extends ConsumerStatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  ConsumerState<LeaveRequestsScreen> createState() =>
      _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends ConsumerState<LeaveRequestsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(leaveRequestsListProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveRequestsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'طلبات الإجازات',
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
                    '${state.pagination!.totalRecords} طلب',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createLeaveRequest),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'إنشاء إجازة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
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
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(LeaveRequestsListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (state.errorMessage != null && state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 56, color: AppColors.danger.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(leaveRequestsListProvider.notifier).loadAll(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 56,
                color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات إجازة',
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        return LeaveRequestCard(request: state.requests[index]);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Leave Request Card — reusable across screens
// ═══════════════════════════════════════════════════════════════════════════
class LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  const LeaveRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColors = _getStatusColors(request.statusId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Leave type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    size: 22,
                    color: statusColors.fg,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName ?? 'كود: ${request.employeeCode ?? '-'}',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.leaveType ?? '-',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColors.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status ?? '-',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColors.fg,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────
          const Divider(height: 1),

          // ── Details ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _DetailChip(
                  icon: Icons.calendar_today_rounded,
                  label: request.startDate ?? '-',
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
                _DetailChip(
                  icon: Icons.calendar_today_rounded,
                  label: request.endDate ?? '-',
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timelapse_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${request.totalLeaveDays ?? 0} يوم',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────────────────
          if (request.decisionNumber != null &&
              request.decisionNumber!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'رقم القرار: ${request.decisionNumber}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  if (request.requestDate != null)
                    Text(
                      request.requestDate!,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  _StatusColors _getStatusColors(int? statusId) {
    switch (statusId) {
      case 4: // معتمد
        return _StatusColors(AppColors.successLight, AppColors.success);
      case 1: // معلق
        return _StatusColors(AppColors.warningLight, AppColors.warning);
      case 2: // مرفوض
        return _StatusColors(AppColors.dangerLight, AppColors.danger);
      default:
        return _StatusColors(AppColors.infoLight, AppColors.info);
    }
  }
}

class _StatusColors {
  final Color bg;
  final Color fg;
  const _StatusColors(this.bg, this.fg);
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Dashboard home screen with summary cards.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.welcomeBack,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'Ahmed Mohamed', // TODO: from profile
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification bell
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.white,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Today's summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.todaySummary,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _SummaryItem(
                              icon: Icons.login_rounded,
                              label: l10n.checkIn,
                              value: '08:30 AM',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.white.withOpacity(0.2),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            _SummaryItem(
                              icon: Icons.logout_rounded,
                              label: l10n.checkOut,
                              value: '--:--',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.white.withOpacity(0.2),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            _SummaryItem(
                              icon: Icons.timer_outlined,
                              label: l10n.workHoursToday,
                              value: '4h 20m',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Actions ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildListDelegate([
                _QuickActionCard(
                  icon: Icons.fingerprint_rounded,
                  label: l10n.attendance,
                  color: AppColors.primary,
                  onTap: () {},
                ),
                _QuickActionCard(
                  icon: Icons.event_note_rounded,
                  label: l10n.leaves,
                  color: AppColors.success,
                  onTap: () {},
                ),
                _QuickActionCard(
                  icon: Icons.schedule_rounded,
                  label: l10n.shifts,
                  color: AppColors.secondary,
                  onTap: () {},
                ),
                _QuickActionCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.leaveBalance,
                  color: AppColors.warning,
                  onTap: () {},
                ),
              ]),
            ),
          ),

          // ── Leave Balance Cards ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.leaveBalance,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _LeaveBalanceCard(
                          label: l10n.annualLeave,
                          remaining: 15,
                          total: 21,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LeaveBalanceCard(
                          label: l10n.sickLeave,
                          remaining: 5,
                          total: 7,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LeaveBalanceCard(
                          label: l10n.casualLeave,
                          remaining: 3,
                          total: 6,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Private Widgets ─────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withOpacity(0.8), size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.white.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final String label;
  final int remaining;
  final int total;
  final Color color;

  const _LeaveBalanceCard({
    required this.label,
    required this.remaining,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remaining / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$remaining',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

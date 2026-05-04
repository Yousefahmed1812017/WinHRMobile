import 'package:flutter/material.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// List of leave requests with status badges and filter chips.
class LeavesListScreen extends StatelessWidget {
  const LeavesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaves),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to new leave request
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newLeaveRequest),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          // Mock data
          final statuses = ['pending', 'approved', 'rejected', 'approved', 'pending'];
          final types = ['Annual', 'Sick', 'Casual', 'Annual', 'Sick'];
          final status = statuses[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        types[index],
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '15 Apr - 17 Apr 2026',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBgColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status, l10n),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.approvedFg;
      case 'rejected':
        return AppColors.rejectedFg;
      case 'pending':
      default:
        return AppColors.pendingFg;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.approvedBg;
      case 'rejected':
        return AppColors.rejectedBg;
      case 'pending':
      default:
        return AppColors.pendingBg;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'approved':
        return l10n.approved;
      case 'rejected':
        return l10n.rejected;
      case 'pending':
      default:
        return l10n.pending;
    }
  }
}

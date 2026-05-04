import 'package:flutter/material.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';

/// Attendance history screen with calendar view.
/// TODO: Integrate table_calendar and real data.
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.attendanceHistory)),
      body: const Center(
        child: Text('Attendance History — Coming Soon'),
      ),
    );
  }
}

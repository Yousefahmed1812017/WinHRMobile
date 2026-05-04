import 'package:flutter/material.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';

class LeaveBalanceScreen extends StatelessWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaveBalance)),
      body: const Center(child: Text('Leave Balance — Coming Soon')),
    );
  }
}

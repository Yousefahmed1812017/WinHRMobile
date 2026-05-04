import 'package:flutter/material.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';

class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myShifts)),
      body: const Center(child: Text('Shifts Calendar — Coming Soon')),
    );
  }
}

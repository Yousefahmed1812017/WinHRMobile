import 'package:flutter/material.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';

/// Form for submitting a new leave request.
/// TODO: Wire up reactive_forms and API call.
class NewLeaveRequestScreen extends StatelessWidget {
  const NewLeaveRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newLeaveRequest)),
      body: const Center(
        child: Text('New Leave Request Form — Coming Soon'),
      ),
    );
  }
}

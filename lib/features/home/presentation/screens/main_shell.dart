import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:win_hr/core/localization/generated/app_localizations.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// Main scaffold with bottom navigation.
/// Wraps child routes from [ShellRoute].
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    RouteNames.home,
    RouteNames.attendance,
    RouteNames.leaves,
    RouteNames.shifts,
    RouteNames.profile,
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync index when deep-linking or back navigation occurs
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTap,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_rounded),
                activeIcon: const Icon(Icons.dashboard_rounded),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.fingerprint_rounded),
                activeIcon: const Icon(Icons.fingerprint_rounded),
                label: l10n.attendance,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.event_note_rounded),
                activeIcon: const Icon(Icons.event_note_rounded),
                label: l10n.leaves,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.schedule_rounded),
                activeIcon: const Icon(Icons.schedule_rounded),
                label: l10n.shifts,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/attendance/presentation/screens/attendance_home_screen.dart';
import '../../features/attendance/presentation/screens/attendance_history_screen.dart';
import '../../features/leaves/presentation/screens/leaves_list_screen.dart';
import '../../features/leaves/presentation/screens/new_leave_request_screen.dart';
import '../../features/leaves/presentation/screens/leave_balance_screen.dart';
import '../../features/shifts/presentation/screens/shifts_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import 'route_names.dart';

/// Application router configuration using [go_router].
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      // ── Auth Routes ───────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Main App Shell (Bottom Navigation) ────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.attendance,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendanceHomeScreen(),
            ),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) =>
                    const AttendanceHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.leaves,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeavesListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const NewLeaveRequestScreen(),
              ),
              GoRoute(
                path: 'balance',
                builder: (context, state) =>
                    const LeaveBalanceScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.shifts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShiftsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],

    // ── Error / 404 ──────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

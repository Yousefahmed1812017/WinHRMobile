import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/employees/presentation/screens/employees_list_screen.dart';
import '../../features/employees/presentation/screens/employee_details_screen.dart';
import '../../features/employees/data/models/employee_model.dart';
import '../../features/leaves/presentation/screens/leave_requests_screen.dart';
import '../../features/leaves/presentation/screens/create_leave_request_screen.dart';
import '../../shared/widgets/main_shell.dart';
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
      // ── Auth Routes (outside shell) ────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Main Shell (with bottom nav) ───────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.employees,
            builder: (context, state) => const EmployeesListScreen(),
          ),
          GoRoute(
            path: RouteNames.leaveRequests,
            builder: (context, state) => const LeaveRequestsScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Detail Routes (full-screen, outside shell) ─────────────────
      GoRoute(
        path: RouteNames.employeeDetails,
        builder: (context, state) {
          final employee = state.extra as Employee;
          return EmployeeDetailsScreen(employee: employee);
        },
      ),
      GoRoute(
        path: RouteNames.createLeaveRequest,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return CreateLeaveRequestScreen(
              prefilledEmployee: extra['employee'] as Employee?,
              prefilledLeaveTypeId: extra['leaveTypeId'] as int?,
            );
          }
          return CreateLeaveRequestScreen(prefilledEmployee: extra as Employee?);
        },
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

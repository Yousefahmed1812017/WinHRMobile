/// Named route paths used across the application.
class RouteNames {
  RouteNames._();

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // ── Main (inside shell) ────────────────────────────────────────────────
  static const String employees = '/employees';
  static const String employeeDetails = '/employees/details';
  static const String leaveRequests = '/leave-requests';
  static const String createLeaveRequest = '/leave-requests/create';
  static const String createAbsence = '/employees/absence';
  static const String profile = '/profile';
}

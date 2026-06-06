/// Named route paths used across the application.
class RouteNames {
  RouteNames._();

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // ── Main (inside shell) ────────────────────────────────────────────────
  static const String home = '/home';
  static const String employees = '/employees';
  static const String employeeDetails = '/employees/details';
  static const String employeeAttendance = '/employees/attendance';
  static const String leaveRequests = '/leave-requests';
  static const String createLeaveRequest = '/leave-requests/create';
  static const String leaveRequestDetails = '/leave-requests/details';
  static const String createAbsence = '/employees/absence';
  static const String attendance = '/attendance';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String dailyLogs = '/daily-logs';
}

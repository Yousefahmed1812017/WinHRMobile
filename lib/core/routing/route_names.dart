/// Named route paths used across the application.
class RouteNames {
  RouteNames._();

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // ── Main Shell ──────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // ── Attendance ──────────────────────────────────────────────────────────
  static const String attendance = '/attendance';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceDetails = '/attendance/details';

  // ── Leaves ──────────────────────────────────────────────────────────────
  static const String leaves = '/leaves';
  static const String newLeaveRequest = '/leaves/new';
  static const String leaveDetails = '/leaves/details';
  static const String leaveBalance = '/leaves/balance';

  // ── Shifts ──────────────────────────────────────────────────────────────
  static const String shifts = '/shifts';
  static const String shiftChangeRequest = '/shifts/change-request';
  static const String shiftRequestsHistory = '/shifts/requests-history';

  // ── Notifications ───────────────────────────────────────────────────────
  static const String notifications = '/notifications';
}

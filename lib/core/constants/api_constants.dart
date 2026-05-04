/// API constants for Win HR application.
/// Update [baseUrl] with your Oracle APEX ORDS server URL.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────────────
  static const String baseUrl =
      'https://your-apex-server.com/ords/hr_app/v1/';

  // ── Timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = 'auth/login';
  static const String refreshToken = 'auth/refresh';
  static const String logout = 'auth/logout';

  // ── Attendance ─────────────────────────────────────────────────────────
  static const String checkin = 'attendance/checkin';
  static const String checkout = 'attendance/checkout';
  static const String attendanceHistory = 'attendance/history';
  static const String attendanceStats = 'attendance/stats';

  // ── Leaves ─────────────────────────────────────────────────────────────
  static const String leaves = 'leaves';
  static const String leaveBalance = 'leaves/balance';
  static const String leaveTypes = 'leaves/types';

  // ── Shifts ─────────────────────────────────────────────────────────────
  static const String shifts = 'shifts';
  static const String shiftChangeRequest = 'shifts/change-request';
  static const String shiftChangeRequests = 'shifts/change-requests';

  // ── Profile ────────────────────────────────────────────────────────────
  static const String profile = 'employee/profile';
  static const String notifications = 'notifications';
}

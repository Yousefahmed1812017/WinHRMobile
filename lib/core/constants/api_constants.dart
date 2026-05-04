/// API constants for Win HR application.
/// Connected to Oracle APEX ORDS server.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────────────
  static const String baseUrl =
      'http://deltamansoura.ddns.net:9090/ords/deltaamaindata/';

  // ── Timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = 'authenticate/login';

  // ── Employees ──────────────────────────────────────────────────────────
  static const String employees = 'Query/EmployeeList';

  // ── Leave Requests ─────────────────────────────────────────────────────
  static const String leaveRequests = 'Query/EmployeeLeaveRequests';
  static const String createLeaveRequest = 'Functions/CreateEmployeeLeaveRequest';
  static const String leaveTypes = 'lookups/leaveTypes';
}

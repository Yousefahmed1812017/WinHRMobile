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
  static const String subordinates = 'Query/Subordinates';
  static const String employeeAttendanceLog = 'Query/EmployeeAttendanceLog';

  // ── Leave Requests ─────────────────────────────────────────────────────
  static const String leaveRequests = 'Query/EmployeeLeaveRequests';
  static const String createLeaveRequest = 'Functions/CreateEmployeeLeaveRequest';
  static const String leaveTypes = 'lookups/leaveTypes';
  static const String createAbsence = 'Functions/CreateAbsence';
  static const String checkInOut = 'Functions/check-in-out';
  static const String updateLeaveStatus = 'Functions/UpdateleaveStatus';
  static const String createCto = 'Functions/CreateCtoTransactions';

  // ── Pending Approvals ──────────────────────────────────────────────────
  static const String pendingApprovals = 'Query/PendingApprovals';
  static const String approveRejectLeave = 'leave-requests/approve-reject';
  static const String createLeaveRequestWithManager = 'Functions/CreateLeaveRequestWithManger';
}

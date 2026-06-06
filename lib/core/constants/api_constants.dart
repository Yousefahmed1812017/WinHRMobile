/// API constants for Win HR application.
/// Connected to Oracle APEX ORDS server.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────────────
  static const String baseUrl =
      'https://semadapi.locksys.co/ords/deltaamaindata/';

  // ── Timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = 'authenticate/login';

  // ── Employees ──────────────────────────────────────────────────────────
  static const String employees = 'Query/EmployeeList';
  static const String subordinates = 'Query/Subordinates';
  static const String employeeAttendanceLog = 'Query/EmployeeAttendanceLog';
  static const String dailyAttendance = 'Query/DailyAttendance';

  // ── Leave Requests ─────────────────────────────────────────────────────
  static const String leaveRequests = 'Query/EmployeeLeaveRequests';
  static const String createLeaveRequest = 'Functions/CreateEmployeeLeaveRequest';
  static const String leaveTypes = 'lookups/leaveTypes';
  static const String createAbsence = 'Functions/CreateAbsence';
  static const String checkInOut = 'Functions/check-in-out';
  static const String updateLeaveStatus = 'Functions/UpdateleaveStatus';
  static const String createCto = 'Functions/CreateCtoTransactions';
  static const String createMission = 'Functions/CreateMission';
  static const String createWorkPermit = 'Functions/CreateWorkPermits';

  // ── Pending Approvals ──────────────────────────────────────────────────
  static const String pendingApprovals = 'Query/PendingApprovals';
  static const String approveRejectLeave = 'Functions/ApproveOrRejectRequest';
  static const String createLeaveRequestWithManager = 'Functions/CreateLeaveRequestWithManger';
}

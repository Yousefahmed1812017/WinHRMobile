/// Data model for a pending approval from the API.
class PendingApproval {
  final int leaveRequestId;
  final int? leaveTypeStageId;
  final int? stageId;
  final String? stageName;
  final int? employeeId;
  final String? employeeCode;
  final String? employeeName;
  final String? department;
  final int? leaveTypeId;
  final String? leaveType;
  final String? requestDate;
  final String? startDate;
  final String? endDate;
  final int? totalLeaveDays;
  final int? workingDays;
  final int? weekendDays;
  final int? officialHolidays;
  final int? submittedById;
  final String? submittedDate;

  const PendingApproval({
    required this.leaveRequestId,
    this.leaveTypeStageId,
    this.stageId,
    this.stageName,
    this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.department,
    this.leaveTypeId,
    this.leaveType,
    this.requestDate,
    this.startDate,
    this.endDate,
    this.totalLeaveDays,
    this.workingDays,
    this.weekendDays,
    this.officialHolidays,
    this.submittedById,
    this.submittedDate,
  });

  factory PendingApproval.fromJson(Map<String, dynamic> json) {
    return PendingApproval(
      leaveRequestId: json['leaveRequestId'] as int? ?? 0,
      leaveTypeStageId: json['leaveTypeStageId'] as int?,
      stageId: json['stageId'] as int?,
      stageName: json['stageName'] as String?,
      employeeId: json['employeeId'] as int?,
      employeeCode: json['employeeCode']?.toString(),
      employeeName: json['employeeName'] as String?,
      department: json['department'] as String?,
      leaveTypeId: json['leaveTypeId'] as int?,
      leaveType: json['leaveType'] as String?,
      requestDate: json['requestDate'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      totalLeaveDays: json['totalLeaveDays'] as int?,
      workingDays: json['workingDays'] as int?,
      weekendDays: json['weekendDays'] as int?,
      officialHolidays: json['officialHolidays'] as int?,
      submittedById: json['submittedById'] as int?,
      submittedDate: json['submittedDate'] as String?,
    );
  }
}

/// Complete API response for pending approvals.
class PendingApprovalsResponse {
  final String status;
  final int code;
  final String message;
  final String messageAr;
  final int totalRecords;
  final List<PendingApproval> data;

  const PendingApprovalsResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.messageAr,
    required this.totalRecords,
    required this.data,
  });

  factory PendingApprovalsResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PendingApprovalsResponse(
      status: json['status'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      messageAr: json['messageAr'] as String? ?? '',
      totalRecords: pagination?['totalRecords'] as int? ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map(
                  (e) => PendingApproval.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

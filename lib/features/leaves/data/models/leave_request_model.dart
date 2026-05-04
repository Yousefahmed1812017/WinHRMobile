/// Data model for a leave request from the API.
class LeaveRequest {
  final int id;
  final int? leaveTypeId;
  final String? leaveType;
  final int? employeeId;
  final String? employeeCode;
  final String? employeeName;
  final String? requestDate;
  final String? startDate;
  final String? endDate;
  final int? totalLeaveDays;
  final String? status;
  final int? statusId;
  final String? decisionNumber;

  const LeaveRequest({
    required this.id,
    this.leaveTypeId,
    this.leaveType,
    this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.requestDate,
    this.startDate,
    this.endDate,
    this.totalLeaveDays,
    this.status,
    this.statusId,
    this.decisionNumber,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int? ?? 0,
      leaveTypeId: json['leaveTypeId'] as int?,
      leaveType: json['leaveType'] as String?,
      employeeId: json['employeeId'] as int?,
      employeeCode: json['employeeCode']?.toString(),
      employeeName: json['employeeName'] as String?,
      requestDate: json['requestDate'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      totalLeaveDays: json['totalLeaveDays'] as int?,
      status: json['status'] as String?,
      statusId: json['statusId'] as int?,
      decisionNumber: json['decisionNumber'] as String?,
    );
  }

  /// Returns a color-semantic status category.
  String get statusCategory {
    switch (statusId) {
      case 4:
        return 'approved'; // معتمد
      case 1:
        return 'pending'; // معلق
      case 2:
        return 'rejected'; // مرفوض
      default:
        return 'other';
    }
  }
}

/// Data model for a leave type from the lookups API.
class LeaveType {
  final int id;
  final String nameEn;
  final String nameAr;

  const LeaveType({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] as int? ?? 0,
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
    );
  }
}

/// Pagination info from the API response.
class LeavesPaginationInfo {
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  const LeavesPaginationInfo({
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory LeavesPaginationInfo.fromJson(Map<String, dynamic> json) {
    return LeavesPaginationInfo(
      totalRecords: json['totalRecords'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 50,
    );
  }
}

/// Complete API response for leave requests list.
class LeaveRequestsResponse {
  final String status;
  final int code;
  final String message;
  final String messageAr;
  final LeavesPaginationInfo? pagination;
  final List<LeaveRequest> data;

  const LeaveRequestsResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.messageAr,
    this.pagination,
    required this.data,
  });

  factory LeaveRequestsResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestsResponse(
      status: json['status'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      messageAr: json['messageAr'] as String? ?? '',
      pagination: json['pagination'] != null
          ? LeavesPaginationInfo.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : null,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

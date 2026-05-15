/// Data model for an employee from the API.
class Employee {
  final int employeeId;
  final String code;
  final String fullNameAr;
  final String fullNameEn;
  final String? jobTitle;
  final String? department;
  final String? hireDate;
  final double? basicSalary;
  final int? jobGradeId;
  final String? jobGradeDate;
  final String? terminationDate;
  final String? decisionNumber;
  final int? workShiftId;
  final String? shiftName;
  final int? shiftGroupId;
  final String? groupName;
  final int? workShiftTypeId;
  final String? shiftType;
  final int? qualificationId;
  final int? employmentStatus;
  final String? employeeStatus;

  // New attendance fields for subordinates query
  final String? checkInTime;
  final String? checkOutTime;
  final String? attendanceStatus;
  final String? attendanceStatusAr;

  const Employee({
    required this.employeeId,
    required this.code,
    required this.fullNameAr,
    required this.fullNameEn,
    this.jobTitle,
    this.department,
    this.hireDate,
    this.basicSalary,
    this.jobGradeId,
    this.jobGradeDate,
    this.terminationDate,
    this.decisionNumber,
    this.workShiftId,
    this.shiftName,
    this.shiftGroupId,
    this.groupName,
    this.workShiftTypeId,
    this.shiftType,
    this.qualificationId,
    this.employmentStatus,
    this.employeeStatus,
    this.checkInTime,
    this.checkOutTime,
    this.attendanceStatus,
    this.attendanceStatusAr,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employeeId'] as int,
      code: json['code']?.toString() ?? '',
      fullNameAr: json['fullNameAr'] as String? ?? json['employeeName'] as String? ?? json['fullName'] as String? ?? '',
      fullNameEn: json['fullNameEn'] as String? ?? json['employeeNameEn'] as String? ?? json['fullName'] as String? ?? '',
      jobTitle: json['jobTitle'] as String?,
      department: json['department'] as String?,
      hireDate: json['hireDate'] as String?,
      basicSalary: (json['basicSalary'] as num?)?.toDouble(),
      jobGradeId: json['jobGradeId'] as int?,
      jobGradeDate: json['jobGradeDate'] as String?,
      terminationDate: json['terminationDate'] as String?,
      decisionNumber: json['decisionNumber'] as String?,
      workShiftId: json['workShiftId'] as int?,
      shiftName: json['shiftName'] as String?,
      shiftGroupId: json['shiftGroupId'] as int?,
      groupName: json['groupName'] as String?,
      workShiftTypeId: json['workShiftTypeId'] as int?,
      shiftType: json['shiftType'] as String?,
      qualificationId: json['qualificationId'] as int?,
      employmentStatus: json['employmentStatus'] as int?,
      employeeStatus: json['employeeStatus'] as String?,
      checkInTime: json['checkInTime'] as String?,
      checkOutTime: json['checkOutTime'] as String?,
      attendanceStatus: json['attendanceStatus'] as String?,
      attendanceStatusAr: json['attendanceStatusAr'] as String?,
    );
  }

  /// Returns true if the employee is currently active.
  bool get isActive => employmentStatus == 1;

  /// Returns true if the employee is retired.
  bool get isRetired => employmentStatus == 6;

  /// Returns true if the employee is deceased.
  bool get isDeceased => employmentStatus == 7;
}

/// Pagination info from the API response.
class PaginationInfo {
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  const PaginationInfo({
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      totalRecords: json['totalRecords'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
    );
  }
}

/// Complete API response for employees list.
class EmployeesResponse {
  final String status;
  final int code;
  final String message;
  final String messageAr;
  final PaginationInfo pagination;
  final List<Employee> employees;

  const EmployeesResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.messageAr,
    required this.pagination,
    required this.employees,
  });

  factory EmployeesResponse.fromJson(Map<String, dynamic> json) {
    return EmployeesResponse(
      status: json['status'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      messageAr: json['messageAr'] as String? ?? '',
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
      employees: (json['data'] as List<dynamic>?)
              ?.map((e) => Employee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

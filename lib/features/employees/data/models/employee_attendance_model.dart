class EmployeeAttendanceLog {
  final String date;
  final String dayName;
  final String checkInTime;
  final String checkOutTime;
  final String checkInMethod;
  final String checkOutMethod;
  final String workingHours;
  final String attendanceStatus;
  final String attendanceStatusAr;
  final String statusClass;

  const EmployeeAttendanceLog({
    required this.date,
    required this.dayName,
    required this.checkInTime,
    required this.checkOutTime,
    required this.checkInMethod,
    required this.checkOutMethod,
    required this.workingHours,
    required this.attendanceStatus,
    required this.attendanceStatusAr,
    required this.statusClass,
  });

  factory EmployeeAttendanceLog.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceLog(
      date: json['date'] as String? ?? '',
      dayName: json['dayName'] as String? ?? '',
      checkInTime: json['checkInTime'] as String? ?? '-',
      checkOutTime: json['checkOutTime'] as String? ?? '-',
      checkInMethod: json['checkInMethod'] as String? ?? '-',
      checkOutMethod: json['checkOutMethod'] as String? ?? '-',
      workingHours: json['workingHours'] as String? ?? '-',
      attendanceStatus: json['attendanceStatus'] as String? ?? '',
      attendanceStatusAr: json['attendanceStatusAr'] as String? ?? '',
      statusClass: json['statusClass'] as String? ?? '',
    );
  }
}

class AttendancePeriod {
  final String fromDate;
  final String toDate;
  final int totalDays;

  const AttendancePeriod({
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
  });

  factory AttendancePeriod.fromJson(Map<String, dynamic> json) {
    return AttendancePeriod(
      fromDate: json['fromDate'] as String? ?? '',
      toDate: json['toDate'] as String? ?? '',
      totalDays: json['totalDays'] as int? ?? 0,
    );
  }
}

class EmployeeAttendanceResponse {
  final String status;
  final int code;
  final String message;
  final String messageAr;
  final AttendancePeriod? period;
  final Map<String, dynamic>? pagination;
  final List<EmployeeAttendanceLog> data;

  const EmployeeAttendanceResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.messageAr,
    this.period,
    this.pagination,
    required this.data,
  });

  factory EmployeeAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceResponse(
      status: json['status'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      messageAr: json['messageAr'] as String? ?? '',
      period: json['period'] != null
          ? AttendancePeriod.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      pagination: json['pagination'] as Map<String, dynamic>?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) =>
                  EmployeeAttendanceLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

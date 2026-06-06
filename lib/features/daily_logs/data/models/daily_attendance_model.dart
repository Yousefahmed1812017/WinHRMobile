import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DailyAttendanceRecord {
  final int employeeId;
  final String code;
  final String fullName;
  final String checkDate;
  final String dayNameAr;
  final String dayNameEn;
  final String checkInTime;
  final String checkOutTime;
  final String status;
  final String statusAr;
  final String statusClass;
  final int isFake;
  final double fakeLatitude;
  final double fakeLongitude;
  final double latitude;
  final double longitude;

  const DailyAttendanceRecord({
    required this.employeeId,
    required this.code,
    required this.fullName,
    required this.checkDate,
    required this.dayNameAr,
    required this.dayNameEn,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    required this.statusAr,
    required this.statusClass,
    this.isFake = 0,
    this.fakeLatitude = 0.0,
    this.fakeLongitude = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRecord(
      employeeId: json['employeeId'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      checkDate: json['checkDate'] as String? ?? '',
      dayNameAr: json['dayNameAr'] as String? ?? '',
      dayNameEn: json['dayNameEn'] as String? ?? '',
      checkInTime: json['checkInTime'] as String? ?? '-',
      checkOutTime: json['checkOutTime'] as String? ?? '-',
      status: json['status'] as String? ?? '',
      statusAr: json['statusAr'] as String? ?? '',
      statusClass: json['statusClass'] as String? ?? '',
      isFake: json['isFake'] as int? ?? 0,
      fakeLatitude: (json['fakelatitudee'] as num?)?.toDouble() ?? 0.0,
      fakeLongitude: (json['fakeLongitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['LATITUDE'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['LONGITUDE'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color getStatusColor() {
    switch (statusClass) {
      case 'greenBadge':
        return AppColors.success;
      case 'orangeBadge':
        return AppColors.warning;
      case 'lightBlueBadge':
        return AppColors.info;
      case 'redBadge':
        return AppColors.danger;
      case 'grayBadge':
      default:
        return AppColors.textTertiary;
    }
  }
}

class DailyAttendanceResponse {
  final String status;
  final int code;
  final String checkDate;
  final List<DailyAttendanceRecord> data;

  const DailyAttendanceResponse({
    required this.status,
    required this.code,
    required this.checkDate,
    required this.data,
  });

  factory DailyAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceResponse(
      status: json['status'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      checkDate: json['checkDate'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => DailyAttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/leave_request_model.dart';

/// Repository for leave requests API calls.
class LeavesRepository {
  final Dio _dio;

  LeavesRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  /// Fetches leave requests. Can filter by employeeCode or employeeId.
  Future<LeaveRequestsResponse> getLeaveRequests({
    String? employeeCode,
    int? employeeId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (employeeCode != null && employeeCode.isNotEmpty) {
        body['employeeCode'] = employeeCode;
      }
      if (employeeId != null) {
        body['employeeId'] = employeeId.toString();
      }

      final response = await _dio.post(
        ApiConstants.leaveRequests,
        data: body,
      );

      return LeaveRequestsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[LeavesRepository] getLeaveRequests error: ${e.message}');
      rethrow;
    }
  }

  /// Fetches the list of available leave types.
  Future<List<LeaveType>> getLeaveTypes() async {
    try {
      final response = await _dio.post(ApiConstants.leaveTypes, data: {});
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[LeavesRepository] getLeaveTypes error: ${e.message}');
      rethrow;
    }
  }

  /// Creates a new leave request.
  Future<Map<String, dynamic>> createLeaveRequest({
    required int employeeId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required int totalLeaveDays,
    String? leaveReason,
    String? emergencyPhone,
    String? notes,
    required String username,
    required int userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createLeaveRequest,
        data: {
          'employeeId': employeeId,
          'leaveTypeId': leaveTypeId,
          'startDate': startDate,
          'endDate': endDate,
          'totalLeaveDays': totalLeaveDays,
          'weekendDays': 0,
          'officialHolidays': 0,
          'workingDays': 0,
          'leaveReason': leaveReason ?? '',
          'emergencyPhone': emergencyPhone ?? '',
          'notes': notes ?? '',
          'username': username,
          'userId': userId,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[LeavesRepository] createLeaveRequest error: ${e.message}');
      rethrow;
    }
  }
}

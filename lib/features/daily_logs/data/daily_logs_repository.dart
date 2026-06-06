import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'models/daily_attendance_model.dart';

class DailyLogsRepository {
  final Dio _dio;

  DailyLogsRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  Future<DailyAttendanceResponse> getDailyAttendance({
    required int managerId,
    required String checkDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.dailyAttendance,
        data: {
          'managerId': managerId,
          'checkDate': checkDate,
        },
      );
      return DailyAttendanceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[DailyLogsRepository] getDailyAttendance error: ${e.message}');
      rethrow;
    }
  }
}

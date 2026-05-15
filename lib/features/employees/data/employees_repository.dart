import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/employee_attendance_model.dart';
import 'models/employee_model.dart';

/// Repository for fetching employee data from the Delta ORDS API.
class EmployeesRepository {
  final Dio _dio;

  EmployeesRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  /// Fetches a paginated list of employees.
  Future<EmployeesResponse> getEmployees({
    required int pageNumber,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.employees,
        data: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          'employeeId': null,
          'employeeCode': null,
        },
      );

      return EmployeesResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[EmployeesRepository] getEmployees error: ${e.message}');
      rethrow;
    }
  }

  /// Fetches subordinates for a given manager (0-based page index).
  Future<EmployeesResponse> getSubordinates({
    required int managerId,
    int pageNumber = 0,
    int pageSize = 50,
    String? employeeCode,
    String? checkDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.subordinates,
        data: {
          'managerId': managerId,
          'employeeId': null,
          'employeeCode': employeeCode != null
              ? (int.tryParse(employeeCode) ?? employeeCode)
              : null,
          if (checkDate != null) 'checkDate': checkDate,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      return EmployeesResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[EmployeesRepository] getSubordinates error: ${e.message}');
      rethrow;
    }
  }

  /// Searches for an employee by their code.
  /// Only sends the employeeCode — no pagination params.
  Future<EmployeesResponse> searchByCode(String code) async {
    try {
      final response = await _dio.post(
        ApiConstants.employees,
        data: {
          'employeeCode': int.tryParse(code) ?? code,
        },
      );

      return EmployeesResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[EmployeesRepository] searchByCode error: ${e.message}');
      rethrow;
    }
  }

  /// Fetches monthly attendance log for a specific employee.
  Future<EmployeeAttendanceResponse> getEmployeeAttendanceLog({
    required int employeeId,
    required String fromDate,
    required String toDate,
    int pageNumber = 0,
    int pageSize = 100,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.employeeAttendanceLog,
        data: {
          'employeeId': employeeId,
          'fromDate': fromDate,
          'toDate': toDate,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      return EmployeeAttendanceResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[EmployeesRepository] getEmployeeAttendanceLog error: ${e.message}');
      rethrow;
    }
  }
}

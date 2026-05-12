import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
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
}

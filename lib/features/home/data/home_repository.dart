import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/pending_approval_model.dart';

/// Repository for home screen API calls.
class HomeRepository {
  final Dio _dio;

  HomeRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  /// Fetches pending approvals for a manager.
  Future<PendingApprovalsResponse> getPendingApprovals({
    required int managerId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.pendingApprovals,
        data: {
          'managerId': managerId.toString(),
        },
      );

      return PendingApprovalsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[HomeRepository] getPendingApprovals error: ${e.message}');
      rethrow;
    }
  }
}

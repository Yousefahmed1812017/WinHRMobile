import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/exceptions.dart';

/// Maps Dio errors to application-level exceptions for consistent handling.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[ErrorInterceptor] ${err.type} → ${err.message}');

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(
          err.copyWith(
            error: const NetworkException('Connection timed out. Try again.'),
          ),
        );
        return;

      case DioExceptionType.connectionError:
        handler.next(
          err.copyWith(
            error: const NetworkException(
              'No internet connection. Please check your network.',
            ),
          ),
        );
        return;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final message = _extractMessage(err.response);

        if (statusCode == 401) {
          handler.next(
            err.copyWith(error: const UnauthorizedException()),
          );
          return;
        }
        if (statusCode == 403) {
          handler.next(
            err.copyWith(
              error: const ServerException('Access denied.'),
            ),
          );
          return;
        }
        if (statusCode == 404) {
          handler.next(
            err.copyWith(
              error: const ServerException('Resource not found.'),
            ),
          );
          return;
        }
        if (statusCode >= 500) {
          handler.next(
            err.copyWith(
              error: ServerException(
                message ?? 'Server error. Please try again later.',
              ),
            ),
          );
          return;
        }

        handler.next(
          err.copyWith(
            error: ServerException(message ?? 'Something went wrong.'),
          ),
        );
        return;

      default:
        handler.next(err);
    }
  }

  /// Attempts to extract a human-readable message from the APEX response body.
  String? _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['error'] as String? ??
            data['error_message'] as String?;
      }
    } catch (_) {}
    return null;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../routing/app_router.dart';
import '../routing/route_names.dart';

/// Injects the JWT Bearer token into every outgoing request.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login endpoint
    if (options.path.contains(ApiConstants.login)) {
      return handler.next(options);
    }

    final token = await _secureStorage.read(key: StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      // Clean and normalize token
      var cleanToken = token.trim();
      if (cleanToken.startsWith('"') && cleanToken.endsWith('"')) {
        cleanToken = cleanToken.substring(1, cleanToken.length - 1).trim();
      }

      debugPrint('[AuthInterceptor] Stored token length: ${token.length}');
      debugPrint('[AuthInterceptor] Cleaned token: "$cleanToken"');

      if (cleanToken.toLowerCase().startsWith('bearer ')) {
        options.headers['Authorization'] = cleanToken;
      } else {
        options.headers['Authorization'] = 'Bearer $cleanToken';
      }
      
      debugPrint('[AuthInterceptor] Header sent: Authorization: ${options.headers['Authorization']}');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Skip checking for login endpoint responses
    if (response.requestOptions.path.contains(ApiConstants.login)) {
      return handler.next(response);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'];
      final message = data['message']?.toString() ?? '';
      final messageAr = data['messageAr']?.toString() ?? '';

      // Check for token expired / unauthorized / PL/SQL value error (which happens on expired/invalid tokens)
      final isUnauthorized = code == 401 ||
          message.contains('Unauthorized') ||
          messageAr.contains('غير مصرح') ||
          message.contains('ORA-06502') ||
          messageAr.contains('خطأ داخلي في الخادم') ||
          message.contains('token') ||
          messageAr.contains('التوكن');

      if (isUnauthorized) {
        debugPrint('[AuthInterceptor] Unauthorized or Expired token detected in response body: $data');
        debugPrint('[AuthInterceptor] Clearing storage and redirecting to Login screen...');
        
        // Clear secure storage
        await _secureStorage.deleteAll();
        
        // Redirect to login screen
        AppRouter.router.go(RouteNames.login);
        
        // Reject the request as an unauthorized error
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: Response(
              requestOptions: response.requestOptions,
              statusCode: 401,
              data: response.data,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('[AuthInterceptor] 401 Unauthorized — token may be expired.');
    }
    handler.next(err);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';

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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('[AuthInterceptor] 401 Unauthorized — token may be expired.');
    }
    handler.next(err);
  }
}

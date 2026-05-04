import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/dio_client.dart';

/// Data class holding the logged-in user's profile info.
class UserData {
  final int userId;
  final String username;
  final String fullName;
  final String email;
  final String? imageUrl;
  final String? roleName;
  final int? employeeId;
  final String? employeeCode;

  const UserData({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.email,
    this.imageUrl,
    this.roleName,
    this.employeeId,
    this.employeeCode,
  });
}

/// Repository handling authentication with the Delta ORDS API.
class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({
    DioClient? dioClient,
    FlutterSecureStorage? storage,
  })  : _dio = (dioClient ?? DioClient()).dio,
        _storage = storage ?? const FlutterSecureStorage();

  /// Authenticates with username/password, stores JWT token + user data.
  /// Returns [UserData] on success, throws on failure.
  Future<UserData> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] == 'success' && data['token'] != null) {
        // Store the JWT token securely
        await _storage.write(
          key: StorageKeys.accessToken,
          value: data['token'] as String,
        );

        // Extract user info
        final user = data['user'] as Map<String, dynamic>? ?? {};

        final userData = UserData(
          userId: user['userId'] as int? ?? 0,
          username: user['username'] as String? ?? username,
          fullName: user['fullName'] as String? ?? '',
          email: user['email'] as String? ?? '',
          imageUrl: user['imageUrl'] as String?,
          roleName: user['roleName'] as String?,
          employeeId: user['employeeId'] as int?,
          employeeCode: user['employeeCode']?.toString(),
        );

        // Persist user data
        await _storeUserData(userData);

        debugPrint('[AuthRepository] Login successful. Token + user stored.');
        return userData;
      }

      throw Exception(data['messageAr'] ?? data['message'] ?? 'فشل تسجيل الدخول');
    } on DioException catch (e) {
      debugPrint('[AuthRepository] Login error: ${e.message}');
      // Try to extract Arabic error message from response
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final msg = responseData['messageAr'] ?? responseData['message'];
        if (msg != null) throw Exception(msg);
      }
      rethrow;
    }
  }

  /// Stores user data to secure storage.
  Future<void> _storeUserData(UserData user) async {
    await Future.wait([
      _storage.write(key: StorageKeys.userId, value: user.userId.toString()),
      _storage.write(key: StorageKeys.username, value: user.username),
      _storage.write(key: StorageKeys.userFullName, value: user.fullName),
      _storage.write(key: StorageKeys.userEmail, value: user.email),
      if (user.imageUrl != null)
        _storage.write(key: StorageKeys.userImageUrl, value: user.imageUrl!),
      if (user.roleName != null)
        _storage.write(key: StorageKeys.userRoleName, value: user.roleName!),
      if (user.employeeId != null)
        _storage.write(
            key: StorageKeys.userEmployeeId,
            value: user.employeeId.toString()),
      if (user.employeeCode != null)
        _storage.write(
            key: StorageKeys.userEmployeeCode, value: user.employeeCode!),
    ]);
  }

  /// Retrieves stored user data from secure storage.
  Future<UserData?> getUserData() async {
    final userId = await _storage.read(key: StorageKeys.userId);
    if (userId == null) return null;

    return UserData(
      userId: int.tryParse(userId) ?? 0,
      username: await _storage.read(key: StorageKeys.username) ?? '',
      fullName: await _storage.read(key: StorageKeys.userFullName) ?? '',
      email: await _storage.read(key: StorageKeys.userEmail) ?? '',
      imageUrl: await _storage.read(key: StorageKeys.userImageUrl),
      roleName: await _storage.read(key: StorageKeys.userRoleName),
      employeeId: int.tryParse(
          await _storage.read(key: StorageKeys.userEmployeeId) ?? ''),
      employeeCode: await _storage.read(key: StorageKeys.userEmployeeCode),
    );
  }

  /// Checks if a valid token exists in secure storage.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  /// Retrieves the stored JWT token.
  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  /// Clears all stored data (logout).
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}

/// Keys used across local storage (Hive, SecureStorage, SharedPrefs).
class StorageKeys {
  StorageKeys._();

  // ── Secure Storage (flutter_secure_storage) ────────────────────────────
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String userFullName = 'user_full_name';
  static const String userEmail = 'user_email';
  static const String userImageUrl = 'user_image_url';
  static const String userRoleName = 'user_role_name';
  static const String userEmployeeId = 'user_employee_id';
  static const String userEmployeeCode = 'user_employee_code';

  // ── Hive Boxes ─────────────────────────────────────────────────────────
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
  static const String attendanceBox = 'attendance_box';

  // ── SharedPreferences ──────────────────────────────────────────────────
  static const String locale = 'locale';
  static const String themeMode = 'theme_mode';
  static const String isFirstLaunch = 'is_first_launch';
  static const String lastSyncTime = 'last_sync_time';
}

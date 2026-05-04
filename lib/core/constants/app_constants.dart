/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Win HR';
  static const String appVersion = '0.1.0';

  // ── Pagination ─────────────────────────────────────────────────────────
  static const int defaultPageSize = 25;

  // ── Date Formats ───────────────────────────────────────────────────────
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateTimeFormatApi = "yyyy-MM-dd'T'HH:mm:ss";
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String timeFormatDisplay = 'hh:mm a';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy hh:mm a';

  // ── Animation Durations ────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ── Supported Locales ──────────────────────────────────────────────────
  static const String arabicLocale = 'ar';
  static const String englishLocale = 'en';
}

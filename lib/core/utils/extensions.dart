import 'package:flutter/material.dart';

/// Handy Dart / Flutter extensions used across the app.

// ── BuildContext shortcuts ──────────────────────────────────────────────
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Shows a themed snackbar.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? colorScheme.error : colorScheme.primary,
      ),
    );
  }
}

// ── String utilities ────────────────────────────────────────────────────
extension StringExtensions on String {
  /// Capitalizes the first letter.
  String get capitalize =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncates to [maxLength] with ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}

// ── DateTime helpers ────────────────────────────────────────────────────
extension DateTimeExtensions on DateTime {
  /// Returns true if [this] is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns a date-only [DateTime] (midnight).
  DateTime get dateOnly => DateTime(year, month, day);
}

// ── Num helpers ─────────────────────────────────────────────────────────
extension NumExtensions on num {
  /// Creates a vertical [SizedBox].
  SizedBox get verticalSpace => SizedBox(height: toDouble());

  /// Creates a horizontal [SizedBox].
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}

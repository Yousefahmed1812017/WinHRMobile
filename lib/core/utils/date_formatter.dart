import 'package:intl/intl.dart';

/// Utility helpers for date / time formatting.
class DateFormatter {
  DateFormatter._();

  /// e.g. "27/04/2026"
  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  /// e.g. "02:30 PM"
  static String formatTime(DateTime date) =>
      DateFormat('hh:mm a').format(date);

  /// e.g. "27/04/2026 02:30 PM"
  static String formatDateTime(DateTime date) =>
      DateFormat('dd/MM/yyyy hh:mm a').format(date);

  /// e.g. "April 27, 2026"
  static String formatDateLong(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);

  /// e.g. "27 أبريل 2026" (Arabic)
  static String formatDateArabic(DateTime date) =>
      DateFormat('d MMMM yyyy', 'ar').format(date);

  /// Returns friendly relative time: "Just now", "5 min ago", etc.
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  /// Parses ISO 8601 string to [DateTime].
  static DateTime? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Duration between two times as "Xh Ym".
  static String durationBetween(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}

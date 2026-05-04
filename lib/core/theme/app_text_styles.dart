import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Win HR typography styles.
/// Uses **Cairo** for Arabic and **Inter** for Latin scripts.
class AppTextStyles {
  AppTextStyles._();

  // ── Base Font Families ─────────────────────────────────────────────────

  static TextStyle get _cairoBase => GoogleFonts.cairo();
  static TextStyle get _interBase => GoogleFonts.inter();

  /// Returns the appropriate base font based on locale.
  static TextStyle baseFont({bool isArabic = true}) =>
      isArabic ? _cairoBase : _interBase;

  // ── Headings ───────────────────────────────────────────────────────────

  static TextStyle headingXL({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle headingLarge({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle headingMedium({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle headingSmall({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  // ── Body ───────────────────────────────────────────────────────────────

  static TextStyle bodyLarge({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMedium({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodySmall({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // ── Labels ─────────────────────────────────────────────────────────────

  static TextStyle labelLarge({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle labelMedium({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle labelSmall({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 10, fontWeight: FontWeight.w500, height: 1.4);

  // ── Button Text ────────────────────────────────────────────────────────

  static TextStyle buttonLarge({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle buttonMedium({bool isArabic = true}) => baseFont(
        isArabic: isArabic,
      ).copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);

  // ── Numbers (always LTR, Inter) ────────────────────────────────────────

  static TextStyle number({double fontSize = 24}) => _interBase.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
}

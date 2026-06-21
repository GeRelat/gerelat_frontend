import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Tipografia {
  Tipografia._();

  static TextStyle get headlineLarge =>
      GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w700);

  static TextStyle get headlineMedium =>
      GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700);

  static TextStyle get headlineSmall =>
      GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800);

  static TextStyle get titleLarge =>
      GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700);

  static TextStyle get titleMedium =>
      GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle get titleSmall =>
      GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);

  static TextStyle get labelLarge =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get labelMedium =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700);

  static TextStyle get labelSmall =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400);

  static TextTheme get textTheme => TextTheme(
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Define todos os estilos de texto do GeRelat.
/// Usa Poppins para títulos e Roboto para textos de corpo e labels.
class Tipografia {
  Tipografia._();

  //  HEADLINES (Poppins)
  /// Título grande — Poppins SemiBold 32px
  static TextStyle get headlineLarge =>
      GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600);

  /// Título médio — Poppins Regular 28px
  static TextStyle get headlineMedium =>
      GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w400);

  /// Título pequeno — Poppins Regular 24px
  static TextStyle get headlineSmall =>
      GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w400);

  //  TITLES (Poppins)
  /// Título de seção grande — Poppins Medium 20px
  static TextStyle get titleLarge =>
      GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500);

  /// Título de seção médio — Poppins Medium 16px
  static TextStyle get titleMedium =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500);

  /// Título de seção pequeno — Poppins Medium 14px
  static TextStyle get titleSmall =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500);

  //  BODY (Roboto)

  /// Texto de corpo grande — Roboto Regular 16px
  static TextStyle get bodyLarge =>
      GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400);

  /// Texto de corpo médio — Roboto Regular 14px
  static TextStyle get bodyMedium =>
      GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400);

  /// Texto de corpo pequeno — Roboto Regular 12px
  static TextStyle get bodySmall =>
      GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400);

  // LABELS (Roboto)

  /// Label grande — Roboto SemiBold 14px
  static TextStyle get labelLarge =>
      GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600);

  /// Label médio — Roboto Bold 12px
  static TextStyle get labelMedium =>
      GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700);

  /// Label pequeno — Roboto Regular 10px
  static TextStyle get labelSmall =>
      GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w400);

  //  TEMA COMPLETO 
  /// Retorna o TextTheme completo para usar no MaterialApp.
  /// Integra todos os estilos acima no sistema de temas do Flutter.
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

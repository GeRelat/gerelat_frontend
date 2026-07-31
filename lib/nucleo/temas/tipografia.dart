import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica do Design System do GeRelat, mapeada aos papéis do
/// type scale do Material 3 (headline/title/body/label, em Large/Medium/
/// Small).
///
/// Os estilos são calculados uma única vez em campos `static final` — em
/// vez de recriar o `TextStyle` a cada leitura — e reaproveitados em todo
/// o app. Use sempre um destes tokens (com `.copyWith(color: ...)` quando
/// precisar variar a cor) em vez de um `TextStyle` manual.
class Tipografia {
  Tipografia._();

  /// Título de destaque de página cheia (Manrope Bold 32px).
  static final TextStyle headlineLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  /// Título de seção principal (Manrope Bold 28px).
  static final TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  /// Título de cartão de resumo/dashboard (Manrope ExtraBold 24px).
  static final TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  /// Título de cabeçalho de página no `AppShell` (Manrope Bold 20px).
  static final TextStyle titleLarge = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// Título de cartão/bloco de conteúdo (Manrope Bold 16px).
  static final TextStyle titleMedium = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Título de item de lista/subcartão (Manrope SemiBold 14px).
  static final TextStyle titleSmall = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Corpo de texto de destaque (Inter Regular 16px).
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Corpo de texto padrão (Inter Regular 14px).
  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Corpo de texto pequeno (Inter Regular 12px).
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Rótulo de destaque — texto de botões e links (Inter SemiBold 14px).
  static final TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Rótulo secundário — legendas e metadados (Inter Bold 12px).
  static final TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /// Rótulo mínimo — texto auxiliar (Inter Regular 10px).
  static final TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );

  /// Título de seção/estado vazio em destaque. Mesmo papel visual de
  /// [titleLarge], porém com peso reforçado — usado em `app_shell.dart`
  /// (cabeçalho de página), `painel_ui.dart` (`EstadoVazio`) e
  /// `dashboard.dart`.
  static final TextStyle titleLargeDestaque = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  /// Título grande do fluxo de autenticação (cadastro, recuperação de
  /// senha). Mesmo papel visual de [headlineMedium], com o letterSpacing
  /// condensado repetido nesses fluxos.
  static final TextStyle headlineMediumDestaque = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.75,
  );

  /// Rótulo de destaque em links/ênfases inline (ex.: "Fazer login",
  /// nome da marca destacado). Mesmo papel visual de [labelLarge], em
  /// tamanho maior.
  static final TextStyle labelLargeDestaque = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Rótulo pequeno, maiúsculo e espaçado (eyebrow), usado como categoria/
  /// cabeçalho de seção acima de listas e formulários.
  static final TextStyle eyebrow = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  /// [TextTheme] usado em `ThemeData.textTheme` (ver `main.dart`), com os
  /// 12 papéis padrão do type scale do Material 3 mapeados aos estilos
  /// acima.
  static final TextTheme textTheme = TextTheme(
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

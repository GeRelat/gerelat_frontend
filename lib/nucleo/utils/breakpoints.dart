import 'package:flutter/material.dart';

class Breakpoints {
  // ── Breakpoints de layout ────────────────────────────────────────────────
  static const double mobile = 600;
  static const double tablet = 1024;

  // ── Thresholds de componentes ────────────────────────────────────────────
  // Largura mínima de tela para exibir o card de login em dois painéis
  static const double thresholdLogin = 700.0;

  // Largura mínima de tela para o formulário de cadastro ter largura fixa
  static const double thresholdForm = 560.0;

  // Largura mínima de tela para os cards de auth terem largura fixa (448px)
  static const double thresholdCard = 480.0;

  // ── Helpers de contexto ───────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;
}

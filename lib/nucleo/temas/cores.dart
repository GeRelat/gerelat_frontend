import 'package:flutter/material.dart';

/// Paleta de cores oficial do GeRelat.
/// Todas as cores usadas na aplicação devem vir daqui.
class Cores {
  Cores._();

  // Cor principal do sistema — azul institucional
  static const Color azulPrimario = Color(0xFF00488D);

  // Fundo geral das páginas — azul muito claro
  static const Color fundoPagina = Color(0xFFF1F4FA);

  // Branco puro — fundos de painéis e cards
  static const Color branco = Color(0xFFFFFFFF);

  // Preto absoluto
  static const Color preto = Color(0xFF000000);

  // Quase preto — usado em títulos e textos de destaque
  static const Color pretoProfundo = Color(0xFF181C20);

  // Cinza escuro — textos secundários e labels
  static const Color cinzaEscuro = Color(0xFF424752);

  // Cinza médio — placeholders e textos de apoio
  static const Color cinzaMedio = Color(0xFF727783);

  // Cinza claro — bordas e divisores
  static const Color cinzaClaro = Color(0xFFDFE3E8);

  // Cinza azulado — backgrounds sutis de inputs
  static const Color cinzaAzulado = Color(0xFFC2C6D4);

  // Branco com 10% de opacidade — sobreposições sutis no painel azul
  static const Color brancoSutil = Color(0x1AFFFFFF);

  // Branco com 2% de opacidade — divisores invisíveis no painel azul
  static const Color brancoMinimoOpaco = Color(0x05FFFFFF);
}

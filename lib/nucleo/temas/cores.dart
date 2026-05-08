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

  // Verde de status ativo
  static const Color verde = Color(0xFF059669);

  // ── Gradiente do botão primário ──────────────────────────────────────────
  // Par de cores para o LinearGradient do BotaoPrimario
  static const Color azulGradienteInicio = Color(0xFF00488D); // = azulPrimario
  static const Color azulGradienteFim = Color(0xFF005FB8);

  // ── Paleta do Dashboard ──────────────────────────────────────────────────
  // Azul vivo do card hero "Criar Relatório"
  static const Color azulDash = Color(0xFF1A6CFF);

  // Azul dos links e ícones ativos do dashboard
  static const Color azulDashLink = Color(0xFF0054D3);

  // Azul do texto e ícone de nav ativo
  static const Color azulDashNavAtivo = Color(0xFF1D4ED8);

  // Fundo do ícone em card de ação (azul claro)
  static const Color azulDashIconeFundo = Color(0xFFEFF6FF);

  // Fundo do item de nav ativo (azul claro 50% opacidade)
  static const Color azulDashNavFundoAtivo = Color(0x80DBEAFE);

  // Fundo da sidebar de navegação
  static const Color cinzaNavFundo = Color(0xFFF1F5F9);

  // Cor dos ícones e textos de nav inativos
  static const Color cinzaNavInativo = Color(0xFF64748B);

  // Fundo dos cards informativos do rodapé
  static const Color cinzaInfoFundo = Color(0xFFF2F4F6);

  // Borda separadora do rodapé da sidebar
  static const Color cinzaNavBorda = Color(0xFFE2E8F0);

  // Cor do ícone decorativo dos cards de info
  static const Color azulDecoratvo = Color(0xFFB2C5FF);

  // Avatar padrão (sem foto)
  static const Color cinzaAvatar = Color(0xFFE6E8EA);

  // ── Cores de feedback / decorativas ─────────────────────────────────────
  // Verde claro — sucesso e brilho decorativo
  static const Color verdeSuccesso = Color(0xFFA3F69C);

  // Verde escuro — ícone de check sobre fundo verde claro
  static const Color verdeEscuro = Color(0xFF002204);

  // Azul claro — círculo de ícone nas telas de recuperação/confirmação
  static const Color azulClaro = Color(0xFFD6E3FF);

  // Azul brilho — efeito de brilho decorativo de fundo
  static const Color azulBrilho = Color(0xFFA8C8FF);
}

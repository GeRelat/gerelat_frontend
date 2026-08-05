import 'package:flutter/material.dart';

/// Paleta de cores do Design System do GeRelat.
///
/// Cada token representa um papel visual, não apenas um valor solto: ao
/// aplicar cor em uma tela, prefira sempre um destes tokens a um
/// `Color(0x...)` direto, para manter a paleta com uma única fonte de
/// verdade.
class Cores {
  Cores._();

  // ---------------------------------------------------------------------
  // Marca e ação — azul institucional: CTAs, links, navegação ativa e
  // elementos de destaque.
  // ---------------------------------------------------------------------

  /// Azul institucional principal — cabeçalho da sidebar, ícone da marca,
  /// título das telas de autenticação.
  static const Color azulPrimario = Color(0xFF00488D);

  /// Azul de ação — botões primários, item de menu ativo, links.
  static const Color azulAcao = Color(0xFF0054D3);

  /// Azul claro de apoio, usado pontualmente (hero do dashboard).
  static const Color azulClaro = Color(0xFF1A6CFF);

  /// Cor final do gradiente diagonal com [azulPrimario] nas telas de
  /// autenticação (recuperação de senha, sucesso de cadastro).
  static const Color azulGradienteFim = Color(0xFF005FB8);

  /// Azul usado em ilustrações decorativas de fundo (círculos com blur)
  /// nas telas de recuperação de senha.
  static const Color azulIlustracaoClaro = Color(0xFFA8C8FF);

  /// Azul suave usado como fundo de ícones ilustrativos nas telas de
  /// recuperação/confirmação de senha.
  static const Color azulIlustracaoSuave = Color(0xFFD6E3FF);

  // ---------------------------------------------------------------------
  // Fundos — cor de superfície/plano de fundo de páginas e seções.
  // ---------------------------------------------------------------------

  /// Fundo padrão de páginas com cartões sobre base neutra clara.
  static const Color fundoPagina = Color(0xFFF1F4FA);

  /// Fundo do canvas do `AppShell` (área atrás do conteúdo das páginas).
  static const Color fundoCanvas = Color(0xFFF7F9FB);

  /// Fundo de blocos/seções internas de cartões e formulários.
  static const Color fundoSecao = Color(0xFFF8FAFC);

  /// Fundo de destaque sutil — sidebar, chips e blocos de apoio.
  static const Color fundoDestaqueSutil = Color(0xFFF1F5F9);

  // ---------------------------------------------------------------------
  // Neutros — preto, branco e escala de cinza para texto, ícones e bordas.
  // ---------------------------------------------------------------------

  static const Color branco = Color(0xFFFFFFFF);

  /// Preto puro — usado como base de sombras leves via
  /// `Cores.preto.withValues(alpha: ...)`.
  static const Color preto = Color(0xFF000000);

  /// Preto suavizado — título das telas de autenticação e base de sombras
  /// mais pronunciadas via `Cores.pretoProfundo.withValues(alpha: ...)`.
  static const Color pretoProfundo = Color(0xFF181C20);

  /// Cor padrão de texto principal (títulos e corpo de texto de destaque).
  static const Color textoPrincipal = Color(0xFF191C1E);

  /// Texto/ícone secundário de maior ênfase (rótulos, subtítulos).
  static const Color cinzaEscuro = Color(0xFF424752);

  /// Texto/ícone secundário de menor ênfase (descrições, metadados).
  /// Ajustado de 0xFF727783 para atingir 4.5:1 (mínimo WCAG/M3 para texto
  /// normal) sobre [branco] e [fundoCanvas].
  static const Color cinzaMedio = Color(0xFF6D727E);

  /// Bordas e divisores neutros.
  static const Color cinzaClaro = Color(0xFFDFE3E8);

  /// Fundo de placeholders de imagem/avatar.
  static const Color cinzaCampo = Color(0xFFE0E3E5);

  /// Texto de apoio em placeholders de campo (hint text).
  static const Color cinzaAzulado = Color(0xFFC2C6D4);

  /// Estado inativo de indicadores (ex.: dots de progresso).
  static const Color cinzaInativo = Color(0xFFE5E8EE);

  /// Borda sutil translúcida usada em cartões e no cabeçalho do `AppShell`.
  static const Color bordaSutil = Color(0x26C2C6D8);

  // ---------------------------------------------------------------------
  // Feedback — status de sucesso e erro.
  // ---------------------------------------------------------------------

  /// Verde de sucesso — cor de texto em rótulos de status ("Ativo") e
  /// indicadores positivos. Ajustado de 0xFF059669 para atingir 4.5:1
  /// (mínimo WCAG/M3 para texto normal) sobre [branco] e [fundoCanvas].
  static const Color verdeSucesso = Color(0xFF04815A);

  /// Verde claro decorativo (ilustração da tela de sucesso de cadastro).
  static const Color verdeClaro = Color(0xFFA3F69C);

  /// Texto sobre [verdeClaro] na tela de sucesso de cadastro.
  static const Color verdeTextoEscuro = Color(0xFF002204);

  /// Vermelho de erro — mensagens de erro e ações destrutivas.
  static const Color vermelhoErro = Color(0xFFE53935);

  /// Âmbar de alerta — avisos que não impedem a ação, como variável
  /// obrigatória ainda sem valor ou referência sem definição no template.
  /// Escolhido para atingir 4.5:1 (mínimo WCAG/M3 para texto normal) sobre
  /// [branco] e [fundoCanvas].
  static const Color ambarAlerta = Color(0xFFB45309);

  // ---------------------------------------------------------------------
  // Translúcidos — elementos sobre o painel azul da tela de login.
  // ---------------------------------------------------------------------

  /// Branco a ~10% de opacidade — cartões translúcidos sobre fundo azul.
  static const Color brancoSutil = Color(0x1AFFFFFF);
}

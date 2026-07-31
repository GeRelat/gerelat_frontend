import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';

/// Sombras do Design System do GeRelat.
///
/// Cobre os valores efetivamente compartilhados por mais de um lugar no
/// app: o cartão de autenticação, o botão primário elevado e o cartão de
/// estatística. Os valores são calculados uma única vez em campos
/// `static final` — em vez de recriados a cada leitura — e reaproveitados
/// por quem os usa.
///
/// Nem toda sombra do app está aqui, de propósito: `pagina_login.dart`,
/// `formulario_cadastro.dart`, `pagina_email_enviado.dart`,
/// `pagina_recuperar_senha.dart` (cartão e botão de envio) têm cada uma um
/// `BoxShadow` próprio, com cor/blur/offset/spread que não coincidem entre
/// si nem com nenhum token daqui — evidência de que foram desenhadas
/// especificamente para aquela tela, não copiadas por acidente. Criar um
/// token para um valor usado em um único lugar não reduziria duplicação
/// nenhuma, então esses permanecem locais.
class Sombras {
  Sombras._();

  /// Sombra do cartão central nas telas de conclusão de cadastro e
  /// redefinição de senha (mesmo valor em `pagina_sucesso_cadastro.dart` e
  /// `pagina_nova_senha.dart`).
  static final List<BoxShadow> cartaoAutenticacao = [
    BoxShadow(
      color: Cores.pretoProfundo.withValues(alpha: 0.04),
      blurRadius: 48,
      offset: const Offset(0, 24),
    ),
  ];

  /// Sombra do botão primário elevado (`elevation: 1`) nas telas de
  /// recuperação de senha (mesmo valor em `pagina_email_enviado.dart` e
  /// `pagina_sucesso_cadastro.dart`).
  static final Color botaoPrimario = Cores.preto.withValues(alpha: 0.05);

  /// Sombra do cartão de estatística (`CartaoInfo`, em `painel_ui.dart`),
  /// usado no dashboard e na página de programas.
  static final List<BoxShadow> cartaoEstatistica = [
    BoxShadow(
      color: Cores.preto.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 1),
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/componentes/botao_primario.dart';
import 'package:gerelat_frontend/nucleo/componentes/decoracao_campo.dart';
import 'package:gerelat_frontend/nucleo/componentes/estilo_botao.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_email_enviado.dart';

/// Página de recuperação de senha.
/// O usuário informa o e-mail e recebe um link de redefinição.
class PaginaRecuperarSenha extends StatefulWidget {
  const PaginaRecuperarSenha({super.key});

  @override
  State<PaginaRecuperarSenha> createState() => _PaginaRecuperarSenhaState();
}

class _PaginaRecuperarSenhaState extends State<PaginaRecuperarSenha> {
  // Controlador do campo de e-mail
  final _controladorEmail = TextEditingController();

  // bool _carregando = false;

  @override
  void dispose() {
    // Libera o controlador ao destruir o widget
    _controladorEmail.dispose();
    super.dispose();
  }

  // TODO: descomentar quando o back-end habilitar recuperação de senha
  void _enviarLink() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PaginaEmailEnviado()),
    );
  }

  // Future<void> _enviarLink() async {
  //   if (!_chaveFormulario.currentState!.validate()) return;
  //   setState(() => _carregando = true);
  //   // chamar endpoint: POST /auth/password-reset/ com { email: _controladorEmail.text.trim() }
  //   await Future.delayed(const Duration(seconds: 1)); // remover após integração
  //   setState(() => _carregando = false);
  //   if (!mounted) return;
  //   Navigator.of(context).pushReplacement(
  //     MaterialPageRoute(builder: (_) => const PaginaEmailEnviado()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      appBar: _construirBarraTopo(),
      body: Stack(
        children: [
          // Efeitos de brilho decorativos no fundo da página
          _construirBrilhoFundo(),
          // Conteúdo principal centralizado
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        _construirCard(),
                        const SizedBox(height: 48),
                        _construirRodapeDecorativo(),
                      ],
                    ),
                  ),
                ),
              ),
              _construirRodape(),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra superior com logo GeRelat usando HeadlineSmall do design system
  PreferredSizeWidget _construirBarraTopo() {
    return AppBar(
      backgroundColor: Cores.fundoPagina,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        'GeRelat',
        style: Tipografia.headlineSmall.copyWith(
          letterSpacing: -1.2,
          color: Cores.pretoProfundo,
        ),
      ),
    );
  }

  /// Efeitos de brilho azul e verde no fundo da página
  Widget _construirBrilhoFundo() {
    return Stack(
      children: [
        // Brilho azul — canto superior direito
        Positioned(
          right: 320,
          top: 256,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              color: Cores.azulBrilho.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Brilho verde — canto inferior esquerdo
        Positioned(
          left: 320,
          bottom: 256,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              color: Cores.verdeSuccesso.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  /// Card principal com formulário de recuperação
  Widget _construirCard() {
    final largura = MediaQuery.sizeOf(context).width;
    final cardWidth = largura < Breakpoints.thresholdCard ? largura - 32 : 448.0;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Cores.branco,
        // Raio maior (24px) conforme especificação do Figma
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Cores.pretoProfundo.withValues(alpha: 0.04),
            blurRadius: 25,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Cores.pretoProfundo.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Brilho decorativo azul — canto superior direito do card
            Positioned(
              right: -64,
              top: -64,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: const Color(0xFFA8C8FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Brilho decorativo verde — canto inferior esquerdo do card
            Positioned(
              left: -64,
              bottom: -64,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: const Color(0xFFA3F69C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirIcone(),
                    const SizedBox(height: 32),
                    _construirTitulo(),
                    const SizedBox(height: 32),
                    _construirCampoEmail(),
                    const SizedBox(height: 24),
                    _construirBotaoEnviar(),
                    const SizedBox(height: 8),
                    _construirLinkVoltar(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Ícone de sincronização dentro de círculo cinza claro
  Widget _construirIcone() {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Cores.fundoPagina,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.sync_outlined,
          color: Cores.azulPrimario,
          size: 25,
        ),
      ),
    );
  }

  /// Título e subtítulo da página usando o design system
  Widget _construirTitulo() {
    return Column(
      children: [
        // Título → HeadlineSmall (Poppins Regular 24px)
        Text(
          'Recuperar Senha',
          style: Tipografia.headlineSmall.copyWith(
            letterSpacing: -0.6,
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 11),
        // Subtítulo → BodyMedium (Roboto Regular 14px)
        Text(
          'Insira seu e-mail para receber um link de redefinição.',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Campo de e-mail com label em maiúsculas
  Widget _construirCampoEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label → LabelMedium (Roboto Bold 12px) em maiúsculas com espaçamento
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'E-MAIL',
            style: Tipografia.labelMedium.copyWith(
              letterSpacing: 0.6,
              color: Cores.cinzaEscuro,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controladorEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: decoracaoCampo(
            dica: 'exemplo@email.com',
            icone: Icons.mail_outline,
            borderRadius: 16,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
          // Valida formato básico de e-mail
          validator: (valor) {
            if (valor == null || valor.isEmpty) return 'Informe o e-mail';
            if (!valor.contains('@')) return 'E-mail inválido';
            return null;
          },
        ),
      ],
    );
  }

  /// Botão com gradiente azul e ícone de seta
  Widget _construirBotaoEnviar() {
    return BotaoPrimario(
      rotulo: 'Enviar Link',
      onPressed: _enviarLink,
      icone: Icons.arrow_forward,
      estilo: EstiloBotao.comGradiente,
    );
  }

  /// Link de volta ao login com seta para esquerda
  Widget _construirLinkVoltar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back,
                  color: Cores.azulPrimario,
                  size: 14,
                ),
                const SizedBox(width: 8),
                // Texto → TitleSmall (Poppins Medium 14px)
                Text(
                  'Voltar ao login',
                  style: Tipografia.titleSmall.copyWith(
                    color: Cores.azulPrimario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Elemento decorativo do rodapé — divisores com ícones entre eles
  Widget _construirRodapeDecorativo() {
    return Opacity(
      opacity: 0.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Divisor esquerdo
          Container(width: 48, height: 1, color: Cores.cinzaMedio),
          const SizedBox(width: 24),
          // Três ícones decorativos centrais
          Row(
            children: [
              const Icon(Icons.language, size: 14, color: Cores.pretoProfundo),
              const SizedBox(width: 16),
              const Icon(Icons.shield_outlined, size: 14, color: Cores.pretoProfundo),
              const SizedBox(width: 16),
              const Icon(Icons.lock_outline, size: 14, color: Cores.pretoProfundo),
            ],
          ),
          const SizedBox(width: 24),
          // Divisor direito
          Container(width: 48, height: 1, color: Cores.cinzaMedio),
        ],
      ),
    );
  }

  /// Rodapé com copyright → BodySmall (Roboto Regular 12px)
  Widget _construirRodape() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        '© 2026 GeRelat • Segurança e transparência em seus relatórios.',
        style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/componentes/barra_topo.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/sombras.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

/// Página exibida após o envio do e-mail de recuperação de senha.
/// Confirma o envio e oferece ação de reenvio e retorno ao login.
class PaginaEmailEnviado extends StatefulWidget {
  final String? email;
  final RepositorioAutenticacao repositorioAutenticacao;

  const PaginaEmailEnviado({
    super.key,
    this.email,
    required this.repositorioAutenticacao,
  });

  @override
  State<PaginaEmailEnviado> createState() => _PaginaEmailEnviadoState();
}

class _PaginaEmailEnviadoState extends State<PaginaEmailEnviado> {
  bool _reenviando = false;

  /// Navega para o login limpando todo o histórico de navegação
  void _voltarAoLogin() {
    context.go('/login');
  }

  Future<void> _reenviar() async {
    final email = widget.email;
    if (email == null || email.isEmpty) {
      context.go('/recuperar-senha');
      return;
    }
    if (_reenviando) return;

    setState(() => _reenviando = true);
    final resultado = await widget.repositorioAutenticacao
        .solicitarRecuperacaoSenha(email: email);
    if (!mounted) return;
    setState(() => _reenviando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado.sucesso
              ? 'E-mail reenviado para $email.'
              : resultado.mensagemErro ?? 'Erro ao reenviar o e-mail.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      appBar: const BarraTopo(backgroundColor: Cores.fundoPagina),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: _construirCard(),
              ),
            ),
          ),
          _construirRodapeCompleto(),
        ],
      ),
    );
  }

  /// Card principal branco com ícone, texto e ações
  Widget _construirCard() {
    return Container(
      width: 448,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Cores.preto.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirIcone(),
          const SizedBox(height: 32),
          _construirTextos(),
          const SizedBox(height: 32),
          _construirAcoes(),
        ],
      ),
    );
  }

  /// Ícone de e-mail com check dentro de círculo azul claro com brilho sutil
  Widget _construirIcone() {
    return Center(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brilho azul sutil atrás do ícone
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Cores.azulPrimario.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
            // Círculo azul claro principal
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Cores.azulIlustracaoSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: Cores.azulPrimario,
                size: 42,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Título e subtítulo de confirmação usando o design system
  Widget _construirTextos() {
    return Column(
      children: [
        // Título → HeadlineMedium (Poppins Regular 28px)
        Text(
          'E-mail de recuperação\nenviado!',
          style: Tipografia.headlineMediumDestaque.copyWith(
            height: 1.25,
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Subtítulo → BodyLarge (Roboto Regular 16px)
        Text(
          'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
          style: Tipografia.bodyLarge.copyWith(
            height: 1.625,
            color: Cores.cinzaEscuro,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Botão principal e texto auxiliar de reenvio
  Widget _construirAcoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botão "Voltar ao Login" → TitleMedium (Poppins Medium 16px)
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _voltarAoLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Cores.azulAcao,
              foregroundColor: Cores.branco,
              elevation: 1,
              shadowColor: Sombras.botaoPrimario,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Voltar ao Login',
              style: Tipografia.titleMedium.copyWith(color: Cores.branco),
            ),
          ),
        ),
        const SizedBox(height: 36),
        // Texto auxiliar com link de reenvio → BodyMedium (Roboto Regular 14px)
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Tipografia.bodyMedium.copyWith(
              height: 1.43,
              color: Cores.cinzaEscuro,
            ),
            children: [
              const TextSpan(text: 'Não recebeu o e-mail? '),
              // "Tente reenviar" como link azul — LabelLarge (Roboto SemiBold 14px)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: TextButton(
                  onPressed: _reenviando ? null : _reenviar,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _reenviando ? 'Reenviando...' : 'Tente reenviar',
                    style: Tipografia.labelLarge.copyWith(
                      color: _reenviando
                          ? Cores.cinzaMedio
                          : Cores.azulPrimario,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: ' ou verifique sua pasta de spam.'),
            ],
          ),
        ),
      ],
    );
  }

  /// Rodapé com "CONFIRMAÇÃO DE SEGURANÇA" entre divisores e copyright abaixo
  Widget _construirRodapeCompleto() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Linha decorativa com texto "CONFIRMAÇÃO DE SEGURANÇA"
          Opacity(
            opacity: 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Divisor esquerdo
                Container(width: 32, height: 1, color: Cores.cinzaEscuro),
                const SizedBox(width: 8),
                // Texto em maiúsculas → LabelSmall (Roboto Regular 10px)
                Text(
                  'CONFIRMAÇÃO DE SEGURANÇA',
                  style: Tipografia.labelSmall.copyWith(
                    letterSpacing: 1,
                    color: Cores.cinzaEscuro,
                  ),
                ),
                const SizedBox(width: 8),
                // Divisor direito
                Container(width: 32, height: 1, color: Cores.cinzaEscuro),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Copyright → BodySmall (Roboto Regular 12px)
          Text(
            '© 2026 GeRelat • Segurança e transparência em seus relatórios.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

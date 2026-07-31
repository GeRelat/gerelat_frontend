import 'package:flutter/material.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/componentes/barra_topo.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/validadores.dart';
import 'package:go_router/go_router.dart';

/// Página de recuperação de senha.
/// O usuário informa o e-mail e recebe um link de redefinição.
class PaginaRecuperarSenha extends StatefulWidget {
  final RepositorioAutenticacao repositorioAutenticacao;

  const PaginaRecuperarSenha({
    super.key,
    required this.repositorioAutenticacao,
  });

  @override
  State<PaginaRecuperarSenha> createState() => _PaginaRecuperarSenhaState();
}

class _PaginaRecuperarSenhaState extends State<PaginaRecuperarSenha> {
  // Chave para validar o formulário
  final _chaveFormulario = GlobalKey<FormState>();

  // Controlador do campo de e-mail
  final _controladorEmail = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    // Libera o controlador ao destruir o widget
    _controladorEmail.dispose();
    super.dispose();
  }

  /// Valida o e-mail e envia a solicitação de recuperação de senha
  Future<void> _enviarLink() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    setState(() => _enviando = true);
    final resultado = await widget.repositorioAutenticacao
        .solicitarRecuperacaoSenha(email: _controladorEmail.text.trim());
    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.sucesso) {
      context.go(
        '/recuperar-senha/enviado',
        extra: _controladorEmail.text.trim(),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resultado.mensagemErro ?? 'Erro ao enviar link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      appBar: const BarraTopo(backgroundColor: Cores.fundoPagina),
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

  /// Efeitos de brilho azul e verde no fundo da página
  Widget _construirBrilhoFundo() {
    return Stack(
      children: [
        // Brilho azul — canto superior direito
        _brilhoDecorativo(
          right: 320,
          top: 256,
          tamanho: 500,
          cor: Cores.azulIlustracaoClaro.withValues(alpha: 0.2),
        ),
        // Brilho verde — canto inferior esquerdo
        _brilhoDecorativo(
          left: 320,
          bottom: 256,
          tamanho: 400,
          cor: Cores.verdeClaro.withValues(alpha: 0.15),
        ),
      ],
    );
  }

  /// Círculo decorativo posicionado — mesmo tratamento usado por
  /// [_construirBrilhoFundo] e [_construirCard].
  Widget _brilhoDecorativo({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double tamanho,
    required Color cor,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
    );
  }

  /// Card principal com formulário de recuperação
  Widget _construirCard() {
    return Container(
      width: 448,
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
            _brilhoDecorativo(
              right: -64,
              top: -64,
              tamanho: 128,
              cor: Cores.azulIlustracaoClaro.withValues(alpha: 0.1),
            ),
            // Brilho decorativo verde — canto inferior esquerdo do card
            _brilhoDecorativo(
              left: -64,
              bottom: -64,
              tamanho: 128,
              cor: Cores.verdeClaro.withValues(alpha: 0.1),
            ),
            // Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _chaveFormulario,
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
            style: Tipografia.eyebrow.copyWith(color: Cores.cinzaEscuro),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controladorEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'exemplo@email.com',
            // Placeholder → BodyMedium (Roboto Regular 14px)
            hintStyle: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            prefixIcon: const Icon(
              Icons.mail_outline,
              color: Cores.cinzaMedio,
              size: 18,
            ),
            filled: true,
            fillColor: Cores.cinzaClaro,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            // Border-radius 16px conforme Figma
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Cores.azulPrimario,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Cores.vermelhoErro),
            ),
          ),
          // Valida formato básico de e-mail
          validator: (valor) {
            if (valor == null || valor.isEmpty) return 'Informe o e-mail';
            if (!emailValido(valor)) return 'E-mail inválido';
            return null;
          },
        ),
      ],
    );
  }

  /// Botão com gradiente azul e ícone de seta
  Widget _construirBotaoEnviar() {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Gradiente azul conforme especificação do Figma
          gradient: const LinearGradient(
            colors: [Cores.azulPrimario, Cores.azulGradienteFim],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Cores.preto.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
              spreadRadius: -1,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _enviando ? null : _enviarLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Cores.branco,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Texto → TitleMedium (Poppins Medium 16px)
          label: Text(
            _enviando ? 'Enviando...' : 'Enviar Link',
            style: Tipografia.titleMedium.copyWith(color: Cores.branco),
          ),
          icon: const Icon(Icons.arrow_forward, size: 14, color: Cores.branco),
          iconAlignment: IconAlignment.end,
        ),
      ),
    );
  }

  /// Link de volta ao login com seta para esquerda
  Widget _construirLinkVoltar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.arrow_back,
            color: Cores.azulPrimario,
            size: 14,
          ),
          // Texto → TitleSmall (Poppins Medium 14px)
          label: Text(
            'Voltar ao login',
            style: Tipografia.titleSmall.copyWith(color: Cores.azulPrimario),
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
              const Icon(
                Icons.shield_outlined,
                size: 14,
                color: Cores.pretoProfundo,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: Cores.pretoProfundo,
              ),
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

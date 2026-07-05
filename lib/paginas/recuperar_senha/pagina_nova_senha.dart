import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

/// Página de redefinição de senha.
/// Acessada pelo link recebido no e-mail de recuperação.
class PaginaNovaSenha extends StatefulWidget {
  final String uid;
  final String token;

  const PaginaNovaSenha({super.key, required this.uid, required this.token});

  @override
  State<PaginaNovaSenha> createState() => _PaginaNovaSenhaState();
}

class _PaginaNovaSenhaState extends State<PaginaNovaSenha> {
  // Chave para validar o formulário
  final _chaveFormulario = GlobalKey<FormState>();

  // Controladores dos campos de senha
  final _controladorNovaSenha = TextEditingController();
  final _controladorConfirmarSenha = TextEditingController();

  // Controla visibilidade da nova senha
  bool _senhaVisivel = false;
  bool _redefinindo = false;

  @override
  void dispose() {
    // Libera os controladores ao destruir o widget
    _controladorNovaSenha.dispose();
    _controladorConfirmarSenha.dispose();
    super.dispose();
  }

  /// Valida os campos e envia a nova senha para a API
  Future<void> _redefinirSenha() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    setState(() => _redefinindo = true);
    final resultado = await DependenciasApp.instancia.repositorioAutenticacao
        .confirmarRecuperacaoSenha(
          uid: widget.uid,
          token: widget.token,
          novaSenha: _controladorNovaSenha.text,
        );
    if (!mounted) return;
    setState(() => _redefinindo = false);

    if (resultado.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso.')),
      );
      context.go('/login');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado.mensagemErro ?? 'Erro ao redefinir senha.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      appBar: _construirBarraTopo(),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 40,
                ),
                child: _construirCard(),
              ),
            ),
          ),
          _construirRodape(),
        ],
      ),
    );
  }

  /// Barra superior com logo GeRelat — HeadlineSmall (Poppins Regular 24px)
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

  /// Card principal com formulário de nova senha
  Widget _construirCard() {
    return Container(
      width: 448,
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.cinzaAzulado.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Cores.pretoProfundo.withValues(alpha: 0.04),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Brilho decorativo azul sutil no canto superior esquerdo
            Positioned(
              left: -64,
              top: -102,
              child: Container(
                width: 512,
                height: 410,
                decoration: BoxDecoration(
                  color: Cores.azulPrimario.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _chaveFormulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirCabecalho(),
                    const SizedBox(height: 32),
                    _construirCampoNovaSenha(),
                    const SizedBox(height: 24),
                    _construirCampoConfirmarSenha(),
                    const SizedBox(height: 24),
                    _construirBotaoRedefinir(),
                    const SizedBox(height: 16),
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

  /// Ícone de cadeado dentro de círculo azul claro + título e subtítulo
  Widget _construirCabecalho() {
    return Column(
      children: [
        // Ícone em círculo azul claro (#D6E3FF)
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Cores.azulIlustracaoSuave,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: Cores.azulPrimario,
            size: 25,
          ),
        ),
        const SizedBox(height: 16),
        // Título → HeadlineMedium (Poppins Regular 28px)
        Text(
          'Nova Senha',
          style: Tipografia.headlineMedium.copyWith(
            letterSpacing: -0.75,
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Subtítulo → BodyMedium (Roboto Regular 14px)
        Text(
          'Defina uma senha forte e segura para sua conta.',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Campo de nova senha com helper text e botão de mostrar/ocultar
  Widget _construirCampoNovaSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label em maiúsculas → LabelMedium (Roboto Bold 12px)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'NOVA SENHA',
            style: Tipografia.labelMedium.copyWith(
              letterSpacing: 0.6,
              color: Cores.cinzaEscuro,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controladorNovaSenha,
          obscureText: !_senhaVisivel,
          decoration: _decoracaoCampo(
            dica: '••••••••',
            icone: Icons.lock_outline,
            sufixo: GestureDetector(
              onTap: () => setState(() => _senhaVisivel = !_senhaVisivel),
              child: Icon(
                _senhaVisivel
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Cores.cinzaMedio,
                size: 18,
              ),
            ),
          ),
          // Valida mínimo de 8 caracteres
          validator: (valor) {
            if (valor == null || valor.isEmpty) return 'Informe a nova senha';
            if (valor.length < 8) return 'Mínimo de 8 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 4),
        // Helper text em itálico → LabelSmall (Roboto Regular 10px)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Use pelo menos 8 caracteres.',
            style: Tipografia.labelSmall.copyWith(
              fontStyle: FontStyle.italic,
              color: Cores.cinzaEscuro.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de confirmação da nova senha com ícone de escudo
  Widget _construirCampoConfirmarSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label em maiúsculas → LabelMedium (Roboto Bold 12px)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'CONFIRMAR NOVA SENHA',
            style: Tipografia.labelMedium.copyWith(
              letterSpacing: 0.6,
              color: Cores.cinzaEscuro,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controladorConfirmarSenha,
          obscureText: true,
          decoration: _decoracaoCampo(
            dica: '••••••••',
            icone: Icons.shield_outlined,
          ),
          // Valida se as senhas coincidem
          validator: (valor) {
            if (valor == null || valor.isEmpty) return 'Confirme a nova senha';
            if (valor != _controladorNovaSenha.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Botão de redefinir senha com ícone de seta → TitleMedium (Poppins Medium 16px)
  Widget _construirBotaoRedefinir() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _redefinindo ? null : _redefinirSenha,
        style: ElevatedButton.styleFrom(
          backgroundColor: Cores.azulPrimario,
          foregroundColor: Cores.branco,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
        label: Text(
          _redefinindo ? 'Redefinindo...' : 'Redefinir Senha',
          style: Tipografia.titleMedium.copyWith(color: Cores.branco),
        ),
        icon: const Icon(Icons.arrow_forward, size: 14, color: Cores.branco),
        iconAlignment: IconAlignment.end,
      ),
    );
  }

  /// Link de volta ao login com seta — TitleSmall (Poppins Medium 14px)
  Widget _construirLinkVoltar() {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/login'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: Cores.azulPrimario, size: 12),
              const SizedBox(width: 4),
              Text(
                'Voltar para o Login',
                style: Tipografia.titleSmall.copyWith(
                  color: Cores.azulPrimario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decoração padrão dos campos de texto
  InputDecoration _decoracaoCampo({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: Tipografia.bodyLarge.copyWith(color: Cores.cinzaMedio),
      prefixIcon: Icon(icone, color: Cores.cinzaMedio, size: 16),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Cores.cinzaClaro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.azulPrimario, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.vermelhoErro),
      ),
    );
  }

  /// Rodapé com copyright → BodySmall (Roboto Regular 12px)
  Widget _construirRodape() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '© 2026 GeRelat • Segurança e transparência em seus relatórios.',
        style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        textAlign: TextAlign.center,
      ),
    );
  }
}

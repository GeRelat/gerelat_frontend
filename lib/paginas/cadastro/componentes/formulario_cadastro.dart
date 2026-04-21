import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/servicos/servico_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/sucesso_cadastro/pagina_sucesso_cadastro.dart';

/// Formulário de cadastro de novo usuário.
/// Contém os campos: nome completo, e-mail, senha e confirmação de senha.
class FormularioCadastro extends StatefulWidget {
  /// Callback chamado ao clicar em "Fazer login" — navega de volta ao login
  final VoidCallback aoClicarEmLogin;

  const FormularioCadastro({super.key, required this.aoClicarEmLogin});

  @override
  State<FormularioCadastro> createState() => _FormularioCadastroState();
}

class _FormularioCadastroState extends State<FormularioCadastro> {
  // Chave global para validar o formulário
  final _chaveFormulario = GlobalKey<FormState>();

  // Controladores dos campos de texto
  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _controladorConfirmarSenha = TextEditingController();

  // Controla visibilidade do campo senha
  bool _senhaVisivel = false;

  // Indica se o cadastro está sendo processado
  bool _carregando = false;

  @override
  void dispose() {
    // Libera todos os controladores ao destruir o widget
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmarSenha.dispose();
    super.dispose();
  }

  /// Valida os campos, chama a API e navega para a tela de sucesso
  Future<void> _realizarCadastro() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    setState(() => _carregando = true);

    final resultado = await ServicoAutenticacao.cadastrar(
      nomeCompleto: _controladorNome.text.trim(),
      email: _controladorEmail.text.trim(),
      senha: _controladorSenha.text,
    );

    setState(() => _carregando = false);

    // Verifica se o widget ainda está na tela antes de usar context
    if (!mounted) return;

    if (resultado.sucesso) {
      // Navega para a página de sucesso substituindo o cadastro na pilha
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaginaSucessoCadastro()),
      );
    } else {
      // Exibe o erro retornado pela API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.mensagemErro ?? 'Erro ao criar conta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 512,
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Cores.pretoProfundo.withValues(alpha: 0.08),
            blurRadius: 64,
            offset: const Offset(0, 32),
            spreadRadius: -12,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 64),
      child: Form(
        key: _chaveFormulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _construirCabecalho(),
            const SizedBox(height: 40),
            _construirCampoNome(),
            const SizedBox(height: 24),
            _construirCampoEmail(),
            const SizedBox(height: 24),
            _construirCampoSenha(),
            const SizedBox(height: 24),
            _construirCampoConfirmarSenha(),
            const SizedBox(height: 24),
            _construirBotaoCadastrar(),
            const SizedBox(height: 8),
            _construirLinkLogin(),
          ],
        ),
      ),
    );
  }

  /// Título e subtítulo do formulário usando o design system
  Widget _construirCabecalho() {
    return Column(
      children: [
        // Título → HeadlineMedium (Poppins Regular 28px)
        Text(
          'Crie sua conta',
          style: Tipografia.headlineMedium.copyWith(
            letterSpacing: -0.75,
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Subtítulo → BodyLarge (Roboto Regular 16px)
        Text(
          'Preencha os dados abaixo para começar a usar o GeRelat.',
          style: Tipografia.bodyLarge.copyWith(
            height: 1.5,
            color: Cores.cinzaEscuro,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Campo de nome completo com ícone de pessoa
  Widget _construirCampoNome() {
    return _construirGrupoCampo(
      rotulo: 'Nome Completo',
      campo: TextFormField(
        controller: _controladorNome,
        decoration: _decoracaoCampo(
          dica: 'Ex: João da Silva',
          icone: Icons.person_outline,
        ),
        // Valida se o nome foi preenchido
        validator: (valor) {
          if (valor == null || valor.trim().isEmpty) return 'Informe seu nome';
          return null;
        },
      ),
    );
  }

  /// Campo de e-mail com ícone de envelope
  Widget _construirCampoEmail() {
    return _construirGrupoCampo(
      rotulo: 'E-mail',
      campo: TextFormField(
        controller: _controladorEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: _decoracaoCampo(
          dica: 'nome@exemplo.com',
          icone: Icons.mail_outline,
        ),
        // Valida formato básico de e-mail
        validator: (valor) {
          if (valor == null || valor.isEmpty) return 'Informe o e-mail';
          if (!valor.contains('@')) return 'E-mail inválido';
          return null;
        },
      ),
    );
  }

  /// Campo de senha com botão de mostrar/ocultar
  Widget _construirCampoSenha() {
    return _construirGrupoCampo(
      rotulo: 'Senha',
      campo: TextFormField(
        controller: _controladorSenha,
        obscureText: !_senhaVisivel,
        decoration: _decoracaoCampo(
          dica: '••••••••',
          icone: Icons.lock_outline,
          sufixo: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _senhaVisivel = !_senhaVisivel),
              child: Icon(
                _senhaVisivel
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Cores.cinzaMedio,
                size: 20,
              ),
            ),
          ),
        ),
        // Valida mínimo de 8 caracteres
        validator: (valor) {
          if (valor == null || valor.isEmpty) return 'Informe a senha';
          if (valor.length < 8) return 'Mínimo de 8 caracteres';
          return null;
        },
      ),
    );
  }

  /// Campo de confirmação de senha — valida se bate com o campo senha
  Widget _construirCampoConfirmarSenha() {
    return _construirGrupoCampo(
      rotulo: 'Confirmar Senha',
      campo: TextFormField(
        controller: _controladorConfirmarSenha,
        obscureText: true,
        decoration: _decoracaoCampo(
          dica: '••••••••',
          icone: Icons.sync_outlined,
        ),
        // Verifica se as senhas coincidem
        validator: (valor) {
          if (valor == null || valor.isEmpty) return 'Confirme a senha';
          if (valor != _controladorSenha.text) return 'As senhas não coincidem';
          return null;
        },
      ),
    );
  }

  /// Botão principal de cadastro usando TitleMedium do design system
  Widget _construirBotaoCadastrar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _carregando ? null : _realizarCadastro,
        style: ElevatedButton.styleFrom(
          backgroundColor: Cores.azulPrimario,
          foregroundColor: Cores.branco,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          shadowColor: Cores.azulPrimario.withValues(alpha: 0.2),
        ),
        icon: _carregando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Cores.branco,
                  strokeWidth: 2,
                ),
              )
            : const SizedBox.shrink(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Texto do botão → TitleMedium (Poppins Medium 16px)
            Text(
              'Cadastrar',
              style: Tipografia.titleMedium.copyWith(color: Cores.branco),
            ),
            if (!_carregando) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Cores.branco),
            ],
          ],
        ),
      ),
    );
  }

  /// Link para voltar ao login usando BodyLarge do design system
  Widget _construirLinkLogin() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Texto neutro → BodyLarge (Roboto Regular 16px)
          Text(
            'Já possui uma conta? ',
            style: Tipografia.bodyLarge.copyWith(color: Cores.cinzaEscuro),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.aoClicarEmLogin,
              // Link de ação → LabelLarge (Roboto SemiBold 14px) em azul
              child: Text(
                'Fazer login',
                style: Tipografia.labelLarge.copyWith(
                  fontSize: 16,
                  color: Cores.azulPrimario,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Agrupa label + campo de texto com espaçamento padrão
  Widget _construirGrupoCampo({required String rotulo, required Widget campo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          // Label do campo → LabelLarge (Roboto SemiBold 14px)
          child: Text(
            rotulo,
            style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro),
          ),
        ),
        const SizedBox(height: 8),
        campo,
      ],
    );
  }

  /// Decoração padrão reutilizável para os campos de texto
  InputDecoration _decoracaoCampo({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      // Placeholder → BodyLarge com opacidade reduzida
      hintStyle: Tipografia.bodyLarge.copyWith(
        color: Cores.cinzaMedio.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(icone, color: Cores.cinzaMedio, size: 18),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Cores.cinzaClaro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

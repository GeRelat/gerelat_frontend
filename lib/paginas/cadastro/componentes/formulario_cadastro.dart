import 'package:flutter/material.dart';
import 'package:gerelat_frontend/aplicacao/view_models/cadastro_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/validadores.dart';
import 'package:go_router/go_router.dart';

/// Formulário de cadastro de novo usuário.
/// Contém os campos: nome completo, e-mail, senha e confirmação de senha.
class FormularioCadastro extends StatefulWidget {
  /// Callback chamado ao clicar em "Fazer login" — navega de volta ao login
  final VoidCallback aoClicarEmLogin;
  final RepositorioAutenticacao repositorioAutenticacao;

  const FormularioCadastro({
    super.key,
    required this.aoClicarEmLogin,
    required this.repositorioAutenticacao,
  });

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
  late final CadastroViewModel _viewModel;
  int? _clienteSelecionadoId;

  // Controla visibilidade do campo senha
  bool _senhaVisivel = false;

  // Indica se o cadastro está sendo processado
  @override
  void initState() {
    super.initState();
    _viewModel = CadastroViewModel(widget.repositorioAutenticacao);
    _viewModel.carregarClientes();
  }

  @override
  void dispose() {
    // Libera todos os controladores ao destruir o widget
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmarSenha.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Valida os campos, chama a API e navega para a tela de sucesso
  Future<void> _realizarCadastro() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    final sucesso = await _viewModel.cadastrar(
      nomeCompleto: _controladorNome.text.trim(),
      email: _controladorEmail.text.trim(),
      senha: _controladorSenha.text,
      clienteId: _clienteSelecionadoId,
    );

    // Verifica se o widget ainda está na tela antes de usar context
    if (!mounted) return;

    if (sucesso) {
      // Navega para a página de sucesso substituindo o cadastro na pilha
      context.go('/cadastro/sucesso');
    } else {
      // Exibe o erro retornado pela API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.mensagemErro ?? 'Erro ao criar conta.'),
          backgroundColor: Cores.vermelhoErro,
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
            AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) => _construirCampoCliente(),
            ),
            const SizedBox(height: 24),
            _construirCampoSenha(),
            const SizedBox(height: 24),
            _construirCampoConfirmarSenha(),
            const SizedBox(height: 24),
            // Só o botão depende de `_viewModel` (estado `carregando`) — o
            // AnimatedBuilder fica restrito a ele em vez do formulário inteiro.
            AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) => _construirBotaoCadastrar(),
            ),
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
        // Título -> HeadlineMedium (Poppins Regular 28px)
        Text(
          'Crie sua conta',
          style: Tipografia.headlineMediumDestaque.copyWith(
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Subtítulo -> BodyLarge (Roboto Regular 16px)
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
          if (!emailValido(valor)) return 'E-mail inválido';
          return null;
        },
      ),
    );
  }

  Widget _construirCampoCliente() {
    return _construirGrupoCampo(
      rotulo: 'Cliente',
      campo: DropdownButtonFormField<int>(
        initialValue: _clienteSelecionadoId,
        isExpanded: true,
        decoration: _decoracaoCampo(
          dica: _viewModel.clientes.isEmpty
              ? 'Nenhum cliente disponível'
              : 'Selecione o cliente',
          icone: Icons.business_outlined,
        ),
        items: [
          for (final cliente in _viewModel.clientes)
            DropdownMenuItem(value: cliente.id, child: Text(cliente.nome)),
        ],
        onChanged: _viewModel.clientes.isEmpty
            ? null
            : (valor) => setState(() => _clienteSelecionadoId = valor),
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
          sufixo: IconButton(
            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            icon: Icon(
              _senhaVisivel
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Cores.cinzaMedio,
              size: 20,
            ),
            tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
            visualDensity: VisualDensity.compact,
          ),
        ),
        // Espelha AUTH_PASSWORD_VALIDATORS do backend (ver validarForcaSenha).
        validator: (valor) => validarForcaSenha(
          valor,
          atributosUsuario: [_controladorNome.text, _controladorEmail.text],
        ),
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
        onPressed: _viewModel.carregando ? null : _realizarCadastro,
        style: ElevatedButton.styleFrom(
          backgroundColor: Cores.azulAcao,
          foregroundColor: Cores.branco,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          shadowColor: Cores.azulAcao.withValues(alpha: 0.2),
        ),
        icon: _viewModel.carregando
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
            if (!_viewModel.carregando) ...[
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
          TextButton(
            onPressed: widget.aoClicarEmLogin,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            // Link de ação → LabelLarge (Roboto SemiBold 14px) em azul
            child: Text(
              'Fazer login',
              style: Tipografia.labelLargeDestaque.copyWith(
                color: Cores.azulPrimario,
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
        borderSide: const BorderSide(color: Cores.vermelhoErro),
      ),
    );
  }
}

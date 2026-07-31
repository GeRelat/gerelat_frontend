import 'package:flutter/material.dart';
import 'package:gerelat_frontend/aplicacao/view_models/login_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/validadores.dart';
import 'package:go_router/go_router.dart';

class PainelDireito extends StatefulWidget {
  final RepositorioAutenticacao repositorioAutenticacao;
  final SessaoViewModel sessao;

  const PainelDireito({
    super.key,
    required this.repositorioAutenticacao,
    required this.sessao,
  });

  @override
  State<PainelDireito> createState() => _PainelDireitoState();
}

class _PainelDireitoState extends State<PainelDireito> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  late final LoginViewModel _viewModel;

  bool _senhaVisivel = false;
  bool _manterConectado = false;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(widget.repositorioAutenticacao);
  }

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _realizarLogin() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    final sucesso = await _viewModel.login(
      email: _controladorEmail.text.trim(),
      senha: _controladorSenha.text,
    );

    if (!mounted) return;

    if (sucesso) {
      widget.sessao.notificarMudancaAutenticacao();
      context.go('/dashboard');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao fazer login.'),
        backgroundColor: Cores.vermelhoErro,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Só o botão "Entrar" depende de `_viewModel` (estado `carregando`) — o
    // restante do painel é estático, então o AnimatedBuilder fica restrito
    // a ele em vez de envolver a tela inteira.
    return Container(
      color: Cores.branco,
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _construirCabecalho(),
                  const SizedBox(height: 36),
                  _construirFormulario(),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _viewModel,
                    builder: (context, _) => _construirBotaoEntrar(),
                  ),
                  const SizedBox(height: 24),
                  _construirDivisor(),
                  const SizedBox(height: 24),
                  _construirLinkCadastro(),
                ],
              ),
            ),
          ),
          _construirRodape(),
        ],
      ),
    );
  }

  Widget _construirCabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo de volta',
          style: Tipografia.headlineMedium.copyWith(
            color: Cores.pretoProfundo,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Acesse sua conta para gerenciar seus relatórios.',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
        ),
      ],
    );
  }

  Widget _construirFormulario() {
    return Form(
      key: _chaveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirLabelCampo('E-mail corporativo'),
          const SizedBox(height: 6),
          _construirCampoEmail(),
          const SizedBox(height: 20),
          _construirLinhaSenhaLabel(),
          const SizedBox(height: 6),
          _construirCampoSenha(),
          const SizedBox(height: 16),
          _construirCheckboxManterConectado(),
        ],
      ),
    );
  }

  Widget _construirLabelCampo(String texto) {
    return Text(
      texto,
      style: Tipografia.labelLarge.copyWith(
        color: Cores.cinzaEscuro,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _construirCampoEmail() {
    return TextFormField(
      controller: _controladorEmail,
      keyboardType: TextInputType.emailAddress,
      decoration: _decoracaoCampo(
        dica: 'nome@empresa.com.br',
        icone: Icons.mail_outline,
      ),
      validator: (valor) {
        if (valor == null || valor.isEmpty) return 'Informe o e-mail';
        if (!emailValido(valor)) return 'E-mail invalido';
        return null;
      },
    );
  }

  Widget _construirLinhaSenhaLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _construirLabelCampo('Senha'),
        TextButton(
          onPressed: () => context.push('/recuperar-senha'),
          style: _estiloBotaoLink,
          child: Text(
            'Esqueci a senha',
            style: Tipografia.labelLarge.copyWith(
              color: Cores.azulPrimario,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirCampoSenha() {
    return TextFormField(
      controller: _controladorSenha,
      obscureText: !_senhaVisivel,
      decoration: _decoracaoCampo(
        dica: '********',
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
      validator: (valor) {
        if (valor == null || valor.isEmpty) return 'Informe a senha';
        if (valor.length < 8) return 'Minimo de 8 caracteres';
        return null;
      },
    );
  }

  Widget _construirCheckboxManterConectado() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _manterConectado,
            activeColor: Cores.azulPrimario,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (valor) {
              setState(() => _manterConectado = valor ?? false);
            },
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Manter conectado',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
      ],
    );
  }

  Widget _construirBotaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _viewModel.carregando ? null : _realizarLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Cores.azulAcao,
          foregroundColor: Cores.branco,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _viewModel.carregando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Cores.branco,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Entrar na Plataforma',
                style: Tipografia.titleSmall.copyWith(fontSize: 15),
              ),
      ),
    );
  }

  Widget _construirDivisor() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Cores.cinzaClaro)),
        const SizedBox(width: 12),
        Text(
          'ou',
          style: Tipografia.bodyMedium.copyWith(
            color: Cores.cinzaMedio,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Cores.cinzaClaro)),
      ],
    );
  }

  Widget _construirLinkCadastro() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Não possui uma conta? ',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
        ),
        TextButton(
          onPressed: () => context.push('/cadastro'),
          style: _estiloBotaoLink,
          child: Text(
            'Cadastrar-se',
            style: Tipografia.titleSmall.copyWith(
              color: Cores.azulPrimario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirRodape() {
    return Center(
      child: Text(
        '2026 GeRelat Intelligence Solutions. Todos os direitos reservados.',
        style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
      ),
    );
  }

  /// Estilo compartilhado pelos links de texto do painel ("Esqueci a senha",
  /// "Cadastrar-se"): sem padding/tap target extra, para caber alinhado ao
  /// texto vizinho.
  static final _estiloBotaoLink = TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  InputDecoration _decoracaoCampo({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: Tipografia.bodyMedium.copyWith(color: Cores.cinzaAzulado),
      prefixIcon: Icon(icone, color: Cores.cinzaMedio, size: 20),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Cores.fundoPagina,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.cinzaClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.cinzaClaro),
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

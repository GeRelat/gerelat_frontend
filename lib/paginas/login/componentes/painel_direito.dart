import 'package:flutter/material.dart';
// import 'package:gerelat_frontend/autenticacao/dominio/casos_de_uso/fazer_login.dart';
// import 'package:gerelat_frontend/autenticacao/injecao_auth.dart';
import 'package:gerelat_frontend/nucleo/componentes/botao_primario.dart';
import 'package:gerelat_frontend/nucleo/componentes/decoracao_campo.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';
// import 'package:gerelat_frontend/nucleo/utils/result.dart';
import 'package:gerelat_frontend/paginas/cadastro/pagina_cadastro.dart';
import 'package:gerelat_frontend/paginas/dashboard/pagina_dashboard.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_recuperar_senha.dart';

/// Painel branco da direita na tela de login.
/// Contém o formulário de autenticação do usuário.
class PainelDireito extends StatefulWidget {
  const PainelDireito({super.key});

  @override
  State<PainelDireito> createState() => _PainelDireitoState();
}

class _PainelDireitoState extends State<PainelDireito> {
  // Chave global para validar o formulário
  final _chaveFormulario = GlobalKey<FormState>();

  // Controladores dos campos de texto
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();

  // Controla se a senha está visível ou oculta
  bool _senhaVisivel = false;

  // Controla o estado do checkbox "Manter conectado"
  bool _manterConectado = false;

  // bool _carregando = false;
  // final _fazerLogin = InjecaoAuth.fazerLogin();

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  // TODO: descomentar quando o back-end habilitar autenticação
  void _realizarLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PaginaDashboard()),
      (rota) => false,
    );
  }

  // Future<void> _realizarLogin() async {
  //   if (!_chaveFormulario.currentState!.validate()) return;
  //   setState(() => _carregando = true);
  //   final resultado = await _fazerLogin(
  //     ParamsLogin(
  //       email: _controladorEmail.text.trim(),
  //       senha: _controladorSenha.text,
  //     ),
  //   );
  //   setState(() => _carregando = false);
  //   if (!mounted) return;
  //   switch (resultado) {
  //     case Right():
  //       Navigator.of(context).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (_) => const PaginaDashboard()),
  //         (rota) => false,
  //       );
  //     case Left(:final error):
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(error.errorMessages),
  //           backgroundColor: Colors.redAccent,
  //         ),
  //       );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final hPadding = largura < 400 ? 24.0 : (largura < Breakpoints.thresholdLogin ? 32.0 : 56.0);

    return Container(
      color: Cores.branco,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 48),
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
                  _construirBotaoEntrar(),
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

  /// Título e subtítulo de boas-vindas
  Widget _construirCabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo de volta',
          style: Tipografia.headlineSmall.copyWith(
            color: Cores.pretoProfundo,
            fontWeight: FontWeight.w700,
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

  /// Formulário com campos de e-mail e senha
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

  /// Label cinza acima dos campos do formulário
  Widget _construirLabelCampo(String texto) {
    return Text(
      texto,
      style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro),
    );
  }

  /// Campo de texto para o e-mail corporativo
  Widget _construirCampoEmail() {
    return TextFormField(
      controller: _controladorEmail,
      keyboardType: TextInputType.emailAddress,
      decoration: _decoracaoCampo(
        dica: 'nome@empresa.com.br',
        icone: Icons.mail_outline,
      ),
      // Valida se o campo não está vazio e tem formato de e-mail
      validator: (valor) {
        if (valor == null || valor.isEmpty) return 'Informe o e-mail';
        if (!valor.contains('@')) return 'E-mail inválido';
        return null;
      },
    );
  }

  /// Linha com o label "Senha" e o link "Esqueci a senha"
  Widget _construirLinhaSenhaLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _construirLabelCampo('Senha'),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // Navega para a página de recuperação de senha
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaginaRecuperarSenha()),
              );
            },
            child: Text(
              'Esqueci a senha',
              style: Tipografia.labelLarge.copyWith(color: Cores.azulPrimario),
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de texto para a senha, com botão de mostrar/ocultar
  Widget _construirCampoSenha() {
    return TextFormField(
      controller: _controladorSenha,
      obscureText: !_senhaVisivel,
      decoration: _decoracaoCampo(
        dica: '••••••••',
        icone: Icons.lock_outline,
        sufixo: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // Alterna entre mostrar e ocultar a senha
              setState(() => _senhaVisivel = !_senhaVisivel);
            },
            child: Icon(
              _senhaVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Cores.cinzaMedio,
              size: 20,
            ),
          ),
        ),
      ),
      // Valida se a senha tem pelo menos 8 caracteres
      validator: (valor) {
        if (valor == null || valor.isEmpty) return 'Informe a senha';
        if (valor.length < 8) return 'Mínimo de 8 caracteres';
        return null;
      },
    );
  }

  /// Checkbox "Manter conectado" abaixo dos campos
  Widget _construirCheckboxManterConectado() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _manterConectado,
            activeColor: Cores.azulPrimario,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (valor) {
              // Atualiza o estado do checkbox
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

  /// Botão principal de login
  Widget _construirBotaoEntrar() {
    return BotaoPrimario(
      rotulo: 'Entrar na Plataforma',
      onPressed: _realizarLogin,
    );
  }

  /// Linha divisória entre o botão e o link de cadastro
  Widget _construirDivisor() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Cores.cinzaClaro)),
        const SizedBox(width: 12),
        Text(
          'ou',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Cores.cinzaClaro)),
      ],
    );
  }

  /// Linha com convite para criar uma nova conta
  Widget _construirLinkCadastro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Não possui uma conta? ',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // Navega para a página de cadastro
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaginaCadastro()),
              );
            },
            child: Text(
              'Cadastrar-se',
              style: Tipografia.labelLarge.copyWith(
                color: Cores.azulPrimario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rodapé com copyright
  Widget _construirRodape() {
    return Center(
      child: Text(
        '© 2026 GeRelat Intelligence Solutions. Todos os direitos reservados.',
        style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) =>
      decoracaoCampo(
        dica: dica,
        icone: icone,
        sufixo: sufixo,
        fillColor: Cores.fundoPagina,
        iconSize: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintColor: Cores.cinzaAzulado,
        bordaVisivel: true,
      );
}

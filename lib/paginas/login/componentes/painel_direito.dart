import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/paginas/cadastro/pagina_cadastro.dart';
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

  // Indica se o login está sendo processado
  bool _carregando = false;

  @override
  void dispose() {
    // Libera os controladores da memória quando o widget é destruído
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  /// Valida os campos e tenta fazer login na API
  Future<void> _realizarLogin() async {
    // Verifica se todos os campos são válidos
    if (!_chaveFormulario.currentState!.validate()) return;

    setState(() => _carregando = true);

    // TODO: integrar com POST /auth/login/ da gerelat-api
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo de volta',
          style: TextStyle(
            color: Cores.pretoProfundo,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Acesse sua conta para gerenciar seus relatórios.',
          style: TextStyle(
            color: Cores.cinzaMedio,
            fontSize: 14,
          ),
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
      style: const TextStyle(
        color: Cores.cinzaEscuro,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
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
            child: const Text(
              'Esqueci a senha',
              style: TextStyle(
                color: Cores.azulPrimario,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
        const Text(
          'Manter conectado',
          style: TextStyle(
            color: Cores.cinzaEscuro,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Botão principal de login
  Widget _construirBotaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _carregando ? null : _realizarLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Cores.azulPrimario,
          foregroundColor: Cores.branco,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _carregando
            // Mostra indicador de carregamento enquanto processa o login
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Cores.branco, strokeWidth: 2),
              )
            : const Text(
                'Entrar na Plataforma',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
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
          style: TextStyle(color: Cores.cinzaMedio, fontSize: 13),
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
        const Text(
          'Não possui uma conta? ',
          style: TextStyle(color: Cores.cinzaMedio, fontSize: 14),
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
            child: const Text(
              'Cadastrar-se',
              style: TextStyle(
                color: Cores.azulPrimario,
                fontSize: 14,
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
    return const Center(
      child: Text(
        '© 2026 GeRelat Intelligence Solutions. Todos os direitos reservados.',
        style: TextStyle(
          color: Cores.cinzaMedio,
          fontSize: 12,
        ),
      ),
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
      hintStyle: const TextStyle(color: Cores.cinzaAzulado, fontSize: 14),
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
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

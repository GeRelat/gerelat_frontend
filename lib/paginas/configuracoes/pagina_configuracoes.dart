import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/alterar_senha_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/validadores.dart';

class PaginaConfiguracoes extends StatefulWidget {
  final RepositorioAutenticacao repositorioAutenticacao;
  final SessaoViewModel? sessaoViewModel;

  const PaginaConfiguracoes({
    super.key,
    required this.repositorioAutenticacao,
    this.sessaoViewModel,
  });

  @override
  State<PaginaConfiguracoes> createState() => _PaginaConfiguracoesState();
}

class _PaginaConfiguracoesState extends State<PaginaConfiguracoes> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmarSenha = TextEditingController();

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;

  late final AlterarSenhaViewModel _viewModel;

  Usuario? _usuario;
  bool _carregandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _viewModel = AlterarSenhaViewModel(widget.repositorioAutenticacao);
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final usuario = await widget.repositorioAutenticacao.obterUsuarioAtual();
    if (!mounted) return;
    setState(() {
      _usuario = usuario;
      _carregandoUsuario = false;
    });
  }

  @override
  void dispose() {
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmarSenha.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await _viewModel.alterarSenha(
      senhaAtual: _senhaAtual.text,
      novaSenha: _novaSenha.text,
    );
    if (!mounted) return;

    if (sucesso) {
      _senhaAtual.clear();
      _novaSenha.clear();
      _confirmarSenha.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao alterar a senha.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações do GeRelat',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 24),
          _construirCartaoConta(),
          const SizedBox(height: 24),
          _construirCartaoSenha(),
        ],
      ),
    );
  }

  Widget _construirCartaoConta() {
    final sessao = widget.sessaoViewModel;
    if (sessao != null) {
      return ListenableBuilder(
        listenable: sessao,
        builder: (context, _) => _construirConteudoCartaoConta(),
      );
    }
    return _construirConteudoCartaoConta();
  }

  Widget _construirConteudoCartaoConta() {
    final usuario = widget.sessaoViewModel?.usuarioAtual ?? _usuario;
    final clientes = usuario?.todosClientesDisponiveis ?? [];
    final clienteAtivoId = widget.sessaoViewModel?.clienteAtivoId;

    ItemContextoCliente? clienteAtivo;
    if (clienteAtivoId != null) {
      for (final c in clientes) {
        if (c.id == clienteAtivoId) {
          clienteAtivo = c;
          break;
        }
      }
    }
    clienteAtivo ??= clientes.isNotEmpty ? clientes.first : null;

    final logoUrl = clienteAtivo?.logomarca.trim() ?? '';
    final temLogo = logoUrl.isNotEmpty;
    final urlCompleta = logoUrl.startsWith('http')
        ? logoUrl
        : '${ClienteHttp.urlBasePadrao}$logoUrl';

    return CartaoConteudo(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Cores.azulAcao.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Cores.bordaSutil, width: 1.5),
            ),
            child: temLogo
                ? Image.network(
                    urlCompleta,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        LucideIcons.user,
                        color: Cores.azulAcao,
                        size: 26,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      LucideIcons.user,
                      color: Cores.azulAcao,
                      size: 26,
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _construirDadosConta()),
        ],
      ),
    );
  }

  Widget _construirDadosConta() {
    if (_carregandoUsuario) {
      return Text(
        'Carregando dados da conta...',
        style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
      );
    }

    final usuario = _usuario;
    if (usuario == null) {
      return Text(
        'Não foi possível carregar os dados da conta.',
        style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usuario.nomeCompleto.isEmpty ? 'Usuário' : usuario.nomeCompleto,
          style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 4),
        Text(
          usuario.email,
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        if (usuario.criadoEm != null) ...[
          const SizedBox(height: 4),
          Text(
            'Membro desde ${_formatarData(usuario.criadoEm!)}',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
        ],
      ],
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Widget _construirCartaoSenha() {
    // Só o botão "Salvar" depende de `_viewModel` (estado `carregando`) — o
    // cartão inteiro (ícone, textos, campos) é estático, então o
    // AnimatedBuilder fica restrito só a ele.
    return CartaoConteudo(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.lock_keyhole,
              color: Cores.azulAcao,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Alterar senha',
              style: Tipografia.titleLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informe a senha atual e defina uma nova senha com pelo menos 8 caracteres.',
              style: Tipografia.bodyMedium.copyWith(
                color: Cores.cinzaEscuro,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CampoFormulario(
              label: 'Senha atual',
              hint: '••••••••',
              icone: LucideIcons.lock,
              controller: _senhaAtual,
              obscureText: !_senhaAtualVisivel,
              sufixo: _construirAlternadorVisibilidade(
                visivel: _senhaAtualVisivel,
                aoAlternar: () =>
                    setState(() => _senhaAtualVisivel = !_senhaAtualVisivel),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 18),
            CampoFormulario(
              label: 'Nova senha',
              hint: '••••••••',
              icone: LucideIcons.lock_keyhole,
              controller: _novaSenha,
              obscureText: !_novaSenhaVisivel,
              sufixo: _construirAlternadorVisibilidade(
                visivel: _novaSenhaVisivel,
                aoAlternar: () =>
                    setState(() => _novaSenhaVisivel = !_novaSenhaVisivel),
              ),
              // Espelha AUTH_PASSWORD_VALIDATORS do backend (ver validarForcaSenha).
              validator: (valor) => validarForcaSenha(
                valor,
                atributosUsuario: [
                  _usuario?.nomeCompleto ?? '',
                  _usuario?.email ?? '',
                ],
              ),
            ),
            const SizedBox(height: 18),
            CampoFormulario(
              label: 'Confirmar nova senha',
              hint: '••••••••',
              icone: LucideIcons.shield_check,
              controller: _confirmarSenha,
              obscureText: !_novaSenhaVisivel,
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Confirme a nova senha';
                }
                if (valor != _novaSenha.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) => Align(
                alignment: Alignment.centerRight,
                child: BotaoPrimario(
                  texto: _viewModel.carregando
                      ? 'Salvando...'
                      : 'Salvar nova senha',
                  icone: LucideIcons.save,
                  onPressed: _viewModel.carregando ? null : _alterarSenha,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAlternadorVisibilidade({
    required bool visivel,
    required VoidCallback aoAlternar,
  }) {
    return IconButton(
      onPressed: aoAlternar,
      icon: Icon(
        visivel ? LucideIcons.eye : LucideIcons.eye_off,
        color: Cores.cinzaMedio,
        size: 18,
      ),
      tooltip: visivel ? 'Ocultar senha' : 'Mostrar senha',
      visualDensity: VisualDensity.compact,
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/alterar_senha_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/validadores.dart';
import 'package:go_router/go_router.dart';

class PaginaConfiguracoes extends StatefulWidget {
  final RepositorioAutenticacao repositorioAutenticacao;
  final RepositorioCatalogo? repositorioCatalogo;
  final SessaoViewModel? sessaoViewModel;
  final String urlBase;

  const PaginaConfiguracoes({
    super.key,
    required this.repositorioAutenticacao,
    this.repositorioCatalogo,
    this.sessaoViewModel,
    this.urlBase = '',
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

  Cliente? _clienteAtivo;
  bool _carregandoCliente = false;
  String? _erroCliente;
  int? _ultimoClienteId;

  @override
  void initState() {
    super.initState();
    _viewModel = AlterarSenhaViewModel(widget.repositorioAutenticacao);
    widget.sessaoViewModel?.addListener(_aoMudarSessao);
    _carregarUsuario();
    _carregarCliente();
  }

  void _aoMudarSessao() {
    final novoId = widget.sessaoViewModel?.clienteAtivoId;
    if (novoId != _ultimoClienteId) {
      _ultimoClienteId = novoId;
      _carregarCliente();
    }
  }

  Future<void> _carregarUsuario() async {
    final usuario = await widget.repositorioAutenticacao.obterUsuarioAtual();
    if (!mounted) return;
    setState(() {
      _usuario = usuario;
      _carregandoUsuario = false;
    });
  }

  Future<void> _carregarCliente() async {
    final clienteId = widget.sessaoViewModel?.clienteAtivoId;
    _ultimoClienteId = clienteId;
    if (clienteId == null || widget.repositorioCatalogo == null) {
      if (mounted) {
        setState(() {
          _clienteAtivo = null;
          _carregandoCliente = false;
          _erroCliente = null;
        });
      }
      return;
    }

    setState(() {
      _carregandoCliente = true;
      _erroCliente = null;
    });

    try {
      final cliente = await widget.repositorioCatalogo!.obterCliente(clienteId);
      if (!mounted) return;
      setState(() {
        _clienteAtivo = cliente;
        _carregandoCliente = false;
        _erroCliente = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clienteAtivo = null;
        _carregandoCliente = false;
        _erroCliente = 'Não foi possível carregar os dados da organização.';
      });
    }
  }

  @override
  void dispose() {
    widget.sessaoViewModel?.removeListener(_aoMudarSessao);
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
          _construirCartaoCliente(),
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
            child: const Center(
              child: Icon(
                LucideIcons.user,
                color: Cores.azulAcao,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _construirDadosConta(usuario)),
        ],
      ),
    );
  }

  Widget _construirDadosConta(Usuario? usuario) {
    if (_carregandoUsuario && usuario == null) {
      return Text(
        'Carregando dados da conta...',
        style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
      );
    }

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

  Widget _construirCartaoCliente() {
    final sessao = widget.sessaoViewModel;
    if (sessao != null) {
      return ListenableBuilder(
        listenable: sessao,
        builder: (context, _) => _construirConteudoCartaoCliente(),
      );
    }
    return _construirConteudoCartaoCliente();
  }

  Widget _construirConteudoCartaoCliente() {
    if (_carregandoCliente) {
      return CartaoConteudo(
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Carregando dados da organização...',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ],
        ),
      );
    }

    if (_erroCliente != null) {
      return CartaoConteudo(
        child: Row(
          children: [
            const Icon(LucideIcons.circle_alert, color: Cores.vermelhoErro, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _erroCliente!,
                style: Tipografia.bodyMedium.copyWith(color: Cores.vermelhoErro),
              ),
            ),
            TextButton(
              onPressed: _carregarCliente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final cliente = _clienteAtivo;
    if (cliente == null) {
      return CartaoConteudo(
        child: Row(
          children: [
            const IconeComFundo(
              icone: LucideIcons.building_2,
              cor: Cores.cinzaEscuro,
              tamanho: 48,
              raio: 12,
              tamanhoIcone: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organização',
                    style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nenhuma organização selecionada.',
                    style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/solicitar-acesso'),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Solicitar acesso'),
            ),
          ],
        ),
      );
    }

    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logomarcaCliente(cliente),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cliente.nome.isNotEmpty ? cliente.nome : 'Organização',
                            style: Tipografia.titleLarge.copyWith(
                              color: Cores.textoPrincipal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Cores.verdeSucesso.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Cores.verdeSucesso.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Cores.verdeSucesso,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Organização Ativa',
                                style: Tipografia.labelSmall.copyWith(
                                  color: Cores.verdeSucesso,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente.cnpj.isNotEmpty
                          ? 'CNPJ: ${cliente.cnpj}'
                          : 'CNPJ não informado',
                      style: Tipografia.bodySmall.copyWith(
                        color: Cores.cinzaMedio,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Cores.bordaSutil),
          const SizedBox(height: 20),
          _construirGradeInfoCliente(cliente),
        ],
      ),
    );
  }

  Widget _logomarcaCliente(Cliente cliente) {
    final url = cliente.logomarca.trim();
    if (url.isEmpty) {
      return const IconeComFundo(
        cor: Cores.azulAcao,
        tamanho: 56,
        raio: 12,
        icone: LucideIcons.building_2,
        tamanhoIcone: 28,
      );
    }

    final urlCompleta = url.startsWith('http')
        ? url
        : (widget.urlBase.isNotEmpty
            ? '${widget.urlBase}$url'
            : '${ClienteHttp.urlBasePadrao}$url');

    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Cores.cinzaClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.bordaSutil),
      ),
      child: Image.network(
        urlCompleta,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const IconeComFundo(
          cor: Cores.azulAcao,
          tamanho: 56,
          raio: 12,
          icone: LucideIcons.building_2,
          tamanhoIcone: 28,
        ),
      ),
    );
  }

  Widget _construirGradeInfoCliente(Cliente cliente) {
    final usuario = widget.sessaoViewModel?.usuarioAtual ?? _usuario;
    final eAdmin = usuario?.eAdminDoCliente(cliente.id) ?? false;

    final itens = [
      (
        icone: LucideIcons.user,
        rotulo: 'Responsável / Contato',
        valor: cliente.nomeContato.isNotEmpty ? cliente.nomeContato : 'Não informado',
      ),
      (
        icone: LucideIcons.mail,
        rotulo: 'E-mail de Contato',
        valor: cliente.emailContato.isNotEmpty ? cliente.emailContato : 'Não informado',
      ),
      (
        icone: LucideIcons.phone,
        rotulo: 'Telefone de Contato',
        valor: cliente.foneContato.isNotEmpty ? cliente.foneContato : 'Não informado',
      ),
      if (eAdmin) ...[
        (
          icone: LucideIcons.signature,
          rotulo: 'Número do Contrato',
          valor: cliente.numeroContrato.isNotEmpty
              ? cliente.numeroContrato
              : 'Não informado',
        ),
        (
          icone: LucideIcons.calendar,
          rotulo: 'Vigência do Contrato',
          valor: cliente.dataTerminoContrato != null
              ? _formatarData(cliente.dataTerminoContrato!)
              : 'Não informada',
        ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final colunas = largura > 700 ? 3 : (largura > 450 ? 2 : 1);
        final itemWidth = (largura - (colunas - 1) * 16) / colunas;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: itens.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _itemInformacao(
                icone: item.icone,
                rotulo: item.rotulo,
                valor: item.valor,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _itemInformacao({
    required IconData icone,
    required String rotulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: Cores.azulAcao),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: Tipografia.bodySmall.copyWith(
                  color: Cores.cinzaEscuro,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: Tipografia.bodyMedium.copyWith(
                  color: Cores.textoPrincipal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Widget _construirCartaoSenha() {
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

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/clientes_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaClientes extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaClientes({super.key, required this.repositorioCatalogo});

  @override
  State<PaginaClientes> createState() => _PaginaClientesState();
}

class _PaginaClientesState extends State<PaginaClientes> {
  late final ClientesViewModel _viewModel;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ClientesViewModel(widget.repositorioCatalogo)..carregar();
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Só `_conteudo()` depende de `_viewModel` — cabeçalho e busca são
    // passados como `child` para não serem reconstruídos a cada notificação.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [child!, const SizedBox(height: 24), _conteudo()],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalho(context),
          const SizedBox(height: 20),
          CampoBusca(
            controlador: _controladorBusca,
            dica: 'Pesquisar clientes...',
            aoAlterar: _viewModel.definirBusca,
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clientes',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cadastre os clientes contratantes e vincule-os aos programas institucionais.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ],
          ),
        ),
        BotaoPrimario(
          texto: 'Novo Cliente',
          icone: LucideIcons.plus,
          onPressed: () async {
            final criado = await context.push<bool>('/clientes/novo');
            if (criado == true) await _viewModel.carregar();
          },
        ),
      ],
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null && _viewModel.clientes.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possivel carregar os clientes',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.clientes.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.search_x,
        titulo: 'Nenhum cliente encontrado',
        descricao:
            'A lista atual não contém clientes compatíveis com a busca informada.',
        acao: 'Limpar busca',
        onAcao: () {
          _controladorBusca.clear();
          _viewModel.definirBusca('');
        },
      );
    }

    return _gradeClientes(_viewModel.clientes);
  }

  Widget _gradeClientes(List<Cliente> clientes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duasColunas = constraints.maxWidth >= 900;
        final largura = duasColunas
            ? (constraints.maxWidth - 24) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: clientes
              .map(
                (cliente) => SizedBox(
                  width: largura,
                  child: _CartaoCliente(
                    cliente,
                    onAlterado: _viewModel.carregar,
                    onExcluir: _viewModel.excluir,
                    obterMensagemErro: () => _viewModel.mensagemErroAcao,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CartaoCliente extends StatelessWidget {
  final Cliente cliente;
  final Future<void> Function() onAlterado;
  final Future<bool> Function(int) onExcluir;
  final String? Function() obterMensagemErro;

  const _CartaoCliente(
    this.cliente, {
    required this.onAlterado,
    required this.onExcluir,
    required this.obterMensagemErro,
  });

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconeComFundo(
                cor: Cores.azulAcao,
                tamanho: 48,
                raio: 12,
                icone: LucideIcons.building_2,
                tamanhoIcone: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nome,
                      style: Tipografia.titleLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente.cnpj.isEmpty
                          ? 'CNPJ não informado'
                          : cliente.cnpj,
                      style: Tipografia.bodySmall.copyWith(
                        color: Cores.cinzaMedio,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _linhaInfo(LucideIcons.user, cliente.nomeContato),
          const SizedBox(height: 6),
          _linhaInfo(LucideIcons.mail, cliente.emailContato),
          const SizedBox(height: 6),
          _linhaInfo(LucideIcons.phone, cliente.foneContato),
          const SizedBox(height: 6),
          _linhaInfo(
            LucideIcons.signature,
            cliente.numeroContrato.isEmpty
                ? 'Contrato não informado'
                : 'Contrato ${cliente.numeroContrato}',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Editar cliente',
                onPressed: () async {
                  final alterado = await context.push<bool>(
                    '/clientes/${cliente.id}/editar',
                  );
                  if (alterado == true) await onAlterado();
                },
                icon: const Icon(LucideIcons.pencil, size: 18),
              ),
              IconButton(
                tooltip: 'Excluir cliente',
                onPressed: () => _confirmarExclusao(context),
                icon: const Icon(
                  LucideIcons.trash_2,
                  size: 18,
                  color: Cores.vermelhoErro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icone, String texto) {
    if (texto.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icone, size: 15, color: Cores.cinzaMedio),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir cliente',
      mensagem:
          'Tem certeza de que deseja excluir "${cliente.nome}"? Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !context.mounted) return;

    final clienteId = cliente.id;
    if (clienteId == null) return;

    final sucesso = await onExcluir(clienteId);
    if (!context.mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(obterMensagemErro() ?? 'Erro ao excluir cliente.'),
      ),
    );
  }
}

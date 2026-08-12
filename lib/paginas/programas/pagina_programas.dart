import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programas_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/sombras.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaProgramas extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaProgramas({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaProgramas> createState() => _PaginaProgramasState();
}

class _PaginaProgramasState extends State<PaginaProgramas> {
  late final ProgramasViewModel _viewModel;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ProgramasViewModel(widget.repositorioCatalogo);
    _viewModel.definirClienteAtivoId(widget.sessaoViewModel.clienteAtivoId);
    widget.sessaoViewModel.addListener(_aoMudarSessao);
  }

  void _aoMudarSessao() {
    _viewModel.definirClienteAtivoId(widget.sessaoViewModel.clienteAtivoId);
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _controladorBusca.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(context),
              const SizedBox(height: 20),
              CampoBusca(
                controlador: _controladorBusca,
                dica: 'Pesquisar programas...',
                aoAlterar: _viewModel.definirBusca,
              ),
              const SizedBox(height: 24),
              _resumo(),
              const SizedBox(height: 32),
              _conteudo(),
            ],
          ),
        );
      },
    );
  }

  Widget _cabecalho(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final modoCompacto = constraints.maxWidth < 960;

        final usuario = widget.sessaoViewModel.usuarioAtual;
        final clienteAtivoId = widget.sessaoViewModel.clienteAtivoId;
        final eAdminCliente = usuario?.eAdminDoCliente(clienteAtivoId) ?? false;
        final eMembroPrograma = usuario?.contextosAcesso.programas.any((p) {
          if (clienteAtivoId == null) return true;
          final cId = int.tryParse('${p['cliente_id']}');
          return cId == clienteAtivoId;
        }) ?? false;

        final podeCriarPrograma = eAdminCliente;
        final podeCriarProjeto = eAdminCliente || eMembroPrograma;

        final informacoes = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Programas institucionais',
              style: Tipografia.headlineMedium.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Organize programas, projetos relacionados e equipes responsáveis.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ],
        );

        final acoes = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            BotaoPrimario(
              texto: 'Variáveis',
              icone: LucideIcons.variable,
              onPressed: () => context.push('/variaveis/definicoes'),
            ),
            BotaoPrimario(
              texto: 'Equipe da Parceira',
              icone: LucideIcons.users,
              onPressed: () => context.push('/projetos/equipe'),
            ),
            if (podeCriarProjeto)
              BotaoPrimario(
                texto: 'Novo Projeto',
                icone: LucideIcons.git_branch_plus,
                onPressed: () async {
                  final criado = await context.push<bool>(
                    '/programas/projetos/novo',
                  );
                  if (criado == true) await _viewModel.carregar();
                },
              ),
            if (podeCriarPrograma)
              BotaoPrimario(
                texto: 'Novo Programa',
                icone: LucideIcons.plus,
                onPressed: () async {
                  final criado = await context.push<bool>('/programas/novo');
                  if (criado == true) await _viewModel.carregar();
                },
              ),
          ],
        );

        if (modoCompacto) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              informacoes,
              const SizedBox(height: 16),
              acoes,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: informacoes),
            const SizedBox(width: 16),
            acoes,
          ],
        );
      },
    );
  }

  Widget _resumo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth < 820 ? 1 : 3;
        const espaco = 24.0;
        final largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            SizedBox(
              width: largura,
              child: CartaoInfo(
                titulo: 'Programas',
                valor: '${_viewModel.totalProgramas}',
                descricao: 'Ativos ou em planejamento',
                icone: LucideIcons.folder_kanban,
              ),
            ),
            SizedBox(
              width: largura,
              child: CartaoInfo(
                titulo: 'Projetos',
                valor: '${_viewModel.totalProjetos}',
                descricao: 'Vinculados aos programas',
                icone: LucideIcons.git_branch,
              ),
            ),
            SizedBox(
              width: largura,
              child: CartaoInfo(
                titulo: 'Eventos',
                valor: '${_viewModel.totalEventos}',
                descricao: 'Mapeados no ciclo atual',
                icone: LucideIcons.calendar,
                cor: Cores.verdeSucesso,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Nao foi possivel carregar os programas',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.programas.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.search_x,
        titulo: 'Nenhum programa encontrado',
        descricao:
            'A lista atual não contém programas compatíveis com a busca informada.',
        acao: 'Limpar busca',
        onAcao: () {
          _controladorBusca.clear();
          _viewModel.definirBusca('');
        },
      );
    }

    return _gradeProgramas(_viewModel.programas);
  }

  Widget _gradeProgramas(List<Programa> programas) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duasColunas = constraints.maxWidth >= 900;
        final largura = duasColunas
            ? (constraints.maxWidth - 24) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: programas
              .map(
                (programa) => SizedBox(
                  width: largura,
                  child: _CartaoPrograma(
                    programa,
                    sessaoViewModel: widget.sessaoViewModel,
                    onEditado: _viewModel.carregar,
                    onExcluir: _viewModel.excluir,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CartaoPrograma extends StatefulWidget {
  final Programa programa;
  final SessaoViewModel sessaoViewModel;
  final Future<void> Function() onEditado;
  final Future<bool> Function(int) onExcluir;

  const _CartaoPrograma(
    this.programa, {
    required this.sessaoViewModel,
    required this.onEditado,
    required this.onExcluir,
  });

  @override
  State<_CartaoPrograma> createState() => _CartaoProgramaState();
}

class _CartaoProgramaState extends State<_CartaoPrograma> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final usuario = widget.sessaoViewModel.usuarioAtual;
    final clienteAtivoId = widget.sessaoViewModel.clienteAtivoId;
    final eAdminCliente = usuario?.eAdminDoCliente(clienteAtivoId) ?? false;
    final eMembroDoPrograma =
        usuario?.contextosAcesso.programas.any(
          (p) => int.tryParse('${p['id']}') == widget.programa.id,
        ) ??
        false;

    final podeEditar = eAdminCliente || eMembroDoPrograma;
    final podeExcluir = eAdminCliente;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _exibirDetalhesPrograma(context, podeEditar, podeExcluir),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Cores.branco,
            border: Border.all(
              color: _hovered ? Cores.azulAcao : Cores.bordaSutil,
              width: _hovered ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered ? Sombras.cartaoEstatistica : null,
          ),
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
                    icone: LucideIcons.folder_kanban,
                    tamanhoIcone: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.programa.nome,
                          style: Tipografia.titleLarge.copyWith(
                            color: Cores.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.programa.descricao,
                          style: Tipografia.bodyMedium.copyWith(
                            color: Cores.cinzaEscuro,
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.programa.clienteNome.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.building_2,
                                size: 14,
                                color: Cores.cinzaMedio,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.programa.clienteNome,
                                style: Tipografia.bodySmall.copyWith(
                                  color: Cores.cinzaMedio,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _metrica('${widget.programa.projetos}', 'Projetos'),
                  const SizedBox(width: 24),
                  _metrica('${widget.programa.eventos}', 'Eventos'),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Projetos do programa',
                    onPressed: () async {
                      await context.push(
                        '/programas/${widget.programa.id}/projetos',
                      );
                      await widget.onEditado();
                    },
                    icon: const Icon(LucideIcons.git_branch, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Equipe fixa do programa',
                    onPressed: () => context.push(
                      '/programas/${widget.programa.id}/equipe',
                    ),
                    icon: const Icon(LucideIcons.users, size: 18),
                  ),
                  if (podeEditar)
                    IconButton(
                      tooltip: 'Editar programa',
                      onPressed: () async {
                        final alterado = await context.push<bool>(
                          '/programas/${widget.programa.id}/editar',
                        );
                        if (alterado == true) {
                          await widget.onEditado();
                        }
                      },
                      icon: const Icon(LucideIcons.pencil, size: 18),
                    ),
                  if (podeExcluir)
                    IconButton(
                      tooltip: 'Excluir programa',
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
        ),
      ),
    );
  }

  void _exibirDetalhesPrograma(
    BuildContext context,
    bool podeEditar,
    bool podeExcluir,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Cores.branco,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconeComFundo(
                      cor: Cores.azulAcao,
                      tamanho: 48,
                      raio: 12,
                      icone: LucideIcons.folder_kanban,
                      tamanhoIcone: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.programa.nome,
                            style: Tipografia.headlineMedium.copyWith(
                              color: Cores.textoPrincipal,
                              fontSize: 20,
                            ),
                          ),
                          if (widget.programa.clienteNome.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.building_2,
                                  size: 14,
                                  color: Cores.cinzaMedio,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.programa.clienteNome,
                                  style: Tipografia.bodySmall.copyWith(
                                    color: Cores.cinzaMedio,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Cores.bordaSutil),
                const SizedBox(height: 20),
                Text(
                  'Descrição',
                  style: Tipografia.labelLarge.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.programa.descricao.isEmpty
                      ? 'Nenhuma descrição informada.'
                      : widget.programa.descricao,
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.textoPrincipal,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Cores.fundoSecao,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Cores.bordaSutil),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.programa.projetos}',
                              style: Tipografia.headlineMedium.copyWith(
                                color: Cores.textoPrincipal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Projetos vinculados',
                              style: Tipografia.bodySmall.copyWith(
                                color: Cores.cinzaMedio,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Cores.bordaSutil,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.programa.eventos}',
                              style: Tipografia.headlineMedium.copyWith(
                                color: Cores.textoPrincipal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Eventos mapeados',
                              style: Tipografia.bodySmall.copyWith(
                                color: Cores.cinzaMedio,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final modoCompacto = constraints.maxWidth < 480;

                    return Row(
                      children: [
                        if (podeExcluir)
                          modoCompacto
                              ? IconButton(
                                  tooltip: 'Excluir programa',
                                  style: IconButton.styleFrom(
                                    foregroundColor: Cores.vermelhoErro,
                                    side: const BorderSide(
                                      color: Cores.vermelhoErro,
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _confirmarExclusao(context);
                                  },
                                  icon: const Icon(
                                    LucideIcons.trash_2,
                                    size: 18,
                                  ),
                                )
                              : OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Cores.vermelhoErro,
                                    side: const BorderSide(
                                      color: Cores.vermelhoErro,
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _confirmarExclusao(context);
                                  },
                                  icon: const Icon(
                                    LucideIcons.trash_2,
                                    size: 16,
                                  ),
                                  label: const Text('Excluir'),
                                ),
                        const Spacer(),
                        modoCompacto
                            ? IconButton(
                                tooltip: 'Projetos do programa',
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await context.push(
                                    '/programas/${widget.programa.id}/projetos',
                                  );
                                  await widget.onEditado();
                                },
                                icon: const Icon(
                                  LucideIcons.git_branch,
                                  size: 18,
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await context.push(
                                    '/programas/${widget.programa.id}/projetos',
                                  );
                                  await widget.onEditado();
                                },
                                icon: const Icon(
                                  LucideIcons.git_branch,
                                  size: 16,
                                ),
                                label: const Text('Projetos'),
                              ),
                        const SizedBox(width: 8),
                        modoCompacto
                            ? IconButton(
                                tooltip: 'Equipe do programa',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.push(
                                    '/programas/${widget.programa.id}/equipe',
                                  );
                                },
                                icon: const Icon(
                                  LucideIcons.users,
                                  size: 18,
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.push(
                                    '/programas/${widget.programa.id}/equipe',
                                  );
                                },
                                icon: const Icon(
                                  LucideIcons.users,
                                  size: 16,
                                ),
                                label: const Text('Equipe'),
                              ),
                        if (podeEditar) ...[
                          const SizedBox(width: 8),
                          modoCompacto
                              ? IconButton(
                                  tooltip: 'Editar programa',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Cores.azulAcao,
                                    foregroundColor: Cores.branco,
                                  ),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    final alterado = await context.push<bool>(
                                      '/programas/${widget.programa.id}/editar',
                                    );
                                    if (alterado == true) {
                                      await widget.onEditado();
                                    }
                                  },
                                  icon: const Icon(
                                    LucideIcons.pencil,
                                    size: 18,
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    final alterado = await context.push<bool>(
                                      '/programas/${widget.programa.id}/editar',
                                    );
                                    if (alterado == true) {
                                      await widget.onEditado();
                                    }
                                  },
                                  icon: const Icon(
                                    LucideIcons.pencil,
                                    size: 16,
                                  ),
                                  label: const Text('Editar'),
                                ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir programa',
      mensagem:
          'Tem certeza de que deseja excluir "${widget.programa.nome}"? '
          'Todos os projetos, eventos, templates e relatórios vinculados a '
          'este programa também serão excluídos. Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !context.mounted) return;

    final programaId = widget.programa.id;
    if (programaId == null) return;

    final sucesso = await widget.onExcluir(programaId);
    if (!context.mounted || sucesso) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao excluir o programa.')),
    );
  }

  Widget _metrica(String valor, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal),
        ),
        Text(
          label,
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
      ],
    );
  }
}

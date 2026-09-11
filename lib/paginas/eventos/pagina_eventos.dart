import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/eventos_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaEventos extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaEventos({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaEventos> createState() => _PaginaEventosState();
}

class _PaginaEventosState extends State<PaginaEventos> {
  late final EventosViewModel _viewModel;

  final TextEditingController _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = EventosViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    widget.sessaoViewModel.addListener(_aoMudarSessao);
  }

  void _aoMudarSessao() {
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
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
    // Cabeçalho e busca não leem `_viewModel` — só `_filtros` (chips ativos)
    // e `_conteudo` dependem dele, então são os únicos dentro do escopo do
    // AnimatedBuilder. O restante é passado como `child` e só é reconstruído
    // quando os constraints do LayoutBuilder mudam, não a cada notificação.
    return LayoutBuilder(
      builder: (context, constraints) {
        final telaPequena = constraints.maxWidth < 700;

        return AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(telaPequena ? 20 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child!,
                  const SizedBox(height: 24),
                  _filtros(telaPequena: telaPequena),
                  const SizedBox(height: 24),
                  _conteudo(context),
                ],
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(context, telaPequena: telaPequena),
              const SizedBox(height: 20),
              _campoBusca(telaPequena: telaPequena),
            ],
          ),
        );
      },
    );
  }

  /// Cabeçalho da página com título e botões.
  Widget _cabecalho(BuildContext context, {required bool telaPequena}) {
    final botoes = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: telaPequena ? WrapAlignment.start : WrapAlignment.end,
      children: [
        BotaoPrimario(
          texto: 'Classes de Evento',
          icone: LucideIcons.tags,
          onPressed: () {
            context.push('/eventos/classes-evento');
          },
        ),
        BotaoPrimario(
          texto: 'Novo Evento',
          icone: LucideIcons.plus,
          onPressed: () async {
            final criado = await context.push<bool>('/eventos/novo');

            if (criado == true) {
              await _viewModel.carregar();
            }
          },
        ),
      ],
    );

    if (telaPequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eventos cadastrados',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          botoes,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Eventos cadastrados',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
        ),
        const SizedBox(width: 24),
        botoes,
      ],
    );
  }

  /// Campo de pesquisa com largura controlada.
  Widget _campoBusca({required bool telaPequena}) {
    return SizedBox(
      width: telaPequena ? double.infinity : 400,
      child: CampoBusca(
        controlador: _controladorBusca,
        dica: 'Pesquisar eventos...',
        aoAlterar: _viewModel.definirBusca,
      ),
    );
  }

  /// Área de filtros.
  Widget _filtros({required bool telaPequena}) {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sliders_horizontal, color: Cores.azulAcao),
              const SizedBox(width: 12),
              Text(
                'Filtros',
                style: Tipografia.titleMedium.copyWith(
                  color: Cores.textoPrincipal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Filtro por Programa
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: CampoSelecao(
                  label: 'Programa',
                  valor: _viewModel.filtroProgramaId ?? 0,
                  itens: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('Todos os programas'),
                    ),
                    ..._viewModel.opcoesProgramas.map(
                      (p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.nome),
                      ),
                    ),
                  ],
                  onChanged: (value) => _viewModel
                      .definirFiltroProgramaId(value == 0 ? null : value),
                ),
              ),
              // Filtro por Projeto
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: CampoSelecao(
                  label: 'Projeto',
                  valor: _viewModel.filtroProjetoId ?? 0,
                  itens: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('Todos os projetos'),
                    ),
                    ..._viewModel.opcoesProjetos.map(
                      (proj) => DropdownMenuItem<int>(
                        value: proj.id,
                        child: Text(proj.nome),
                      ),
                    ),
                  ],
                  onChanged: (value) => _viewModel
                      .definirFiltroProjetoId(value == 0 ? null : value),
                ),
              ),
              // Filtro por Classe de Evento
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: CampoSelecao(
                  label: 'Classe de Evento',
                  valor: _viewModel.filtroClasseId ?? 0,
                  itens: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('Todas as classes'),
                    ),
                    ..._viewModel.classes.map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.nomeClasse),
                      ),
                    ),
                  ],
                  onChanged: (value) => _viewModel
                      .definirFiltroClasseId(value == 0 ? null : value),
                ),
              ),
              // Filtro por Período
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Período:',
                    style: Tipografia.bodyMedium.copyWith(
                      color: Cores.cinzaEscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _chip(
                    'Todos',
                    ativo: _viewModel.filtroPeriodo == 'Todos',
                    onTap: () => _viewModel.definirFiltroPeriodo('Todos'),
                  ),
                  _chip(
                    'Este mês',
                    ativo: _viewModel.filtroPeriodo == 'Este mês',
                    onTap: () => _viewModel.definirFiltroPeriodo('Este mês'),
                  ),
                  _chip(
                    'Este ano',
                    ativo: _viewModel.filtroPeriodo == 'Este ano',
                    onTap: () => _viewModel.definirFiltroPeriodo('Este ano'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Define qual conteúdo será exibido.
  Widget _conteudo(BuildContext context) {
    if (_viewModel.carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_viewModel.mensagemErro != null) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possível carregar os eventos',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.eventos.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.search_x,
        titulo: 'Nenhum evento encontrado',
        descricao: 'Nenhum evento corresponde aos filtros e à busca atual.',
        acao: 'Limpar filtros',
        onAcao: () {
          _controladorBusca.clear();

          _viewModel.definirBusca('');
          _viewModel.definirFiltroPeriodo('Todos');
        },
      );
    }

    return _listaEventos(context, _viewModel.eventos);
  }

  /// Tabela de eventos.
  ///
  /// Quando a tela não comporta a largura mínima da tabela,
  /// é habilitada a rolagem horizontal.
  Widget _listaEventos(BuildContext context, List<Evento> eventos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const larguraMinimaTabela = 600.0;

        final larguraTabela = math.max(
          constraints.maxWidth,
          larguraMinimaTabela,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: larguraTabela,
              child: CartaoConteudo(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _cabecalhoTabela(),
                    for (final evento in eventos) _linha(context, evento),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const _colunas = [
    ColunaTabelaCrud(rotulo: 'Evento', flex: 3, gutterDireita: 12),
    ColunaTabelaCrud(rotulo: 'Programa', flex: 2, gutterDireita: 12),
    ColunaTabelaCrud(rotulo: 'Data', largura: 110),
    ColunaTabelaCrud(
      rotulo: 'Ações',
      largura: 120,
      alinhamento: TextAlign.center,
    ),
  ];

  /// Cabeçalho da tabela.
  Widget _cabecalhoTabela() {
    return const CabecalhoTabelaCrud(colunas: _colunas, altura: 52);
  }

  /// Linha de um evento.
  Widget _linha(BuildContext context, Evento evento) {
    final podeEditarExcluir = _viewModel.temAcessoAoProjeto(evento.projetoId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Cores.azulAcao.withValues(alpha: 0.05),
        onTap: () => _exibirDetalhesEvento(context, evento),
        child: LinhaTabelaCrud(
          colunas: _colunas,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          celulas: [
            Text(
              evento.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
            ),
            Text(
              evento.programa,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
            Text(
              _formatarData(evento.data),
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Ver detalhes',
                  constraints: _restricoesBotaoAcao,
                  padding: _paddingBotaoAcao,
                  onPressed: () => _exibirDetalhesEvento(context, evento),
                  icon: const Icon(
                    LucideIcons.eye,
                    size: 18,
                    color: Cores.azulAcao,
                  ),
                ),
                if (podeEditarExcluir)
                  IconButton(
                    tooltip: 'Editar evento',
                    constraints: _restricoesBotaoAcao,
                    padding: _paddingBotaoAcao,
                    onPressed: () async {
                      final alterado = await context.push<bool>(
                        '/eventos/${evento.id}/editar',
                      );

                      if (alterado == true) {
                        await _viewModel.carregar();
                      }
                    },
                    icon: const Icon(
                      LucideIcons.pencil,
                      size: 18,
                      color: Cores.cinzaEscuro,
                    ),
                  ),
                if (podeEditarExcluir)
                  IconButton(
                    tooltip: 'Excluir evento',
                    constraints: _restricoesBotaoAcao,
                    padding: _paddingBotaoAcao,
                    onPressed: () {
                      _confirmarExclusao(context, evento);
                    },
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
    );
  }

  void _exibirDetalhesEvento(BuildContext context, Evento evento) {
    final podeEditarExcluir = _viewModel.temAcessoAoProjeto(evento.projetoId);

    final escopoTexto =
        evento.programa.isNotEmpty ? evento.programa : 'Projeto';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 540,
            color: Cores.branco,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecalho com fundo sutil e icone destacado
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Cores.azulAcao.withValues(alpha: 0.05),
                    border: const Border(
                      bottom: BorderSide(color: Cores.cinzaClaro, width: 1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Cores.azulAcao.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.calendar,
                          color: Cores.azulAcao,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evento.nome,
                              style: Tipografia.headlineSmall.copyWith(
                                color: Cores.textoPrincipal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (evento.classeEventoNome.isNotEmpty)
                                  _badgeTag(
                                    rotulo: evento.classeEventoNome,
                                    icone: LucideIcons.tag,
                                    corFundo: Cores.azulAcao.withValues(alpha: 0.1),
                                    corTexto: Cores.azulAcao,
                                  ),
                                _badgeTag(
                                  rotulo: escopoTexto,
                                  icone: LucideIcons.layers,
                                  corFundo: Cores.cinzaClaro,
                                  corTexto: Cores.cinzaEscuro,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          LucideIcons.x,
                          color: Cores.cinzaMedio,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // Area de conteudo com informacoes em grid
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _blocoInfoGrid(
                                icone: LucideIcons.calendar_days,
                                rotulo: 'Data do Evento',
                                valor: _formatarData(evento.data),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _blocoInfoGrid(
                                icone: LucideIcons.tag,
                                rotulo: 'Classe de Evento',
                                valor: evento.classeEventoNome.isEmpty
                                    ? '-'
                                    : evento.classeEventoNome,
                              ),
                            ),
                          ],
                        ),
                        if (evento.local.isNotEmpty || evento.endereco.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (evento.local.isNotEmpty)
                                Expanded(
                                  child: _blocoInfoGrid(
                                    icone: LucideIcons.map_pin,
                                    rotulo: 'Local',
                                    valor: evento.local,
                                  ),
                                ),
                              if (evento.local.isNotEmpty && evento.endereco.isNotEmpty)
                                const SizedBox(width: 16),
                              if (evento.endereco.isNotEmpty)
                                Expanded(
                                  child: _blocoInfoGrid(
                                    icone: LucideIcons.map,
                                    rotulo: 'Endereço',
                                    valor: evento.endereco,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (evento.objetivo.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Cores.cinzaClaro.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Cores.cinzaClaro),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.target,
                                      size: 16,
                                      color: Cores.azulAcao,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Objetivo do Evento',
                                      style: Tipografia.labelMedium.copyWith(
                                        color: Cores.textoPrincipal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  evento.objetivo,
                                  style: Tipografia.bodyMedium.copyWith(
                                    color: Cores.textoPrincipal,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Rodape de acoes
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Cores.branco,
                    border: Border(
                      top: BorderSide(color: Cores.cinzaClaro, width: 1),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final modoCompacto = constraints.maxWidth < 440;

                      return Row(
                        children: [
                          if (podeEditarExcluir)
                            modoCompacto
                                ? IconButton(
                                    tooltip: 'Excluir Evento',
                                    style: IconButton.styleFrom(
                                      foregroundColor: Cores.vermelhoErro,
                                      side: const BorderSide(
                                        color: Cores.vermelhoErro,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _confirmarExclusao(context, evento);
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
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _confirmarExclusao(context, evento);
                                    },
                                    icon: const Icon(
                                      LucideIcons.trash_2,
                                      size: 16,
                                    ),
                                    label: const Text('Excluir'),
                                  ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Fechar',
                              style: Tipografia.labelLarge.copyWith(
                                color: Cores.cinzaEscuro,
                              ),
                            ),
                          ),
                          if (podeEditarExcluir) ...[
                            const SizedBox(width: 8),
                            modoCompacto
                                ? IconButton(
                                    tooltip: 'Editar Evento',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Cores.azulAcao,
                                      foregroundColor: Cores.branco,
                                    ),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      context.push(
                                        '/eventos/${evento.id}/editar',
                                      );
                                    },
                                    icon: const Icon(
                                      LucideIcons.pencil,
                                      size: 18,
                                    ),
                                  )
                                : BotaoPrimario(
                                    texto: 'Editar',
                                    icone: LucideIcons.pencil,
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      context.push(
                                        '/eventos/${evento.id}/editar',
                                      );
                                    },
                                  ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badgeTag({
    required String rotulo,
    required IconData icone,
    required Color corFundo,
    required Color corTexto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: corTexto),
          const SizedBox(width: 5),
          Text(
            rotulo,
            style: Tipografia.bodySmall.copyWith(
              color: corTexto,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoInfoGrid({
    required IconData icone,
    required String rotulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Cores.cinzaClaro,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icone, size: 16, color: Cores.cinzaEscuro),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: Tipografia.bodySmall.copyWith(
                  color: Cores.cinzaMedio,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: Tipografia.bodyMedium.copyWith(
                  color: Cores.textoPrincipal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Área de toque uniforme dos botões de ação da tabela (editar/excluir).
  static const _restricoesBotaoAcao = BoxConstraints(
    minWidth: 36,
    minHeight: 36,
  );
  static const _paddingBotaoAcao = EdgeInsets.all(8);

  /// Confirmação de exclusão do evento.
  Future<void> _confirmarExclusao(BuildContext context, Evento evento) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir evento',
      mensagem:
          'Tem certeza de que deseja excluir "${evento.nome}"? '
          'Relatórios já gerados para este evento permanecerão, '
          'mas perderão o vínculo com ele. '
          'Esta ação não pode ser desfeita.',
    );

    if (!confirmou || !context.mounted) {
      return;
    }

    final eventoId = evento.id;

    if (eventoId == null) {
      return;
    }

    final sucesso = await _viewModel.excluir(eventoId);

    if (!context.mounted || sucesso) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _viewModel.mensagemErro ?? 'Não foi possível excluir o evento.',
        ),
        backgroundColor: Cores.vermelhoErro,
      ),
    );
  }

  /// Filtro em formato de chip.
  Widget _chip(
    String texto, {
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ativo
              ? Cores.azulAcao.withValues(alpha: 0.16)
              : Cores.azulAcao.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          texto,
          style: Tipografia.labelMedium.copyWith(color: Cores.azulAcao),
        ),
      ),
    );
  }

  /// Formata a data no padrão brasileiro.
  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Data não informada';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }
}

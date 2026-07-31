import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/eventos_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaEventos extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaEventos({super.key, required this.repositorioCatalogo});

  @override
  State<PaginaEventos> createState() => _PaginaEventosState();
}

class _PaginaEventosState extends State<PaginaEventos> {
  late final EventosViewModel _viewModel;

  final TextEditingController _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();

    _viewModel = EventosViewModel(widget.repositorioCatalogo)..carregar();
  }

  @override
  void dispose() {
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
    final descricao = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.sliders_horizontal, color: Cores.azulAcao),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'Filtre por programa, classe de evento, data ou status.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ),
      ],
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          'Todos',
          ativo:
              _viewModel.filtroPeriodo == 'Todos' &&
              _viewModel.filtroStatus == 'Todos',
          onTap: () {
            _viewModel.definirFiltroPeriodo('Todos');
            _viewModel.definirFiltroStatus('Todos');
          },
        ),
        _chip(
          'Este mês',
          ativo: _viewModel.filtroPeriodo == 'Este mês',
          onTap: () {
            _viewModel.definirFiltroPeriodo('Este mês');
          },
        ),
        _chip(
          'Confirmados',
          ativo: _viewModel.filtroStatus == 'Confirmados',
          onTap: () {
            final novoStatus = _viewModel.filtroStatus == 'Confirmados'
                ? 'Todos'
                : 'Confirmados';

            _viewModel.definirFiltroStatus(novoStatus);
          },
        ),
      ],
    );

    return CartaoConteudo(
      child: telaPequena
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [descricao, const SizedBox(height: 16), chips],
            )
          : Row(
              children: [
                Expanded(child: descricao),
                const SizedBox(width: 24),
                chips,
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
          _viewModel.definirFiltroStatus('Todos');
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
        const larguraMinimaTabela = 1000.0;

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
    ColunaTabelaCrud(rotulo: 'Evento', flex: 3, gutterDireita: 20),
    ColunaTabelaCrud(rotulo: 'Programa', flex: 2, gutterDireita: 20),
    ColunaTabelaCrud(rotulo: 'Data', largura: 150),
    ColunaTabelaCrud(rotulo: 'Status', largura: 135),
    ColunaTabelaCrud(
      rotulo: 'Ações',
      largura: 96,
      alinhamento: TextAlign.center,
    ),
  ];

  /// Cabeçalho da tabela.
  Widget _cabecalhoTabela() {
    return const CabecalhoTabelaCrud(colunas: _colunas, altura: 52);
  }

  /// Linha de um evento.
  Widget _linha(BuildContext context, Evento evento) {
    return LinhaTabelaCrud(
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
        _status(evento.status),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
    );
  }

  /// Área de toque uniforme dos botões de ação da tabela (editar/excluir).
  static const _restricoesBotaoAcao = BoxConstraints(
    minWidth: 40,
    minHeight: 40,
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

  /// Indicador visual do status do evento.
  Widget _status(String texto) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 125),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Cores.azulAcao.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Tipografia.labelMedium.copyWith(color: Cores.azulAcao),
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

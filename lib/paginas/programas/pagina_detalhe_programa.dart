import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/eventos_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_equipe_programa.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_projetos_programa.dart';
import 'package:go_router/go_router.dart';

/// Página de um programa com abas: Visão geral · Projetos · Eventos · Equipe.
/// Substitui o antigo diálogo pequeno acessível pelo card da lista.
class PaginaDetalhePrograma extends StatefulWidget {
  final int programaId;
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  /// Aba inicial (0..3), usada pelos atalhos do card.
  final int abaInicial;

  const PaginaDetalhePrograma({
    super.key,
    required this.programaId,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
    this.abaInicial = 0,
  });

  @override
  State<PaginaDetalhePrograma> createState() => _PaginaDetalheProgramaState();
}

class _PaginaDetalheProgramaState extends State<PaginaDetalhePrograma> {
  late int _aba;
  Programa? _programa;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _aba = widget.abaInicial.clamp(0, 3);
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final programa = await widget.repositorioCatalogo.obterPrograma(
        widget.programaId,
      );
      if (!mounted) return;
      setState(() {
        _programa = programa;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final nome = _programa?.nome ?? 'Programa';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              if ((_programa?.clienteNome ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _programa!.clienteNome,
                  style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
                ),
              ],
              const SizedBox(height: 16),
              SeletorAbas(
                selecionado: _aba,
                aoSelecionar: (i) => setState(() => _aba = i),
                itens: const [
                  (rotulo: 'Visão geral', icone: LucideIcons.layout_dashboard),
                  (rotulo: 'Projetos', icone: LucideIcons.git_branch),
                  (rotulo: 'Eventos', icone: LucideIcons.calendar),
                  (rotulo: 'Equipe', icone: LucideIcons.users),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Cores.bordaSutil),
        Expanded(child: _corpo()),
      ],
    );
  }

  Widget _corpo() {
    switch (_aba) {
      case 1:
        return PaginaProjetosPrograma(
          programaId: widget.programaId,
          repositorioCatalogo: widget.repositorioCatalogo,
          sessaoViewModel: widget.sessaoViewModel,
        );
      case 2:
        return _AbaEventosPrograma(
          programaId: widget.programaId,
          repositorioCatalogo: widget.repositorioCatalogo,
          sessaoViewModel: widget.sessaoViewModel,
        );
      case 3:
        return PaginaEquipePrograma(
          programaId: widget.programaId,
          repositorioCatalogo: widget.repositorioCatalogo,
          sessaoViewModel: widget.sessaoViewModel,
        );
      default:
        return _visaoGeral();
    }
  }

  Widget _visaoGeral() {
    final p = _programa;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CartaoConteudo(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descrição',
                  style: Tipografia.labelLarge.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (p?.descricao ?? '').isEmpty
                      ? 'Nenhuma descrição informada.'
                      : p!.descricao,
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.textoPrincipal,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _metrica('${p?.projetos ?? 0}', 'Projetos'),
                    const SizedBox(width: 32),
                    _metrica('${p?.eventos ?? 0}', 'Eventos'),
                  ],
                ),
                const SizedBox(height: 20),
                BotaoPrimario(
                  texto: 'Editar programa',
                  icone: LucideIcons.pencil,
                  onPressed: () async {
                    final alterado = await context.push<bool>(
                      '/programas/${widget.programaId}/editar',
                    );
                    if (alterado == true) _carregar();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrica(String valor, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: Tipografia.headlineMedium.copyWith(
            color: Cores.textoPrincipal,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
      ],
    );
  }
}

/// Lista de eventos do programa — reusa [EventosViewModel] com o filtro de
/// nível/escopo pré-fixado neste programa.
class _AbaEventosPrograma extends StatefulWidget {
  final int programaId;
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const _AbaEventosPrograma({
    required this.programaId,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<_AbaEventosPrograma> createState() => _AbaEventosProgramaState();
}

class _AbaEventosProgramaState extends State<_AbaEventosPrograma> {
  late final EventosViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EventosViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    _carregar();
  }

  Future<void> _carregar() async {
    await _viewModel.carregar();
    if (!mounted) return;
    _viewModel.definirFiltroNivel(NivelEscopo.programa);
    _viewModel.definirFiltroEscopoId(widget.programaId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  static const _colunas = [
    ColunaTabelaCrud(rotulo: 'Evento', flex: 3),
    ColunaTabelaCrud(rotulo: 'Data', largura: 120),
    ColunaTabelaCrud(rotulo: 'Ações', largura: 100, alinhamento: TextAlign.center),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Eventos deste programa',
                      style: Tipografia.titleLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                  ),
                  BotaoPrimario(
                    texto: 'Novo Evento',
                    icone: LucideIcons.plus,
                    onPressed: () async {
                      final criado = await context.push<bool>('/eventos/novo');
                      if (criado == true) _carregar();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _conteudo(),
            ],
          ),
        );
      },
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final eventos = _viewModel.eventos;
    if (eventos.isEmpty) {
      return const EstadoVazio(
        icone: LucideIcons.calendar,
        titulo: 'Nenhum evento neste programa',
        descricao: 'Os eventos deste programa e de seus projetos aparecem aqui.',
        acao: '',
      );
    }
    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const CabecalhoTabelaCrud(colunas: _colunas),
          for (final evento in eventos) _linha(evento),
        ],
      ),
    );
  }

  Widget _linha(Evento evento) {
    return LinhaTabelaCrud(
      colunas: _colunas,
      celulas: [
        Text(
          evento.nome,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        Text(
          _data(evento.data),
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Editar evento',
              onPressed: () async {
                final alterado = await context.push<bool>(
                  '/eventos/${evento.id}/editar',
                );
                if (alterado == true) _carregar();
              },
              icon: const Icon(LucideIcons.pencil, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  String _data(DateTime? data) {
    if (data == null) return '—';
    final d = data.day.toString().padLeft(2, '0');
    final m = data.month.toString().padLeft(2, '0');
    return '$d/$m/${data.year}';
  }
}

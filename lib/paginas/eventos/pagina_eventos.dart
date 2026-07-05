import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/eventos_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaEventos extends StatefulWidget {
  const PaginaEventos({super.key});

  @override
  State<PaginaEventos> createState() => _PaginaEventosState();
}

class _PaginaEventosState extends State<PaginaEventos> {
  late final EventosViewModel _viewModel;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = EventosViewModel(DependenciasApp.instancia.repositorioCatalogo)
      ..carregar();
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    _viewModel.dispose();
    super.dispose();
  }

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
              _cabecalho(context),
              const SizedBox(height: 20),
              CampoBusca(
                controlador: _controladorBusca,
                dica: 'Pesquisar eventos...',
                aoAlterar: _viewModel.definirBusca,
              ),
              const SizedBox(height: 24),
              _filtros(),
              const SizedBox(height: 24),
              _conteudo(context),
            ],
          ),
        );
      },
    );
  }

  Widget _cabecalho(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Eventos cadastrados',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
        ),
        Row(
          children: [
            BotaoPrimario(
              texto: 'Classes de Evento',
              icone: LucideIcons.tags,
              onPressed: () => context.push('/eventos/classes-evento'),
            ),
            const SizedBox(width: 12),
            BotaoPrimario(
              texto: 'Novo Evento',
              icone: LucideIcons.plus,
              onPressed: () async {
                final criado = await context.push<bool>('/eventos/novo');
                if (criado == true) await _viewModel.carregar();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _filtros() {
    return CartaoConteudo(
      child: Row(
        children: [
          const Icon(LucideIcons.sliders_horizontal, color: Cores.azulAcao),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filtre por programa, classe de evento, data ou status.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          _chip(
            'Todos',
            ativo: _viewModel.filtroPeriodo == 'Todos',
            onTap: () => _viewModel.definirFiltroPeriodo('Todos'),
          ),
          const SizedBox(width: 8),
          _chip(
            'Este mes',
            ativo: _viewModel.filtroPeriodo == 'Este mes',
            onTap: () => _viewModel.definirFiltroPeriodo('Este mes'),
          ),
          const SizedBox(width: 8),
          _chip(
            'Confirmados',
            ativo: _viewModel.filtroStatus == 'Confirmados',
            onTap: () => _viewModel.definirFiltroStatus(
              _viewModel.filtroStatus == 'Confirmados'
                  ? 'Todos'
                  : 'Confirmados',
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Nao foi possivel carregar os eventos',
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

  Widget _listaEventos(BuildContext context, List<Evento> eventos) {
    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _cabecalhoTabela(),
          for (final evento in eventos) _linha(context, evento),
        ],
      ),
    );
  }

  Widget _cabecalhoTabela() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Cores.fundoSecao,
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          _celulaCabecalho('Evento', flex: 3),
          _celulaCabecalho('Programa', flex: 2),
          _celulaCabecalho('Data'),
          _celulaCabecalho('Status'),
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, Evento evento) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              evento.nome,
              style: Tipografia.labelLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              evento.programa,
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          Expanded(
            child: Text(
              _formatarData(evento.data),
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _status(evento.status),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Editar evento',
                  onPressed: () async {
                    final alterado = await context.push<bool>(
                      '/eventos/${evento.id}/editar',
                    );
                    if (alterado == true) {
                      await _viewModel.carregar();
                    }
                  },
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
                IconButton(
                  tooltip: 'Excluir evento',
                  onPressed: () => _confirmarExclusao(context, evento),
                  icon: const Icon(
                    LucideIcons.trash_2,
                    size: 18,
                    color: Cores.vermelhoErro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, Evento evento) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text(
          'Tem certeza de que deseja excluir "${evento.nome}"? '
          'Relatórios já gerados para este evento permanecerão, mas perderão '
          'o vínculo com ele. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Cores.vermelhoErro),
            ),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;

    final eventoId = evento.id;
    if (eventoId == null) return;

    final sucesso = await _viewModel.excluir(eventoId);
    if (!context.mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao excluir evento.'),
      ),
    );
  }

  Widget _celulaCabecalho(String texto, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        texto.toUpperCase(),
        style: Tipografia.labelMedium.copyWith(
          color: Cores.cinzaMedio,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

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

  Widget _status(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Cores.azulAcao.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: Tipografia.labelMedium.copyWith(color: Cores.azulAcao),
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Data não informada';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}

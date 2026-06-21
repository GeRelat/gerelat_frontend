import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/eventos_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_formulario_evento.dart';

class PaginaEventos extends StatefulWidget {
  const PaginaEventos({super.key});

  @override
  State<PaginaEventos> createState() => _PaginaEventosState();
}

class _PaginaEventosState extends State<PaginaEventos> {
  late final EventosViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EventosViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )
      ..carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      secaoAtual: SecaoApp.eventos,
      titulo: 'Gestao de Eventos',
      dicaPesquisa: 'Pesquisar eventos...',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalho(context),
                const SizedBox(height: 24),
                _filtros(),
                const SizedBox(height: 24),
                _conteudo(context),
              ],
            ),
          );
        },
      ),
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
        BotaoPrimario(
          texto: 'Novo Evento',
          icone: LucideIcons.plus,
          onPressed: () async {
            final criado = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const PaginaFormularioEvento()),
            );
            if (criado == true) await _viewModel.carregar();
          },
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
          _chip('Todos'),
          const SizedBox(width: 8),
          _chip('Este mes'),
          const SizedBox(width: 8),
          _chip('Confirmados'),
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
        color: Color(0xFFF8FAFC),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PaginaFormularioEvento(edicao: true),
                    ),
                  ),
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
              ],
            ),
          ),
        ],
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

  Widget _chip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

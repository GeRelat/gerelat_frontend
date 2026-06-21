import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/relatorios_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_gerar_relatorio.dart';

class PaginaRelatorios extends StatefulWidget {
  const PaginaRelatorios({super.key});

  @override
  State<PaginaRelatorios> createState() => _PaginaRelatoriosState();
}

class _PaginaRelatoriosState extends State<PaginaRelatorios> {
  late final RelatoriosViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RelatoriosViewModel(
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
      secaoAtual: SecaoApp.relatorios,
      titulo: 'Relatorios',
      dicaPesquisa: 'Pesquisar relatorios...',
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
                _atalhoGeracao(context),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relatorios gerados',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Acompanhe documentos gerados e inicie novas geracoes.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ],
          ),
        ),
        BotaoPrimario(
          texto: 'Novo Relatorio',
          icone: LucideIcons.plus,
          onPressed: () => _abrirGeracao(context),
        ),
      ],
    );
  }

  Widget _atalhoGeracao(BuildContext context) {
    return CartaoConteudo(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Cores.azulAcao.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.file_output, color: Cores.azulAcao),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geracao rapida',
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Abra o fluxo completo para selecionar evento, template e parametros do documento.',
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
              ],
            ),
          ),
          BotaoPrimario(
            texto: 'Abrir Gerador',
            icone: LucideIcons.arrow_right,
            onPressed: () => _abrirGeracao(context),
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
        titulo: 'Nao foi possivel carregar os relatorios',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.estaVazio) {
      return EstadoVazio(
        icone: LucideIcons.file_text,
        titulo: 'Nenhum relatorio gerado ainda',
        descricao:
            'Escolha um evento e um template para criar o primeiro relatorio institucional.',
        acao: 'Gerar Relatorio',
        onAcao: () => _abrirGeracao(context),
      );
    }

    return _listaRelatorios(_viewModel.relatorios);
  }

  Widget _listaRelatorios(List<Relatorio> relatorios) {
    return CartaoConteudo(
      child: Column(
        children: [
          for (final relatorio in relatorios)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.file_text),
              title: Text(relatorio.titulo),
              subtitle: Text('${relatorio.evento} - ${relatorio.template}'),
              trailing: Text(relatorio.status),
            ),
        ],
      ),
    );
  }

  void _abrirGeracao(BuildContext context) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(builder: (_) => const PaginaGerarRelatorio()),
        )
        .then((gerado) {
          if (gerado == true) _viewModel.carregar();
        });
  }
}

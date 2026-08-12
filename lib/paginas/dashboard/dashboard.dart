import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/dashboard_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const DashboardPage({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(widget.repositorioCatalogo);
    widget.sessaoViewModel.addListener(_aoMudarSessao);
    _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId);
  }

  void _aoMudarSessao() {
    if (_viewModel.clienteId != widget.sessaoViewModel.clienteAtivoId) {
      _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId);
    }
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, widget.sessaoViewModel]),
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visão geral da sua gestão de relatórios',
                style: Tipografia.headlineSmall.copyWith(
                  color: Cores.textoPrincipal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _conteudoResumo(),
              const SizedBox(height: 32),
              child!,
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _acoesPrincipais(context),
          const SizedBox(height: 32),
          _sincronizacao(),
        ],
      ),
    );
  }

  Widget _conteudoResumo() {
    if (_viewModel.carregando && _viewModel.resumo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possivel carregar o resumo',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: () =>
            _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId),
      );
    }

    final resumo =
        _viewModel.resumo ??
        const ResumoDashboard(
          programas: 0,
          projetos: 0,
          eventos: 0,
          templates: 0,
          relatorios: 0,
        );

    return _statusCards(resumo);
  }

  Widget _statusCards(ResumoDashboard resumo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth < 760
            ? 1
            : constraints.maxWidth < 1080
            ? 2
            : 3;
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
                valor: '${resumo.programas}',
                descricao: '${resumo.projetos} projetos vinculados',
                icone: LucideIcons.folder_kanban,
              ),
            ),
            SizedBox(
              width: largura,
              child: CartaoInfo(
                titulo: 'Templates',
                valor: '${resumo.templates}',
                descricao: 'Padrões corporativos disponíveis',
                icone: LucideIcons.copy,
              ),
            ),
            SizedBox(
              width: largura,
              child: CartaoInfo(
                titulo: 'Relatórios',
                valor: '${resumo.relatorios}',
                descricao: '${resumo.eventos} eventos mapeados',
                icone: LucideIcons.file_text,
                cor: Cores.verdeSucesso,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _acoesPrincipais(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 960;
        final relatorio = _HeroRelatorio(
          onTap: () => context.go('/relatorios'),
        );
        final programa = _AcaoSecundaria(
          titulo: 'Novo Programa',
          descricao: 'Configure um novo programa institucional no sistema.',
          icone: LucideIcons.folder_plus,
          onTap: () => context.go('/programas'),
        );

        if (compacto) {
          return Column(
            children: [relatorio, const SizedBox(height: 24), programa],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: relatorio),
            const SizedBox(width: 24),
            Expanded(child: programa),
          ],
        );
      },
    );
  }

  Widget _sincronizacao() {
    return CartaoConteudo(
      child: Row(
        children: [
          const IconeComFundo(
            tamanho: 44,
            raio: 12,
            cor: Cores.azulAcao,
            icone: LucideIcons.refresh_cw,
            tamanhoIcone: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última atualização',
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seu dashboard foi sincronizado há poucos minutos com a base de dados corporativa.',
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRelatorio extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroRelatorio({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Cores.azulClaro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar Novo Relatório',
                  style: Tipografia.headlineMedium.copyWith(
                    color: Cores.branco,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Gere relatórios completos a partir dos seus eventos cadastrados.',
                  style: Tipografia.bodyLarge.copyWith(
                    color: Cores.branco,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.arrow_right, size: 18),
                  label: const Text('Começar agora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.branco,
                    foregroundColor: Cores.azulAcao,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _IconeEmCaixa(
            tamanho: 148,
            raio: 28,
            corFundo: Cores.branco.withValues(alpha: 0.16),
            icone: LucideIcons.chart_bar,
            corIcone: Cores.branco,
            tamanhoIcone: 72,
          ),
        ],
      ),
    );
  }
}

class _AcaoSecundaria extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final VoidCallback onTap;

  const _AcaoSecundaria({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconeComFundo(
            tamanho: 64,
            raio: 999,
            cor: Cores.azulAcao,
            icone: icone,
            tamanhoIcone: 30,
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Tipografia.titleLargeDestaque.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: Tipografia.bodyMedium.copyWith(
              color: Cores.cinzaEscuro,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(LucideIcons.arrow_right, size: 16),
            label: const Text('Cadastrar programa'),
          ),
        ],
      ),
    );
  }
}

/// Caixa arredondada com um ícone centralizado — usada pelo cartão de
/// sincronização, pelo hero de "Criar Novo Relatório" e pela ação
/// secundária "Novo Programa".
class _IconeEmCaixa extends StatelessWidget {
  final double tamanho;
  final double raio;
  final Color corFundo;
  final IconData icone;
  final Color corIcone;
  final double? tamanhoIcone;

  const _IconeEmCaixa({
    required this.tamanho,
    required this.raio,
    required this.corFundo,
    required this.icone,
    required this.corIcone,
    this.tamanhoIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(raio),
      ),
      child: Icon(icone, color: corIcone, size: tamanhoIcone),
    );
  }
}

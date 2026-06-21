import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/dashboard_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_programas.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_relatorios.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(
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
      secaoAtual: SecaoApp.dashboard,
      titulo: 'Dashboard',
      dicaPesquisa: 'Pesquisar...',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visao geral da sua gestao de relatorios',
                  style: Tipografia.headlineSmall.copyWith(
                    color: Cores.textoPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                _conteudoResumo(),
                const SizedBox(height: 32),
                _acoesPrincipais(context),
                const SizedBox(height: 32),
                _sincronizacao(),
              ],
            ),
          );
        },
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
        titulo: 'Nao foi possivel carregar o resumo',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
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
                descricao: 'Padroes corporativos disponiveis',
                icone: LucideIcons.copy,
              ),
            ),
            SizedBox(
              width: largura,
              child: CartaoInfo(
                titulo: 'Relatorios',
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
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PaginaRelatorios()),
          ),
        );
        final programa = _AcaoSecundaria(
          titulo: 'Novo Programa',
          descricao: 'Configure um novo programa institucional no sistema.',
          icone: LucideIcons.folder_plus,
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PaginaProgramas()),
          ),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Cores.azulAcao.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.refresh_cw, color: Cores.azulAcao),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ultima atualizacao',
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seu dashboard foi sincronizado ha poucos minutos com a base de dados corporativa.',
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
                  'Criar Novo Relatorio',
                  style: Tipografia.headlineMedium.copyWith(
                    color: Cores.branco,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Gere relatorios completos a partir dos seus eventos cadastrados.',
                  style: Tipografia.bodyLarge.copyWith(
                    color: Cores.branco,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.arrow_right, size: 18),
                  label: const Text('Comecar agora'),
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
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: Cores.branco.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              LucideIcons.chart_bar,
              color: Cores.branco,
              size: 72,
            ),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Cores.azulAcao.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icone, color: Cores.azulAcao, size: 30),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Tipografia.titleLarge.copyWith(
              color: Cores.textoPrincipal,
              fontWeight: FontWeight.w800,
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

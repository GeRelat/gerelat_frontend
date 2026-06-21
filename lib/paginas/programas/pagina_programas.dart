import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programas_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_formulario_programa.dart';

class PaginaProgramas extends StatefulWidget {
  const PaginaProgramas({super.key});

  @override
  State<PaginaProgramas> createState() => _PaginaProgramasState();
}

class _PaginaProgramasState extends State<PaginaProgramas> {
  late final ProgramasViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProgramasViewModel(
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
      secaoAtual: SecaoApp.programas,
      titulo: 'Gestao de Programas',
      dicaPesquisa: 'Pesquisar programas...',
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
                _resumo(),
                const SizedBox(height: 32),
                _conteudo(),
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
                'Programas institucionais',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Organize programas, projetos relacionados e equipes responsaveis.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ],
          ),
        ),
        BotaoPrimario(
          texto: 'Novo Programa',
          icone: LucideIcons.plus,
          onPressed: () async {
            final criado = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const PaginaFormularioPrograma(),
              ),
            );
            if (criado == true) await _viewModel.carregar();
          },
        ),
      ],
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
                (programa) =>
                    SizedBox(width: largura, child: _CartaoPrograma(programa)),
              )
              .toList(),
        );
      },
    );
  }
}

class _CartaoPrograma extends StatelessWidget {
  final Programa programa;

  const _CartaoPrograma(this.programa);

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Cores.azulAcao.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.folder_kanban,
                  color: Cores.azulAcao,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      programa.nome,
                      style: Tipografia.titleLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      programa.descricao,
                      style: Tipografia.bodyMedium.copyWith(
                        color: Cores.cinzaEscuro,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _metrica('${programa.projetos}', 'Projetos'),
              const SizedBox(width: 24),
              _metrica('${programa.eventos}', 'Eventos'),
              const Spacer(),
              _status(programa.status),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Editar programa',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const PaginaFormularioPrograma(edicao: true),
                  ),
                ),
                icon: const Icon(LucideIcons.pencil, size: 18),
              ),
            ],
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
          style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal),
        ),
        Text(
          label,
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
      ],
    );
  }

  Widget _status(String texto) {
    final ativo = texto == 'Ativo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (ativo ? Cores.verdeSucesso : Cores.azulAcao).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: Tipografia.labelMedium.copyWith(
          color: ativo ? Cores.verdeSucesso : Cores.azulAcao,
        ),
      ),
    );
  }
}

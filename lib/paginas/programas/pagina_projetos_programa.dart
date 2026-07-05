import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/projetos_programa_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaProjetosPrograma extends StatefulWidget {
  final int programaId;

  const PaginaProjetosPrograma({super.key, required this.programaId});

  @override
  State<PaginaProjetosPrograma> createState() =>
      _PaginaProjetosProgramaState();
}

class _PaginaProjetosProgramaState extends State<PaginaProjetosPrograma> {
  late final ProjetosProgramaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjetosProgramaViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
      programaId: widget.programaId,
    )..carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _novoProjeto() async {
    final criado = await context.push<bool>(
      '/programas/projetos/novo',
      extra: widget.programaId,
    );
    if (criado == true) await _viewModel.carregar();
  }

  Future<void> _editarProjeto(int projetoId) async {
    final alterado = await context.push<bool>(
      '/programas/projetos/$projetoId/editar',
    );
    if (alterado == true) await _viewModel.carregar();
  }

  Future<void> _confirmarExclusao(Projeto projeto) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir projeto'),
        content: Text(
          'Tem certeza de que deseja excluir "${projeto.nome}"? Eventos, '
          'templates, campos e equipes vinculados a ele também serão '
          'excluídos. Esta ação não pode ser desfeita.',
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
    if (confirmou != true || !mounted) return;

    final projetoId = projeto.id;
    if (projetoId == null) return;

    final sucesso = await _viewModel.excluir(projetoId);
    if (!mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao excluir projeto.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.carregando && _viewModel.programa == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final nomePrograma = _viewModel.programa?.nome ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projetos — $nomePrograma',
                          style: Tipografia.headlineMedium.copyWith(
                            color: Cores.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Projetos vinculados a este programa institucional.',
                          style: Tipografia.bodyMedium.copyWith(
                            color: Cores.cinzaEscuro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BotaoPrimario(
                    texto: 'Novo Projeto',
                    icone: LucideIcons.plus,
                    onPressed: _novoProjeto,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _conteudo(),
            ],
          ),
        );
      },
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando && _viewModel.projetos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null && _viewModel.projetos.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possível carregar os projetos',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.projetos.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.git_branch,
        titulo: 'Nenhum projeto cadastrado',
        descricao: 'Cadastre o primeiro projeto vinculado a este programa.',
        acao: 'Novo Projeto',
        onAcao: _novoProjeto,
      );
    }

    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _cabecalhoTabela(),
          for (final projeto in _viewModel.projetos) _linha(projeto),
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
          _celulaCabecalho('Nome', flex: 2),
          _celulaCabecalho('Parceira', flex: 2),
          _celulaCabecalho('Sigla'),
          _celulaCabecalho('Ações'),
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

  Widget _linha(Projeto projeto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              projeto.nome,
              style: Tipografia.labelLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              projeto.parceira.isEmpty ? '—' : projeto.parceira,
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          Expanded(
            child: Text(
              projeto.sigla.isEmpty ? '—' : projeto.sigla,
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () {
                    final projetoId = projeto.id;
                    if (projetoId != null) _editarProjeto(projetoId);
                  },
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: () => _confirmarExclusao(projeto),
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
}

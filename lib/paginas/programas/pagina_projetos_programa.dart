import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/projetos_programa_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaProjetosPrograma extends StatefulWidget {
  final int programaId;
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaProjetosPrograma({
    super.key,
    required this.programaId,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaProjetosPrograma> createState() => _PaginaProjetosProgramaState();
}

class _PaginaProjetosProgramaState extends State<PaginaProjetosPrograma> {
  late final ProjetosProgramaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjetosProgramaViewModel(
      widget.repositorioCatalogo,
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
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir projeto',
      mensagem:
          'Tem certeza de que deseja excluir "${projeto.nome}"? Eventos, '
          'templates, campos e equipes vinculados a ele também serão '
          'excluídos. Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !mounted) return;

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
    final usuario = widget.sessaoViewModel.usuarioAtual;
    final clienteAtivoId = widget.sessaoViewModel.clienteAtivoId;
    final eAdmin = usuario?.eAdminDoCliente(clienteAtivoId) ?? false;
    final eMembroDoPrograma = usuario?.contextosAcesso.programas.any(
          (p) => int.tryParse('${p['id']}') == widget.programaId,
        ) ??
        false;

    final podeCriarEExcluir = eAdmin || eMembroDoPrograma;

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
                  if (podeCriarEExcluir)
                    BotaoPrimario(
                      texto: 'Novo Projeto',
                      icone: LucideIcons.plus,
                      onPressed: _novoProjeto,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _conteudo(podeCriarEExcluir: podeCriarEExcluir, usuario: usuario),
            ],
          ),
        );
      },
    );
  }

  Widget _conteudo({
    required bool podeCriarEExcluir,
    required dynamic usuario,
  }) {
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
        descricao: podeCriarEExcluir
            ? 'Cadastre o primeiro projeto vinculado a este programa.'
            : 'Não há projetos cadastrados vinculados a este programa.',
        acao: 'Novo Projeto',
        onAcao: podeCriarEExcluir ? _novoProjeto : null,
      );
    }

    final temAcoes = _viewModel.projetos.any((p) {
      final eMembroDoP = usuario?.contextosAcesso.projetos.any(
            (item) => int.tryParse('${item['id']}') == p.id,
          ) ??
          false;
      return podeCriarEExcluir || eMembroDoP;
    });

    final colunas = temAcoes
        ? const [
            ColunaTabelaCrud(rotulo: 'Nome', flex: 2),
            ColunaTabelaCrud(rotulo: 'Parceira', flex: 2),
            ColunaTabelaCrud(rotulo: 'Sigla', flex: 1),
            ColunaTabelaCrud(rotulo: 'Ações', flex: 1),
          ]
        : const [
            ColunaTabelaCrud(rotulo: 'Nome', flex: 2),
            ColunaTabelaCrud(rotulo: 'Parceira', flex: 2),
            ColunaTabelaCrud(rotulo: 'Sigla', flex: 1),
          ];

    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          CabecalhoTabelaCrud(colunas: colunas),
          for (final projeto in _viewModel.projetos)
            _linha(
              projeto: projeto,
              colunas: colunas,
              podeCriarEExcluir: podeCriarEExcluir,
              usuario: usuario,
              temAcoes: temAcoes,
            ),
        ],
      ),
    );
  }

  Widget _linha({
    required Projeto projeto,
    required List<ColunaTabelaCrud> colunas,
    required bool podeCriarEExcluir,
    required dynamic usuario,
    required bool temAcoes,
  }) {
    final eMembroDoProjeto = usuario?.contextosAcesso.projetos.any(
          (p) => int.tryParse('${p['id']}') == projeto.id,
        ) ??
        false;

    final podeEditar = podeCriarEExcluir || eMembroDoProjeto;
    final podeExcluir = podeCriarEExcluir;

    return LinhaTabelaCrud(
      colunas: colunas,
      celulas: [
        Text(
          projeto.nome,
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        Text(
          projeto.parceira.isEmpty ? '—' : projeto.parceira,
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        Text(
          projeto.sigla.isEmpty ? '—' : projeto.sigla,
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        if (temAcoes)
          Row(
            children: [
              if (podeEditar)
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () {
                    final projetoId = projeto.id;
                    if (projetoId != null) _editarProjeto(projetoId);
                  },
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
              if (podeExcluir)
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
      ],
    );
  }
}

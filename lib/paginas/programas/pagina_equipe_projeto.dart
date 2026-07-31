import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/equipe_projeto_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaEquipeProjeto extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaEquipeProjeto({super.key, required this.repositorioCatalogo});

  @override
  State<PaginaEquipeProjeto> createState() => _PaginaEquipeProjetoState();
}

class _PaginaEquipeProjetoState extends State<PaginaEquipeProjeto> {
  final _formKey = GlobalKey<FormState>();
  final _nomeEquipe = TextEditingController();
  final _nome = TextEditingController();
  final _cargo = TextEditingController();
  final _focoNomeEquipe = FocusNode();
  late final EquipeProjetoViewModel _viewModel;
  int? _membroEmEdicaoId;

  @override
  void initState() {
    super.initState();
    _viewModel = EquipeProjetoViewModel(widget.repositorioCatalogo)
      ..carregarProjetos();
  }

  @override
  void dispose() {
    _nomeEquipe.dispose();
    _nome.dispose();
    _cargo.dispose();
    _focoNomeEquipe.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _iniciarEdicao(MembroEquipeProjeto membro) {
    setState(() {
      _membroEmEdicaoId = membro.id;
      _nomeEquipe.text = membro.nomeEquipe;
      _nome.text = membro.nome;
      _cargo.text = membro.cargo;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _membroEmEdicaoId = null;
      _nomeEquipe.clear();
      _nome.clear();
      _cargo.clear();
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final sucesso = await _viewModel.salvar(
      membroId: _membroEmEdicaoId,
      nomeEquipe: _nomeEquipe.text.trim(),
      nome: _nome.text.trim(),
      cargo: _cargo.text.trim(),
    );
    if (!mounted) return;
    if (sucesso) {
      _cancelarEdicao();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  Future<void> _confirmarExclusao(MembroEquipeProjeto membro) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Remover da equipe',
      mensagem:
          'Remover ${membro.nome} da equipe "${membro.nomeEquipe}" deste projeto?',
      textoConfirmar: 'Remover',
    );
    if (!confirmou) return;

    final membroId = membro.id;
    if (membroId == null) return;
    final sucesso = await _viewModel.excluir(membroId);
    if (!mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao remover.')),
      );
    }
    if (_membroEmEdicaoId == membroId) {
      _cancelarEdicao();
    }
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // O título é a única parte que não depende de `_viewModel`; é passado
    // como `child` para não ser reconstruído a cada notificação.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando && _viewModel.projetos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child!,
              const SizedBox(height: 24),
              CartaoConteudo(
                child: CampoSelecao(
                  label: 'Projeto',
                  valor: _viewModel.projetoSelecionadoId,
                  itens: _viewModel.projetos
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _viewModel.selecionarProjeto(value),
                ),
              ),
              const SizedBox(height: 24),
              if (_viewModel.projetoSelecionadoId == null)
                CartaoConteudo(
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.arrow_up,
                        color: Cores.cinzaMedio,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Escolha um projeto acima para ver e gerenciar sua equipe.',
                          style: Tipografia.bodyMedium.copyWith(
                            color: Cores.cinzaEscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _formularioMembro(),
                const SizedBox(height: 32),
                _conteudoLista(),
              ],
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipe da parceira',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha um projeto para ver e gerenciar a equipe da entidade parceira.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }

  Widget _formularioMembro() {
    return CartaoConteudo(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampoFormulario(
              label: 'Nome da Equipe',
              hint: 'Ex: Equipe Técnica',
              icone: LucideIcons.tags,
              controller: _nomeEquipe,
              focusNode: _focoNomeEquipe,
              validator: _obrigatorio,
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFormulario(
                    label: 'Nome',
                    hint: 'Ex: João Pereira',
                    icone: LucideIcons.user,
                    controller: _nome,
                    validator: _obrigatorio,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: CampoFormulario(
                    label: 'Cargo',
                    hint: 'Ex: Analista',
                    icone: LucideIcons.badge_info,
                    controller: _cargo,
                    validator: _obrigatorio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_membroEmEdicaoId != null) ...[
                  TextButton(
                    onPressed: _viewModel.carregando ? null : _cancelarEdicao,
                    child: const Text('Cancelar edição'),
                  ),
                  const SizedBox(width: 12),
                ],
                BotaoPrimario(
                  texto: _viewModel.carregando
                      ? 'Salvando...'
                      : _membroEmEdicaoId != null
                      ? 'Salvar'
                      : 'Adicionar',
                  icone: _membroEmEdicaoId != null
                      ? LucideIcons.save
                      : LucideIcons.plus,
                  onPressed: _viewModel.carregando ? null : _salvar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoLista() {
    if (_viewModel.carregando && _viewModel.membros.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.membros.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.users,
        titulo: 'Nenhum membro cadastrado',
        descricao: 'Adicione o primeiro membro da equipe deste projeto.',
        acao: 'Adicionar membro',
        onAcao: () => _focoNomeEquipe.requestFocus(),
      );
    }

    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _cabecalhoTabela(),
          for (final membro in _viewModel.membros) _linha(membro),
        ],
      ),
    );
  }

  static const _colunas = [
    ColunaTabelaCrud(rotulo: 'Equipe', flex: 2),
    ColunaTabelaCrud(rotulo: 'Nome', flex: 2),
    ColunaTabelaCrud(rotulo: 'Cargo', flex: 2),
    ColunaTabelaCrud(rotulo: 'Ações', flex: 1),
  ];

  Widget _cabecalhoTabela() {
    return const CabecalhoTabelaCrud(colunas: _colunas);
  }

  Widget _linha(MembroEquipeProjeto membro) {
    return LinhaTabelaCrud(
      colunas: _colunas,
      celulas: [
        Text(
          membro.nomeEquipe,
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        Text(
          membro.nome,
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        Text(
          membro.cargo,
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _iniciarEdicao(membro),
              icon: const Icon(LucideIcons.pencil, size: 18),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: () => _confirmarExclusao(membro),
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

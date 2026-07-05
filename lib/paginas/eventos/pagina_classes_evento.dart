import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/classe_evento_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaClassesEvento extends StatefulWidget {
  const PaginaClassesEvento({super.key});

  @override
  State<PaginaClassesEvento> createState() => _PaginaClassesEventoState();
}

class _PaginaClassesEventoState extends State<PaginaClassesEvento> {
  final _formKey = GlobalKey<FormState>();
  final _nomeClasse = TextEditingController();
  final _focoNome = FocusNode();
  late final ClasseEventoViewModel _viewModel;
  int? _classeEmEdicaoId;

  @override
  void initState() {
    super.initState();
    _viewModel = ClasseEventoViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )..carregarProjetos();
  }

  @override
  void dispose() {
    _nomeClasse.dispose();
    _focoNome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _iniciarEdicao(ClasseEvento classe) {
    setState(() {
      _classeEmEdicaoId = classe.id;
      _nomeClasse.text = classe.nomeClasse;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _classeEmEdicaoId = null;
      _nomeClasse.clear();
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final sucesso = await _viewModel.salvar(
      classeId: _classeEmEdicaoId,
      nomeClasse: _nomeClasse.text.trim(),
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

  Future<void> _confirmarExclusao(ClasseEvento classe) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover classe de evento'),
        content: Text(
          'Remover a classe "${classe.nomeClasse}"? Os eventos cadastrados '
          'nesta classe também serão excluídos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(color: Cores.vermelhoErro),
            ),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    final classeId = classe.id;
    if (classeId == null) return;
    final sucesso = await _viewModel.excluir(classeId);
    if (!mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao remover.')),
      );
    }
    if (_classeEmEdicaoId == classeId) {
      _cancelarEdicao();
    }
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.carregando && _viewModel.projetos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classes de evento',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Categorias usadas para classificar os eventos de cada projeto.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
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
                  onChanged: (value) {
                    _cancelarEdicao();
                    _viewModel.selecionarProjeto(value);
                  },
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
                          'Escolha um projeto acima para ver e gerenciar suas classes de evento.',
                          style: Tipografia.bodyMedium.copyWith(
                            color: Cores.cinzaEscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _formularioClasse(),
                const SizedBox(height: 32),
                _conteudoLista(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _formularioClasse() {
    return CartaoConteudo(
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoFormulario(
                label: 'Nome da Classe',
                hint: 'Ex: Oficina',
                icone: LucideIcons.tags,
                controller: _nomeClasse,
                focusNode: _focoNome,
                validator: _obrigatorio,
              ),
            ),
            const SizedBox(width: 18),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Row(
                children: [
                  if (_classeEmEdicaoId != null) ...[
                    TextButton(
                      onPressed: _viewModel.carregando ? null : _cancelarEdicao,
                      child: const Text('Cancelar edição'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  BotaoPrimario(
                    texto: _viewModel.carregando
                        ? 'Salvando...'
                        : _classeEmEdicaoId != null
                        ? 'Salvar'
                        : 'Adicionar',
                    icone: _classeEmEdicaoId != null
                        ? LucideIcons.save
                        : LucideIcons.plus,
                    onPressed: _viewModel.carregando ? null : _salvar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoLista() {
    if (_viewModel.carregando && _viewModel.classes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.classes.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.tags,
        titulo: 'Nenhuma classe cadastrada',
        descricao: 'Adicione a primeira classe de evento deste projeto.',
        acao: 'Adicionar classe',
        onAcao: () => _focoNome.requestFocus(),
      );
    }

    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _cabecalhoTabela(),
          for (final classe in _viewModel.classes) _linha(classe),
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
          _celulaCabecalho('Nome da Classe', flex: 3),
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

  Widget _linha(ClasseEvento classe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              classe.nomeClasse,
              style: Tipografia.labelLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _iniciarEdicao(classe),
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => _confirmarExclusao(classe),
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

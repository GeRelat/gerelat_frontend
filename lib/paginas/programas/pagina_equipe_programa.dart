import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/equipe_programa_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaEquipePrograma extends StatefulWidget {
  final int programaId;

  const PaginaEquipePrograma({super.key, required this.programaId});

  @override
  State<PaginaEquipePrograma> createState() => _PaginaEquipeProgramaState();
}

class _PaginaEquipeProgramaState extends State<PaginaEquipePrograma> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cargo = TextEditingController();
  final _focoNome = FocusNode();
  late final EquipeProgramaViewModel _viewModel;
  int? _membroEmEdicaoId;

  @override
  void initState() {
    super.initState();
    _viewModel = EquipeProgramaViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
      programaId: widget.programaId,
    )..carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _cargo.dispose();
    _focoNome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _iniciarEdicao(MembroEquipePrograma membro) {
    setState(() {
      _membroEmEdicaoId = membro.id;
      _nome.text = membro.nome;
      _cargo.text = membro.cargo;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _membroEmEdicaoId = null;
      _nome.clear();
      _cargo.clear();
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final sucesso = await _viewModel.salvar(
      membroId: _membroEmEdicaoId,
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

  Future<void> _confirmarExclusao(MembroEquipePrograma membro) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover da equipe'),
        content: Text('Remover ${membro.nome} da equipe fixa do programa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

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
              Text(
                'Equipe fixa — $nomePrograma',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pessoas que compõem a equipe permanente deste programa.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
              const SizedBox(height: 24),
              CartaoConteudo(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoFormulario(
                              label: 'Nome',
                              hint: 'Ex: Maria da Silva',
                              icone: LucideIcons.user,
                              controller: _nome,
                              focusNode: _focoNome,
                              validator: _obrigatorio,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: CampoFormulario(
                              label: 'Cargo',
                              hint: 'Ex: Coordenadora',
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
                              onPressed: _viewModel.carregando
                                  ? null
                                  : _cancelarEdicao,
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
              ),
              const SizedBox(height: 32),
              _conteudoLista(),
            ],
          ),
        );
      },
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
        descricao: 'Adicione o primeiro membro da equipe fixa deste programa.',
        acao: 'Adicionar membro',
        onAcao: () => _focoNome.requestFocus(),
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
          _celulaCabecalho('Cargo', flex: 2),
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

  Widget _linha(MembroEquipePrograma membro) {
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
              membro.nome,
              style: Tipografia.labelLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              membro.cargo,
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          Expanded(
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

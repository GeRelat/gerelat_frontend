import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/projeto_form_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioProjeto extends StatefulWidget {
  final bool edicao;
  final int? projetoId;
  final int? programaIdInicial;
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;

  const PaginaFormularioProjeto({
    super.key,
    this.edicao = false,
    this.projetoId,
    this.programaIdInicial,
    required this.repositorioCatalogo,
    required this.urlBase,
  });

  @override
  State<PaginaFormularioProjeto> createState() =>
      _PaginaFormularioProjetoState();
}

class _PaginaFormularioProjetoState extends State<PaginaFormularioProjeto> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _parceira = TextEditingController();
  final _sigla = TextEditingController();
  String _logomarca = '';
  late final ProjetoFormViewModel _viewModel;
  int? _programaId;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjetoFormViewModel(widget.repositorioCatalogo);
    final projetoId = widget.projetoId;
    if (widget.edicao && projetoId != null) {
      _viewModel.carregar(projetoId).then((_) {
        final projeto = _viewModel.projeto;
        if (!mounted || projeto == null) return;
        _nome.text = projeto.nome;
        _parceira.text = projeto.parceira;
        _sigla.text = projeto.sigla;
        setState(() {
          _logomarca = projeto.logomarca;
          _programaId = projeto.programaId;
        });
      });
    } else {
      _programaId = widget.programaIdInicial;
      _viewModel.carregarOpcoes();
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _parceira.dispose();
    _sigla.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _programaId == null) return;
    final sucesso = await _viewModel.salvar(
      projetoId: widget.projetoId,
      programaId: _programaId!,
      nome: _nome.text.trim(),
      parceira: _parceira.text.trim(),
      sigla: _sigla.text.trim(),
      logomarca: _logomarca,
    );
    if (!mounted) return;
    if (sucesso) {
      context.pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar projeto.'),
      ),
    );
  }

  Future<void> _excluir() async {
    final projetoId = widget.projetoId;
    if (projetoId == null) return;

    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir projeto',
      mensagem:
          'Tem certeza de que deseja excluir este projeto? Eventos, templates, '
          'campos e equipes vinculados a ele também serão excluídos. '
          'Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !mounted) return;

    final sucesso = await _viewModel.excluir(projetoId);
    if (!mounted) return;
    if (sucesso) {
      context.pop(true);
      return;
    }
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
        if (_viewModel.carregando && _viewModel.programas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.edicao
                            ? 'Editar projeto'
                            : 'Cadastrar projeto vinculado ao programa',
                        style: Tipografia.headlineMedium.copyWith(
                          color: Cores.textoPrincipal,
                        ),
                      ),
                    ),
                    if (widget.edicao)
                      TextButton.icon(
                        onPressed: _viewModel.carregando ? null : _excluir,
                        icon: const Icon(
                          LucideIcons.trash_2,
                          size: 18,
                          color: Cores.vermelhoErro,
                        ),
                        label: Text(
                          'Excluir',
                          style: Tipografia.labelLarge.copyWith(
                            color: Cores.vermelhoErro,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                CartaoConteudo(
                  child: Column(
                    children: [
                      CampoSelecao(
                        label: 'Programa',
                        valor: _programaId,
                        itens: _viewModel.programas
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _programaId = value),
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Nome do Projeto',
                        hint: 'Ex: Projeto de Relatórios Institucionais',
                        icone: LucideIcons.briefcase_business,
                        controller: _nome,
                        validator: _obrigatorio,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Parceira',
                        hint: 'Nome da entidade parceira',
                        icone: LucideIcons.handshake,
                        controller: _parceira,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Sigla',
                        hint: 'Ex: GRL',
                        icone: LucideIcons.badge_info,
                        controller: _sigla,
                        maxLength: 30,
                      ),
                      const SizedBox(height: 18),
                      SeletorLogomarca(
                        urlAtual: _logomarca,
                        aoAlterar: (url) => setState(() => _logomarca = url),
                        repositorioCatalogo: widget.repositorioCatalogo,
                        urlBase: widget.urlBase,
                      ),
                      const SizedBox(height: 28),
                      BarraAcoesFormulario(
                        textoPrimario: _viewModel.carregando
                            ? 'Salvando...'
                            : widget.edicao
                            ? 'Salvar Projeto'
                            : 'Criar Projeto',
                        onSalvar: _viewModel.carregando ? null : _salvar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

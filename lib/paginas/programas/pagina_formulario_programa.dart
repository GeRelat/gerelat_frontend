import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programa_form_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioPrograma extends StatefulWidget {
  final bool edicao;
  final int? programaId;
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final SessaoViewModel sessaoViewModel;

  const PaginaFormularioPrograma({
    super.key,
    this.edicao = false,
    this.programaId,
    required this.repositorioCatalogo,
    required this.urlBase,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaFormularioPrograma> createState() =>
      _PaginaFormularioProgramaState();
}

class _PaginaFormularioProgramaState extends State<PaginaFormularioPrograma> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _leiCriacao = TextEditingController();
  final _convenio = TextEditingController();
  final _rodape = TextEditingController();
  String _logomarca = '';
  late final ProgramaFormViewModel _viewModel;
  int? _clienteId;

  @override
  void initState() {
    super.initState();
    final repositorio = widget.repositorioCatalogo;
    _viewModel = ProgramaFormViewModel(repositorio, repositorio);
    final programaId = widget.programaId;
    _clienteId = widget.sessaoViewModel.clienteAtivoId;
    if (widget.edicao && programaId != null) {
      _viewModel
          .carregar(
            programaId,
            clienteAtivoId: widget.sessaoViewModel.clienteAtivoId,
          )
          .then((_) {
            final programa = _viewModel.programa;
            if (!mounted || programa == null) return;
            _nome.text = programa.nome;
            _leiCriacao.text = programa.leiCriacao;
            _convenio.text = programa.convenioDados;
            _rodape.text = programa.rodape;
            setState(() {
              _logomarca = programa.logomarca;
              if (programa.clienteId != null) {
                _clienteId = programa.clienteId;
              }
            });
          });
    } else {
      _viewModel.carregarClientes(
        clienteAtivoId: widget.sessaoViewModel.clienteAtivoId,
      );
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _leiCriacao.dispose();
    _convenio.dispose();
    _rodape.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final sucesso = await _viewModel.salvar(
      programaId: widget.programaId,
      nome: _nome.text.trim(),
      leiCriacao: _leiCriacao.text.trim(),
      convenioDados: _convenio.text.trim(),
      rodape: _rodape.text.trim(),
      logomarca: _logomarca,
      clienteId: _clienteId,
    );
    if (!mounted) return;
    if (sucesso) {
      context.pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O título não depende de `_viewModel` — é passado como `child`.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child!,
              const SizedBox(height: 24),
              CartaoConteudo(
                child: Column(
                  children: [
                    CampoFormulario(
                      label: 'Nome do Programa',
                      hint: 'Ex: Programa de Inovação Institucional',
                      icone: LucideIcons.folder_kanban,
                      controller: _nome,
                      validator: _obrigatorio,
                      maxLength: 150,
                    ),
                    const SizedBox(height: 18),
                    CampoSelecao(
                      label: 'Cliente',
                      valor: _clienteId,
                      itens: _viewModel.clientes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _clienteId = value),
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 18),
                    CampoFormulario(
                      label: 'Lei de Criação',
                      hint: 'Ex: Lei Municipal nº 123/2026',
                      icone: LucideIcons.landmark,
                      controller: _leiCriacao,
                      validator: _obrigatorio,
                      maxLength: 150,
                    ),
                    const SizedBox(height: 18),
                    CampoFormulario(
                      label: 'Dados do Convênio',
                      hint: 'Informe o convênio relacionado',
                      icone: LucideIcons.handshake,
                      controller: _convenio,
                      validator: _obrigatorio,
                      maxLength: 150,
                    ),
                    const SizedBox(height: 18),
                    SeletorLogomarca(
                      urlAtual: _logomarca,
                      aoAlterar: (url) => setState(() => _logomarca = url),
                      repositorioCatalogo: widget.repositorioCatalogo,
                      urlBase: widget.urlBase,
                      escopo:
                          widget.edicao && widget.programaId != null
                              ? NivelEscopo.programa
                              : NivelEscopo.cliente,
                      escopoId:
                          (widget.edicao && widget.programaId != null)
                              ? widget.programaId
                              : (_clienteId ??
                                  widget.sessaoViewModel.clienteAtivoId),
                    ),
                    const SizedBox(height: 18),
                    CampoFormulario(
                      label: 'Rodapé',
                      hint: 'Texto opcional usado nos documentos',
                      icone: LucideIcons.file_text,
                      controller: _rodape,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    BarraAcoesFormulario(
                      textoPrimario: _viewModel.carregando
                          ? 'Salvando...'
                          : widget.edicao
                          ? 'Salvar Programa'
                          : 'Criar Programa',
                      onSalvar: _viewModel.carregando ? null : _salvar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      child: Text(
        'Cadastrar programa institucional',
        style: Tipografia.headlineMedium.copyWith(color: Cores.textoPrincipal),
      ),
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

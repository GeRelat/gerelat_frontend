import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programa_form_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioPrograma extends StatefulWidget {
  final bool edicao;
  final int? programaId;

  const PaginaFormularioPrograma({
    super.key,
    this.edicao = false,
    this.programaId,
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
  final _logomarca = TextEditingController();
  late final ProgramaFormViewModel _viewModel;
  int? _clienteId;

  @override
  void initState() {
    super.initState();
    final repositorio = DependenciasApp.instancia.repositorioCatalogo;
    _viewModel = ProgramaFormViewModel(repositorio, repositorio);
    final programaId = widget.programaId;
    if (widget.edicao && programaId != null) {
      _viewModel.carregar(programaId).then((_) {
        final programa = _viewModel.programa;
        if (!mounted || programa == null) return;
        _nome.text = programa.nome;
        _leiCriacao.text = programa.leiCriacao;
        _convenio.text = programa.convenioDados;
        _rodape.text = programa.rodape;
        _logomarca.text = programa.logomarca;
        setState(() => _clienteId = programa.clienteId);
      });
    } else {
      _viewModel.carregarClientes();
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _leiCriacao.dispose();
    _convenio.dispose();
    _rodape.dispose();
    _logomarca.dispose();
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
      logomarca: _logomarca.text.trim(),
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cadastrar programa institucional',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
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
                    ),
                    const SizedBox(height: 18),
                    CampoSelecao(
                      label: 'Cliente (opcional)',
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
                    ),
                    const SizedBox(height: 18),
                    CampoFormulario(
                      label: 'Dados do Convênio',
                      hint: 'Informe o convênio relacionado',
                      icone: LucideIcons.handshake,
                      controller: _convenio,
                      validator: _obrigatorio,
                    ),
                    const SizedBox(height: 18),
                    CampoFormulario(
                      label: 'Logomarca',
                      hint: 'URL ou caminho da logomarca do programa',
                      icone: LucideIcons.image,
                      controller: _logomarca,
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
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programa_form_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaFormularioPrograma extends StatefulWidget {
  final bool edicao;

  const PaginaFormularioPrograma({super.key, this.edicao = false});

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
  late final ProgramaFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProgramaFormViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    );
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
      nome: _nome.text.trim(),
      leiCriacao: _leiCriacao.text.trim(),
      convenioDados: _convenio.text.trim(),
      rodape: _rodape.text.trim(),
    );
    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      secaoAtual: SecaoApp.programas,
      titulo: widget.edicao ? 'Editar Programa' : 'Novo Programa',
      dicaPesquisa: 'Pesquisar programas...',
      child: AnimatedBuilder(
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
      ),
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

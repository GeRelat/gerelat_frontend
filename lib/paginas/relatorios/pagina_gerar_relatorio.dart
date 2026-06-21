import 'package:flutter/material.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaGerarRelatorio extends StatefulWidget {
  const PaginaGerarRelatorio({super.key});

  @override
  State<PaginaGerarRelatorio> createState() => _PaginaGerarRelatorioState();
}

class _PaginaGerarRelatorioState extends State<PaginaGerarRelatorio> {
  final _formKey = GlobalKey<FormState>();
  late final GerarRelatorioViewModel _viewModel;
  int? _eventoId;
  int? _templateId;

  @override
  void initState() {
    super.initState();
    _viewModel = GerarRelatorioViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )..carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _gerar() async {
    if (!_formKey.currentState!.validate() || _templateId == null) return;
    final sucesso = await _viewModel.gerar(
      templateId: _templateId!,
      eventoId: _eventoId,
    );
    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao gerar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      secaoAtual: SecaoApp.relatorios,
      titulo: 'Gerar Relatório',
      dicaPesquisa: 'Pesquisar relatórios...',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.carregando && _viewModel.templates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novo relatório',
                    style: Tipografia.headlineMedium.copyWith(
                      color: Cores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CartaoConteudo(
                    child: Column(
                      children: [
                        CampoSelecao(
                          label: 'Evento vinculado',
                          valor: _eventoId,
                          itens: _viewModel.eventos
                              .where((evento) => evento.id != null)
                              .map(
                                (evento) => DropdownMenuItem(
                                  value: evento.id,
                                  child: Text(evento.nome),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _eventoId = value),
                        ),
                        const SizedBox(height: 18),
                        CampoSelecao(
                          label: 'Template',
                          valor: _templateId,
                          itens: _viewModel.templates
                              .where((template) => template.id != null)
                              .map(
                                (template) => DropdownMenuItem(
                                  value: template.id,
                                  child: Text(template.nome),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _templateId = value),
                        ),
                        const SizedBox(height: 28),
                        BarraAcoesFormulario(
                          textoPrimario: _viewModel.carregando
                              ? 'Gerando...'
                              : 'Gerar Documento',
                          onSalvar: _viewModel.carregando ? null : _gerar,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

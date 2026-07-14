import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

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
      context.pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao gerar.')),
    );
  }

  Future<void> _previsualizar() async {
    if (_templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um template para pré-visualizar.')),
      );
      return;
    }

    final texto = await _viewModel.previsualizar(
      templateId: _templateId!,
      eventoId: _eventoId,
    );
    if (!mounted) return;

    if (texto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.mensagemErro ?? 'Erro ao pré-visualizar o template.',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pré-visualização do relatório'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Text(
              texto.isEmpty ? '(Documento sem conteúdo textual.)' : texto,
              style: Tipografia.bodyMedium.copyWith(color: Cores.textoPrincipal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
                        label: 'Evento vinculado (opcional)',
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
                        onChanged: (value) => setState(() => _eventoId = value),
                        // `eventoId` é nullable em toda a cadeia (ViewModel,
                        // entidade, repositório) — o relatório pode ser
                        // gerado sem vínculo a um evento. Sem este
                        // `validator`, o padrão do CampoSelecao exige seleção
                        // e tornava esse fluxo inalcançável pela UI.
                        validator: (_) => null,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _viewModel.carregando || _templateId == null
                                ? null
                                : _previsualizar,
                            icon: const Icon(LucideIcons.eye, size: 18),
                            label: const Text('Pré-visualizar'),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
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
    );
  }
}

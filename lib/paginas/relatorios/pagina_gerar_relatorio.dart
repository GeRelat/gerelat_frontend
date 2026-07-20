import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_editor_relatorio.dart';
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
  final _nome = TextEditingController();
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
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Eventos elegíveis para o template selecionado: apenas os do mesmo projeto
  /// do template (as variáveis são resolvidas pelo projeto do evento). Sem
  /// template selecionado, retorna vazio.
  Iterable<Evento> _eventosDoTemplate() {
    if (_templateId == null) return const [];
    int? projetoId;
    for (final t in _viewModel.templates) {
      if (t.id == _templateId) {
        projetoId = t.projetoId;
        break;
      }
    }
    return _viewModel.eventos.where(
      (evento) =>
          evento.id != null &&
          (projetoId == null || evento.projetoId == projetoId),
    );
  }

  Future<void> _previsualizarEEditar() async {
    if (!_formKey.currentState!.validate() || _templateId == null) return;

    final documento = await _viewModel.obterDocumentoPreview(
      templateId: _templateId!,
      eventoId: _eventoId,
    );
    if (!mounted) return;

    if (documento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.mensagemErro ?? 'Erro ao pré-visualizar o template.',
          ),
        ),
      );
      return;
    }

    final gerado = await context.push<bool>(
      '/relatorios/editor',
      extra: ArgumentosEditorRelatorio(
        templateId: _templateId!,
        eventoId: _eventoId,
        nome: _nome.text.trim().isEmpty ? null : _nome.text.trim(),
        documento: documento,
      ),
    );
    if (!mounted) return;
    if (gerado == true) context.pop(true);
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
                const SizedBox(height: 6),
                Text(
                  'Selecione o template e o evento. Você verá o documento com as '
                  'variáveis preenchidas e poderá editar os blocos manuais antes '
                  'de gerar o relatório definitivo.',
                  style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
                ),
                const SizedBox(height: 24),
                CartaoConteudo(
                  child: Column(
                    children: [
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
                        onChanged: (value) => setState(() {
                          _templateId = value;
                          // Ao trocar de template, o evento anterior pode ser de
                          // outro projeto — zera a seleção.
                          _eventoId = null;
                        }),
                      ),
                      const SizedBox(height: 18),
                      CampoSelecao(
                        label: 'Evento vinculado (opcional)',
                        valor: _eventoId,
                        itens: _eventosDoTemplate()
                            .map(
                              (evento) => DropdownMenuItem(
                                value: evento.id,
                                child: Text(evento.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _eventoId = value),
                        // `eventoId` é nullable em toda a cadeia — o relatório
                        // pode ser gerado sem vínculo a um evento.
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Nome do relatório (opcional)',
                        hint: 'Ex: Relatório da Oficina de Informática',
                        icone: LucideIcons.file_text,
                        controller: _nome,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          BotaoPrimario(
                            texto: _viewModel.carregando
                                ? 'Carregando...'
                                : 'Pré-visualizar e editar',
                            icone: LucideIcons.eye,
                            onPressed:
                                _viewModel.carregando || _templateId == null
                                ? null
                                : _previsualizarEEditar,
                          ),
                        ],
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

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_editor_relatorio.dart';
import 'package:go_router/go_router.dart';

class PaginaGerarRelatorio extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaGerarRelatorio({super.key, required this.repositorioCatalogo});

  @override
  State<PaginaGerarRelatorio> createState() => _PaginaGerarRelatorioState();
}

class _PaginaGerarRelatorioState extends State<PaginaGerarRelatorio> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  late final GerarRelatorioViewModel _viewModel;
  int? _templateId;

  @override
  void initState() {
    super.initState();
    _viewModel = GerarRelatorioViewModel(widget.repositorioCatalogo)
      ..carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _previsualizarEEditar() async {
    if (!_formKey.currentState!.validate() || _templateId == null) return;

    final documento = await _viewModel.obterDocumentoPreview();
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
        clienteId: _viewModel.clienteId,
        programaId: _viewModel.programaId,
        projetoId: _viewModel.projetoId,
        eventoId: _viewModel.eventoId,
        nome: _nome.text.trim().isEmpty ? null : _nome.text.trim(),
        documento: documento,
      ),
    );
    if (!mounted) return;
    if (gerado == true) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // O título é a única parte que não depende de `_viewModel`.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando && _viewModel.templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final podeGerar =
            _templateId != null &&
            _viewModel.escopoCompleto &&
            !_viewModel.carregando;
        return SingleChildScrollView(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CampoSelecao(
                        label: 'Template',
                        valor: _templateId,
                        itens: _viewModel.templates
                            .where((template) => template.id != null)
                            .map(
                              (template) => DropdownMenuItem(
                                value: template.id,
                                child: Text(
                                  '${template.nome} (${template.nivel.rotulo})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _templateId = value);
                          _viewModel.selecionarTemplate(value);
                        },
                      ),
                      if (_templateId != null) ...[
                        const SizedBox(height: 18),
                        ..._seletoresDeEscopo(),
                        const SizedBox(height: 18),
                        _painelAvisos(),
                      ],
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
                            onPressed: podeGerar
                                ? _previsualizarEEditar
                                : null,
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
            'Selecione o template e a que instância ele se aplica. Você verá o '
            'documento com as variáveis preenchidas e poderá editar os blocos '
            'manuais antes de gerar o relatório definitivo.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }

  /// Um seletor por nível abaixo do escopo do template, até o nível que as
  /// variáveis do documento exigem. Se o template só usa variáveis do próprio
  /// escopo, nenhum seletor aparece.
  List<Widget> _seletoresDeEscopo() {
    final template = _viewModel.template;
    if (template == null) return const [];

    final niveis = _viewModel.niveisASelecionar;
    if (niveis.isEmpty) {
      return [
        _painelInformativo(
          icone: LucideIcons.circle_check,
          cor: Cores.verdeSucesso,
          texto:
              'Este template usa apenas variáveis de ${template.nivel.rotulo.toLowerCase()}. '
              'Nada mais precisa ser escolhido.',
        ),
      ];
    }

    return [
      for (final nivel in niveis) ...[
        CampoSelecao(
          label: nivel.rotulo,
          valor: _valorDe(nivel),
          itens: _viewModel
              .opcoesDe(nivel)
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.nome)),
              )
              .toList(),
          onChanged: (value) => _viewModel.definirEscopo(nivel, value),
          // Validado pelo painel de avisos + botão desabilitado, não pelo
          // Form: o `CampoSelecao` só é obrigatório quando é o nível exigido,
          // e níveis intermediários podem ficar vazios.
          validator: (_) => null,
        ),
        const SizedBox(height: 18),
      ],
    ];
  }

  int? _valorDe(NivelAplicacao nivel) => switch (nivel) {
    NivelAplicacao.cliente => _viewModel.clienteId,
    NivelAplicacao.programa => _viewModel.programaId,
    NivelAplicacao.projeto => _viewModel.projetoId,
    NivelAplicacao.evento => _viewModel.eventoId,
  };

  /// Tudo que o usuário deveria saber antes de gerar: escopo faltando,
  /// variáveis sem definição, obrigatórias em uso e blocos manuais.
  Widget _painelAvisos() {
    final avisos = <Widget>[];

    final escopoIncompleto = _viewModel.mensagemEscopoIncompleto;
    if (escopoIncompleto != null) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.triangle_alert,
          cor: Cores.ambarAlerta,
          texto: escopoIncompleto,
        ),
      );
    }

    if (_viewModel.refsNaoContempladas.isNotEmpty) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.circle_alert,
          cor: Cores.ambarAlerta,
          titulo: 'Variáveis não contempladas',
          texto:
              'O template referencia variáveis que não existem neste escopo. '
              'Elas sairão no documento como o próprio nome entre colchetes. '
              'Cadastre-as em "Definições de variáveis" ou remova-as do template:\n'
              '${_viewModel.refsNaoContempladas.map((ref) => '• $ref').join('\n')}',
        ),
      );
    }

    final obrigatorias = _viewModel.obrigatoriasUsadas;
    if (obrigatorias.isNotEmpty) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.list_checks,
          cor: Cores.azulAcao,
          titulo: 'Variáveis obrigatórias em uso',
          texto:
              'Confira em "Valores de variáveis" se estas já estão preenchidas '
              'para a instância escolhida:\n'
              '${obrigatorias.map((v) => '• ${v.referencia} (${v.nivelAplicacao.rotulo})').join('\n')}',
        ),
      );
    }

    if (_viewModel.blocosManuais.isNotEmpty) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.square_pen,
          cor: Cores.azulAcao,
          texto:
              '${_viewModel.blocosManuais.length} bloco(s) de texto livre para '
              'preencher na pré-visualização: '
              '${_viewModel.blocosManuais.join(', ')}.',
        ),
      );
    }

    if (avisos.isEmpty) {
      return _painelInformativo(
        icone: LucideIcons.circle_check,
        cor: Cores.verdeSucesso,
        texto: 'Todas as variáveis do template serão resolvidas.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final aviso in avisos)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: aviso),
      ],
    );
  }

  Widget _painelInformativo({
    required IconData icone,
    required Color cor,
    String? titulo,
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) ...[
                  Text(
                    titulo,
                    style: Tipografia.labelLarge.copyWith(color: cor),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  texto,
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                    height: 1.45,
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

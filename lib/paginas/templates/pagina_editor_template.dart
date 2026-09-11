import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/editor_template_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_variaveis.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Editor de conteúdo do template: painel lateral com as variáveis do projeto
/// (inseríveis como nós) + blocos manuais, e o editor ProseMirror embarcado.
class PaginaEditorTemplate extends StatefulWidget {
  final int templateId;
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaEditorTemplate({
    super.key,
    required this.templateId,
    required this.repositorioCatalogo,
  });

  @override
  State<PaginaEditorTemplate> createState() => _PaginaEditorTemplateState();
}

class _PaginaEditorTemplateState extends State<PaginaEditorTemplate> {
  late final EditorTemplateViewModel _viewModel;
  final EditorProseMirrorController _controller = EditorProseMirrorController();
  bool _salvouAlgumaVez = false;
  String _temaEditor = 'light';
  Map<String, dynamic>? _documentoAutoria;

  // O editor roda num `<iframe>` (ver `EditorProseMirror`). Se navegarmos pra
  // fora enquanto ele ainda está montado, o Flutter tenta compor a transição
  // de saída da rota com o platform view ainda vivo e quebra com "Cannot get
  // renderObject of inactive element". Por isso `_voltar()` desmonta o editor
  // (via este flag) e espera o frame terminar antes de fazer `context.pop`.
  bool _saindo = false;

  @override
  void initState() {
    super.initState();
    _carregarTemaEditor();
    _viewModel = EditorTemplateViewModel(widget.repositorioCatalogo)
      ..carregar(widget.templateId);
  }

  Future<void> _carregarTemaEditor() async {
    final prefs = await SharedPreferences.getInstance();
    final escuro = prefs.getBool('editor_tema_escuro') ?? false;
    if (mounted) {
      setState(() {
        _temaEditor = escuro ? 'dark' : 'light';
      });
    }
  }

  Future<void> _salvarTemaEditor(String tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('editor_tema_escuro', tema == 'dark');
    if (mounted) {
      setState(() {
        _temaEditor = tema;
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _inserirVariavel(VariavelDisponivel variavel) {
    switch (variavel.tipo) {
      case TipoCampo.texto:
        _controller.inserirVarTexto(variavel.referencia);
      case TipoCampo.textoRico:
        _controller.inserirVarRichtext(variavel.referencia);
      case TipoCampo.imagem:
        _controller.inserirVarImagem(variavel.referencia);
      case TipoCampo.tabela:
        // Sem colunas: na autoria só existe o schema da variável, não um
        // valor. O backend também ignora o `columns` do nó do template —
        // `converters._block_nodes_for_table_ref` monta as colunas a partir do
        // valor resolvido e só aproveita o `caption` do nó.
        _controller.inserirVarTabela(variavel.referencia, colunas: const []);
    }
  }

  Future<void> _inserirBlocoManual() async {
    final label = await _pedirTexto(
      titulo: 'Novo bloco manual (parágrafo)',
      hint: 'Ex: Observações da equipe',
    );
    if (label == null) return;
    _controller.inserirBloco(label.trim().isEmpty ? 'bloco' : label.trim());
  }

  Future<void> _inserirBlocoManualEmLinha() async {
    final label = await _pedirTexto(
      titulo: 'Novo bloco manual em linha',
      hint: 'Ex: Fiscal responsável',
    );
    if (label == null) return;
    _controller.inserirBlocoInline(
      label.trim().isEmpty ? 'campo livre' : label.trim(),
    );
  }

  Future<void> _alternarPrevisualizacao() async {
    if (_viewModel.modoPrevisualizacao) {
      _viewModel.definirModoPrevisualizacao(false);
      if (_documentoAutoria != null) {
        _controller.definirDocumento(_documentoAutoria!, modo: 'template');
      }
      return;
    }

    final docAtual = await _controller.obterDocumento();
    if (!mounted) return;
    if (docAtual.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O editor ainda está carregando.')),
      );
      return;
    }

    _documentoAutoria = docAtual;
    final docResolvido = await _viewModel.resolverPrevisualizacao(
      widget.templateId,
      docAtual,
    );
    if (!mounted) return;

    if (docResolvido != null) {
      _viewModel.definirModoPrevisualizacao(true);
      _controller.definirDocumento(docResolvido, modo: 'report');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.mensagemErro ??
                'Não foi possível pré-visualizar as variáveis deste template.',
          ),
        ),
      );
    }
  }

  Future<String?> _pedirTexto({
    required String titulo,
    required String hint,
  }) async {
    final controlador = TextEditingController();
    // O editor roda num `<iframe>`, que captura o clique do mouse mesmo com
    // um `Dialog` do Flutter desenhado visualmente por cima dele. Desligamos
    // a interatividade do iframe enquanto o diálogo estiver aberto para que
    // os botões "Cancelar"/"Inserir" recebam o clique de verdade.
    _controller.definirInteratividade(false);
    try {
      final resultado = await showDialog<String>(
        context: context,
        // Usa `Navigator.of(dialogContext).pop` (não `context.pop` do go_router):
        // dentro de um `showDialog`, `context.pop` fecharia a rota da página do
        // editor inteira em vez do diálogo, desmontando este widget e disparando
        // "_dependents.isEmpty is not true".
        builder: (dialogContext) => AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controlador,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controlador.text),
              child: const Text('Inserir'),
            ),
          ],
        ),
      );
      return resultado;
    } finally {
      controlador.dispose();
      if (mounted) _controller.definirInteratividade(true);
    }
  }

  Future<void> _salvar() async {
    final Map<String, dynamic> documento;
    if (_viewModel.modoPrevisualizacao && _documentoAutoria != null) {
      documento = _documentoAutoria!;
    } else {
      documento = await _controller.obterDocumento();
    }
    if (!mounted) return;
    if (documento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O editor ainda está carregando.')),
      );
      return;
    }
    _documentoAutoria = documento;
    final ok = await _viewModel.salvar(widget.templateId, documento);
    if (!mounted) return;
    if (ok) {
      _salvouAlgumaVez = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Template salvo.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.mensagemErro ?? 'Erro ao salvar o template.',
          ),
        ),
      );
    }
  }

  /// Desmonta o editor (o `<iframe>`) e só então volta para a tela anterior.
  ///
  /// Se navegássemos direto (`context.pop`) com o editor ainda montado, o
  /// Flutter tentaria compor a animação de transição de saída com o platform
  /// view ainda vivo e quebraria com "Cannot get renderObject of inactive
  /// element" no meio da transição.
  Future<void> _voltar() async {
    setState(() => _saindo = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    context.pop(_salvouAlgumaVez);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final template = _viewModel.template;
        return Scaffold(
          backgroundColor: Cores.fundoSecao,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.arrow_left),
              tooltip: 'Voltar',
              onPressed: _voltar,
            ),
            title: Text(
              template == null
                  ? 'Editor de template'
                  : 'Editor — ${template.nome}',
            ),
            actions: [
              Tooltip(
                message: _viewModel.modoPrevisualizacao
                    ? 'Voltar para o modo de edição'
                    : 'Pré-visualizar variáveis resolvidas no texto',
                child: IconButton(
                  icon: Icon(
                    _viewModel.modoPrevisualizacao
                        ? LucideIcons.eye_off
                        : LucideIcons.eye,
                    color: _viewModel.modoPrevisualizacao
                        ? Cores.azulAcao
                        : null,
                  ),
                  onPressed: _viewModel.carregandoPrevisualizacao ||
                          _viewModel.salvando
                      ? null
                      : _alternarPrevisualizacao,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: FilledButton.icon(
                  onPressed: _viewModel.salvando ? null : _salvar,
                  icon: const Icon(LucideIcons.save, size: 18),
                  label: Text(_viewModel.salvando ? 'Salvando...' : 'Salvar'),
                ),
              ),
            ],
          ),
          body: _corpo(),
        );
      },
    );
  }

  Widget _corpo() {
    if (_saindo) {
      return const SizedBox.shrink();
    }
    if (_viewModel.carregando && _viewModel.documentoInicial == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.mensagemErro != null &&
        _viewModel.documentoInicial == null) {
      return Center(
        child: Text(
          _viewModel.mensagemErro!,
          style: Tipografia.bodyMedium.copyWith(color: Cores.vermelhoErro),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: PainelVariaveis(
            variaveis: _viewModel.variaveis,
            aoInserir: _inserirVariavel,
            barraFormatacao: _barraFormatacao(),
            aoInserirBlocoManual: _inserirBlocoManual,
            aoInserirBlocoInline: _inserirBlocoManualEmLinha,
            modoPrevisualizacao: _viewModel.modoPrevisualizacao,
            carregandoPrevisualizacao: _viewModel.carregandoPrevisualizacao,
            aoAlternarPrevisualizacao: _alternarPrevisualizacao,
          ),
        ),
        const VerticalDivider(width: 1, color: Cores.bordaSutil),
        Expanded(
          child: Container(
            color: Cores.branco,
            child: Column(
              children: [
                if (_viewModel.modoPrevisualizacao)
                  Container(
                    color: Cores.azulAcao.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.eye,
                          size: 16,
                          color: Cores.azulAcao,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Modo de pré-visualização ativo: exibindo variáveis resolvidas com dados reais deste escopo.',
                            style: Tipografia.bodySmall.copyWith(
                              color: Cores.azulAcao,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _alternarPrevisualizacao,
                          icon: const Icon(LucideIcons.pencil, size: 14),
                          label: const Text('Voltar a editar'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Cores.azulAcao,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: EditorProseMirror(
                    controller: _controller,
                    documentoInicial: _viewModel.documentoInicial,
                    modo: 'template',
                    temaInicial: _temaEditor,
                    aoMudarTema: _salvarTemaEditor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _barraFormatacao() {
    Widget botao(String rotulo, VoidCallback onTap, {String? tooltip}) {
      return Tooltip(
        message: tooltip ?? rotulo,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
          child: Text(rotulo),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        botao('B', _controller.negrito, tooltip: 'Negrito'),
        botao('I', _controller.italico, tooltip: 'Itálico'),
        botao('U', _controller.sublinhado, tooltip: 'Sublinhado'),
        botao('H1', () => _controller.titulo(1)),
        botao('H2', () => _controller.titulo(2)),
        botao('H3', () => _controller.titulo(3)),
        botao('¶', _controller.paragrafo, tooltip: 'Parágrafo'),
        botao('↩', _controller.desfazer, tooltip: 'Desfazer'),
        botao('↪', _controller.refazer, tooltip: 'Refazer'),
      ],
    );
  }

}

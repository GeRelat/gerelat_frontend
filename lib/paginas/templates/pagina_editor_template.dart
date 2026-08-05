import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/editor_template_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

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

  // O editor roda num `<iframe>` (ver `EditorProseMirror`). Se navegarmos pra
  // fora enquanto ele ainda está montado, o Flutter tenta compor a transição
  // de saída da rota com o platform view ainda vivo e quebra com "Cannot get
  // renderObject of inactive element". Por isso `_voltar()` desmonta o editor
  // (via este flag) e espera o frame terminar antes de fazer `context.pop`.
  bool _saindo = false;

  @override
  void initState() {
    super.initState();
    _viewModel = EditorTemplateViewModel(widget.repositorioCatalogo)
      ..carregar(widget.templateId);
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
      titulo: 'Novo bloco manual',
      hint: 'Ex: Observações da equipe',
    );
    if (label == null) return;
    _controller.inserirBloco(label.trim().isEmpty ? 'bloco' : label.trim());
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
    final documento = await _controller.obterDocumento();
    if (!mounted) return;
    if (documento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O editor ainda está carregando.')),
      );
      return;
    }
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
              Padding(
                padding: const EdgeInsets.only(right: 12),
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
        SizedBox(width: 300, child: _painelLateral()),
        const VerticalDivider(width: 1, color: Cores.bordaSutil),
        Expanded(
          child: Container(
            color: Cores.branco,
            child: EditorProseMirror(
              controller: _controller,
              documentoInicial: _viewModel.documentoInicial,
              modo: 'template',
            ),
          ),
        ),
      ],
    );
  }

  Widget _painelLateral() {
    return Container(
      color: Cores.branco,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tituloSecao('Formatação'),
          const SizedBox(height: 8),
          _barraFormatacao(),
          const SizedBox(height: 20),
          _tituloSecao('Variáveis disponíveis'),
          const SizedBox(height: 4),
          Text(
            'Insira uma variável para que ela seja preenchida automaticamente '
            'com os dados do banco na geração do relatório. A etiqueta indica '
            'de qual nível vem o valor — usar uma variável de evento, por '
            'exemplo, obrigará a escolher um evento ao gerar o relatório.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
          const SizedBox(height: 12),
          if (_viewModel.variaveis.isEmpty)
            Text(
              'Nenhuma variável disponível para o escopo deste template.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            )
          else ...[
            ..._grupoVariaveis(
              'Customizadas',
              _viewModel.variaveisCustomizadas,
              vazio: 'Nenhuma variável cadastrada para este escopo.',
            ),
            ..._grupoVariaveis(
              'Campos do sistema',
              _viewModel.variaveisDeSistema,
              vazio: '',
            ),
          ],
          const SizedBox(height: 20),
          _tituloSecao('Blocos manuais'),
          const SizedBox(height: 4),
          Text(
            'Um bloco de texto livre, sem variável de banco, para ser '
            'preenchido/editado manualmente na geração do relatório.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _inserirBlocoManual,
            icon: const Icon(LucideIcons.square_pen, size: 18),
            label: const Text('Inserir bloco manual'),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Text(
      texto.toUpperCase(),
      style: Tipografia.labelLarge.copyWith(
        color: Cores.cinzaEscuro,
        letterSpacing: 0.6,
      ),
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

  /// Um subtítulo seguido dos itens do grupo. Devolve lista para poder ser
  /// espalhada no `ListView` do painel, e some quando o grupo está vazio e
  /// não há mensagem para mostrar.
  List<Widget> _grupoVariaveis(
    String titulo,
    List<VariavelDisponivel> variaveis, {
    required String vazio,
  }) {
    if (variaveis.isEmpty && vazio.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Text(
          titulo,
          style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro),
        ),
      ),
      if (variaveis.isEmpty)
        Text(vazio, style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio))
      else
        ...variaveis.map(_itemVariavel),
    ];
  }

  Widget _itemVariavel(VariavelDisponivel variavel) {
    final (icone, cor) = switch (variavel.tipo) {
      TipoCampo.texto => (LucideIcons.type, Cores.azulAcao),
      TipoCampo.textoRico => (LucideIcons.text_quote, Cores.verdeSucesso),
      TipoCampo.imagem => (LucideIcons.image, Cores.azulAcao),
      TipoCampo.tabela => (LucideIcons.table, Cores.verdeSucesso),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _inserirVariavel(variavel),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Cores.fundoSecao,
            border: Border.all(color: Cores.bordaSutil),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icone, size: 18, color: cor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variavel.referencia,
                      style: Tipografia.labelLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                    Text(
                      '${variavel.tipo.rotulo} · ${variavel.nivelAplicacao.rotulo}',
                      style: Tipografia.bodySmall.copyWith(
                        color: Cores.cinzaMedio,
                      ),
                    ),
                    if (variavel.descricao.isNotEmpty &&
                        variavel.descricao != variavel.referencia)
                      Text(
                        variavel.descricao,
                        style: Tipografia.bodySmall.copyWith(
                          color: Cores.cinzaMedio,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(LucideIcons.plus, size: 16, color: Cores.cinzaMedio),
            ],
          ),
        ),
      ),
    );
  }
}

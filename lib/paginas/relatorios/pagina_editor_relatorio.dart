import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parâmetros passados de [PaginaGerarRelatorio] para o editor de relatório.
class ArgumentosEditorRelatorio {
  final int templateId;

  /// Cadeia de escopo escolhida na tela anterior. É o que permite ao backend
  /// resolver as variáveis de cada nível — e o que ele valida contra os gaps
  /// do documento antes de enfileirar a geração.
  final int? clienteId;
  final int? programaId;
  final int? projetoId;
  final int? eventoId;
  final String? nome;
  final Map<String, dynamic> documento;

  const ArgumentosEditorRelatorio({
    required this.templateId,
    this.clienteId,
    this.programaId,
    this.projetoId,
    required this.eventoId,
    required this.nome,
    required this.documento,
  });
}

/// Preview editável do relatório: mostra o documento com as variáveis do banco
/// já resolvidas (bloqueadas) e permite editar apenas os blocos manuais
/// (`custom_text`) antes de gerar o `.docx` definitivo.
class PaginaEditorRelatorio extends StatefulWidget {
  final ArgumentosEditorRelatorio argumentos;
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaEditorRelatorio({
    super.key,
    required this.argumentos,
    required this.repositorioCatalogo,
  });

  @override
  State<PaginaEditorRelatorio> createState() => _PaginaEditorRelatorioState();
}

class _PaginaEditorRelatorioState extends State<PaginaEditorRelatorio> {
  final EditorProseMirrorController _controller = EditorProseMirrorController();
  late final RepositorioRelatorios _relatoriosRepositorio;
  bool _gerando = false;
  String _temaEditor = 'light';

  @override
  void initState() {
    super.initState();
    _carregarTemaEditor();
    _relatoriosRepositorio = widget.repositorioCatalogo;
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

  Future<void> _gerar() async {
    final documento = await _controller.obterDocumento();
    if (!mounted) return;
    if (documento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O editor ainda está carregando.')),
      );
      return;
    }

    setState(() => _gerando = true);
    try {
      await _relatoriosRepositorio.gerarRelatorioComDocumento(
        templateId: widget.argumentos.templateId,
        clienteId: widget.argumentos.clienteId,
        programaId: widget.argumentos.programaId,
        projetoId: widget.argumentos.projetoId,
        eventoId: widget.argumentos.eventoId,
        documentoJson: documento,
        nome: widget.argumentos.nome,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório gerado com sucesso.')),
      );
      context.pop(true);
    } catch (erro) {
      if (!mounted) return;
      setState(() => _gerando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar o relatório: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoSecao,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          tooltip: 'Voltar',
          onPressed: () => context.pop(false),
        ),
        title: const Text('Pré-visualização do relatório'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _gerando ? null : _gerar,
              icon: const Icon(LucideIcons.circle_check, size: 18),
              label: Text(_gerando ? 'Gerando...' : 'Gerar relatório'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _barra(),
          Expanded(
            child: Container(
              color: Cores.branco,
              child: EditorProseMirror(
                controller: _controller,
                documentoInicial: widget.argumentos.documento,
                modo: 'report',
                temaInicial: _temaEditor,
                aoMudarTema: _salvarTemaEditor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barra() {
    Widget botao(
      String rotulo,
      VoidCallback onTap, {
      String? tooltip,
      IconData? icone,
    }) {
      return Tooltip(
        message: tooltip ?? rotulo,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: icone != null
              ? Icon(icone, size: 16)
              : Text(
                  rotulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Cores.branco,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Os blocos manuais (destacados) são editáveis. As variáveis do '
              'banco estão bloqueadas. O cabeçalho com as logomarcas do cliente '
              'e da parceira é inserido automaticamente no documento final.',
              style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
            ),
          ),
          const SizedBox(width: 12),
          botao('B', _controller.negrito, tooltip: 'Negrito'),
          const SizedBox(width: 4),
          botao('I', _controller.italico, tooltip: 'Itálico'),
          const SizedBox(width: 4),
          botao('U', _controller.sublinhado, tooltip: 'Sublinhado'),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Cores.cinzaClaro),
          const SizedBox(width: 8),
          botao('H1', () => _controller.titulo(1), tooltip: 'Título 1'),
          const SizedBox(width: 4),
          botao('H2', () => _controller.titulo(2), tooltip: 'Título 2'),
          const SizedBox(width: 4),
          botao('H3', () => _controller.titulo(3), tooltip: 'Título 3'),
          const SizedBox(width: 4),
          botao('¶', _controller.paragrafo, tooltip: 'Parágrafo'),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Cores.cinzaClaro),
          const SizedBox(width: 8),
          botao(
            'Desfazer',
            _controller.desfazer,
            tooltip: 'Desfazer',
            icone: LucideIcons.undo,
          ),
          const SizedBox(width: 4),
          botao(
            'Refazer',
            _controller.refazer,
            tooltip: 'Refazer',
            icone: LucideIcons.redo,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Cores.cinzaClaro),
          const SizedBox(width: 8),
          Tooltip(
            message: _temaEditor == 'dark'
                ? 'Alternar para modo claro'
                : 'Alternar para modo escuro',
            child: IconButton(
              onPressed: () {
                final novoTema = _temaEditor == 'dark' ? 'light' : 'dark';
                _salvarTemaEditor(novoTema);
                _controller.definirTema(novoTema);
              },
              icon: Icon(
                _temaEditor == 'dark' ? LucideIcons.sun : LucideIcons.moon,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gerelat_frontend/nucleo/servicos/ponte_editor_prosemirror.dart';

/// Controla imperativamente um [EditorProseMirror]: inserir nós, formatar e
/// recuperar o documento atual. Uma instância é vinculada ao widget e
/// permanece utilizável enquanto o widget estiver montado.
class EditorProseMirrorController {
  PonteEditorProseMirror? _ponte;
  int _proximoId = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pendentes = {};

  /// True quando o editor já emitiu `EDITOR_READY`.
  bool get pronto => _pronto;
  bool _pronto = false;

  void _anexar(PonteEditorProseMirror ponte) => _ponte = ponte;

  void _aoReceberMensagem(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'DOC_RESULT':
        final id = msg['id']?.toString();
        final completer = id != null ? _pendentes.remove(id) : null;
        if (completer != null && !completer.isCompleted) {
          final doc = msg['doc'];
          completer.complete(
            doc is Map ? Map<String, dynamic>.from(doc) : <String, dynamic>{},
          );
        }
    }
  }

  // ── Inserção de nós ─────────────────────────────────────────────
  void inserirVarTexto(String ref) =>
      _ponte?.enviar({'type': 'INSERT_VAR_TEXT', 'ref': ref});

  void inserirVarRichtext(String ref) =>
      _ponte?.enviar({'type': 'INSERT_VAR_RICHTEXT', 'ref': ref});

  void inserirVarImagem(String ref, {String caption = ''}) => _ponte?.enviar({
    'type': 'INSERT_VAR_IMAGE',
    'ref': ref,
    'caption': caption,
  });

  void inserirVarTabela(
    String ref, {
    List<Map<String, dynamic>> colunas = const [],
    String caption = '',
  }) => _ponte?.enviar({
    'type': 'INSERT_VAR_TABLE',
    'ref': ref,
    'columns': colunas,
    'caption': caption,
  });

  void inserirBloco(String label) =>
      _ponte?.enviar({'type': 'INSERT_CUSTOM_TEXT', 'label': label});

  // ── Formatação ──────────────────────────────────────────────────
  void negrito() => _ponte?.enviar({'type': 'FORMAT_BOLD'});
  void italico() => _ponte?.enviar({'type': 'FORMAT_ITALIC'});
  void sublinhado() => _ponte?.enviar({'type': 'FORMAT_UNDERLINE'});
  void titulo(int nivel) =>
      _ponte?.enviar({'type': 'SET_HEADING', 'level': nivel});
  void paragrafo() => _ponte?.enviar({'type': 'SET_PARAGRAPH'});
  void desfazer() => _ponte?.enviar({'type': 'UNDO'});
  void refazer() => _ponte?.enviar({'type': 'REDO'});

  // ── Documento / modo ────────────────────────────────────────────
  void definirModo(String modo) =>
      _ponte?.enviar({'type': 'SET_MODE', 'mode': modo});

  void definirTema(String tema) =>
      _ponte?.enviar({'type': 'SET_THEME', 'theme': tema});

  void definirDocumento(Map<String, dynamic> doc, {String? modo}) =>
      _ponte?.enviar({'type': 'SET_DOC', 'doc': doc, 'mode': ?modo});

  /// Liga/desliga a captura de clique/mouse do editor.
  ///
  /// Chame com `false` antes de abrir um `Dialog`/`showDialog` por cima do
  /// editor (ele roda num `<iframe>`, que captura o clique mesmo com um
  /// diálogo do Flutter desenhado visualmente acima) e `true` ao fechar.
  void definirInteratividade(bool ativa) =>
      _ponte?.definirInteratividade(ativa);

  /// Recupera o documento atual do editor. Retorna um mapa vazio se o editor
  /// não estiver pronto ou não responder a tempo.
  Future<Map<String, dynamic>> obterDocumento() {
    final ponte = _ponte;
    if (ponte == null) return Future.value(<String, dynamic>{});
    final id = 'req_${_proximoId++}';
    final completer = Completer<Map<String, dynamic>>();
    _pendentes[id] = completer;
    ponte.enviar({'type': 'GET_DOC', 'id': id});
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendentes.remove(id);
        return <String, dynamic>{};
      },
    );
  }
}

/// Widget que embarca o editor ProseMirror (bundle JS servido em
/// `web/pm-editor/editor-only.html`) via `<iframe>` e o conecta a um
/// [EditorProseMirrorController].
class EditorProseMirror extends StatefulWidget {
  const EditorProseMirror({
    super.key,
    required this.controller,
    this.documentoInicial,
    this.modo = 'template',
    this.temaInicial,
    this.aoMudarTema,
    this.aoFicarPronto,
    this.aoAlterarDocumento,
  });

  final EditorProseMirrorController controller;
  final Map<String, dynamic>? documentoInicial;

  /// `'template'` (autoria completa) ou `'report'` (só blocos custom_text
  /// editáveis).
  final String modo;
  final String? temaInicial;
  final ValueChanged<String>? aoMudarTema;
  final VoidCallback? aoFicarPronto;
  final ValueChanged<Map<String, dynamic>>? aoAlterarDocumento;

  @override
  State<EditorProseMirror> createState() => _EditorProseMirrorState();
}

class _EditorProseMirrorState extends State<EditorProseMirror> {
  late final PonteEditorProseMirror _ponte;
  late final String _viewType;
  StreamSubscription<Map<String, dynamic>>? _assinatura;

  @override
  void initState() {
    super.initState();
    _viewType =
        'pm-editor-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    _ponte = PonteEditorProseMirror(_viewType, 'pm-editor/editor-only.html');
    widget.controller._anexar(_ponte);
    _ponte.registrar();

    _assinatura = _ponte.mensagens.listen((msg) {
      if (msg['type'] == 'EDITOR_READY') {
        widget.controller._pronto = true;
        _ponte.enviar({
          'type': 'SET_DOC',
          'doc': widget.documentoInicial ?? _docVazio(),
          'mode': widget.modo,
        });
        if (widget.temaInicial != null) {
          _ponte.enviar({
            'type': 'SET_THEME',
            'theme': widget.temaInicial,
          });
        }
        widget.aoFicarPronto?.call();
      } else if (msg['type'] == 'THEME_CHANGED') {
        final tema = msg['theme'] as String?;
        if (tema != null) {
          widget.aoMudarTema?.call(tema);
        }
      } else if (msg['type'] == 'DOC_CHANGED') {
        final doc = msg['doc'];
        if (doc is Map) {
          widget.aoAlterarDocumento?.call(Map<String, dynamic>.from(doc));
        }
      }
      widget.controller._aoReceberMensagem(msg);
    });
  }

  Map<String, dynamic> _docVazio() => {
    'type': 'doc',
    'content': [
      {'type': 'paragraph', 'content': <dynamic>[]},
    ],
  };

  @override
  void dispose() {
    _assinatura?.cancel();
    _ponte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

/// Ponte entre o Flutter e o editor ProseMirror embarcado num `<iframe>`.
///
/// Registra uma view factory (para uso com [HtmlElementView]) que devolve um
/// `<iframe>` apontando para o bundle do editor servido na mesma origem
/// (`web/pm-editor/editor-only.html`). A comunicação é feita via `postMessage`,
/// seguindo o protocolo documentado em `src/editor-only.js` do editor.
class PonteEditorProseMirror {
  PonteEditorProseMirror(this.viewType, this.src);

  final String viewType;
  final String src;

  web.HTMLIFrameElement? _iframe;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  JSFunction? _ouvinteMensagem;
  bool _registrado = false;

  /// Mensagens recebidas do editor (já decodificadas de JSON).
  Stream<Map<String, dynamic>> get mensagens => _controller.stream;

  void registrar() {
    if (_registrado) return;
    _registrado = true;

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      _iframe = iframe;
      return iframe;
    });

    final ouvinte = (web.MessageEvent event) {
      // Não filtramos por `event.source == iframe.contentWindow`: a
      // comparação de identidade entre wrappers de `Window` é pouco confiável
      // (pode dar `false` para a mesma janela), o que descartava todas as
      // mensagens do editor (EDITOR_READY, DOC_RESULT, ...). Em vez disso,
      // aceitamos apenas mensagens no formato do nosso protocolo (um mapa com
      // uma chave `type` do tipo String), o que já ignora ruído de terceiros.
      final dados = event.data?.dartify();
      Map<String, dynamic>? mapa;
      if (dados is String) {
        try {
          final decodificado = json.decode(dados);
          if (decodificado is Map) {
            mapa = Map<String, dynamic>.from(decodificado);
          }
        } catch (_) {
          return;
        }
      } else if (dados is Map) {
        mapa = Map<String, dynamic>.from(dados);
      }

      if (mapa == null || mapa['type'] is! String) return;
      _controller.add(mapa);
    }.toJS;
    _ouvinteMensagem = ouvinte;
    web.window.addEventListener('message', ouvinte);
  }

  /// Envia uma mensagem ao editor (serializada como JSON).
  void enviar(Map<String, dynamic> mensagem) {
    final janela = _iframe?.contentWindow;
    if (janela == null) return;
    janela.postMessage(json.encode(mensagem).toJS, '*'.toJS);
  }

  /// Liga/desliga a captura de clique/mouse do `<iframe>`.
  ///
  /// Um `<iframe>` é um browsing context à parte: mesmo com um `Dialog` do
  /// Flutter desenhado visualmente por cima, o clique do mouse continua
  /// indo para o iframe, não para os widgets do Flutter. Chamando isto com
  /// `false` antes de abrir um diálogo (e `true` ao fechar) o clique volta a
  /// chegar nos widgets do Flutter que estiverem por cima.
  void definirInteratividade(bool ativa) {
    _iframe?.style.pointerEvents = ativa ? 'auto' : 'none';
  }

  void dispose() {
    final ouvinte = _ouvinteMensagem;
    if (ouvinte != null) {
      web.window.removeEventListener('message', ouvinte);
    }
    _controller.close();
  }
}

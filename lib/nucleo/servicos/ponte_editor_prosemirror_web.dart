import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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

  html.IFrameElement? _iframe;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<html.MessageEvent>? _assinatura;
  bool _registrado = false;

  /// Mensagens recebidas do editor (já decodificadas de JSON).
  Stream<Map<String, dynamic>> get mensagens => _controller.stream;

  void registrar() {
    if (_registrado) return;
    _registrado = true;

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      _iframe = iframe;
      return iframe;
    });

    _assinatura = html.window.onMessage.listen((event) {
      // Não filtramos por `event.source == iframe.contentWindow`: no dart:html
      // a comparação de identidade entre wrappers de `Window` é pouco confiável
      // (pode dar `false` para a mesma janela), o que descartava todas as
      // mensagens do editor (EDITOR_READY, DOC_RESULT, ...). Em vez disso,
      // aceitamos apenas mensagens no formato do nosso protocolo (um mapa com
      // uma chave `type` do tipo String), o que já ignora ruído de terceiros.
      final dados = event.data;
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
    });
  }

  /// Envia uma mensagem ao editor (serializada como JSON).
  void enviar(Map<String, dynamic> mensagem) {
    final janela = _iframe?.contentWindow;
    if (janela == null) return;
    janela.postMessage(json.encode(mensagem), '*');
  }

  void dispose() {
    _assinatura?.cancel();
    _controller.close();
  }
}

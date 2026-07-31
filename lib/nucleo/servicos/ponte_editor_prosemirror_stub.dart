import 'dart:async';

/// Ponte entre o Flutter e o editor ProseMirror embarcado num `<iframe>`.
///
/// Implementação real disponível apenas na web (ver
/// `ponte_editor_prosemirror_web.dart`). Este stub existe para que o código
/// compile em plataformas sem `dart:html`.
class PonteEditorProseMirror {
  PonteEditorProseMirror(this.viewType, this.src);

  final String viewType;
  final String src;

  Stream<Map<String, dynamic>> get mensagens =>
      const Stream<Map<String, dynamic>>.empty();

  void registrar() => throw UnsupportedError(
    'O editor ProseMirror só está disponível na plataforma web.',
  );

  void enviar(Map<String, dynamic> mensagem) => throw UnsupportedError(
    'O editor ProseMirror só está disponível na plataforma web.',
  );

  void definirInteratividade(bool ativa) {}

  void dispose() {}
}

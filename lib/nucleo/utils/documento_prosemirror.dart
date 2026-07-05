/// Converte um documento ProseMirror (o `documento_json` retornado por
/// `/templates/<id>/preview/`) em texto simples, para uma pré-visualização
/// legível antes de gerar o relatório definitivo em .docx.
String renderizarDocumentoProseMirrorComoTexto(Map<String, dynamic> documento) {
  final buffer = StringBuffer();
  _renderizarNo(documento, buffer);
  return buffer.toString().trim();
}

void _renderizarNo(Map<dynamic, dynamic> no, StringBuffer buffer) {
  final tipo = no['type'];

  if (tipo == 'text' && no['text'] is String) {
    buffer.write(no['text']);
    return;
  }

  final filhos = no['content'];
  if (filhos is List) {
    for (var i = 0; i < filhos.length; i++) {
      final filho = filhos[i];
      if (filho is Map) _renderizarNo(filho, buffer);
      if (tipo == 'table_row' && i < filhos.length - 1) buffer.write(' | ');
    }
  }

  switch (tipo) {
    case 'paragraph':
    case 'heading':
    case 'table_row':
      buffer.write('\n');
    case 'table':
      buffer.write('\n');
  }
}

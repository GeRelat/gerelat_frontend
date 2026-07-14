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

  if (tipo == 'hard_break') {
    buffer.write('\n');
    return;
  }

  if (tipo == 'image_block') {
    final attrs = no['attrs'];
    final legenda = attrs is Map ? attrs['caption'] : null;
    buffer.write(
      legenda is String && legenda.trim().isNotEmpty
          ? '[Imagem: ${legenda.trim()}]'
          : '[Imagem]',
    );
    buffer.write('\n');
    return;
  }

  final filhos = no['content'];
  if (filhos is List) {
    for (var i = 0; i < filhos.length; i++) {
      final filho = filhos[i];
      if (filho is Map) _renderizarNo(filho, buffer);
      if (tipo == 'table_row' && i < filhos.length - 1) buffer.write(' | ');
    }
  } else if (tipo is String) {
    // Nó sem texto e sem filhos reconhecidos por esta pré-visualização
    // (ex.: tabela cujos dados ficam em `attrs`, não em `content`). Indica
    // a omissão em vez de sumir silenciosamente, para o preview não parecer
    // mais vazio do que o .docx gerado de fato.
    buffer.write('[$tipo]');
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

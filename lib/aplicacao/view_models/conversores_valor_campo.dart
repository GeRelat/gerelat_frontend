// Conversões entre o que o usuário edita na tela e o JSON de `CampoValor.valor`
// esperado pelo backend (`document_engine.validate_document_value`).

/// Coluna de uma variável do tipo tabela: `chave` é o identificador usado nas
/// linhas, `rotulo` é o cabeçalho exibido no documento.
class ColunaTabela {
  final String chave;
  final String rotulo;

  const ColunaTabela({required this.chave, required this.rotulo});
}

// ── Conversão texto <-> valor (só TEXT) ──
//
// RICHTEXT não passa mais por aqui: seu valor é um documento ProseMirror
// completo (editado no `DialogoEditorTextoRico`, podendo conter nós de
// variável). `extrairTextoDeValor` descartaria qualquer nó inline que não seja
// `text` — ver `extrairDocDeValor` / `resumoDeDoc` abaixo.

// Cada linha digitada vira um parágrafo, na ordem — inclusive linhas em
// branco (parágrafo com `content: []`), para preservar o espaçamento entre
// parágrafos que o usuário digitou. Filtrar linhas vazias aqui apagava esse
// espaçamento a cada save/reload.
Map<String, dynamic> construirValorTexto(String textoMultilinha) {
  final linhas = textoMultilinha.split('\n').map((linha) => linha.trim());
  return {
    'type': 'doc',
    'content': linhas
        .map(
          (linha) => {
            'type': 'paragraph',
            'content': linha.isEmpty
                ? const <Map<String, dynamic>>[]
                : [
                    {'type': 'text', 'text': linha},
                  ],
          },
        )
        .toList(),
  };
}

// Espelha `construirValorTexto`: cada bloco (parágrafo) do documento vira
// exatamente uma linha, mesmo quando não tem nós de texto (parágrafo em
// branco) — sem isso, o round-trip texto -> valor -> texto perde as linhas
// em branco que a construção acima passou a preservar.
String extrairTextoDeValor(Map<String, dynamic> valor) {
  final content = valor['content'];
  if (content is! List) return '';
  final linhas = <String>[];
  for (final bloco in content) {
    if (bloco is! Map || bloco['content'] is! List) continue;
    final buffer = StringBuffer();
    for (final no in bloco['content'] as List) {
      if (no is Map && no['type'] == 'text' && no['text'] is String) {
        buffer.write(no['text'] as String);
      }
    }
    linhas.add(buffer.toString());
  }
  return linhas.join('\n');
}

// ── Documento richtext <-> valor (RICHTEXT) ──

/// Documento ProseMirror vazio, ponto de partida do editor de texto rico.
Map<String, dynamic> docRichtextVazio() => {
  'type': 'doc',
  'content': [
    {'type': 'paragraph', 'content': <Map<String, dynamic>>[]},
  ],
};

/// Devolve o documento richtext gravado como está (é um doc ProseMirror
/// completo), ou um doc vazio quando ainda não há valor.
Map<String, dynamic> extrairDocDeValor(Map<String, dynamic> valor) {
  if (valor['type'] == 'doc' && valor['content'] is List) {
    return Map<String, dynamic>.from(valor);
  }
  return docRichtextVazio();
}

/// Achata um documento richtext para uma linha de texto legível no cartão da
/// variável. Nós de variável (`var_text`, `var_richtext`, ...) viram `[ref]`.
String resumoDeDoc(Map<String, dynamic> doc) {
  final buffer = StringBuffer();

  void percorrer(Object? nos) {
    if (nos is! List) return;
    for (final no in nos) {
      if (no is! Map) continue;
      final tipo = no['type'];
      if (tipo == 'text' && no['text'] is String) {
        buffer.write(no['text'] as String);
      } else if (tipo == 'hard_break') {
        buffer.write(' ');
      } else {
        final attrs = no['attrs'];
        final ref = attrs is Map ? (attrs['ref'] ?? attrs['label']) : null;
        if (ref is String && ref.isNotEmpty) buffer.write('[$ref]');
      }
      percorrer(no['content']);
      if (tipo == 'paragraph' || tipo == 'heading') buffer.write(' ');
    }
  }

  percorrer(doc['content']);
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ── Conversão colunas/linhas <-> valor (TABLE) ──

Map<String, dynamic> construirValorTabela({
  required List<ColunaTabela> colunas,
  required List<Map<String, String>> linhas,
}) {
  return {
    'columns': colunas.map((c) => {'key': c.chave, 'label': c.rotulo}).toList(),
    'rows': linhas,
  };
}

({List<ColunaTabela> colunas, List<Map<String, String>> linhas})
extrairTabelaDeValor(Map<String, dynamic> valor) {
  final colunasRaw = valor['columns'];
  final linhasRaw = valor['rows'];
  final colunas = <ColunaTabela>[];
  if (colunasRaw is List) {
    for (final coluna in colunasRaw) {
      if (coluna is Map) {
        colunas.add(
          ColunaTabela(
            chave: '${coluna['key'] ?? ''}',
            rotulo: '${coluna['label'] ?? ''}',
          ),
        );
      }
    }
  }
  final linhas = <Map<String, String>>[];
  if (linhasRaw is List) {
    for (final linha in linhasRaw) {
      if (linha is Map) {
        linhas.add(linha.map((k, v) => MapEntry('$k', '$v')));
      }
    }
  }
  return (colunas: colunas, linhas: linhas);
}

// ── Conversão dados de imagem <-> valor (IMAGE) ──

Map<String, dynamic> construirValorImagem({
  required int assetId,
  String? legenda,
  double? larguraMm,
  double? alturaMm,
}) {
  return {
    'asset_id': assetId,
    if (legenda != null && legenda.isNotEmpty) 'caption': legenda,
    'width_mm': ?larguraMm,
    'height_mm': ?alturaMm,
  };
}

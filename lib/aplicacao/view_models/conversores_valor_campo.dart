// Conversões entre o que o usuário edita na tela e o JSON de `CampoValor.valor`
// esperado pelo backend (`document_engine.validate_document_value`).

/// Coluna de uma variável do tipo tabela: `chave` é o identificador usado nas
/// linhas, `rotulo` é o cabeçalho exibido no documento.
class ColunaTabela {
  final String chave;
  final String rotulo;

  const ColunaTabela({required this.chave, required this.rotulo});
}

// ── Conversão texto <-> valor (TEXT e RICHTEXT, tratados como texto simples) ──

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

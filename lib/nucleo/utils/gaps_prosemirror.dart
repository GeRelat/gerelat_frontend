import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

/// Leitura no cliente dos "gaps" (nós de variável e blocos manuais) de um
/// documento ProseMirror, para antecipar na interface o que o backend faria em
/// `document_engine/converters.extract_gap_refs` e `document_engine/scope.py`.
///
/// Serve para avisar o usuário **antes** de gerar o relatório: quais variáveis
/// o template usa, quais delas não têm definição, e qual nível da hierarquia
/// precisa ser informado para que todas sejam resolvidas.

/// Prefixo reservado dos campos nativos (`sistema.<nivel>.<campo>`).
/// Espelha `SISTEMA_PREFIXO` em `document_engine/system_fields.py`.
const String prefixoSistema = 'sistema.';

const Set<String> _tiposVariavel = {
  'var_text',
  'variable',
  'var_richtext',
  'var_image',
  'image_ref',
  'var_table',
  'table_ref',
};

/// Referências de variável usadas pelo documento.
///
/// Diferente de `extract_gap_refs` no backend, **não** inclui os `label` de
/// `custom_text`: um bloco manual é texto livre preenchido na geração do
/// relatório, não uma variável — o backend também o ignora ao decidir o nível
/// exigido (`scan_required_nivel` faz `nivel_map.get(ref)` → `None` →
/// `continue`). Incluí-lo aqui transformaria todo bloco manual num falso
/// aviso de "variável não contemplada".
///
/// Quando [docsPorRef] é informado (mapa referência → documento do valor de uma
/// variável de texto rico), a varredura desce também para dentro desses valores
/// — espelha o parâmetro `docs_por_ref` de `extract_gap_refs` no backend. O
/// backend continua sendo a autoridade: sem esse mapa, um `sistema.evento.*`
/// aninhado só aparece na recusa da geração, não no aviso preventivo.
Set<String> extrairRefsDeVariaveis(
  Map<String, dynamic> documento, [
  Map<String, Map<String, dynamic>>? docsPorRef,
]) {
  final refs = <String>{};
  final visitados = <String>{};

  void percorrer(Object? conteudo) {
    _percorrer(conteudo, (tipo, attrs) {
      if (!_tiposVariavel.contains(tipo)) return;
      final ref = attrs['ref'];
      if (ref is! String || ref.isEmpty) return;
      refs.add(ref);
      if (docsPorRef != null && visitados.add(ref)) {
        final doc = docsPorRef[ref];
        if (doc != null) percorrer(doc['content']);
      }
    });
  }

  percorrer(documento['content']);
  return refs;
}

/// Rótulos dos blocos manuais (`custom_text`) do documento, na ordem em que
/// aparecem e sem repetição — são os trechos que o usuário vai poder editar
/// livremente na pré-visualização do relatório.
List<String> extrairLabelsDeBlocosManuais(Map<String, dynamic> documento) {
  final labels = <String>{};
  _percorrer(documento['content'], (tipo, attrs) {
    if (tipo != 'custom_text') return;
    final label = attrs['label'];
    if (label is String && label.isNotEmpty) labels.add(label);
  });
  return labels.toList();
}

/// Nível mais profundo exigido pelas [refs], ou `null` se nenhuma delas depende
/// de uma instância da hierarquia.
///
/// Espelha `scan_required_nivel`: referências `sistema.<nivel>.<campo>` têm o
/// nível no próprio nome; as demais são procuradas em [nivelPorReferencia]
/// (montado a partir das definições visíveis). Referência desconhecida é
/// ignorada aqui — ela aparece para o usuário como variável não contemplada,
/// não como exigência de escopo.
NivelAplicacao? nivelExigidoPorRefs(
  Iterable<String> refs,
  Map<String, NivelAplicacao> nivelPorReferencia,
) {
  NivelAplicacao? maisProfundo;
  for (final ref in refs) {
    final nivel = ehReferenciaDeSistema(ref)
        ? NivelAplicacao.porValorApiOuNulo(nivelDaReferenciaDeSistema(ref))
        : nivelPorReferencia[ref];
    if (nivel == null) continue;
    if (maisProfundo == null || nivel.ordem > maisProfundo.ordem) {
      maisProfundo = nivel;
    }
  }
  return maisProfundo;
}

bool ehReferenciaDeSistema(String referencia) =>
    referencia.startsWith(prefixoSistema);

/// `sistema.projeto.parceira` → `projeto`.
String nivelDaReferenciaDeSistema(String referencia) {
  return referencia.substring(prefixoSistema.length).split('.').first;
}

/// Visita recursivamente `content`, entregando `(type, attrs)` de cada nó.
void _percorrer(
  Object? conteudo,
  void Function(String tipo, Map<String, dynamic> attrs) visitar,
) {
  if (conteudo is! List) return;
  for (final no in conteudo) {
    if (no is! Map) continue;
    final tipo = no['type'];
    final attrs = no['attrs'];
    if (tipo is String) {
      visitar(tipo, attrs is Map ? Map<String, dynamic>.from(attrs) : const {});
    }
    _percorrer(no['content'], visitar);
  }
}

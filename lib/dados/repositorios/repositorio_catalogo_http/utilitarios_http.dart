import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';

int? paraInteiro(Object? valor) {
  if (valor is int) return valor;
  if (valor is String) return int.tryParse(valor);
  return null;
}

String paraTexto(Object? valor, {String fallback = ''}) {
  if (valor == null) return fallback;
  final texto = valor.toString().trim();
  return texto.isEmpty ? fallback : texto;
}

/// Extrai o id retornado ao criar um recurso, ou lança um erro claro
/// se a API responder algo inesperado (em vez de mascarar com um id `0`
/// silencioso, que só apareceria depois como um 404 confuso).
int idCriado(Map<String, dynamic> resposta, String chave, String recurso) {
  final id = paraInteiro(resposta[chave]);
  if (id == null) {
    throw Exception(
      'Resposta inesperada da API ao criar $recurso: campo "$chave" ausente.',
    );
  }
  return id;
}

/// Constrói um mapa `id -> nome` a partir de uma lista bruta da API.
/// Usado para "juntar" o nome de uma entidade relacionada (cliente de um
/// programa, programa de um evento, evento/template de um relatório etc.)
/// sem precisar de uma requisição por item.
Map<int, String> mapaIdNome(List<Map<String, dynamic>> itens) {
  return {
    for (final item in itens)
      if (paraInteiro(item['id']) != null)
        paraInteiro(item['id'])!: paraTexto(item['nome']),
  };
}

/// Converte itens brutos da API em [OpcaoSelecao] (id + nome), descartando
/// os que não têm id válido. Usado pelos combos de seleção (clientes,
/// programas, projetos, classes de evento).
List<OpcaoSelecao> paraOpcoes(
  List<Map<String, dynamic>> itens, {
  required String campoNome,
  required String fallback,
}) {
  return itens
      .map(
        (item) => OpcaoSelecao(
          id: paraInteiro(item['id']) ?? 0,
          nome: paraTexto(item[campoNome], fallback: fallback),
        ),
      )
      .where((opcao) => opcao.id > 0)
      .toList();
}

String formatarDataParaApi(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final ano = data.year.toString();
  return '$ano-$mes-$dia';
}

Future<Map<String, dynamic>> aguardarTaskConcluir(
  ServicoApiGerelat api,
  String taskId,
) async {
  const tentativasMaximas = 50;
  for (var tentativa = 0; tentativa < tentativasMaximas; tentativa++) {
    final resposta = await api.obter('/tasks/$taskId/');
    final statusTask = paraTexto(resposta['task_status']);

    if (statusTask == 'SUCCESS') {
      return resposta;
    }
    if (statusTask == 'FAILURE') {
      final erro = paraTexto(
        resposta['error'],
        fallback: 'Falha ao criar template.',
      );
      throw Exception(erro);
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  throw Exception('Tempo limite excedido aguardando a criação do template.');
}

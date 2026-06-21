import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';

class ServicoApiGerelat {
  final ClienteHttp _cliente;

  ServicoApiGerelat(this._cliente);

  Future<List<Map<String, dynamic>>> listar(String caminho) async {
    final resposta = await _cliente.get(caminho);
    _validar(resposta);
    final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
    final lista = decodificado is Map<String, dynamic>
        ? decodificado['results']
        : decodificado;
    if (lista is! List) {
      throw const FormatException('Resposta da API em formato inesperado.');
    }
    return lista
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> criar(
    String caminho,
    Map<String, dynamic> dados,
  ) async {
    final resposta = await _cliente.post(caminho, body: dados);
    _validar(resposta);
    if (resposta.bodyBytes.isEmpty) return {};
    final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
    return decodificado is Map
        ? Map<String, dynamic>.from(decodificado)
        : <String, dynamic>{};
  }

  void _validar(http.Response resposta) {
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return;
    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    final detalhe = _detalheErro(resposta);
    throw Exception(detalhe ?? 'Erro ${resposta.statusCode} ao consultar a API.');
  }

  String? _detalheErro(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map && corpo['detail'] != null) {
        return corpo['detail'].toString();
      }
      if (corpo is Map) {
        for (final valor in corpo.values) {
          if (valor is List && valor.isNotEmpty) return valor.first.toString();
          if (valor is String) return valor;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

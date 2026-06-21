import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:gerelat_frontend/nucleo/servicos/servico_token.dart';

typedef VoidCallbackAssincrono = Future<void> Function();

class ClienteHttp {
  final http.Client _cliente;
  final ServicoToken _servicoToken;
  final String urlBase;

  VoidCallbackAssincrono? onSessaoExpirada;

  ClienteHttp({
    required ServicoToken servicoToken,
    http.Client? cliente,
    this.urlBase = 'http://localhost:8000',
  }) : _servicoToken = servicoToken,
       _cliente = cliente ?? http.Client();

  Map<String, String> get cabecalhosJson => {
    'Content-Type': 'application/json',
    if (_servicoToken.accessToken != null)
      'Authorization': 'Bearer ${_servicoToken.accessToken}',
  };

  Future<http.Response> get(String caminho) async {
    final resposta = await _cliente.get(
      Uri.parse('$urlBase$caminho'),
      headers: cabecalhosJson,
    );
    await _tratarSessaoExpirada(resposta);
    return resposta;
  }

  Future<http.Response> post(
    String caminho, {
    Map<String, dynamic>? body,
    bool autenticado = true,
  }) async {
    final headers = autenticado
        ? cabecalhosJson
        : {'Content-Type': 'application/json'};
    final resposta = await _cliente.post(
      Uri.parse('$urlBase$caminho'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    await _tratarSessaoExpirada(resposta);
    return resposta;
  }

  Future<http.Response> put(
    String caminho, {
    required Map<String, dynamic> body,
  }) async {
    final resposta = await _cliente.put(
      Uri.parse('$urlBase$caminho'),
      headers: cabecalhosJson,
      body: jsonEncode(body),
    );
    await _tratarSessaoExpirada(resposta);
    return resposta;
  }

  Future<void> _tratarSessaoExpirada(http.Response resposta) async {
    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      await _servicoToken.limpar();
      await onSessaoExpirada?.call();
    }
  }

  void fechar() => _cliente.close();
}

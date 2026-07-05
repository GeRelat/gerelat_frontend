import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:gerelat_frontend/nucleo/servicos/servico_token.dart';
import 'package:http_parser/http_parser.dart';

typedef VoidCallbackAssincrono = Future<void> Function();

class ClienteHttp {
  final http.Client _cliente;
  final ServicoToken _servicoToken;
  final String urlBase;

  VoidCallbackAssincrono? onSessaoExpirada;

  /// Deduplica renovações concorrentes: com `ROTATE_REFRESH_TOKENS=True` no
  /// backend, cada `/auth/login/refresh/` bem-sucedido invalida o refresh
  /// token usado. Se duas requisições expirarem ao mesmo tempo, a segunda
  /// tentativa usaria um token já invalidado e falharia.
  Future<bool>? _renovacaoEmAndamento;

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

  Map<String, String> get cabecalhosAutenticados => {
    if (_servicoToken.accessToken != null)
      'Authorization': 'Bearer ${_servicoToken.accessToken}',
  };

  Future<http.Response> get(String caminho) => _comRenovacao(
    () => _cliente.get(_uri(caminho), headers: cabecalhosAutenticados),
  );

  Future<http.Response> delete(String caminho) => _comRenovacao(
    () => _cliente.delete(_uri(caminho), headers: cabecalhosAutenticados),
  );

  Future<http.Response> post(
    String caminho, {
    Map<String, dynamic>? body,
    bool autenticado = true,
  }) => _comRenovacao(() {
    final headers = autenticado
        ? cabecalhosJson
        : {'Content-Type': 'application/json'};
    return _cliente.post(
      _uri(caminho),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
  });

  Future<http.Response> put(
    String caminho, {
    required Map<String, dynamic> body,
  }) => _comRenovacao(
    () => _cliente.put(
      _uri(caminho),
      headers: cabecalhosJson,
      body: jsonEncode(body),
    ),
  );

  Future<http.Response> patch(
    String caminho, {
    required Map<String, dynamic> body,
  }) => _comRenovacao(
    () => _cliente.patch(
      _uri(caminho),
      headers: cabecalhosJson,
      body: jsonEncode(body),
    ),
  );

  /// [contentType] deve refletir o arquivo enviado (ex.: `image/png` para
  /// assets, ou o MIME de `.docx` para templates) — o backend valida o
  /// content-type declarado e rejeita uploads com um tipo incompatível.
  Future<http.Response> postMultipart(
    String caminho, {
    required Map<String, String> fields,
    required String fileField,
    required Uint8List fileBytes,
    required String filename,
    required String contentType,
  }) => _comRenovacao(() async {
    final requisicao = http.MultipartRequest('POST', _uri(caminho))
      ..headers.addAll(cabecalhosAutenticados)
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );
    return http.Response.fromStream(await requisicao.send());
  });

  Uri _uri(String caminho) => Uri.parse('$urlBase$caminho');

  /// Executa [requisicao]; se a resposta vier 401 e houver um refresh token
  /// disponível, tenta renovar a sessão via `/auth/login/refresh/` e repete a
  /// requisição uma única vez antes de desistir.
  Future<http.Response> _comRenovacao(
    Future<http.Response> Function() requisicao,
  ) async {
    var resposta = await requisicao();
    if (resposta.statusCode == 401 && await _renovarToken()) {
      resposta = await requisicao();
    }
    await _tratarSessaoExpirada(resposta);
    return resposta;
  }

  Future<bool> _renovarToken() {
    final refreshToken = _servicoToken.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return Future.value(false);
    }

    return _renovacaoEmAndamento ??= _executarRenovacao(refreshToken).whenComplete(
      () => _renovacaoEmAndamento = null,
    );
  }

  Future<bool> _executarRenovacao(String refreshToken) async {
    try {
      final resposta = await _cliente.post(
        _uri('/auth/login/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (resposta.statusCode != 200) return false;

      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final novoAccessToken = corpo['access']?.toString();
      if (novoAccessToken == null) return false;

      await _servicoToken.salvar(
        accessToken: novoAccessToken,
        refreshToken: corpo['refresh']?.toString() ?? refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _tratarSessaoExpirada(http.Response resposta) async {
    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      await _servicoToken.limpar();
      await onSessaoExpirada?.call();
    }
  }

  void fechar() => _cliente.close();
}

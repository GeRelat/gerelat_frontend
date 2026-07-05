import 'dart:convert';

import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';
import 'package:gerelat_frontend/nucleo/servicos/servico_token.dart';

class ResultadoAutenticacao {
  final bool sucesso;
  final String? mensagemErro;

  const ResultadoAutenticacao.sucesso() : sucesso = true, mensagemErro = null;
  const ResultadoAutenticacao.erro(this.mensagemErro) : sucesso = false;
}

class ServicoAutenticacao {
  final ClienteHttp _clienteHttp;
  final ServicoToken _servicoToken;

  ServicoAutenticacao({
    required ClienteHttp clienteHttp,
    required ServicoToken servicoToken,
  }) : _clienteHttp = clienteHttp,
       _servicoToken = servicoToken;

  Future<ResultadoAutenticacao> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await _clienteHttp.post(
        '/auth/register/',
        autenticado: false,
        body: {'full_name': nomeCompleto, 'email': email, 'password': senha},
      );

      if (resposta.statusCode == 201) {
        return const ResultadoAutenticacao.sucesso();
      }

      final mensagem = _extrairMensagemErro(_decodificarObjeto(resposta.body));
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      return const ResultadoAutenticacao.erro(
        'Nao foi possivel conectar ao servidor. Verifique sua conexao.',
      );
    }
  }

  Future<ResultadoAutenticacao> login({
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await _clienteHttp.post(
        '/auth/login/',
        autenticado: false,
        body: {'email': email, 'password': senha},
      );

      if (resposta.statusCode == 200) {
        final corpo = _decodificarObjeto(resposta.body);
        final accessToken = corpo['access']?.toString();
        final refreshToken = corpo['refresh']?.toString();

        if (accessToken == null || refreshToken == null) {
          return const ResultadoAutenticacao.erro(
            'Resposta de login invalida. Tokens nao encontrados.',
          );
        }

        await _servicoToken.salvar(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return const ResultadoAutenticacao.sucesso();
      }

      final mensagem = _extrairMensagemErro(_decodificarObjeto(resposta.body));
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      return const ResultadoAutenticacao.erro(
        'Nao foi possivel conectar ao servidor. Verifique sua conexao.',
      );
    }
  }

  Future<ResultadoAutenticacao> solicitarRecuperacaoSenha({
    required String email,
  }) async {
    try {
      final resposta = await _clienteHttp.post(
        '/auth/password/reset/',
        autenticado: false,
        body: {'email': email},
      );

      if (resposta.statusCode == 200) {
        return const ResultadoAutenticacao.sucesso();
      }

      final mensagem = _extrairMensagemErro(_decodificarObjeto(resposta.body));
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      return const ResultadoAutenticacao.erro(
        'Nao foi possivel conectar ao servidor. Verifique sua conexao.',
      );
    }
  }

  Future<ResultadoAutenticacao> confirmarRecuperacaoSenha({
    required String uid,
    required String token,
    required String novaSenha,
  }) async {
    try {
      final resposta = await _clienteHttp.post(
        '/auth/password/reset/confirm/',
        autenticado: false,
        body: {'uid': uid, 'token': token, 'new_password': novaSenha},
      );

      if (resposta.statusCode == 200) {
        return const ResultadoAutenticacao.sucesso();
      }

      final mensagem = _extrairMensagemErro(_decodificarObjeto(resposta.body));
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      return const ResultadoAutenticacao.erro(
        'Nao foi possivel conectar ao servidor. Verifique sua conexao.',
      );
    }
  }

  Future<Usuario?> obterUsuarioAtual() async {
    try {
      final resposta = await _clienteHttp.get('/auth/me/');
      if (resposta.statusCode != 200) return null;

      final corpo = _decodificarObjeto(resposta.body);
      return Usuario(
        id: int.tryParse('${corpo['id']}') ?? 0,
        nomeCompleto: corpo['full_name']?.toString() ?? '',
        email: corpo['email']?.toString() ?? '',
        criadoEm: DateTime.tryParse(corpo['created_at']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ResultadoAutenticacao> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    try {
      final resposta = await _clienteHttp.post(
        '/auth/change-password/',
        body: {'old_password': senhaAtual, 'new_password': novaSenha},
      );

      if (resposta.statusCode == 200) {
        return const ResultadoAutenticacao.sucesso();
      }

      final mensagem = _extrairMensagemErro(_decodificarObjeto(resposta.body));
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      return const ResultadoAutenticacao.erro(
        'Nao foi possivel conectar ao servidor. Verifique sua conexao.',
      );
    }
  }

  Future<void> sair() async {
    final refreshToken = _servicoToken.refreshToken;

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _clienteHttp.post(
          '/auth/logout/',
          body: {'refresh': refreshToken},
        );
      }
    } catch (_) {
      // Mesmo se a API falhar, a sessao local deve ser encerrada.
    } finally {
      await _servicoToken.limpar();
    }
  }

  String _extrairMensagemErro(Map<String, dynamic> corpo) {
    for (final valor in corpo.values) {
      if (valor is List && valor.isNotEmpty) return valor.first.toString();
      if (valor is String) return valor;
    }
    return 'Ocorreu um erro inesperado.';
  }

  Map<String, dynamic> _decodificarObjeto(String corpo) {
    try {
      final decodificado = jsonDecode(corpo);
      if (decodificado is Map<String, dynamic>) return decodificado;
    } catch (_) {
      return {'detail': 'Ocorreu um erro inesperado.'};
    }
    return {'detail': 'Ocorreu um erro inesperado.'};
  }
}

import 'dart:convert';

import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
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
    int? clienteId,
  }) async {
    try {
      final resposta = await _clienteHttp.post(
        '/auth/register/',
        autenticado: false,
        body: {
          'full_name': nomeCompleto,
          'email': email,
          'password': senha,
          if (clienteId != null) 'cliente': clienteId,
        },
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

  Future<List<OpcaoSelecao>> listarClientesPublicos() async {
    try {
      final resposta = await _clienteHttp.get('/clientes/publicos/');
      if (resposta.statusCode != 200) return const [];

      final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
      final lista = decodificado is Map<String, dynamic>
          ? decodificado['results']
          : decodificado;
      if (lista is! List) return const [];

      return lista
          .whereType<Map>()
          .map((cliente) {
            final id = int.tryParse('${cliente['id']}');
            if (id == null) return null;
            return OpcaoSelecao(
              id: id,
              nome: cliente['nome']?.toString() ?? 'Cliente sem nome',
            );
          })
          .whereType<OpcaoSelecao>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<ResultadoAutenticacao> solicitarAcessoCliente({
    required int clienteId,
    int? programaId,
    int? projetoId,
    String? papelSolicitado,
  }) async {
    try {
      final body = <String, dynamic>{
        'cliente': clienteId,
      };
      if (programaId != null) body['programa'] = programaId;
      if (projetoId != null) body['projeto'] = projetoId;
      if (papelSolicitado != null) body['papel_solicitado'] = papelSolicitado;

      final resposta = await _clienteHttp.post(
        '/solicitacoes-cliente/',
        body: body,
      );

      if (resposta.statusCode == 200 || resposta.statusCode == 201) {
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
      final contextosRaw = corpo['contextos_acesso'] is Map<String, dynamic>
          ? corpo['contextos_acesso'] as Map<String, dynamic>
          : null;

      return Usuario(
        id: int.tryParse('${corpo['id']}') ?? 0,
        nomeCompleto: corpo['full_name']?.toString() ?? '',
        email: corpo['email']?.toString() ?? '',
        criadoEm: DateTime.tryParse(corpo['created_at']?.toString() ?? ''),
        possuiContextoAcesso: corpo['possui_contexto_acesso'] == true,
        contextosAcesso: ContextosAcesso.fromMap(contextosRaw),
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
    String msg;
    if (corpo['detail'] != null) {
      final detail = corpo['detail'];
      if (detail is List && detail.isNotEmpty) {
        msg = detail.first.toString();
      } else {
        msg = detail.toString();
      }
    } else if (corpo['non_field_errors'] != null) {
      final nfe = corpo['non_field_errors'];
      if (nfe is List && nfe.isNotEmpty) {
        msg = nfe.first.toString();
      } else {
        msg = nfe.toString();
      }
    } else {
      msg = 'Ocorreu um erro inesperado.';
      for (final valor in corpo.values) {
        if (valor is List && valor.isNotEmpty) {
          msg = valor.first.toString();
          break;
        }
        if (valor is String && valor.isNotEmpty) {
          msg = valor;
          break;
        }
      }
    }
    return _formatarMensagemLimpa(msg);
  }

  String _formatarMensagemLimpa(String texto) {
    var limpo = texto.trim();
    if (limpo.contains('ao receber')) {
      final idx = limpo.indexOf('ao receber');
      limpo = limpo.substring(idx + 'ao receber'.length).trim();
    }
    while ((limpo.startsWith('[') && limpo.endsWith(']')) ||
        (limpo.startsWith('"') && limpo.endsWith('"')) ||
        (limpo.startsWith("'") && limpo.endsWith("'"))) {
      limpo = limpo.substring(1, limpo.length - 1).trim();
    }
    if (limpo.isEmpty) return 'Ocorreu um erro inesperado.';
    return limpo;
  }

  Map<String, dynamic> _decodificarObjeto(String corpo) {
    try {
      final decodificado = jsonDecode(corpo);
      if (decodificado is Map<String, dynamic>) return decodificado;
      if (decodificado is Map) return Map<String, dynamic>.from(decodificado);
      if (decodificado is List && decodificado.isNotEmpty) {
        final primeiro = decodificado.first;
        if (primeiro is Map) return Map<String, dynamic>.from(primeiro);
        return {'detail': primeiro.toString()};
      }
      return {'detail': decodificado.toString()};
    } catch (_) {
      return {'detail': 'Ocorreu um erro inesperado.'};
    }
  }
}

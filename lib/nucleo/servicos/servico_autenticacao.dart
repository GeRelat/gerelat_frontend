import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado de uma operação de autenticação.
/// Carrega ou uma mensagem de erro ou indica sucesso.
class ResultadoAutenticacao {
  final bool sucesso;
  final String? mensagemErro;

  const ResultadoAutenticacao.sucesso() : sucesso = true, mensagemErro = null;
  const ResultadoAutenticacao.erro(this.mensagemErro) : sucesso = false;
}

/// Serviço responsável por toda a comunicação com os endpoints de autenticação da gerelat-api.
class ServicoAutenticacao {
  // URL base da API — aponta para o backend Django rodando localmente
  static const String _urlBase = 'http://localhost:8000';

  /// Registra um novo usuário chamando POST /auth/register/
  /// Recebe nome completo, e-mail e senha.
  /// Retorna sucesso ou a mensagem de erro da API.
  static Future<ResultadoAutenticacao> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await http.post(
        Uri.parse('$_urlBase/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': nomeCompleto,
          'email': email,
          'password': senha,
        }),
      );

      // Cadastro realizado com sucesso
      if (resposta.statusCode == 201) {
        return const ResultadoAutenticacao.sucesso();
      }

      // API retornou um erro — tenta extrair a mensagem
      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final mensagem = _extrairMensagemErro(corpo);
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      // Erro de conexão — backend pode estar desligado
      return const ResultadoAutenticacao.erro(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }
  }

  /// Faz login chamando POST /auth/login/
  /// Retorna sucesso com token ou mensagem de erro.
  static Future<ResultadoAutenticacao> login({
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await http.post(
        Uri.parse('$_urlBase/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': senha}),
      );

      if (resposta.statusCode == 200) {
        // TODO: salvar os tokens JWT retornados pela API
        return const ResultadoAutenticacao.sucesso();
      }

      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final mensagem = _extrairMensagemErro(corpo);
      return ResultadoAutenticacao.erro(mensagem);
    } catch (_) {
      return const ResultadoAutenticacao.erro(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }
  }

  /// Extrai a primeira mensagem de erro legível retornada pela API Django
  static String _extrairMensagemErro(Map<String, dynamic> corpo) {
    for (final valor in corpo.values) {
      if (valor is List && valor.isNotEmpty) return valor.first.toString();
      if (valor is String) return valor;
    }
    return 'Ocorreu um erro inesperado.';
  }
}

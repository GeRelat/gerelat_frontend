import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/servicos/servico_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/servicos/servico_token.dart';

class RepositorioAutenticacaoHttp implements RepositorioAutenticacao {
  final ServicoAutenticacao _servico;
  final ServicoToken _tokens;

  RepositorioAutenticacaoHttp({
    required ServicoAutenticacao servico,
    required ServicoToken tokens,
  }) : _servico = servico,
       _tokens = tokens;

  @override
  bool get estaAutenticado => _tokens.estaAutenticado;

  @override
  Future<void> inicializar() => _tokens.carregar();

  @override
  Future<ResultadoLogin> login({
    required String email,
    required String senha,
  }) async {
    final resultado = await _servico.login(
      email: email,
      senha: senha,
    );

    if (resultado.sucesso) return const ResultadoLogin.sucesso();
    return ResultadoLogin.erro(resultado.mensagemErro);
  }

  @override
  Future<ResultadoLogin> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    final resultado = await _servico.cadastrar(
      nomeCompleto: nomeCompleto,
      email: email,
      senha: senha,
    );
    if (resultado.sucesso) return const ResultadoLogin.sucesso();
    return ResultadoLogin.erro(resultado.mensagemErro);
  }

  @override
  Future<void> sair() => _servico.sair();
}

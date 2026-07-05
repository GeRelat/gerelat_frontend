import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
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
  Future<Usuario?> obterUsuarioAtual() => _servico.obterUsuarioAtual();

  @override
  Future<ResultadoLogin> login({
    required String email,
    required String senha,
  }) async {
    final resultado = await _servico.login(email: email, senha: senha);

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
  Future<ResultadoLogin> solicitarRecuperacaoSenha({
    required String email,
  }) async {
    final resultado = await _servico.solicitarRecuperacaoSenha(email: email);
    if (resultado.sucesso) return const ResultadoLogin.sucesso();
    return ResultadoLogin.erro(resultado.mensagemErro);
  }

  @override
  Future<ResultadoLogin> confirmarRecuperacaoSenha({
    required String uid,
    required String token,
    required String novaSenha,
  }) async {
    final resultado = await _servico.confirmarRecuperacaoSenha(
      uid: uid,
      token: token,
      novaSenha: novaSenha,
    );
    if (resultado.sucesso) return const ResultadoLogin.sucesso();
    return ResultadoLogin.erro(resultado.mensagemErro);
  }

  @override
  Future<ResultadoLogin> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final resultado = await _servico.alterarSenha(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
    );
    if (resultado.sucesso) return const ResultadoLogin.sucesso();
    return ResultadoLogin.erro(resultado.mensagemErro);
  }

  @override
  Future<void> sair() => _servico.sair();
}

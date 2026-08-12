import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
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
    return _paraResultadoLogin(
      await _servico.login(email: email, senha: senha),
    );
  }

  @override
  Future<ResultadoLogin> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
    int? clienteId,
  }) async {
    return _paraResultadoLogin(
      await _servico.cadastrar(
        nomeCompleto: nomeCompleto,
        email: email,
        senha: senha,
        clienteId: clienteId,
      ),
    );
  }

  @override
  Future<List<OpcaoSelecao>> listarClientesPublicos() {
    return _servico.listarClientesPublicos();
  }

  @override
  Future<ResultadoLogin> solicitarAcessoCliente({
    required int clienteId,
    int? programaId,
    int? projetoId,
    String? papelSolicitado,
  }) async {
    return _paraResultadoLogin(
      await _servico.solicitarAcessoCliente(
        clienteId: clienteId,
        programaId: programaId,
        projetoId: projetoId,
        papelSolicitado: papelSolicitado,
      ),
    );
  }

  @override
  Future<ResultadoLogin> solicitarRecuperacaoSenha({
    required String email,
  }) async {
    return _paraResultadoLogin(
      await _servico.solicitarRecuperacaoSenha(email: email),
    );
  }

  @override
  Future<ResultadoLogin> confirmarRecuperacaoSenha({
    required String uid,
    required String token,
    required String novaSenha,
  }) async {
    return _paraResultadoLogin(
      await _servico.confirmarRecuperacaoSenha(
        uid: uid,
        token: token,
        novaSenha: novaSenha,
      ),
    );
  }

  @override
  Future<ResultadoLogin> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    return _paraResultadoLogin(
      await _servico.alterarSenha(senhaAtual: senhaAtual, novaSenha: novaSenha),
    );
  }

  @override
  Future<void> sair() => _servico.sair();

  /// Converte o resultado interno de [ServicoAutenticacao] para o
  /// [ResultadoLogin] da interface de domínio — mesma conversão repetida em
  /// todos os métodos acima.
  ResultadoLogin _paraResultadoLogin(ResultadoAutenticacao resultado) {
    if (resultado.sucesso) return const ResultadoLogin.sucesso();
    return ResultadoLogin.erro(resultado.mensagemErro);
  }
}

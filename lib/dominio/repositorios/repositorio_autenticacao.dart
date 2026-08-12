import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';

class ResultadoLogin {
  final bool sucesso;
  final String? mensagemErro;

  const ResultadoLogin.sucesso() : sucesso = true, mensagemErro = null;
  const ResultadoLogin.erro(this.mensagemErro) : sucesso = false;
}

abstract class RepositorioAutenticacao {
  bool get estaAutenticado;

  Future<void> inicializar();

  Future<Usuario?> obterUsuarioAtual();

  Future<ResultadoLogin> login({required String email, required String senha});

  Future<ResultadoLogin> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
    int? clienteId,
  });

  Future<List<OpcaoSelecao>> listarClientesPublicos();

  Future<ResultadoLogin> solicitarAcessoCliente({
    required int clienteId,
    int? programaId,
    int? projetoId,
    String? papelSolicitado,
  });

  Future<ResultadoLogin> solicitarRecuperacaoSenha({required String email});

  Future<ResultadoLogin> confirmarRecuperacaoSenha({
    required String uid,
    required String token,
    required String novaSenha,
  });

  Future<ResultadoLogin> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  });

  Future<void> sair();
}

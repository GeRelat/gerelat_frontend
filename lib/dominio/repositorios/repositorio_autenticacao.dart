class ResultadoLogin {
  final bool sucesso;
  final String? mensagemErro;

  const ResultadoLogin.sucesso() : sucesso = true, mensagemErro = null;
  const ResultadoLogin.erro(this.mensagemErro) : sucesso = false;
}

abstract class RepositorioAutenticacao {
  bool get estaAutenticado;

  Future<void> inicializar();

  Future<ResultadoLogin> login({required String email, required String senha});

  Future<ResultadoLogin> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  });

  Future<void> sair();
}

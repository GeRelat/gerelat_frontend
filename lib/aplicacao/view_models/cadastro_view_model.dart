import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

class CadastroViewModel extends BaseViewModel {
  final RepositorioAutenticacao _repositorio;

  CadastroViewModel(this._repositorio);

  Future<bool> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    iniciarCarregamento();
    try {
      final resultado = await _repositorio.cadastrar(
        nomeCompleto: nomeCompleto,
        email: email,
        senha: senha,
      );
      if (resultado.sucesso) {
        finalizarCarregamento();
        return true;
      }
      definirErro(resultado.mensagemErro ?? 'Erro ao criar conta.');
      return false;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

class LoginViewModel extends BaseViewModel {
  final RepositorioAutenticacao _repositorio;

  LoginViewModel(this._repositorio);

  Future<bool> login({required String email, required String senha}) async {
    iniciarCarregamento();
    try {
      final resultado = await _repositorio.login(email: email, senha: senha);

      if (resultado.sucesso) {
        finalizarCarregamento();
        return true;
      }

      definirErro(resultado.mensagemErro ?? 'Erro ao fazer login.');
      return false;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

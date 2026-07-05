import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

class AlterarSenhaViewModel extends BaseViewModel {
  final RepositorioAutenticacao _repositorio;

  AlterarSenhaViewModel(this._repositorio);

  Future<bool> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    iniciarCarregamento();
    try {
      final resultado = await _repositorio.alterarSenha(
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      );

      if (resultado.sucesso) {
        finalizarCarregamento();
        return true;
      }

      definirErro(resultado.mensagemErro ?? 'Erro ao alterar a senha.');
      return false;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

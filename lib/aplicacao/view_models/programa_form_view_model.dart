import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ProgramaFormViewModel extends BaseViewModel {
  final RepositorioProgramas _repositorio;

  ProgramaFormViewModel(this._repositorio);

  Future<bool> salvar({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
  }) async {
    iniciarCarregamento();
    try {
      await _repositorio.criarPrograma(
        nome: nome,
        leiCriacao: leiCriacao,
        convenioDados: convenioDados,
        rodape: rodape,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

class SessaoViewModel extends BaseViewModel {
  final RepositorioAutenticacao _repositorio;

  SessaoViewModel(this._repositorio);

  bool get estaAutenticado => _repositorio.estaAutenticado;

  Future<void> inicializar() => _repositorio.inicializar();

  Future<bool> sair() async {
    iniciarCarregamento();
    try {
      await _repositorio.sair();
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

class SessaoViewModel extends BaseViewModel {
  final RepositorioAutenticacao _repositorio;

  SessaoViewModel(this._repositorio);

  bool get estaAutenticado => _repositorio.estaAutenticado;

  Future<void> inicializar() => _repositorio.inicializar();

  /// Avisa quem estiver ouvindo (ex: o redirect do GoRouter) que o estado de
  /// autenticação mudou: login, logout ou expiração de sessão.
  void notificarMudancaAutenticacao() => notifyListeners();

  Future<bool> sair() async {
    iniciarCarregamento();
    try {
      await _repositorio.sair();
      finalizarCarregamento();
      notificarMudancaAutenticacao();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

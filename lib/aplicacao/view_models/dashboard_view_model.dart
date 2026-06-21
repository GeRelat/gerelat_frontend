import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class DashboardViewModel extends BaseViewModel {
  final RepositorioDashboard _repositorio;
  ResumoDashboard? _resumo;

  DashboardViewModel(this._repositorio);

  ResumoDashboard? get resumo => _resumo;

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _resumo = await _repositorio.obterResumoDashboard();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }
}

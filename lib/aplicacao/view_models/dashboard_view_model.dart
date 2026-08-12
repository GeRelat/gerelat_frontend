import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class DashboardViewModel extends BaseViewModel {
  final RepositorioDashboard _repositorio;
  ResumoDashboard? _resumo;
  int? _clienteId;

  DashboardViewModel(this._repositorio);

  ResumoDashboard? get resumo => _resumo;
  int? get clienteId => _clienteId;

  Future<void> carregar({int? clienteId}) async {
    _clienteId = clienteId;
    iniciarCarregamento();
    try {
      _resumo = await _repositorio.obterResumoDashboard(clienteId: clienteId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }
}

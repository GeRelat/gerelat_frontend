import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RelatoriosViewModel extends BaseViewModel {
  final RepositorioRelatorios _repositorio;
  List<Relatorio> _relatorios = [];

  RelatoriosViewModel(this._repositorio);

  List<Relatorio> get relatorios => List.unmodifiable(_relatorios);
  bool get estaVazio => _relatorios.isEmpty;

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _relatorios = await _repositorio.listarRelatorios();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }
}

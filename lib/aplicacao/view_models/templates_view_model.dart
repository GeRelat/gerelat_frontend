import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplatesViewModel extends BaseViewModel {
  final RepositorioTemplates _repositorio;
  List<TemplateRelatorio> _templates = [];

  TemplatesViewModel(this._repositorio);

  List<TemplateRelatorio> get templates => List.unmodifiable(_templates);

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _templates = await _repositorio.listarTemplates();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }
}

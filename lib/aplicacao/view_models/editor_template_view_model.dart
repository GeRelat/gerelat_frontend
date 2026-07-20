import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

/// Estado do editor de conteúdo de um template: carrega o `modelo_json` atual e
/// as variáveis (`ProjetoCampo`) do projeto do template, e persiste o documento
/// editado.
class EditorTemplateViewModel extends BaseViewModel {
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioProjetoCampo _camposRepositorio;

  EditorTemplateViewModel(RepositorioCatalogo repositorio)
    : _templatesRepositorio = repositorio,
      _camposRepositorio = repositorio;

  TemplateRelatorio? _template;
  Map<String, dynamic>? _documentoInicial;
  List<ProjetoCampo> _campos = [];
  bool _salvando = false;

  TemplateRelatorio? get template => _template;
  Map<String, dynamic>? get documentoInicial => _documentoInicial;
  List<ProjetoCampo> get campos => List.unmodifiable(_campos);
  bool get salvando => _salvando;

  Future<void> carregar(int templateId) async {
    iniciarCarregamento();
    try {
      _template = await _templatesRepositorio.obterTemplate(templateId);
      _documentoInicial = await _templatesRepositorio.obterModeloTemplate(
        templateId,
      );
      final projetoId = _template?.projetoId;
      _campos = projetoId == null
          ? []
          : await _camposRepositorio.listarCamposProjeto(projetoId: projetoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar(int templateId, Map<String, dynamic> documento) async {
    _salvando = true;
    notifyListeners();
    try {
      await _templatesRepositorio.salvarModeloTemplate(
        templateId: templateId,
        modeloJson: documento,
      );
      _salvando = false;
      notifyListeners();
      return true;
    } catch (erro) {
      _salvando = false;
      definirErro(erro);
      return false;
    }
  }
}

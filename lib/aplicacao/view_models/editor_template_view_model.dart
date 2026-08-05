import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/variaveis_do_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

/// Estado do editor de conteúdo de um template: carrega o `modelo_json` atual e
/// as variáveis que podem ser inseridas no escopo do template, e persiste o
/// documento editado.
class EditorTemplateViewModel extends BaseViewModel {
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioCatalogo _catalogo;

  EditorTemplateViewModel(RepositorioCatalogo repositorio)
    : _templatesRepositorio = repositorio,
      _catalogo = repositorio;

  TemplateRelatorio? _template;
  Map<String, dynamic>? _documentoInicial;
  List<VariavelDisponivel> _variaveis = [];
  bool _salvando = false;

  TemplateRelatorio? get template => _template;
  Map<String, dynamic>? get documentoInicial => _documentoInicial;
  List<VariavelDisponivel> get variaveis => List.unmodifiable(_variaveis);
  bool get salvando => _salvando;

  /// Campos nativos (`sistema.*`), sempre disponíveis.
  List<VariavelDisponivel> get variaveisDeSistema =>
      _variaveis.where((v) => v.origem == OrigemVariavel.sistema).toList();

  /// Variáveis cadastradas como `CampoDefinicao` visíveis neste escopo.
  List<VariavelDisponivel> get variaveisCustomizadas =>
      _variaveis.where((v) => v.origem == OrigemVariavel.customizado).toList();

  Future<void> carregar(int templateId) async {
    iniciarCarregamento();
    try {
      final template = await _templatesRepositorio.obterTemplate(templateId);
      _template = template;
      _documentoInicial = await _templatesRepositorio.obterModeloTemplate(
        templateId,
      );
      final escopoId = template.escopoId;
      _variaveis = escopoId == null
          ? []
          : await carregarVariaveisDoEscopo(
              _catalogo,
              await HierarquiaEscopo.carregar(_catalogo, comEventos: false),
              escopo: template.nivel,
              escopoId: escopoId,
            );
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

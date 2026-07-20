import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class GerarRelatorioViewModel extends BaseViewModel {
  final RepositorioEventos _eventosRepositorio;
  final RepositorioTemplates _templatesRepositorio;
  List<Evento> _eventos = [];
  List<TemplateRelatorio> _templates = [];

  GerarRelatorioViewModel(RepositorioCatalogo repositorio)
    : _eventosRepositorio = repositorio,
      _templatesRepositorio = repositorio;

  List<Evento> get eventos => List.unmodifiable(_eventos);
  List<TemplateRelatorio> get templates => List.unmodifiable(_templates);

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _eventos = await _eventosRepositorio.listarEventos();
      _templates = await _templatesRepositorio.listarTemplates();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  /// Resolve as variáveis do projeto/evento sobre o template e devolve o
  /// documento ProseMirror pronto para preview/edição no editor.
  Future<Map<String, dynamic>?> obterDocumentoPreview({
    required int templateId,
    int? eventoId,
  }) async {
    iniciarCarregamento();
    try {
      final documento = await _templatesRepositorio.previsualizarTemplate(
        templateId: templateId,
        eventoId: eventoId,
      );
      finalizarCarregamento();
      return documento;
    } catch (erro) {
      definirErro(erro);
      return null;
    }
  }
}

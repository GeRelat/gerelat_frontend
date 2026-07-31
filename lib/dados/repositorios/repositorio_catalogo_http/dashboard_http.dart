import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

mixin RepositorioDashboardHttpMixin
    on RepositorioProgramas, RepositorioTemplates, RepositorioRelatorios
    implements RepositorioDashboard {
  @override
  Future<ResumoDashboard> obterResumoDashboard() async {
    final programas = await listarProgramas();
    final templates = await listarTemplates();
    final relatorios = await listarRelatorios();

    return ResumoDashboard(
      programas: programas.length,
      projetos: programas.fold(
        0,
        (total, programa) => total + programa.projetos,
      ),
      eventos: programas.fold(0, (total, programa) => total + programa.eventos),
      templates: templates.length,
      relatorios: relatorios.length,
    );
  }
}

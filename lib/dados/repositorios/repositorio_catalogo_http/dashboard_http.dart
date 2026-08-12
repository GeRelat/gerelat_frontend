import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

mixin RepositorioDashboardHttpMixin
    on
        RepositorioProgramas,
        RepositorioTemplates,
        RepositorioRelatorios,
        RepositorioEventos
    implements RepositorioDashboard {
  @override
  Future<ResumoDashboard> obterResumoDashboard({int? clienteId}) async {
    final programas = await listarProgramas();
    final projetos = await listarProjetosDetalhados();
    final templates = await listarTemplates();
    final relatorios = await listarRelatorios();
    final eventos = await listarEventos();

    if (clienteId == null) {
      return ResumoDashboard(
        programas: programas.length,
        projetos: projetos.length,
        eventos: eventos.length,
        templates: templates.length,
        relatorios: relatorios.length,
      );
    }

    final programasDoCliente =
        programas.where((p) => p.clienteId == clienteId).toList();
    final programaIds =
        programasDoCliente.map((p) => p.id).whereType<int>().toSet();

    final projetosDoCliente =
        projetos.where((p) => programaIds.contains(p.programaId)).toList();
    final projetoIds =
        projetosDoCliente.map((p) => p.id).whereType<int>().toSet();

    final eventosDoCliente = eventos.where((e) {
      if (e.clienteId == clienteId) return true;
      if (e.programaId != null && programaIds.contains(e.programaId)) return true;
      if (e.projetoId != null && projetoIds.contains(e.projetoId)) return true;
      return false;
    }).toList();
    final eventoIds = eventosDoCliente.map((e) => e.id).whereType<int>().toSet();

    final templatesDoCliente = templates.where((t) {
      if (t.clienteId == clienteId) return true;
      if (t.programaId != null && programaIds.contains(t.programaId)) return true;
      if (t.projetoId != null && projetoIds.contains(t.projetoId)) return true;
      return false;
    }).toList();
    final templateIds =
        templatesDoCliente.map((t) => t.id).whereType<int>().toSet();

    final relatoriosDoCliente = relatorios.where((r) {
      if (r.eventoId != null && eventoIds.contains(r.eventoId)) return true;
      if (r.templateId != null && templateIds.contains(r.templateId)) return true;
      return false;
    }).toList();

    return ResumoDashboard(
      programas: programasDoCliente.length,
      projetos: projetosDoCliente.length,
      eventos: eventosDoCliente.length,
      templates: templatesDoCliente.length,
      relatorios: relatoriosDoCliente.length,
    );
  }
}

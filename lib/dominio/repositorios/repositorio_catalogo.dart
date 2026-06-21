import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';

abstract interface class RepositorioProgramas {
  Future<List<Programa>> listarProgramas();

  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
  });
}

abstract interface class RepositorioEventos {
  Future<List<Evento>> listarEventos();

  Future<List<OpcaoSelecao>> listarProjetos();

  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId});

  Future<void> criarEvento({
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  });
}

abstract interface class RepositorioTemplates {
  Future<List<TemplateRelatorio>> listarTemplates();
}

abstract interface class RepositorioRelatorios {
  Future<List<Relatorio>> listarRelatorios();

  Future<void> gerarRelatorio({
    required int templateId,
    int? eventoId,
  });
}

abstract interface class RepositorioDashboard {
  Future<ResumoDashboard> obterResumoDashboard();
}

abstract class RepositorioCatalogo
    implements
        RepositorioProgramas,
        RepositorioEventos,
        RepositorioTemplates,
        RepositorioRelatorios,
        RepositorioDashboard {}

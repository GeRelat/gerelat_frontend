import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RepositorioCatalogoMemoria implements RepositorioCatalogo {
  static const _programas = [
    Programa(
      nome: 'Programa de Inovacao Institucional',
      descricao:
          'Projetos e eventos voltados a inovacao, pesquisa e impacto social.',
      projetos: 3,
      eventos: 8,
      status: 'Ativo',
    ),
    Programa(
      nome: 'Formacao Continuada',
      descricao: 'Acoes de capacitacao, oficinas e encontros formativos.',
      projetos: 2,
      eventos: 5,
      status: 'Ativo',
    ),
    Programa(
      nome: 'Extensao Comunitaria',
      descricao:
          'Iniciativas de relacionamento e entrega para comunidades parceiras.',
      projetos: 4,
      eventos: 12,
      status: 'Planejamento',
    ),
  ];

  static final _eventos = [
    Evento(
      nome: 'Oficina de Dados Abertos',
      programa: 'Formacao Continuada',
      data: DateTime(2026, 6, 12),
      status: 'Planejado',
    ),
    Evento(
      nome: 'Mostra de Projetos Integradores',
      programa: 'Inovacao Institucional',
      data: DateTime(2026, 6, 28),
      status: 'Confirmado',
    ),
    Evento(
      nome: 'Encontro com Comunidades Parceiras',
      programa: 'Extensao Comunitaria',
      data: DateTime(2026, 7, 5),
      status: 'Rascunho',
    ),
  ];

  static const _templates = [
    TemplateRelatorio(
      nome: 'Relatorio Padrao de Evento',
      descricao:
          'Template oficial para documentacao de eventos institucionais.',
      tipo: 'DOCX',
      status: 'Ativo',
    ),
    TemplateRelatorio(
      nome: 'Sintese Executiva',
      descricao: 'Modelo compacto para apresentacao de resultados a diretoria.',
      tipo: 'DOCX',
      status: 'Rascunho',
    ),
  ];

  static const _relatorios = <Relatorio>[];

  @override
  Future<List<Evento>> listarEventos() async => _eventos;

  @override
  Future<List<Programa>> listarProgramas() async => _programas;

  @override
  Future<List<Relatorio>> listarRelatorios() async => _relatorios;

  @override
  Future<List<TemplateRelatorio>> listarTemplates() async => _templates;

  @override
  Future<ResumoDashboard> obterResumoDashboard() async {
    final totalProjetos = _programas.fold<int>(
      0,
      (total, programa) => total + programa.projetos,
    );
    final totalEventos = _programas.fold<int>(
      0,
      (total, programa) => total + programa.eventos,
    );

    return ResumoDashboard(
      programas: _programas.length,
      projetos: totalProjetos,
      eventos: totalEventos,
      templates: _templates.length,
      relatorios: _relatorios.length,
    );
  }

  @override
  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
  }) async {}

  @override
  Future<List<OpcaoSelecao>> listarProjetos() async => const [
    OpcaoSelecao(id: 1, nome: 'Projeto Integrador'),
  ];

  @override
  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId}) async =>
      const [OpcaoSelecao(id: 1, nome: 'Oficina')];

  @override
  Future<void> criarEvento({
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {}

  @override
  Future<void> gerarRelatorio({
    required int templateId,
    int? eventoId,
  }) async {}
}

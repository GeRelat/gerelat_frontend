import 'dart:typed_data';

import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
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
  Future<Evento> obterEvento(int eventoId) async => _eventos.first;

  @override
  Future<List<Programa>> listarProgramas() async => _programas;

  @override
  Future<Programa> obterPrograma(int programaId) async => _programas.first;

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
    String logomarca = '',
    int? clienteId,
  }) async {}

  @override
  Future<void> atualizarPrograma({
    required int programaId,
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  }) async {}

  @override
  Future<void> excluirPrograma(int programaId) async {}

  @override
  Future<List<Cliente>> listarClientes() async => const [];

  @override
  Future<List<OpcaoSelecao>> listarClientesSelecao() async => const [];

  @override
  Future<Cliente> obterCliente(int clienteId) async =>
      const Cliente(nome: 'Cliente de exemplo');

  @override
  Future<void> criarCliente({
    required String nome,
    String cnpj = '',
    String nomeContato = '',
    String emailContato = '',
    String foneContato = '',
    String numeroContrato = '',
    required DateTime dataTerminoContrato,
  }) async {}

  @override
  Future<void> atualizarCliente({
    required int clienteId,
    required String nome,
    String cnpj = '',
    String nomeContato = '',
    String emailContato = '',
    String foneContato = '',
    String numeroContrato = '',
    required DateTime dataTerminoContrato,
  }) async {}

  @override
  Future<void> excluirCliente(int clienteId) async {}

  @override
  Future<List<OpcaoSelecao>> listarProgramasSelecao() async => const [
    OpcaoSelecao(id: 1, nome: 'Programa de Inovacao Institucional'),
  ];

  @override
  Future<List<MembroEquipePrograma>> listarEquipePrograma({
    required int programaId,
  }) async => const [];

  @override
  Future<void> criarMembroEquipe({
    required int programaId,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> atualizarMembroEquipe({
    required int membroId,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> excluirMembroEquipe(int membroId) async {}

  @override
  Future<List<MembroEquipeProjeto>> listarEquipeProjeto({
    required int projetoId,
  }) async => const [];

  @override
  Future<void> criarMembroEquipeProjeto({
    required int projetoId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> atualizarMembroEquipeProjeto({
    required int membroId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> excluirMembroEquipeProjeto(int membroId) async {}

  @override
  Future<List<ProjetoCampo>> listarCamposProjeto({
    required int projetoId,
  }) async => const [];

  @override
  Future<void> criarCampoProjeto({
    required int projetoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {}

  @override
  Future<void> atualizarCampoProjeto({
    required int campoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {}

  @override
  Future<void> excluirCampoProjeto(int campoId) async {}

  @override
  Future<int> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    String descricao = '',
  }) async => 1;

  @override
  Future<List<Asset>> listarAssets() async => const [];

  @override
  Future<Asset> obterAsset(int assetId) async => const Asset();

  @override
  Future<void> atualizarAsset({
    required int assetId,
    required String descricao,
  }) async {}

  @override
  Future<void> excluirAsset(int assetId) async {}

  @override
  Future<void> criarProjeto({
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {}

  @override
  Future<List<Projeto>> listarProjetosDetalhados({int? programaId}) async =>
      const [];

  @override
  Future<Projeto> obterProjeto(int projetoId) async =>
      const Projeto(nome: 'Projeto de exemplo');

  @override
  Future<void> atualizarProjeto({
    required int projetoId,
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {}

  @override
  Future<void> excluirProjeto(int projetoId) async {}

  @override
  Future<List<OpcaoSelecao>> listarProjetos() async => const [
    OpcaoSelecao(id: 1, nome: 'Projeto Integrador'),
  ];

  @override
  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId}) async =>
      const [OpcaoSelecao(id: 1, nome: 'Oficina')];

  @override
  Future<int> criarClasseEvento({
    required int projetoId,
    required String nomeClasse,
  }) async => 1;

  @override
  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({
    required int projetoId,
  }) async => const [];

  @override
  Future<void> atualizarClasseEvento({
    required int classeId,
    required String nomeClasse,
  }) async {}

  @override
  Future<void> excluirClasseEvento(int classeId) async {}

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
  Future<void> atualizarEvento({
    required int eventoId,
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {}

  @override
  Future<void> excluirEvento(int eventoId) async {}

  @override
  Future<void> gerarRelatorio({required int templateId, int? eventoId}) async {}

  @override
  Future<int> criarTemplate({
    required int projetoId,
    required String nomeTemplate,
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async => 1;

  @override
  Future<Map<int, int>> listarVinculosClasseTemplate(int templateId) async =>
      const {};

  @override
  Future<void> vincularTemplateClasse({
    required int templateId,
    required int classeEventoId,
  }) async {}

  @override
  Future<void> desvincularTemplateClasse(int vinculoId) async {}

  @override
  Future<void> excluirTemplate(int templateId) async {}

  @override
  Future<List<AssinaturaTemplate>> listarAssinaturasTemplate(
    int templateId,
  ) async => const [];

  @override
  Future<void> criarAssinaturaTemplate({
    required int templateId,
    int? equipeProgramaId,
    int? equipeProjetoId,
  }) async {}

  @override
  Future<void> excluirAssinaturaTemplate(int assinaturaId) async {}

  @override
  Future<Uint8List> baixarArquivoTemplate(int templateId) async =>
      Uint8List(0);

  @override
  Future<Map<String, dynamic>> previsualizarTemplate({
    required int templateId,
    int? eventoId,
  }) async => const {
    'type': 'doc',
    'content': <Map<String, dynamic>>[],
  };

  @override
  Future<TemplateRelatorio> obterTemplate(int templateId) async =>
      _templates.first;

  @override
  Future<void> atualizarTemplate({
    required int templateId,
    required int projetoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  }) async {}

  @override
  Future<Uint8List> baixarRelatorio(int relatorioId) async => Uint8List(0);

  @override
  Future<void> atualizarRelatorio({
    required int relatorioId,
    required String nome,
  }) async {}

  @override
  Future<void> excluirRelatorio(int relatorioId) async {}
}

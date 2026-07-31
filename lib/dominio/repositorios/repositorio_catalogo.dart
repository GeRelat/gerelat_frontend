import 'dart:typed_data';

import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';

abstract interface class RepositorioClientes {
  Future<List<Cliente>> listarClientes();

  Future<List<OpcaoSelecao>> listarClientesSelecao();

  Future<Cliente> obterCliente(int clienteId);

  Future<void> criarCliente({
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
  });

  Future<void> atualizarCliente({
    required int clienteId,
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
  });

  Future<void> excluirCliente(int clienteId);
}

abstract interface class RepositorioProgramas {
  Future<List<Programa>> listarProgramas();

  Future<List<OpcaoSelecao>> listarProgramasSelecao();

  Future<Programa> obterPrograma(int programaId);

  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  });

  Future<void> atualizarPrograma({
    required int programaId,
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  });

  Future<void> excluirPrograma(int programaId);

  Future<void> criarProjeto({
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  });

  Future<List<Projeto>> listarProjetosDetalhados({int? programaId});

  Future<Projeto> obterProjeto(int projetoId);

  Future<void> atualizarProjeto({
    required int projetoId,
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  });

  Future<void> excluirProjeto(int projetoId);
}

abstract interface class RepositorioEventos {
  Future<List<Evento>> listarEventos();

  Future<Evento> obterEvento(int eventoId);

  Future<List<OpcaoSelecao>> listarProjetos();

  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId});

  Future<int> criarClasseEvento({
    required int projetoId,
    required String nomeClasse,
  });

  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({
    required int projetoId,
  });

  Future<void> atualizarClasseEvento({
    required int classeId,
    required String nomeClasse,
  });

  Future<void> excluirClasseEvento(int classeId);

  Future<void> criarEvento({
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  });

  Future<void> atualizarEvento({
    required int eventoId,
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  });

  Future<void> excluirEvento(int eventoId);
}

abstract interface class RepositorioTemplates {
  Future<List<TemplateRelatorio>> listarTemplates();

  Future<TemplateRelatorio> obterTemplate(int templateId);

  /// Cria um template a partir de um documento ProseMirror já pronto (ou de um
  /// documento vazio quando [modeloJson] é `null`). Usado pelo fluxo do editor,
  /// no qual o upload de `.docx` é opcional. Retorna o id do template criado.
  Future<int> criarTemplateComModelo({
    required int projetoId,
    required String nomeTemplate,
    Map<String, dynamic>? modeloJson,
  });

  /// Converte um `.docx` em documento ProseMirror (`modelo_json`) via
  /// `/templates/convert-docx/`, sem criar nada. Serve para semear o editor.
  Future<Map<String, dynamic>> converterDocxParaModelo({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  });

  /// Lê o `modelo_json` (documento ProseMirror do template) para edição no
  /// editor. Retorna um documento vazio se o template ainda não tiver conteúdo.
  Future<Map<String, dynamic>> obterModeloTemplate(int templateId);

  /// Persiste o `modelo_json` editado no editor (PATCH `/templates/<id>/`).
  Future<void> salvarModeloTemplate({
    required int templateId,
    required Map<String, dynamic> modeloJson,
  });

  Future<void> atualizarTemplate({
    required int templateId,
    required int projetoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  });

  /// Mapa classeEventoId -> id do vínculo, para o template informado.
  Future<Map<int, int>> listarVinculosClasseTemplate(int templateId);

  Future<void> vincularTemplateClasse({
    required int templateId,
    required int classeEventoId,
  });

  Future<void> desvincularTemplateClasse(int vinculoId);

  Future<void> excluirTemplate(int templateId);

  Future<List<AssinaturaTemplate>> listarAssinaturasTemplate(int templateId);

  /// Cria uma assinatura vinculando o template a um membro de equipe.
  /// Informe exatamente um dos dois ids (regra espelhada do backend, ver
  /// `AssinaturaTemplateSerializer.validate`).
  Future<void> criarAssinaturaTemplate({
    required int templateId,
    int? equipeProgramaId,
    int? equipeProjetoId,
  });

  Future<void> excluirAssinaturaTemplate(int assinaturaId);

  /// Baixa o arquivo .docx original do template (via `/templates/<id>/download/`).
  /// Retorna vazio/erro se o template foi criado sem upload de arquivo base
  /// (ex.: fluxo `from-json`, que não armazena o .docx original).
  Future<Uint8List> baixarArquivoTemplate(int templateId);

  /// Resolve as variáveis do projeto/evento sobre o `modelo_json` do template
  /// (via `/templates/<id>/preview/`) e retorna o documento ProseMirror
  /// resultante, para pré-visualização antes de gerar o relatório definitivo.
  Future<Map<String, dynamic>> previsualizarTemplate({
    required int templateId,
    int? eventoId,
  });
}

abstract interface class RepositorioRelatorios {
  Future<List<Relatorio>> listarRelatorios();

  /// Gera o relatório definitivo a partir do documento ProseMirror já
  /// resolvido/editado no preview ([documentoJson]). Envia para
  /// `POST /relatorios/`, aguarda a task assíncrona concluir e retorna o id do
  /// relatório gerado.
  Future<int> gerarRelatorioComDocumento({
    required int templateId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    String? nome,
  });

  Future<Uint8List> baixarRelatorio(int relatorioId);

  Future<void> atualizarRelatorio({
    required int relatorioId,
    required String nome,
  });

  Future<void> excluirRelatorio(int relatorioId);
}

abstract interface class RepositorioDashboard {
  Future<ResumoDashboard> obterResumoDashboard();
}

abstract interface class RepositorioEquipePrograma {
  Future<List<MembroEquipePrograma>> listarEquipePrograma({
    required int programaId,
  });

  Future<void> criarMembroEquipe({
    required int programaId,
    required String nome,
    required String cargo,
  });

  Future<void> atualizarMembroEquipe({
    required int membroId,
    required String nome,
    required String cargo,
  });

  Future<void> excluirMembroEquipe(int membroId);
}

abstract interface class RepositorioEquipeProjeto {
  Future<List<MembroEquipeProjeto>> listarEquipeProjeto({
    required int projetoId,
  });

  Future<void> criarMembroEquipeProjeto({
    required int projetoId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  });

  Future<void> atualizarMembroEquipeProjeto({
    required int membroId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  });

  Future<void> excluirMembroEquipeProjeto(int membroId);
}

abstract interface class RepositorioProjetoCampo {
  Future<List<ProjetoCampo>> listarCamposProjeto({required int projetoId});

  Future<void> criarCampoProjeto({
    required int projetoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  });

  Future<void> atualizarCampoProjeto({
    required int campoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  });

  Future<void> excluirCampoProjeto(int campoId);
}

abstract interface class RepositorioAssets {
  /// Envia uma imagem e retorna o id do Asset criado.
  Future<int> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    String descricao = '',
  });

  Future<List<Asset>> listarAssets();

  Future<Asset> obterAsset(int assetId);

  Future<void> atualizarAsset({
    required int assetId,
    required String descricao,
  });

  Future<void> excluirAsset(int assetId);
}

abstract class RepositorioCatalogo
    implements
        RepositorioClientes,
        RepositorioProgramas,
        RepositorioEventos,
        RepositorioTemplates,
        RepositorioRelatorios,
        RepositorioDashboard,
        RepositorioEquipePrograma,
        RepositorioEquipeProjeto,
        RepositorioProjetoCampo,
        RepositorioAssets {}

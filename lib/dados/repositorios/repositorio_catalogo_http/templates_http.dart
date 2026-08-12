import 'dart:typed_data';

import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioTemplatesHttpMixin implements RepositorioTemplates {
  ServicoApiGerelat get api;

  @override
  Future<List<TemplateRelatorio>> listarTemplates() async {
    final templates = await api.listar('/templates/');
    return templates.map(_templateDeMapa).toList();
  }

  @override
  Future<TemplateRelatorio> obterTemplate(int templateId) async {
    return _templateDeMapa(await api.obter('/templates/$templateId/'));
  }

  TemplateRelatorio _templateDeMapa(Map<String, dynamic> template) {
    final arquivo = paraTexto(template['modelo_arquivo_base']);
    return TemplateRelatorio(
      id: paraInteiro(template['id']),
      nivel: NivelEscopo.porValorApi(paraTexto(template['nivel'])),
      clienteId: paraInteiro(template['cliente']),
      programaId: paraInteiro(template['programa']),
      projetoId: paraInteiro(template['projeto']),
      nome: paraTexto(template['nome'], fallback: 'Template sem nome'),
      descricao: arquivo.isEmpty
          ? 'Template disponível para geração de relatórios.'
          : 'Arquivo base: $arquivo',
      tipo: 'DOCX',
      status: 'Ativo',
      arquivoBase: arquivo,
    );
  }

  /// Corpo com `nivel` + os três donos possíveis, sendo `null` os dois que não
  /// correspondem ao nível.
  ///
  /// Os `null` explícitos são obrigatórios no PATCH: o
  /// `_validate_owner_matches_nivel` do backend cai para o valor já gravado
  /// quando o campo não vem no corpo, então um PATCH parcial que só troca o
  /// dono deixaria o dono antigo preenchido e a API responderia 400
  /// ("Informe exatamente um dos campos: cliente, programa ou projeto.").
  Map<String, dynamic> _corpoEscopo(NivelEscopo escopo, int escopoId) => {
    'nivel': escopo.valorApi,
    'cliente': escopo == NivelEscopo.cliente ? escopoId : null,
    'programa': escopo == NivelEscopo.programa ? escopoId : null,
    'projeto': escopo == NivelEscopo.projeto ? escopoId : null,
  };

  @override
  Future<void> atualizarTemplate({
    required int templateId,
    required NivelEscopo escopo,
    required int escopoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  }) async {
    await api.atualizar('/templates/$templateId/', {
      ..._corpoEscopo(escopo, escopoId),
      'nome': nomeTemplate,
    });

    if (arquivoBytes == null || nomeArquivo == null) return;

    final modeloJson = await _converterDocxParaJson(
      arquivoBytes: arquivoBytes,
      nomeArquivo: nomeArquivo,
    );

    await api.atualizar('/templates/$templateId/', {'modelo_json': modeloJson});
  }

  @override
  Future<int> criarTemplateComModelo({
    required NivelEscopo escopo,
    required int escopoId,
    required String nomeTemplate,
    Map<String, dynamic>? modeloJson,
  }) async {
    final resposta = await api.criar('/templates/', {
      'nome': nomeTemplate,
      ..._corpoEscopo(escopo, escopoId),
      'modelo_json': modeloJson ?? _documentoVazio(),
    });

    final taskId = paraTexto(resposta['task_id']);
    if (taskId.isEmpty) {
      throw Exception(
        'Resposta inesperada da API ao criar template: task_id ausente.',
      );
    }

    final resultado = await aguardarTaskConcluir(api, taskId);
    final resultadoMap = resultado['result'];
    if (resultadoMap is! Map) {
      throw Exception('Resposta inesperada da task ao criar template.');
    }

    return idCriado(Map<String, dynamic>.from(resultadoMap), 'id', 'template');
  }

  @override
  Future<Map<String, dynamic>> converterDocxParaModelo({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) {
    return _converterDocxParaJson(
      arquivoBytes: arquivoBytes,
      nomeArquivo: nomeArquivo,
    );
  }

  @override
  Future<Map<String, dynamic>> obterModeloTemplate(int templateId) async {
    final template = await api.obter('/templates/$templateId/');
    final modelo = template['modelo_json'];
    if (modelo is Map && modelo.isNotEmpty) {
      return Map<String, dynamic>.from(modelo);
    }
    return _documentoVazio();
  }

  @override
  Future<void> salvarModeloTemplate({
    required int templateId,
    required Map<String, dynamic> modeloJson,
  }) async {
    await api.atualizar('/templates/$templateId/', {'modelo_json': modeloJson});
  }

  Map<String, dynamic> _documentoVazio() => {
    'type': 'doc',
    'content': [
      {'type': 'paragraph', 'content': <dynamic>[]},
    ],
  };

  /// Converte um .docx em ProseMirror JSON via `/templates/convert-docx/`,
  /// o mesmo formato usado por `Template.modelo_json` para resolver
  /// variáveis e gerar o relatório final (ver document_engine no gerelat-api).
  Future<Map<String, dynamic>> _converterDocxParaJson({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async {
    final conversao = await api.criarMultipart(
      caminho: '/templates/convert-docx/',
      campos: const {},
      campoArquivo: 'arquivo',
      arquivoBytes: arquivoBytes,
      nomeArquivo: nomeArquivo,
      contentType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );

    final modeloJson = conversao['modelo_json'];
    if (modeloJson is! Map) {
      throw Exception('Falha ao converter o arquivo .docx em template.');
    }
    return Map<String, dynamic>.from(modeloJson);
  }

  @override
  Future<Map<int, int>> listarVinculosClasseTemplate(int templateId) async {
    final vinculos = await api.listar('/template-classes-evento/');
    final mapa = <int, int>{};
    for (final vinculo in vinculos) {
      if (paraInteiro(vinculo['template']) != templateId) continue;
      final classeId = paraInteiro(vinculo['classe_evento']);
      final vinculoId = paraInteiro(vinculo['id']);
      if (classeId == null || vinculoId == null) continue;
      mapa[classeId] = vinculoId;
    }
    return mapa;
  }

  @override
  Future<void> vincularTemplateClasse({
    required int templateId,
    required int classeEventoId,
  }) async {
    await api.criar('/template-classes-evento/', {
      'template': templateId,
      'classe_evento': classeEventoId,
    });
  }

  @override
  Future<void> desvincularTemplateClasse(int vinculoId) async {
    await api.excluir('/template-classes-evento/$vinculoId/');
  }

  @override
  Future<void> excluirTemplate(int templateId) async {
    await api.excluir('/templates/$templateId/');
  }

  @override
  Future<List<AssinaturaTemplate>> listarAssinaturasTemplate(
    int templateId,
  ) async {
    final assinaturas = await api.listar('/assinaturas-template/');
    final relevantes = assinaturas
        .where(
          (assinatura) => paraInteiro(assinatura['template']) == templateId,
        )
        .toList();

    final idsEquipePrograma = relevantes
        .map((assinatura) => paraInteiro(assinatura['equipe_programa']))
        .whereType<int>()
        .toSet();
    final idsEquipeProjeto = relevantes
        .map((assinatura) => paraInteiro(assinatura['equipe_projeto']))
        .whereType<int>()
        .toSet();

    final membrosPrograma = idsEquipePrograma.isEmpty
        ? <Map<String, dynamic>>[]
        : await api.listar('/equipes-programa/');
    final membrosProjeto = idsEquipeProjeto.isEmpty
        ? <Map<String, dynamic>>[]
        : await api.listar('/equipes-projeto/');

    final dadosPorEquipePrograma = {
      for (final membro in membrosPrograma)
        if (paraInteiro(membro['id']) != null)
          paraInteiro(membro['id'])!: (
            nome: paraTexto(membro['nome']),
            cargo: paraTexto(membro['cargo']),
          ),
    };
    final dadosPorEquipeProjeto = {
      for (final membro in membrosProjeto)
        if (paraInteiro(membro['id']) != null)
          paraInteiro(membro['id'])!: (
            nome: paraTexto(membro['nome']),
            cargo: paraTexto(membro['cargo']),
          ),
    };

    return relevantes.map((assinatura) {
      final idEquipePrograma = paraInteiro(assinatura['equipe_programa']);
      final idEquipeProjeto = paraInteiro(assinatura['equipe_projeto']);
      final dadosPrograma = idEquipePrograma == null
          ? null
          : dadosPorEquipePrograma[idEquipePrograma];
      final dadosProjeto = idEquipeProjeto == null
          ? null
          : dadosPorEquipeProjeto[idEquipeProjeto];

      return AssinaturaTemplate(
        id: paraInteiro(assinatura['id']),
        templateId: paraInteiro(assinatura['template']),
        equipeProgramaId: idEquipePrograma,
        equipeProjetoId: idEquipeProjeto,
        nomeSignatario: dadosPrograma?.nome ?? dadosProjeto?.nome ?? '',
        cargoSignatario: dadosPrograma?.cargo ?? dadosProjeto?.cargo ?? '',
      );
    }).toList();
  }

  @override
  Future<void> criarAssinaturaTemplate({
    required int templateId,
    int? equipeProgramaId,
    int? equipeProjetoId,
  }) async {
    await api.criar('/assinaturas-template/', {
      'template': templateId,
      'equipe_programa': equipeProgramaId,
      'equipe_projeto': equipeProjetoId,
    });
  }

  @override
  Future<void> excluirAssinaturaTemplate(int assinaturaId) async {
    await api.excluir('/assinaturas-template/$assinaturaId/');
  }

  @override
  Future<Uint8List> baixarArquivoTemplate(int templateId) async {
    return api.baixarArquivo('/templates/$templateId/download/');
  }

  @override
  Future<List<Evento>> listarEventosDisponiveis(int templateId) async {
    final meventos = await api.listar(
      '/templates/$templateId/eventos-disponiveis/',
    );
    return meventos.map((evento) {
      final idProjeto = paraInteiro(evento['projeto']);
      final idClasse = paraInteiro(evento['classe_evento']);
      final nomeNoPayload = paraTexto(evento['classe_evento_nome']);
      return Evento(
        id: paraInteiro(evento['id']),
        clienteId: paraInteiro(evento['cliente']),
        programaId: paraInteiro(evento['programa']),
        projetoId: idProjeto,
        classeEventoId: idClasse,
        nome: paraTexto(evento['nome'], fallback: 'Evento sem nome'),
        programa: paraTexto(
          evento['programa_nome'],
          fallback: 'Escopo direto',
        ),
        data: DateTime.tryParse(paraTexto(evento['data'])),
        local: paraTexto(evento['local']),
        endereco: paraTexto(evento['endereco']),
        objetivo: paraTexto(evento['objetivo']),
        classeEventoNome: nomeNoPayload,
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> previsualizarTemplate({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
  }) async {
    final query = _queryEscopo(
      clienteId: clienteId,
      programaId: programaId,
      projetoId: projetoId,
      eventoId: eventoId,
    );
    final resposta = await api.obter('/templates/$templateId/preview/$query');
    final documento = resposta['documento_json'];
    if (documento is! Map) {
      throw Exception(
        'Não foi possível carregar a pré-visualização do template.',
      );
    }
    return Map<String, dynamic>.from(documento);
  }

  @override
  Future<List<VariavelDisponivel>> listarVariaveisDisponiveis({
    required NivelEscopo escopo,
    required int escopoId,
  }) async {
    final query = _queryEscopo(
      clienteId: escopo == NivelEscopo.cliente ? escopoId : null,
      programaId: escopo == NivelEscopo.programa ? escopoId : null,
      projetoId: escopo == NivelEscopo.projeto ? escopoId : null,
      extras: {'nivel': escopo.valorApi},
    );
    final variaveis = await api.listar(
      '/templates/variaveis-disponiveis/$query',
    );

    return variaveis
        .map(
          (variavel) => VariavelDisponivel(
            referencia: paraTexto(variavel['referencia']),
            descricao: paraTexto(variavel['descricao']),
            tipo: TipoCampo.porValorApi(paraTexto(variavel['tipo'])),
            nivelAplicacao: NivelAplicacao.porValorApi(
              paraTexto(variavel['nivel_aplicacao']),
            ),
            origem: OrigemVariavel.porValorApi(paraTexto(variavel['origem'])),
            obrigatorio: variavel['obrigatorio'] == true,
            escopoNome: paraTexto(variavel['escopo_nome']),
          ),
        )
        .toList();
  }

  /// Monta a query string com os ids da cadeia de escopo que estiverem
  /// preenchidos (mais [extras]), ou string vazia se não houver nenhum.
  String _queryEscopo({
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, String> extras = const {},
  }) {
    final parametros = <String, String>{
      ...extras,
      if (clienteId != null) 'cliente_id': '$clienteId',
      if (programaId != null) 'programa_id': '$programaId',
      if (projetoId != null) 'projeto_id': '$projetoId',
      if (eventoId != null) 'evento_id': '$eventoId',
    };
    if (parametros.isEmpty) return '';
    return '?${Uri(queryParameters: parametros).query}';
  }
}

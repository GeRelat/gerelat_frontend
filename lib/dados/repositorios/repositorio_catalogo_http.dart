import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
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
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RepositorioCatalogoHttp implements RepositorioCatalogo {
  final ServicoApiGerelat _api;

  RepositorioCatalogoHttp(this._api);

  @override
  Future<List<Cliente>> listarClientes() async {
    final clientes = await _getLista('/clientes/');
    return clientes.map(_clienteDeMapa).toList();
  }

  @override
  Future<List<OpcaoSelecao>> listarClientesSelecao() async {
    final clientes = await _getLista('/clientes/');
    return clientes
        .map(
          (cliente) => OpcaoSelecao(
            id: _inteiro(cliente['id']) ?? 0,
            nome: _texto(cliente['nome'], fallback: 'Cliente sem nome'),
          ),
        )
        .where((opcao) => opcao.id > 0)
        .toList();
  }

  @override
  Future<Cliente> obterCliente(int clienteId) async {
    final cliente = await _api.obter('/clientes/$clienteId/');
    return _clienteDeMapa(cliente);
  }

  @override
  Future<void> criarCliente({required String nome, String cnpj = '', String nomeContato = '', String emailContato = '', String foneContato = '', String numeroContrato = '', required DateTime dataTerminoContrato}) async {
    await _api.criar('/clientes/', {
      'nome': nome,
      'cnpj': cnpj,
      'nome_contato': nomeContato,
      'email_contato': emailContato,
      'fone_contato': foneContato,
      'numero_contrato': numeroContrato,
      'data_termino_contrato': _dataApi(dataTerminoContrato),
    });
  }

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
  }) async {
    await _api.atualizar('/clientes/$clienteId/', {
      'nome': nome,
      'cnpj': cnpj,
      'nome_contato': nomeContato,
      'email_contato': emailContato,
      'fone_contato': foneContato,
      'numero_contrato': numeroContrato,
      'data_termino_contrato': _dataApi(dataTerminoContrato),
    });
  }

  @override
  Future<void> excluirCliente(int clienteId) async {
    await _api.excluir('/clientes/$clienteId/');
  }

  Cliente _clienteDeMapa(Map<String, dynamic> cliente) {
    return Cliente(
      id: _inteiro(cliente['id']),
      nome: _texto(cliente['nome'], fallback: 'Cliente sem nome'),
      cnpj: _texto(cliente['cnpj']),
      nomeContato: _texto(cliente['nome_contato']),
      emailContato: _texto(cliente['email_contato']),
      foneContato: _texto(cliente['fone_contato']),
      numeroContrato: _texto(cliente['numero_contrato']),
      dataTerminoContrato: DateTime.tryParse(_texto(cliente['data_termino_contrato'])),
    );
  }

  @override
  Future<List<Programa>> listarProgramas() async {
    final programas = await _getLista('/programas/');
    final projetos = await _getLista('/projetos/');
    final eventos = await _getLista('/eventos/');
    final clientes = await _getLista('/clientes/');

    final projetosPorPrograma = <int, int>{};
    final programaPorProjeto = <int, int>{};

    for (final projeto in projetos) {
      final idProjeto = _inteiro(projeto['id']);
      final idPrograma = _inteiro(projeto['programa']);
      if (idProjeto == null || idPrograma == null) continue;

      programaPorProjeto[idProjeto] = idPrograma;
      projetosPorPrograma[idPrograma] = (projetosPorPrograma[idPrograma] ?? 0) + 1;
    }

    final eventosPorPrograma = <int, int>{};
    for (final evento in eventos) {
      final idProjeto = _inteiro(evento['projeto']);
      final idPrograma = programaPorProjeto[idProjeto];
      if (idPrograma == null) continue;
      eventosPorPrograma[idPrograma] = (eventosPorPrograma[idPrograma] ?? 0) + 1;
    }

    final nomeClientePorId = {
      for (final cliente in clientes)
        if (_inteiro(cliente['id']) != null)
          _inteiro(cliente['id'])!: _texto(cliente['nome']),
    };

    return programas.map((programa) {
      final idPrograma = _inteiro(programa['id']) ?? 0;
      final idCliente = _inteiro(programa['cliente']);
      return Programa(
        id: idPrograma,
        nome: _texto(programa['nome'], fallback: 'Programa sem nome'),
        descricao: _descricaoPrograma(programa),
        projetos: projetosPorPrograma[idPrograma] ?? 0,
        eventos: eventosPorPrograma[idPrograma] ?? 0,
        status: 'Ativo',
        leiCriacao: _texto(programa['lei_criacao']),
        convenioDados: _texto(programa['convenio_dados']),
        rodape: _texto(programa['rodape']),
        logomarca: _texto(programa['logomarca']),
        clienteId: idCliente,
        clienteNome: idCliente == null ? '' : (nomeClientePorId[idCliente] ?? ''),
      );
    }).toList();
  }

  @override
  Future<Programa> obterPrograma(int programaId) async {
    final programa = await _api.obter('/programas/$programaId/');
    final idCliente = _inteiro(programa['cliente']);
    var nomeCliente = '';
    if (idCliente != null) {
      final cliente = await _api.obter('/clientes/$idCliente/');
      nomeCliente = _texto(cliente['nome']);
    }

    // A API não filtra por query param, então contamos como em
    // `listarProgramas`: projetos ligados a este programa e eventos ligados
    // a esses projetos.
    final projetos = await _getLista('/projetos/');
    final idsProjetosDoPrograma = projetos
        .where((projeto) => _inteiro(projeto['programa']) == programaId)
        .map((projeto) => _inteiro(projeto['id']))
        .whereType<int>()
        .toSet();

    final eventos = await _getLista('/eventos/');
    final totalEventos = eventos.where((evento) => idsProjetosDoPrograma.contains(_inteiro(evento['projeto']))).length;

    return Programa(
      id: _inteiro(programa['id']),
      nome: _texto(programa['nome'], fallback: 'Programa sem nome'),
      descricao: _descricaoPrograma(programa),
      projetos: idsProjetosDoPrograma.length,
      eventos: totalEventos,
      status: 'Ativo',
      leiCriacao: _texto(programa['lei_criacao']),
      convenioDados: _texto(programa['convenio_dados']),
      rodape: _texto(programa['rodape']),
      logomarca: _texto(programa['logomarca']),
      clienteId: idCliente,
      clienteNome: nomeCliente,
    );
  }

  @override
  Future<List<Evento>> listarEventos() async {
    final eventos = await _getLista('/eventos/');
    final projetos = await _getLista('/projetos/');
    final programas = await _getLista('/programas/');

    final programaPorId = {
      for (final programa in programas)
        if (_inteiro(programa['id']) != null)
          _inteiro(programa['id'])!: _texto(programa['nome']),
    };

    final programaPorProjeto = <int, String>{};
    for (final projeto in projetos) {
      final idProjeto = _inteiro(projeto['id']);
      final idPrograma = _inteiro(projeto['programa']);
      if (idProjeto == null || idPrograma == null) continue;
      programaPorProjeto[idProjeto] = programaPorId[idPrograma] ?? 'Programa nao informado';
    }

    return eventos.map((evento) {
      final idProjeto = _inteiro(evento['projeto']);
      return Evento(
        id: _inteiro(evento['id']),
        projetoId: idProjeto,
        classeEventoId: _inteiro(evento['classe_evento']),
        nome: _texto(evento['nome'], fallback: 'Evento sem nome'),
        programa: programaPorProjeto[idProjeto] ?? 'Programa nao informado',
        data: DateTime.tryParse(_texto(evento['data'])),
        status: 'Confirmado',
        local: _texto(evento['local']),
        endereco: _texto(evento['endereco']),
        objetivo: _texto(evento['objetivo']),
      );
    }).toList();
  }

  @override
  Future<Evento> obterEvento(int eventoId) async {
    final evento = await _api.obter('/eventos/$eventoId/');
    final projetoId = _inteiro(evento['projeto']);
    final classeEventoId = _inteiro(evento['classe_evento']);

    String programa = 'Programa nao informado';
    if (projetoId != null) {
      final projeto = await _api.obter('/projetos/$projetoId/');
      final programaId = _inteiro(projeto['programa']);
      if (programaId != null) {
        final programaMap = await _api.obter('/programas/$programaId/');
        programa = _texto(programaMap['nome'], fallback: programa);
      }
    }

    String classeEventoNome = '';
    if (classeEventoId != null) {
      final classeEvento = await _api.obter('/classes-evento/$classeEventoId/');
      classeEventoNome = _texto(classeEvento['nome_classe']);
    }

    return Evento(
      id: _inteiro(evento['id']),
      projetoId: projetoId,
      classeEventoId: classeEventoId,
      nome: _texto(evento['nome'], fallback: 'Evento sem nome'),
      programa: programa,
      data: DateTime.tryParse(_texto(evento['data'])),
      status: 'Confirmado',
      local: _texto(evento['local']),
      endereco: _texto(evento['endereco']),
      objetivo: _texto(evento['objetivo']),
      classeEventoNome: classeEventoNome,
    );
  }

  @override
  Future<List<Relatorio>> listarRelatorios() async {
    final relatorios = await _getLista('/relatorios/');
    final eventos = await _getLista('/eventos/');
    final templates = await _getLista('/templates/');

    final eventoPorId = {
      for (final evento in eventos)
        if (_inteiro(evento['id']) != null)
          _inteiro(evento['id'])!: _texto(evento['nome']),
    };

    final templatePorId = {
      for (final template in templates)
        if (_inteiro(template['id']) != null)
          _inteiro(template['id'])!: _texto(template['nome']),
    };

    return relatorios.map((relatorio) {
      final idRelatorio = _inteiro(relatorio['id']) ?? 0;
      final idEvento = _inteiro(relatorio['evento']);
      final idTemplate = _inteiro(relatorio['template']);
      final nome = _texto(relatorio['nome']);

      return Relatorio(
        id: idRelatorio,
        eventoId: idEvento,
        templateId: idTemplate,
        titulo: nome.isEmpty ? 'Relatorio $idRelatorio' : nome,
        evento: eventoPorId[idEvento] ?? 'Evento nao informado',
        template: templatePorId[idTemplate] ?? 'Template nao informado',
        dataGeracao: _formatarDataTexto(_texto(relatorio['data_criacao'])),
        status: _texto(relatorio['status'], fallback: 'Pendente'),
      );
    }).toList();
  }

  @override
  Future<List<TemplateRelatorio>> listarTemplates() async {
    final templates = await _getLista('/templates/');

    return templates.map((template) {
      final arquivo = _texto(template['modelo_arquivo_base']);
      return TemplateRelatorio(
        id: _inteiro(template['id']),
        projetoId: _inteiro(template['projeto']),
        nome: _texto(template['nome'], fallback: 'Template sem nome'),
        descricao: arquivo.isEmpty
            ? 'Template disponivel para geracao de relatorios.'
            : 'Arquivo base: $arquivo',
        tipo: 'DOCX',
        status: 'Ativo',
        arquivoBase: arquivo,
      );
    }).toList();
  }

  @override
  Future<TemplateRelatorio> obterTemplate(int templateId) async {
    final template = await _api.obter('/templates/$templateId/');
    final arquivo = _texto(template['modelo_arquivo_base']);
    return TemplateRelatorio(
      id: _inteiro(template['id']),
      projetoId: _inteiro(template['projeto']),
      nome: _texto(template['nome'], fallback: 'Template sem nome'),
      descricao: arquivo.isEmpty
          ? 'Template disponivel para geracao de relatorios.'
          : 'Arquivo base: $arquivo',
      tipo: 'DOCX',
      status: 'Ativo',
      arquivoBase: arquivo,
    );
  }

  @override
  Future<ResumoDashboard> obterResumoDashboard() async {
    final programas = await listarProgramas();
    final templates = await listarTemplates();
    final relatorios = await listarRelatorios();

    return ResumoDashboard(
      programas: programas.length,
      projetos: programas.fold(0, (total, programa) => total + programa.projetos),
      eventos: programas.fold(0, (total, programa) => total + programa.eventos),
      templates: templates.length,
      relatorios: relatorios.length,
    );
  }

  @override
  Future<void> criarPrograma({required String nome, required String leiCriacao, required String convenioDados, String rodape = '', String logomarca = '', int? clienteId}) async {
    await _api.criar('/programas/', {'nome': nome, 'lei_criacao': leiCriacao, 'convenio_dados': convenioDados, 'rodape': rodape, 'logomarca': logomarca, 'cliente': clienteId});
  }

  @override
  Future<void> atualizarPrograma({required int programaId, required String nome, required String leiCriacao, required String convenioDados, String rodape = '', String logomarca = '', int? clienteId}) async {
    await _api.atualizar('/programas/$programaId/', {'nome': nome, 'lei_criacao': leiCriacao, 'convenio_dados': convenioDados, 'rodape': rodape, 'logomarca': logomarca, 'cliente': clienteId});
  }

  @override
  Future<void> excluirPrograma(int programaId) async {
    await _api.excluir('/programas/$programaId/');
  }

  @override
  Future<List<MembroEquipePrograma>> listarEquipePrograma({required int programaId}) async {
    final membros = await _getLista('/equipes-programa/');
    return membros
        .where((membro) => _inteiro(membro['programa']) == programaId)
        .map(
          (membro) => MembroEquipePrograma(
            id: _inteiro(membro['id']),
            programaId: programaId,
            nome: _texto(membro['nome']),
            cargo: _texto(membro['cargo']),
          ),
        )
        .toList();
  }

  @override
  Future<void> criarMembroEquipe({required int programaId, required String nome, required String cargo}) async {
    await _api.criar('/equipes-programa/', {'programa': programaId, 'nome': nome, 'cargo': cargo});
  }

  @override
  Future<void> atualizarMembroEquipe({required int membroId, required String nome, required String cargo}) async {
    await _api.atualizar('/equipes-programa/$membroId/', {'nome': nome, 'cargo': cargo});
  }

  @override
  Future<void> excluirMembroEquipe(int membroId) async {
    await _api.excluir('/equipes-programa/$membroId/');
  }

  @override
  Future<List<MembroEquipeProjeto>> listarEquipeProjeto({required int projetoId}) async {
    final membros = await _getLista('/equipes-projeto/');
    return membros
        .where((membro) => _inteiro(membro['projeto']) == projetoId)
        .map(
          (membro) => MembroEquipeProjeto(
            id: _inteiro(membro['id']),
            projetoId: projetoId,
            nomeEquipe: _texto(membro['nome_equipe']),
            nome: _texto(membro['nome']),
            cargo: _texto(membro['cargo']),
          ),
        )
        .toList();
  }

  @override
  Future<void> criarMembroEquipeProjeto({required int projetoId, required String nomeEquipe, required String nome, required String cargo}) async {
    await _api.criar('/equipes-projeto/', {'projeto': projetoId, 'nome_equipe': nomeEquipe, 'nome': nome, 'cargo': cargo});
  }

  @override
  Future<void> atualizarMembroEquipeProjeto({required int membroId, required String nomeEquipe, required String nome, required String cargo}) async {
    await _api.atualizar('/equipes-projeto/$membroId/', {'nome_equipe': nomeEquipe, 'nome': nome, 'cargo': cargo});
  }

  @override
  Future<void> excluirMembroEquipeProjeto(int membroId) async {
    await _api.excluir('/equipes-projeto/$membroId/');
  }

  @override
  Future<List<OpcaoSelecao>> listarProgramasSelecao() async {
    final programas = await _getLista('/programas/');
    return programas
        .map(
          (programa) => OpcaoSelecao(
            id: _inteiro(programa['id']) ?? 0,
            nome: _texto(programa['nome'], fallback: 'Programa sem nome'),
          ),
        )
        .where((opcao) => opcao.id > 0)
        .toList();
  }

  @override
  Future<void> criarProjeto({required int programaId, required String nome, String parceira = '', String sigla = '', String logomarca = ''}) async {
    await _api.criar('/projetos/', {'programa': programaId, 'nome': nome, 'parceira': parceira, 'sigla': sigla, 'logomarca': logomarca});
  }

  @override
  Future<List<Projeto>> listarProjetosDetalhados({int? programaId}) async {
    final projetos = await _getLista('/projetos/');
    return projetos.where((projeto) => programaId == null || _inteiro(projeto['programa']) == programaId).map(_projetoDeMapa).toList();
  }

  @override
  Future<Projeto> obterProjeto(int projetoId) async {
    final projeto = await _api.obter('/projetos/$projetoId/');
    return _projetoDeMapa(projeto);
  }

  @override
  Future<void> atualizarProjeto({required int projetoId, required int programaId, required String nome, String parceira = '', String sigla = '', String logomarca = ''}) async {
    await _api.atualizar('/projetos/$projetoId/', {'programa': programaId, 'nome': nome, 'parceira': parceira, 'sigla': sigla, 'logomarca': logomarca});
  }

  @override
  Future<void> excluirProjeto(int projetoId) async {
    await _api.excluir('/projetos/$projetoId/');
  }

  Projeto _projetoDeMapa(Map<String, dynamic> projeto) {
    return Projeto(
      id: _inteiro(projeto['id']),
      programaId: _inteiro(projeto['programa']),
      nome: _texto(projeto['nome'], fallback: 'Projeto sem nome'),
      parceira: _texto(projeto['parceira']),
      sigla: _texto(projeto['sigla']),
      logomarca: _texto(projeto['logomarca']),
    );
  }

  @override
  Future<List<OpcaoSelecao>> listarProjetos() async {
    final projetos = await _getLista('/projetos/');
    return projetos
        .map(
          (projeto) => OpcaoSelecao(
            id: _inteiro(projeto['id']) ?? 0,
            nome: _texto(projeto['nome'], fallback: 'Projeto sem nome'),
          ),
        )
        .where((opcao) => opcao.id > 0)
        .toList();
  }

  @override
  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId}) async {
    final classes = await _getLista('/classes-evento/');
    return classes
        .where((classe) => projetoId == null || _inteiro(classe['projeto']) == projetoId)
        .map(
          (classe) => OpcaoSelecao(
            id: _inteiro(classe['id']) ?? 0,
            nome: _texto(classe['nome_classe'], fallback: 'Classe sem nome'),
          ),
        )
        .where((opcao) => opcao.id > 0)
        .toList();
  }

  @override
  Future<int> criarClasseEvento({
    required int projetoId,
    required String nomeClasse,
  }) async {
    final resposta = await _api.criar('/classes-evento/', {
      'projeto': projetoId,
      'nome_classe': nomeClasse,
    });
    return _idCriado(resposta, 'id', 'classe de evento');
  }

  @override
  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({required int projetoId}) async {
    final classes = await _getLista('/classes-evento/');
    return classes
        .where((classe) => _inteiro(classe['projeto']) == projetoId)
        .map(
          (classe) => ClasseEvento(
            id: _inteiro(classe['id']),
            projetoId: _inteiro(classe['projeto']),
            nomeClasse: _texto(
              classe['nome_classe'],
              fallback: 'Classe sem nome',
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> atualizarClasseEvento({required int classeId, required String nomeClasse}) async {
    await _api.atualizar('/classes-evento/$classeId/', {'nome_classe': nomeClasse});
  }

  @override
  Future<void> excluirClasseEvento(int classeId) async {
    await _api.excluir('/classes-evento/$classeId/');
  }

  @override
  Future<void> criarEvento({required int projetoId, required int classeEventoId, required String nome, required DateTime data, String local = '', String endereco = '', String objetivo = ''}) async {
    await _api.criar('/eventos/', {'projeto': projetoId, 'classe_evento': classeEventoId, 'nome': nome, 'data': _dataApi(data), 'local': local, 'endereco': endereco, 'objetivo': objetivo});
  }

  @override
  Future<void> atualizarEvento({required int eventoId, required int projetoId, required int classeEventoId, required String nome, required DateTime data, String local = '', String endereco = '', String objetivo = ''}) async {
    await _api.atualizar('/eventos/$eventoId/', {'projeto': projetoId, 'classe_evento': classeEventoId, 'nome': nome, 'data': _dataApi(data), 'local': local, 'endereco': endereco, 'objetivo': objetivo});
  }

  @override
  Future<void> excluirEvento(int eventoId) async {
    await _api.excluir('/eventos/$eventoId/');
  }

  @override
  Future<void> gerarRelatorio({required int templateId, int? eventoId}) async {
    await gerarRelatorioComDocumento(templateId: templateId, eventoId: eventoId);
  }

  @override
  Future<int> gerarRelatorioComDocumento({
    required int templateId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    String? nome,
  }) async {
    final dados = <String, dynamic>{'template': templateId};
    if (eventoId case final id?) dados['evento'] = id;
    if (documentoJson != null) dados['documento_json'] = documentoJson;
    if (nome != null && nome.trim().isNotEmpty) dados['nome'] = nome.trim();

    final resposta = await _api.criar('/relatorios/', dados);
    final taskId = _texto(resposta['task_id']);
    if (taskId.isEmpty) {
      throw Exception(
        'Resposta inesperada da API ao gerar relatório: task_id ausente.',
      );
    }

    final resultado = await _aguardarTaskConcluir(taskId);
    final resultadoMap = resultado['result'];
    if (resultadoMap is! Map) {
      throw Exception('Resposta inesperada da task ao gerar relatório.');
    }
    return _idCriado(Map<String, dynamic>.from(resultadoMap), 'id', 'relatório');
  }

  @override
  Future<int> criarTemplate({
    required int projetoId,
    required String nomeTemplate,
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async {
    try {
      developer.log(
        'criarTemplate: projetoId=$projetoId nomeTemplate=$nomeTemplate nomeArquivo=$nomeArquivo bytes=${arquivoBytes.length}',
        name: 'RepositorioCatalogoHttp',
      );
    } catch (_) {}
    final modeloJson = await _converterDocxParaJson(
      arquivoBytes: arquivoBytes,
      nomeArquivo: nomeArquivo,
    );

    try {
      developer.log(
        'criarTemplate: modeloJson tipo=${modeloJson.runtimeType} chaves=${modeloJson.keys.toList()}',
        name: 'RepositorioCatalogoHttp',
      );
    } catch (_) {}

    final resposta = await _api.criar('/templates/', {
      'nome': nomeTemplate,
      'projeto': projetoId,
      'modelo_json': modeloJson,
    });

    try {
      developer.log(
        'criarTemplate: resposta status esperada via _idCriado bodyKeys=${resposta.keys.toList()} resposta=$resposta',
        name: 'RepositorioCatalogoHttp',
      );
    } catch (_) {}
    final taskId = _texto(resposta['task_id']);
    if (taskId.isEmpty) {
      throw Exception('Resposta inesperada da API ao criar template: task_id ausente.');
    }

    final resultado = await _aguardarTaskConcluir(taskId);
    final resultadoMap = resultado['result'];
    if (resultadoMap is! Map) {
      throw Exception('Resposta inesperada da task ao criar template.');
    }

    return _idCriado(Map<String, dynamic>.from(resultadoMap), 'id', 'template');
  }

  @override
  Future<void> atualizarTemplate({
    required int templateId,
    required int projetoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  }) async {
    await _api.atualizar('/templates/$templateId/', {
      'projeto': projetoId,
      'nome': nomeTemplate,
    });

    if (arquivoBytes == null || nomeArquivo == null) return;

    final modeloJson = await _converterDocxParaJson(arquivoBytes: arquivoBytes, nomeArquivo: nomeArquivo);

    await _api.atualizar('/templates/$templateId/update-json/', {'modelo_json': modeloJson});
  }

  @override
  Future<int> criarTemplateComModelo({
    required int projetoId,
    required String nomeTemplate,
    Map<String, dynamic>? modeloJson,
  }) async {
    final resposta = await _api.criar('/templates/', {
      'nome': nomeTemplate,
      'projeto': projetoId,
      'modelo_json': modeloJson ?? _documentoVazio(),
    });

    final taskId = _texto(resposta['task_id']);
    if (taskId.isEmpty) {
      throw Exception(
        'Resposta inesperada da API ao criar template: task_id ausente.',
      );
    }

    final resultado = await _aguardarTaskConcluir(taskId);
    final resultadoMap = resultado['result'];
    if (resultadoMap is! Map) {
      throw Exception('Resposta inesperada da task ao criar template.');
    }

    return _idCriado(Map<String, dynamic>.from(resultadoMap), 'id', 'template');
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
    final template = await _api.obter('/templates/$templateId/');
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
    await _api.atualizar('/templates/$templateId/', {
      'modelo_json': modeloJson,
    });
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
  Future<Map<String, dynamic>> _converterDocxParaJson({required Uint8List arquivoBytes, required String nomeArquivo}) async {
    final conversao = await _api.criarMultipart(
      caminho: '/templates/convert-docx/',
      campos: const {},
      campoArquivo: 'arquivo',
      arquivoBytes: arquivoBytes,
      nomeArquivo: nomeArquivo,
      contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );

    final modeloJson = conversao['modelo_json'];
    if (modeloJson is! Map) {
      throw Exception('Falha ao converter o arquivo .docx em template.');
    }
    return Map<String, dynamic>.from(modeloJson);
  }

  @override
  Future<Map<int, int>> listarVinculosClasseTemplate(int templateId) async {
    final vinculos = await _getLista('/template-classes-evento/');
    final mapa = <int, int>{};
    for (final vinculo in vinculos) {
      if (_inteiro(vinculo['template']) != templateId) continue;
      final classeId = _inteiro(vinculo['classe_evento']);
      final vinculoId = _inteiro(vinculo['id']);
      if (classeId == null || vinculoId == null) continue;
      mapa[classeId] = vinculoId;
    }
    return mapa;
  }

  @override
  Future<void> vincularTemplateClasse({required int templateId, required int classeEventoId}) async {
    await _api.criar('/template-classes-evento/', {'template': templateId, 'classe_evento': classeEventoId});
  }

  @override
  Future<void> desvincularTemplateClasse(int vinculoId) async {
    await _api.excluir('/template-classes-evento/$vinculoId/');
  }

  @override
  Future<void> excluirTemplate(int templateId) async {
    await _api.excluir('/templates/$templateId/');
  }

  @override
  Future<List<AssinaturaTemplate>> listarAssinaturasTemplate(int templateId) async {
    final assinaturas = await _getLista('/assinaturas-template/');
    final relevantes = assinaturas.where((assinatura) => _inteiro(assinatura['template']) == templateId).toList();

    final idsEquipePrograma = relevantes.map((assinatura) => _inteiro(assinatura['equipe_programa'])).whereType<int>().toSet();
    final idsEquipeProjeto = relevantes.map((assinatura) => _inteiro(assinatura['equipe_projeto'])).whereType<int>().toSet();

    final membrosPrograma = idsEquipePrograma.isEmpty ? <Map<String, dynamic>>[] : await _getLista('/equipes-programa/');
    final membrosProjeto = idsEquipeProjeto.isEmpty ? <Map<String, dynamic>>[] : await _getLista('/equipes-projeto/');

    final dadosPorEquipePrograma = {
      for (final membro in membrosPrograma)
        if (_inteiro(membro['id']) != null)
          _inteiro(membro['id'])!: (
            nome: _texto(membro['nome']),
            cargo: _texto(membro['cargo']),
          ),
    };
    final dadosPorEquipeProjeto = {
      for (final membro in membrosProjeto)
        if (_inteiro(membro['id']) != null)
          _inteiro(membro['id'])!: (
            nome: _texto(membro['nome']),
            cargo: _texto(membro['cargo']),
          ),
    };

    return relevantes.map((assinatura) {
      final idEquipePrograma = _inteiro(assinatura['equipe_programa']);
      final idEquipeProjeto = _inteiro(assinatura['equipe_projeto']);
      final dadosPrograma = idEquipePrograma == null ? null : dadosPorEquipePrograma[idEquipePrograma];
      final dadosProjeto = idEquipeProjeto == null ? null : dadosPorEquipeProjeto[idEquipeProjeto];

      return AssinaturaTemplate(
        id: _inteiro(assinatura['id']),
        templateId: _inteiro(assinatura['template']),
        equipeProgramaId: idEquipePrograma,
        equipeProjetoId: idEquipeProjeto,
        nomeSignatario: dadosPrograma?.nome ?? dadosProjeto?.nome ?? '',
        cargoSignatario: dadosPrograma?.cargo ?? dadosProjeto?.cargo ?? '',
      );
    }).toList();
  }

  @override
  Future<void> criarAssinaturaTemplate({required int templateId, int? equipeProgramaId, int? equipeProjetoId}) async {
    await _api.criar('/assinaturas-template/', {'template': templateId, 'equipe_programa': equipeProgramaId, 'equipe_projeto': equipeProjetoId});
  }

  @override
  Future<void> excluirAssinaturaTemplate(int assinaturaId) async {
    await _api.excluir('/assinaturas-template/$assinaturaId/');
  }

  @override
  Future<Uint8List> baixarArquivoTemplate(int templateId) async {
    return _api.baixarArquivo('/templates/$templateId/download/');
  }

  @override
  Future<Map<String, dynamic>> previsualizarTemplate({required int templateId, int? eventoId}) async {
    final caminho = eventoId == null ? '/templates/$templateId/preview/' : '/templates/$templateId/preview/?evento_id=$eventoId';
    final resposta = await _api.obter(caminho);
    final documento = resposta['documento_json'];
    if (documento is! Map) {
      throw Exception('Não foi possível carregar a pré-visualização do template.');
    }
    return Map<String, dynamic>.from(documento);
  }

  @override
  Future<List<ProjetoCampo>> listarCamposProjeto({required int projetoId}) async {
    final campos = await _getLista('/projeto-campos/');
    return campos
        .where((campo) => _inteiro(campo['projeto']) == projetoId)
        .map(
          (campo) => ProjetoCampo(
            id: _inteiro(campo['id']),
            projetoId: projetoId,
            referencia: _texto(campo['referencia']),
            descricao: _texto(campo['descricao']),
            tipo: TipoCampoProjeto.porValorApi(_texto(campo['tipo'])),
            obrigatorio: campo['obrigatorio'] == true,
            valor: campo['valor'] is Map ? Map<String, dynamic>.from(campo['valor'] as Map) : const {},
          ),
        )
        .toList();
  }

  @override
  Future<void> criarCampoProjeto({required int projetoId, required String referencia, required String descricao, required TipoCampoProjeto tipo, required bool obrigatorio, required Map<String, dynamic> valor}) async {
    await _api.criar('/projeto-campos/', {'projeto': projetoId, 'referencia': referencia, 'descricao': descricao, 'tipo': tipo.valorApi, 'obrigatorio': obrigatorio, 'valor': valor});
  }

  @override
  Future<void> atualizarCampoProjeto({required int campoId, required String referencia, required String descricao, required TipoCampoProjeto tipo, required bool obrigatorio, required Map<String, dynamic> valor}) async {
    await _api.atualizar('/projeto-campos/$campoId/', {'referencia': referencia, 'descricao': descricao, 'tipo': tipo.valorApi, 'obrigatorio': obrigatorio, 'valor': valor});
  }

  @override
  Future<void> excluirCampoProjeto(int campoId) async {
    await _api.excluir('/projeto-campos/$campoId/');
  }

  @override
  Future<int> criarAsset({required Uint8List arquivoBytes, required String nomeArquivo, String descricao = ''}) async {
    final resposta = await _api.criarMultipart(caminho: '/assets/', campos: {'descricao': descricao}, campoArquivo: 'arquivo', arquivoBytes: arquivoBytes, nomeArquivo: nomeArquivo, contentType: _mimeImagem(nomeArquivo));
    return _idCriado(resposta, 'id', 'asset');
  }

  @override
  Future<List<Asset>> listarAssets() async {
    final assets = await _getLista('/assets/');
    return assets.map(_assetDeMapa).toList();
  }

  @override
  Future<Asset> obterAsset(int assetId) async {
    final asset = await _api.obter('/assets/$assetId/');
    return _assetDeMapa(asset);
  }

  @override
  Future<void> atualizarAsset({required int assetId, required String descricao}) async {
    await _api.atualizar('/assets/$assetId/', {'descricao': descricao});
  }

  @override
  Future<void> excluirAsset(int assetId) async {
    await _api.excluir('/assets/$assetId/');
  }

  Asset _assetDeMapa(Map<String, dynamic> asset) {
    return Asset(id: _inteiro(asset['id']), descricao: _texto(asset['descricao']), urlArquivo: _texto(asset['arquivo']));
  }

  @override
  Future<Uint8List> baixarRelatorio(int relatorioId) async {
    return _api.baixarArquivo('/relatorios/$relatorioId/download/');
  }

  @override
  Future<void> atualizarRelatorio({required int relatorioId, required String nome}) async {
    await _api.atualizar('/relatorios/$relatorioId/', {'nome': nome});
  }

  @override
  Future<void> excluirRelatorio(int relatorioId) async {
    await _api.excluir('/relatorios/$relatorioId/');
  }

  Future<List<Map<String, dynamic>>> _getLista(String caminho) async {
    return _api.listar(caminho);
  }

  Future<Map<String, dynamic>> _aguardarTaskConcluir(String taskId) async {
    const tentativasMaximas = 50;
    for (var tentativa = 0; tentativa < tentativasMaximas; tentativa++) {
      final resposta = await _api.obter('/tasks/$taskId/');
      final statusTask = _texto(resposta['task_status']);

      if (statusTask == 'SUCCESS') {
        return resposta;
      }
      if (statusTask == 'FAILURE') {
        final erro = _texto(resposta['error'], fallback: 'Falha ao criar template.');
        throw Exception(erro);
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    throw Exception('Tempo limite excedido aguardando a criação do template.');
  }

  int? _inteiro(Object? valor) {
    if (valor is int) return valor;
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  /// Extrai o id retornado ao criar um recurso, ou lança um erro claro
  /// se a API responder algo inesperado (em vez de mascarar com um id `0`
  /// silencioso, que só apareceria depois como um 404 confuso).
  int _idCriado(Map<String, dynamic> resposta, String chave, String recurso) {
    final id = _inteiro(resposta[chave]);
    if (id == null) {
      throw Exception('Resposta inesperada da API ao criar $recurso: campo "$chave" ausente.');
    }
    return id;
  }

  String _texto(Object? valor, {String fallback = ''}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  /// Deriva o content-type a partir da extensão do arquivo. O backend
  /// (`AssetCreateRequestSerializer.validate_arquivo`) rejeita uploads cujo
  /// content-type não comece com `image/`.
  String _mimeImagem(String nomeArquivo) {
    final extensao = nomeArquivo.split('.').last.toLowerCase();
    switch (extensao) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _descricaoPrograma(Map<String, dynamic> programa) {
    final lei = _texto(programa['lei_criacao']);
    final convenio = _texto(programa['convenio_dados']);
    final rodape = _texto(programa['rodape']);

    if (rodape.isNotEmpty) return rodape;
    if (lei.isNotEmpty && convenio.isNotEmpty) {
      return 'Lei de criação: $lei. Convênio: $convenio.';
    }
    if (lei.isNotEmpty) return 'Lei de criação: $lei.';
    if (convenio.isNotEmpty) return 'Convênio: $convenio.';
    return 'Programa cadastrado na API GeRelat.';
  }

  String _dataApi(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$ano-$mes-$dia';
  }

  String _formatarDataTexto(String valor) {
    if (valor.isEmpty) return 'Data não informada';
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}

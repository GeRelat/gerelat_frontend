import 'dart:typed_data';

import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/agendamento_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioRelatoriosHttpMixin implements RepositorioRelatorios {
  ServicoApiGerelat get api;

  @override
  Future<List<Relatorio>> listarRelatorios() async {
    final relatorios = await api.listar('/relatorios/');
    final eventos = await api.listar('/eventos/');
    final templates = await api.listar('/templates/');

    final eventoPorId = mapaIdNome(eventos);
    final templatePorId = mapaIdNome(templates);

    return relatorios.map((relatorio) {
      final idRelatorio = paraInteiro(relatorio['id']) ?? 0;
      final idEvento = paraInteiro(relatorio['evento']);
      final idTemplate = paraInteiro(relatorio['template']);
      final nome = paraTexto(relatorio['nome']);
      final docJson = relatorio['documento_json'] is Map
          ? Map<String, dynamic>.from(relatorio['documento_json'] as Map)
          : null;

      final dataCriacao = paraTexto(relatorio['data_criacao']);
      final ultimaAtualizacao = paraTexto(relatorio['ultima_atualizacao']);

      return Relatorio(
        id: idRelatorio,
        eventoId: idEvento,
        templateId: idTemplate,
        titulo: nome.isEmpty ? 'Relatorio $idRelatorio' : nome,
        evento: eventoPorId[idEvento] ?? 'Evento nao informado',
        template: templatePorId[idTemplate] ?? 'Template nao informado',
        dataGeracao: _formatarDataTexto(dataCriacao),
        status: paraTexto(relatorio['status'], fallback: 'Pendente'),
        dataCriacao: _formatarDataHoraTexto(dataCriacao),
        ultimaAtualizacao: _formatarDataHoraTexto(
          ultimaAtualizacao.isEmpty ? dataCriacao : ultimaAtualizacao,
        ),
        documentoJson: docJson,
      );
    }).toList();
  }

  @override
  Future<int> gerarRelatorioComDocumento({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    String? nome,
  }) async {
    final dados = <String, dynamic>{'template': templateId};
    // O backend resolve a cadeia a partir do elo mais profundo informado, mas
    // valida os elos mais rasos que também vierem — então mandamos todos os
    // que o usuário escolheu, e nenhum dos que ele não escolheu.
    if (clienteId case final id?) dados['cliente'] = id;
    if (programaId case final id?) dados['programa'] = id;
    if (projetoId case final id?) dados['projeto'] = id;
    if (eventoId case final id?) dados['evento'] = id;
    if (documentoJson != null) dados['documento_json'] = documentoJson;
    if (nome != null && nome.trim().isNotEmpty) dados['nome'] = nome.trim();

    final resposta = await api.criar('/relatorios/', dados);
    final taskId = paraTexto(resposta['task_id']);
    if (taskId.isEmpty) {
      throw Exception(
        'Resposta inesperada da API ao gerar relatório: task_id ausente.',
      );
    }

    final resultado = await aguardarTaskConcluir(api, taskId);
    final resultadoMap = resultado['result'];
    if (resultadoMap is! Map) {
      throw Exception('Resposta inesperada da task ao gerar relatório.');
    }
    return idCriado(Map<String, dynamic>.from(resultadoMap), 'id', 'relatório');
  }

  @override
  Future<Uint8List> baixarRelatorio(int relatorioId) async {
    return api.baixarArquivo('/relatorios/$relatorioId/download/');
  }

  @override
  Future<void> atualizarRelatorio({
    required int relatorioId,
    String? nome,
    Map<String, dynamic>? documentoJson,
  }) async {
    final payload = <String, dynamic>{};
    if (nome != null) payload['nome'] = nome;
    if (documentoJson != null) payload['documento_json'] = documentoJson;
    if (payload.isNotEmpty) {
      await api.atualizar('/relatorios/$relatorioId/', payload);
    }
  }

  @override
  Future<void> excluirRelatorio(int relatorioId) async {
    await api.excluir('/relatorios/$relatorioId/');
  }

  @override
  Future<void> agendarRelatorio({
    required String nome,
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    required String tipoAgendamento,
    DateTime? dataHoraExecucao,
    String? recorrencia,
    String? horarioExecucao,
    int? diaSemana,
    int? diaMes,
    bool ativo = true,
  }) async {
    final dados = <String, dynamic>{
      'nome': nome,
      'template': templateId,
      'tipo_agendamento': tipoAgendamento,
      'ativo': ativo,
    };
    if (clienteId != null) dados['cliente'] = clienteId;
    if (programaId != null) dados['programa'] = programaId;
    if (projetoId != null) dados['projeto'] = projetoId;
    if (eventoId != null) dados['evento'] = eventoId;
    if (documentoJson != null) dados['documento_json'] = documentoJson;
    if (dataHoraExecucao != null) {
      dados['data_hora_execucao'] = dataHoraExecucao.toUtc().toIso8601String();
    }
    if (recorrencia != null) dados['recorrencia'] = recorrencia;
    if (horarioExecucao != null) dados['horario_execucao'] = horarioExecucao;
    if (diaSemana != null) dados['dia_semana'] = diaSemana;
    if (diaMes != null) dados['dia_mes'] = diaMes;

    await api.criar('/agendamentos-relatorio/', dados);
  }

  @override
  Future<List<AgendamentoRelatorio>> listarAgendamentos({
    int? clienteId,
  }) async {
    final url = clienteId != null
        ? '/agendamentos-relatorio/?cliente_id=$clienteId'
        : '/agendamentos-relatorio/';
    final lista = await api.listar(url);

    return lista.map((map) {
      final id = paraInteiro(map['id']) ?? 0;
      final nome = paraTexto(map['nome']);
      final templateId = paraInteiro(map['template']) ?? 0;
      final templateNome = paraTexto(map['template_nome']);
      final clienteId = paraInteiro(map['cliente']);
      final clienteNome = paraTexto(map['cliente_nome']);
      final programaId = paraInteiro(map['programa']);
      final programaNome = paraTexto(map['programa_nome']);
      final projetoId = paraInteiro(map['projeto']);
      final projetoNome = paraTexto(map['projeto_nome']);
      final eventoId = paraInteiro(map['evento']);
      final criadoPorId = paraInteiro(map['criado_por']);
      final criadoPorNome = paraTexto(map['criado_por_nome']);
      final docJson = map['documento_json'] is Map
          ? Map<String, dynamic>.from(map['documento_json'] as Map)
          : null;
      final tipoAgendamento =
          paraTexto(map['tipo_agendamento'], fallback: 'pontual');
      final dataHoraExecucao = paraTexto(map['data_hora_execucao']);
      final recorrencia = paraTexto(map['recorrencia']);
      final horarioExecucao = paraTexto(map['horario_execucao']);
      final diaSemana = paraInteiro(map['dia_semana']);
      final diaMes = paraInteiro(map['dia_mes']);
      final ativo = map['ativo'] == true;
      final dataCriacao = paraTexto(map['data_criacao']);
      final ultimaAtualizacao = paraTexto(map['ultima_atualizacao']);
      final ultimaExecucao = paraTexto(map['ultima_execucao']);
      final proximaExecucao = paraTexto(map['proxima_execucao']);

      return AgendamentoRelatorio(
        id: id,
        nome: nome,
        templateId: templateId,
        templateNome: templateNome,
        clienteId: clienteId,
        clienteNome: clienteNome,
        programaId: programaId,
        programaNome: programaNome,
        projetoId: projetoId,
        projetoNome: projetoNome,
        eventoId: eventoId,
        criadoPorId: criadoPorId,
        criadoPorNome: criadoPorNome,
        documentoJson: docJson,
        tipoAgendamento: tipoAgendamento,
        dataHoraExecucao:
            dataHoraExecucao.isNotEmpty ? _formatarDataHoraTexto(dataHoraExecucao) : null,
        recorrencia: recorrencia.isNotEmpty ? recorrencia : null,
        horarioExecucao: horarioExecucao.isNotEmpty ? horarioExecucao : null,
        diaSemana: diaSemana,
        diaMes: diaMes,
        ativo: ativo,
        dataCriacao: _formatarDataHoraTexto(dataCriacao),
        ultimaAtualizacao: _formatarDataHoraTexto(ultimaAtualizacao),
        ultimaExecucao:
            ultimaExecucao.isNotEmpty ? _formatarDataHoraTexto(ultimaExecucao) : null,
        proximaExecucao:
            proximaExecucao.isNotEmpty ? _formatarDataHoraTexto(proximaExecucao) : null,
      );
    }).toList();
  }

  @override
  Future<void> alterarStatusAgendamento({
    required int agendamentoId,
    required bool ativo,
  }) async {
    await api.atualizar('/agendamentos-relatorio/$agendamentoId/', {'ativo': ativo});
  }

  @override
  Future<void> excluirAgendamento(int agendamentoId) async {
    await api.excluir('/agendamentos-relatorio/$agendamentoId/');
  }

  String _formatarDataTexto(String valor) {
    if (valor.isEmpty) return 'Data não informada';
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _formatarDataHoraTexto(String valor) {
    if (valor.isEmpty) return 'Data não informada';
    final data = DateTime.tryParse(valor)?.toLocal();
    if (data == null) return valor;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$minuto';
  }
}

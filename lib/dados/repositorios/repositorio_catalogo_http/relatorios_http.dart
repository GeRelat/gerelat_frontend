import 'dart:typed_data';

import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
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

      return Relatorio(
        id: idRelatorio,
        eventoId: idEvento,
        templateId: idTemplate,
        titulo: nome.isEmpty ? 'Relatorio $idRelatorio' : nome,
        evento: eventoPorId[idEvento] ?? 'Evento nao informado',
        template: templatePorId[idTemplate] ?? 'Template nao informado',
        dataGeracao: _formatarDataTexto(paraTexto(relatorio['data_criacao'])),
        status: paraTexto(relatorio['status'], fallback: 'Pendente'),
      );
    }).toList();
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
    required String nome,
  }) async {
    await api.atualizar('/relatorios/$relatorioId/', {'nome': nome});
  }

  @override
  Future<void> excluirRelatorio(int relatorioId) async {
    await api.excluir('/relatorios/$relatorioId/');
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

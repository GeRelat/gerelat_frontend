class Relatorio {
  final int? id;
  final int? eventoId;
  final int? templateId;
  final String titulo;
  final String evento;
  final String template;
  final String dataGeracao;
  final String status;
  final String dataCriacao;
  final String ultimaAtualizacao;
  final Map<String, dynamic>? documentoJson;

  const Relatorio({
    this.id,
    this.eventoId,
    this.templateId,
    required this.titulo,
    required this.evento,
    required this.template,
    required this.dataGeracao,
    required this.status,
    this.dataCriacao = '',
    this.ultimaAtualizacao = '',
    this.documentoJson,
  });
}

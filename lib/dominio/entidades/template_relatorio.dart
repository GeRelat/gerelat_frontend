class TemplateRelatorio {
  final int? id;
  final int? projetoId;
  final String nome;
  final String descricao;
  final String tipo;
  final String status;
  final String arquivoBase;

  const TemplateRelatorio({
    this.id,
    this.projetoId,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.status,
    this.arquivoBase = '',
  });
}

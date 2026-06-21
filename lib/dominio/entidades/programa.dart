class Programa {
  final int? id;
  final String nome;
  final String descricao;
  final int projetos;
  final int eventos;
  final String status;

  const Programa({
    this.id,
    required this.nome,
    required this.descricao,
    required this.projetos,
    required this.eventos,
    required this.status,
  });
}

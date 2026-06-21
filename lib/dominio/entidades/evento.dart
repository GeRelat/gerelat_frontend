class Evento {
  final int? id;
  final int? projetoId;
  final int? classeEventoId;
  final String nome;
  final String programa;
  final DateTime? data;
  final String status;

  const Evento({
    this.id,
    this.projetoId,
    this.classeEventoId,
    required this.nome,
    required this.programa,
    required this.data,
    required this.status,
  });
}

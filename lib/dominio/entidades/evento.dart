class Evento {
  final int? id;
  final int? projetoId;
  final int? classeEventoId;
  final String nome;
  final String programa;
  final DateTime? data;
  final String status;
  final String local;
  final String endereco;
  final String objetivo;
  final String classeEventoNome;

  const Evento({
    this.id,
    this.projetoId,
    this.classeEventoId,
    required this.nome,
    required this.programa,
    required this.data,
    required this.status,
    this.local = '',
    this.endereco = '',
    this.objetivo = '',
    this.classeEventoNome = '',
  });
}

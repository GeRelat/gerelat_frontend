class MembroEquipeProjeto {
  final int? id;
  final int projetoId;
  final String nomeEquipe;
  final String nome;
  final String cargo;

  const MembroEquipeProjeto({
    this.id,
    required this.projetoId,
    required this.nomeEquipe,
    required this.nome,
    required this.cargo,
  });
}

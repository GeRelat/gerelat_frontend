class Projeto {
  final int? id;
  final int? programaId;
  final String nome;
  final String parceira;
  final String sigla;
  final String logomarca;

  const Projeto({
    this.id,
    this.programaId,
    required this.nome,
    this.parceira = '',
    this.sigla = '',
    this.logomarca = '',
  });
}

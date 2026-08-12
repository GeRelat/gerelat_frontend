class Cliente {
  final int? id;
  final String nome;
  final String cnpj;
  final String nomeContato;
  final String emailContato;
  final String foneContato;
  final String numeroContrato;
  final DateTime? dataTerminoContrato;
  final String logomarca;

  const Cliente({
    this.id,
    required this.nome,
    this.cnpj = '',
    this.nomeContato = '',
    this.emailContato = '',
    this.foneContato = '',
    this.numeroContrato = '',
    this.dataTerminoContrato,
    this.logomarca = '',
  });
}

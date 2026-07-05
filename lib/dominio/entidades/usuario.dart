class Usuario {
  final int id;
  final String nomeCompleto;
  final String email;
  final DateTime? criadoEm;

  const Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.criadoEm,
  });
}

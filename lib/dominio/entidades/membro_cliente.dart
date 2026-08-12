class MembroClienteModel {
  final int id;
  final int user;
  final String userEmail;
  final String userNome;
  final int cliente;
  final String clienteNome;
  final int? promovidoPor;
  final String promovidoPorEmail;
  final String promovidoPorNome;
  final DateTime? dataPromocao;

  const MembroClienteModel({
    required this.id,
    required this.user,
    required this.userEmail,
    required this.userNome,
    required this.cliente,
    required this.clienteNome,
    this.promovidoPor,
    this.promovidoPorEmail = '',
    this.promovidoPorNome = '',
    this.dataPromocao,
  });

  factory MembroClienteModel.fromJson(Map<String, dynamic> json) {
    return MembroClienteModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userEmail: (json['user_email'] as String?) ?? '',
      userNome: (json['user_nome'] as String?) ?? '',
      cliente: json['cliente'] as int,
      clienteNome: (json['cliente_nome'] as String?) ?? '',
      promovidoPor: json['promovido_por'] as int?,
      promovidoPorEmail: (json['promovido_por_email'] as String?) ?? '',
      promovidoPorNome: (json['promovido_por_nome'] as String?) ?? '',
      dataPromocao: json['data_promocao'] != null
          ? DateTime.tryParse(json['data_promocao'] as String)
          : null,
    );
  }
}

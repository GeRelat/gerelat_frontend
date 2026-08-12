class SolicitacaoClienteModel {
  final int id;
  final int user;
  final String userEmail;
  final String userNome;
  final int cliente;
  final String clienteNome;
  final String status;
  final DateTime? createdAt;

  const SolicitacaoClienteModel({
    required this.id,
    required this.user,
    required this.userEmail,
    required this.userNome,
    required this.cliente,
    required this.clienteNome,
    required this.status,
    this.createdAt,
  });

  factory SolicitacaoClienteModel.fromJson(Map<String, dynamic> json) {
    return SolicitacaoClienteModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userEmail: (json['user_email'] as String?) ?? '',
      userNome: (json['user_nome'] as String?) ?? '',
      cliente: json['cliente'] as int,
      clienteNome: (json['cliente_nome'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'PENDENTE',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

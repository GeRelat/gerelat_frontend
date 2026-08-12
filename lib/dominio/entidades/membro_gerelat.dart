class MembroGeRelatModel {
  final int id;
  final int user;
  final String userEmail;
  final String userNome;

  const MembroGeRelatModel({
    required this.id,
    required this.user,
    required this.userEmail,
    required this.userNome,
  });

  factory MembroGeRelatModel.fromJson(Map<String, dynamic> json) {
    return MembroGeRelatModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userEmail: (json['user_email'] as String?) ?? '',
      userNome: (json['user_nome'] as String?) ?? '',
    );
  }
}

class UsuarioDisponivelModel {
  final int id;
  final String email;
  final String nome;

  const UsuarioDisponivelModel({
    required this.id,
    required this.email,
    required this.nome,
  });

  factory UsuarioDisponivelModel.fromJson(Map<String, dynamic> json) {
    return UsuarioDisponivelModel(
      id: json['id'] as int,
      email: (json['email'] as String?) ?? '',
      nome: (json['nome'] as String?) ?? '',
    );
  }
}

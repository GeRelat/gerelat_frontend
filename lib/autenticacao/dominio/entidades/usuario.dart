import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
  final String id;
  final String nomeCompleto;
  final String email;

  const Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
  });

  @override
  List<Object?> get props => [id, nomeCompleto, email];
}

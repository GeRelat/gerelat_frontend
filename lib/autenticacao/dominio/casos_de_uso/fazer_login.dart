import 'package:equatable/equatable.dart';
import 'package:gerelat_frontend/autenticacao/dominio/repositorios/i_repositorio_auth.dart';
import 'package:gerelat_frontend/nucleo/casos_de_uso/usecases.dart';
import 'package:gerelat_frontend/nucleo/utils/type_def.dart';

class FazerLogin extends UsecaseWithParams<void, ParamsLogin> {
  final IRepositorioAuth _repositorio;

  const FazerLogin(this._repositorio);

  @override
  ResultFuture<void> call(ParamsLogin params) =>
      _repositorio.login(email: params.email, senha: params.senha);
}

class ParamsLogin extends Equatable {
  final String email;
  final String senha;

  const ParamsLogin({required this.email, required this.senha});

  @override
  List<Object?> get props => [email, senha];
}

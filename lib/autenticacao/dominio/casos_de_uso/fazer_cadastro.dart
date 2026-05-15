import 'package:equatable/equatable.dart';
import 'package:gerelat_frontend/autenticacao/dominio/repositorios/i_repositorio_auth.dart';
import 'package:gerelat_frontend/nucleo/casos_de_uso/usecases.dart';
import 'package:gerelat_frontend/nucleo/utils/type_def.dart';

class FazerCadastro extends UsecaseWithParams<void, ParamsCadastro> {
  final IRepositorioAuth _repositorio;

  const FazerCadastro(this._repositorio);

  @override
  ResultFuture<void> call(ParamsCadastro params) =>
      _repositorio.cadastrar(
        nomeCompleto: params.nomeCompleto,
        email: params.email,
        senha: params.senha,
      );
}

class ParamsCadastro extends Equatable {
  final String nomeCompleto;
  final String email;
  final String senha;

  const ParamsCadastro({
    required this.nomeCompleto,
    required this.email,
    required this.senha,
  });

  @override
  List<Object?> get props => [nomeCompleto, email, senha];
}

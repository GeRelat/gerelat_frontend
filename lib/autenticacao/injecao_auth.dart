import 'package:gerelat_frontend/autenticacao/dados/fontes/fonte_auth_remota.dart';
import 'package:gerelat_frontend/autenticacao/dados/repositorios/repositorio_auth.dart';
import 'package:gerelat_frontend/autenticacao/dominio/casos_de_uso/fazer_cadastro.dart';
import 'package:gerelat_frontend/autenticacao/dominio/casos_de_uso/fazer_login.dart';

/// Ponto único de composição de dependências da feature de autenticação.
/// Monta a cadeia: FonteRemota → Repositório → CasoDeUso.
class InjecaoAuth {
  InjecaoAuth._();

  static RepositorioAuth _repositorio() =>
      RepositorioAuth(const FonteAuthRemota());

  static FazerLogin fazerLogin() => FazerLogin(_repositorio());
  static FazerCadastro fazerCadastro() => FazerCadastro(_repositorio());
}

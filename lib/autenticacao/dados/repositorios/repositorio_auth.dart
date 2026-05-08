import 'package:gerelat_frontend/autenticacao/dados/fontes/fonte_auth_remota.dart';
import 'package:gerelat_frontend/autenticacao/dominio/repositorios/i_repositorio_auth.dart';
import 'package:gerelat_frontend/nucleo/utils/base_repo.dart';
import 'package:gerelat_frontend/nucleo/utils/type_def.dart';

/// Implementação concreta de IRepositorioAuth.
/// Delega as chamadas à fonte remota e converte erros em Failure via BaseRepository.
class RepositorioAuth extends BaseRepository implements IRepositorioAuth {
  final FonteAuthRemota _fonte;

  const RepositorioAuth(this._fonte);

  @override
  ResultFuture<void> login({
    required String email,
    required String senha,
  }) =>
      request(() => _fonte.login(email: email, senha: senha));

  @override
  ResultFuture<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) =>
      request(
        () => _fonte.cadastrar(
          nomeCompleto: nomeCompleto,
          email: email,
          senha: senha,
        ),
      );
}

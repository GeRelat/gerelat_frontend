import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';
import 'package:gerelat_frontend/nucleo/utils/base_data_source.dart';

/// Fonte de dados remota para autenticação.
/// Usa Dio via ClienteHttp e herda o tratamento de erros do BaseDatasource.
class FonteAuthRemota extends BaseDatasource {
  const FonteAuthRemota() : super();

  Future<void> login({
    required String email,
    required String senha,
  }) {
    return request(() async {
      await ClienteHttp.instancia.post(
        '/auth/login/',
        data: {'email': email, 'password': senha},
      );
    });
  }

  Future<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) {
    return request(() async {
      await ClienteHttp.instancia.post(
        '/auth/register/',
        data: {
          'full_name': nomeCompleto,
          'email': email,
          'password': senha,
        },
      );
    });
  }
}

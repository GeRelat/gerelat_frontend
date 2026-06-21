import 'package:gerelat_frontend/dados/repositorios/repositorio_autenticacao_http.dart';
import 'package:gerelat_frontend/dados/repositorios/repositorio_catalogo_http.dart';
import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';
import 'package:gerelat_frontend/nucleo/servicos/servico_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/servicos/servico_token.dart';

class DependenciasApp {
  static final DependenciasApp instancia = DependenciasApp._criar();

  final ServicoToken servicoToken;
  final ClienteHttp clienteHttp;
  final RepositorioCatalogo repositorioCatalogo;
  final RepositorioAutenticacao repositorioAutenticacao;

  DependenciasApp._({
    required this.servicoToken,
    required this.clienteHttp,
    required this.repositorioCatalogo,
    required this.repositorioAutenticacao,
  });

  factory DependenciasApp._criar() {
    final tokens = ServicoToken();
    final cliente = ClienteHttp(servicoToken: tokens);
    final autenticacao = ServicoAutenticacao(
      clienteHttp: cliente,
      servicoToken: tokens,
    );

    return DependenciasApp._(
      servicoToken: tokens,
      clienteHttp: cliente,
      repositorioCatalogo: RepositorioCatalogoHttp(
        ServicoApiGerelat(cliente),
      ),
      repositorioAutenticacao: RepositorioAutenticacaoHttp(
        servico: autenticacao,
        tokens: tokens,
      ),
    );
  }
}

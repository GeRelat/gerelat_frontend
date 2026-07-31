import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'repositorio_catalogo_http/assets_http.dart';
import 'repositorio_catalogo_http/clientes_http.dart';
import 'repositorio_catalogo_http/dashboard_http.dart';
import 'repositorio_catalogo_http/equipe_programa_http.dart';
import 'repositorio_catalogo_http/equipe_projeto_http.dart';
import 'repositorio_catalogo_http/eventos_http.dart';
import 'repositorio_catalogo_http/programas_http.dart';
import 'repositorio_catalogo_http/projeto_campo_http.dart';
import 'repositorio_catalogo_http/relatorios_http.dart';
import 'repositorio_catalogo_http/templates_http.dart';

class RepositorioCatalogoHttp
    with
        RepositorioClientesHttpMixin,
        RepositorioAssetsHttpMixin,
        RepositorioEquipeProgramaHttpMixin,
        RepositorioEquipeProjetoHttpMixin,
        RepositorioProjetoCampoHttpMixin,
        RepositorioEventosHttpMixin,
        RepositorioTemplatesHttpMixin,
        RepositorioRelatoriosHttpMixin,
        RepositorioProgramasHttpMixin,
        RepositorioDashboardHttpMixin
    implements RepositorioCatalogo {
  final ServicoApiGerelat _api;

  RepositorioCatalogoHttp(this._api);

  @override
  ServicoApiGerelat get api => _api;
}

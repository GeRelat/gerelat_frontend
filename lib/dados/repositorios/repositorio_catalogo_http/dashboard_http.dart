import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioDashboardHttpMixin implements RepositorioDashboard {
  ServicoApiGerelat get api;

  @override
  Future<ResumoDashboard> obterResumoDashboard({int? clienteId}) async {
    final caminho = clienteId != null
        ? '/dashboard/resumo/?cliente_id=$clienteId'
        : '/dashboard/resumo/';
    final dados = await api.obter(caminho);

    return ResumoDashboard(
      programas: paraInteiro(dados['programas']) ?? 0,
      projetos: paraInteiro(dados['projetos']) ?? 0,
      eventos: paraInteiro(dados['eventos']) ?? 0,
      templates: paraInteiro(dados['templates']) ?? 0,
      relatorios: paraInteiro(dados['relatorios']) ?? 0,
    );
  }
}

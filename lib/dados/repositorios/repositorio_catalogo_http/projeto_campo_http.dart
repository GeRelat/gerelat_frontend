import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioProjetoCampoHttpMixin implements RepositorioProjetoCampo {
  ServicoApiGerelat get api;

  @override
  Future<List<ProjetoCampo>> listarCamposProjeto({
    required int projetoId,
  }) async {
    final campos = await api.listar('/projeto-campos/');
    return campos
        .where((campo) => paraInteiro(campo['projeto']) == projetoId)
        .map(
          (campo) => ProjetoCampo(
            id: paraInteiro(campo['id']),
            projetoId: projetoId,
            referencia: paraTexto(campo['referencia']),
            descricao: paraTexto(campo['descricao']),
            tipo: TipoCampoProjeto.porValorApi(paraTexto(campo['tipo'])),
            obrigatorio: campo['obrigatorio'] == true,
            valor: campo['valor'] is Map
                ? Map<String, dynamic>.from(campo['valor'] as Map)
                : const {},
          ),
        )
        .toList();
  }

  @override
  Future<void> criarCampoProjeto({
    required int projetoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {
    await api.criar('/projeto-campos/', {
      'projeto': projetoId,
      'referencia': referencia,
      'descricao': descricao,
      'tipo': tipo.valorApi,
      'obrigatorio': obrigatorio,
      'valor': valor,
    });
  }

  @override
  Future<void> atualizarCampoProjeto({
    required int campoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {
    await api.atualizar('/projeto-campos/$campoId/', {
      'referencia': referencia,
      'descricao': descricao,
      'tipo': tipo.valorApi,
      'obrigatorio': obrigatorio,
      'valor': valor,
    });
  }

  @override
  Future<void> excluirCampoProjeto(int campoId) async {
    await api.excluir('/projeto-campos/$campoId/');
  }
}

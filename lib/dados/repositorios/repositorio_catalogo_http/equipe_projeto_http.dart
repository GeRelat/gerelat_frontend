import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioEquipeProjetoHttpMixin implements RepositorioEquipeProjeto {
  ServicoApiGerelat get api;

  @override
  Future<List<MembroEquipeProjeto>> listarEquipeProjeto({
    required int projetoId,
  }) async {
    final membros = await api.listar('/equipes-projeto/');
    return membros
        .where((membro) => paraInteiro(membro['projeto']) == projetoId)
        .map(
          (membro) => MembroEquipeProjeto(
            id: paraInteiro(membro['id']),
            projetoId: projetoId,
            nomeEquipe: paraTexto(membro['nome_equipe']),
            nome: paraTexto(membro['nome']),
            cargo: paraTexto(membro['cargo']),
          ),
        )
        .toList();
  }

  @override
  Future<void> criarMembroEquipeProjeto({
    required int projetoId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {
    await api.criar('/equipes-projeto/', {
      'projeto': projetoId,
      'nome_equipe': nomeEquipe,
      'nome': nome,
      'cargo': cargo,
    });
  }

  @override
  Future<void> atualizarMembroEquipeProjeto({
    required int membroId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {
    await api.atualizar('/equipes-projeto/$membroId/', {
      'nome_equipe': nomeEquipe,
      'nome': nome,
      'cargo': cargo,
    });
  }

  @override
  Future<void> excluirMembroEquipeProjeto(int membroId) async {
    await api.excluir('/equipes-projeto/$membroId/');
  }
}

import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioEquipeProgramaHttpMixin implements RepositorioEquipePrograma {
  ServicoApiGerelat get api;

  @override
  Future<List<MembroEquipePrograma>> listarEquipePrograma({
    required int programaId,
  }) async {
    final membros = await api.listar('/equipes-programa/');
    return membros
        .where((membro) => paraInteiro(membro['programa']) == programaId)
        .map(
          (membro) => MembroEquipePrograma(
            id: paraInteiro(membro['id']),
            programaId: programaId,
            nome: paraTexto(membro['nome']),
            cargo: paraTexto(membro['cargo']),
          ),
        )
        .toList();
  }

  @override
  Future<void> criarMembroEquipe({
    required int programaId,
    required String nome,
    required String cargo,
  }) async {
    await api.criar('/equipes-programa/', {
      'programa': programaId,
      'nome': nome,
      'cargo': cargo,
    });
  }

  @override
  Future<void> atualizarMembroEquipe({
    required int membroId,
    required String nome,
    required String cargo,
  }) async {
    await api.atualizar('/equipes-programa/$membroId/', {
      'nome': nome,
      'cargo': cargo,
    });
  }

  @override
  Future<void> excluirMembroEquipe(int membroId) async {
    await api.excluir('/equipes-programa/$membroId/');
  }
}

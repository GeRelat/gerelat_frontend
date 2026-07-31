import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EquipeProgramaViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;
  final int programaId;

  Programa? _programa;
  List<MembroEquipePrograma> _membros = [];

  EquipeProgramaViewModel(this._repositorio, {required this.programaId});

  Programa? get programa => _programa;
  List<MembroEquipePrograma> get membros => List.unmodifiable(_membros);

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _programa = await _repositorio.obterPrograma(programaId);
      _membros = await _repositorio.listarEquipePrograma(
        programaId: programaId,
      );
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? membroId,
    required String nome,
    required String cargo,
  }) {
    return _executarAcao(() async {
      if (membroId == null) {
        await _repositorio.criarMembroEquipe(
          programaId: programaId,
          nome: nome,
          cargo: cargo,
        );
      } else {
        await _repositorio.atualizarMembroEquipe(
          membroId: membroId,
          nome: nome,
          cargo: cargo,
        );
      }
    });
  }

  Future<bool> excluir(int membroId) {
    return _executarAcao(() => _repositorio.excluirMembroEquipe(membroId));
  }

  /// Executa uma ação de escrita e recarrega a equipe do programa — mesmo
  /// tratamento usado por [salvar] e [excluir].
  Future<bool> _executarAcao(Future<void> Function() acao) async {
    iniciarCarregamento();
    try {
      await acao();
      _membros = await _repositorio.listarEquipePrograma(
        programaId: programaId,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

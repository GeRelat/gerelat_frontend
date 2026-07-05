import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ProjetoFormViewModel extends BaseViewModel {
  final RepositorioProgramas _repositorio;
  List<OpcaoSelecao> _programas = [];
  Projeto? _projeto;

  ProjetoFormViewModel(this._repositorio);

  List<OpcaoSelecao> get programas => List.unmodifiable(_programas);
  Projeto? get projeto => _projeto;

  Future<void> carregarOpcoes() async {
    iniciarCarregamento();
    try {
      _programas = await _repositorio.listarProgramasSelecao();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> carregar(int projetoId) async {
    iniciarCarregamento();
    try {
      _projeto = await _repositorio.obterProjeto(projetoId);
      _programas = await _repositorio.listarProgramasSelecao();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? projetoId,
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {
    iniciarCarregamento();
    try {
      if (projetoId == null) {
        await _repositorio.criarProjeto(
          programaId: programaId,
          nome: nome,
          parceira: parceira,
          sigla: sigla,
          logomarca: logomarca,
        );
      } else {
        await _repositorio.atualizarProjeto(
          projetoId: projetoId,
          programaId: programaId,
          nome: nome,
          parceira: parceira,
          sigla: sigla,
          logomarca: logomarca,
        );
      }
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> excluir(int projetoId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirProjeto(projetoId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

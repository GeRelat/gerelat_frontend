import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ProjetosProgramaViewModel extends BaseViewModel {
  final RepositorioProgramas _repositorio;
  final int programaId;
  List<Projeto> _projetos = [];
  Programa? _programa;

  ProjetosProgramaViewModel(this._repositorio, {required this.programaId});

  List<Projeto> get projetos => List.unmodifiable(_projetos);
  Programa? get programa => _programa;

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _programa = await _repositorio.obterPrograma(programaId);
      _projetos = await _repositorio.listarProjetosDetalhados(
        programaId: programaId,
      );
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> excluir(int projetoId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirProjeto(projetoId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

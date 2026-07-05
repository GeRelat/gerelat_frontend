import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ProgramasViewModel extends BaseViewModel {
  final RepositorioProgramas _repositorio;
  List<Programa> _programas = [];
  String _termoBusca = '';

  ProgramasViewModel(this._repositorio);

  List<Programa> get programas {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return List.unmodifiable(_programas);
    return _programas
        .where((programa) {
          return programa.nome.toLowerCase().contains(termo) ||
              programa.descricao.toLowerCase().contains(termo) ||
              programa.leiCriacao.toLowerCase().contains(termo) ||
              programa.convenioDados.toLowerCase().contains(termo);
        })
        .toList(growable: false);
  }

  int get totalProgramas => _programas.length;
  int get totalProjetos =>
      _programas.fold(0, (total, programa) => total + programa.projetos);
  int get totalEventos =>
      _programas.fold(0, (total, programa) => total + programa.eventos);

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _programas = await _repositorio.listarProgramas();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  void definirBusca(String valor) {
    _termoBusca = valor;
    notifyListeners();
  }

  Future<bool> excluir(int programaId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirPrograma(programaId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

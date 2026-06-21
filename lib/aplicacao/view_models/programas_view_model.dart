import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ProgramasViewModel extends BaseViewModel {
  final RepositorioProgramas _repositorio;
  List<Programa> _programas = [];

  ProgramasViewModel(this._repositorio);

  List<Programa> get programas => List.unmodifiable(_programas);
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
}

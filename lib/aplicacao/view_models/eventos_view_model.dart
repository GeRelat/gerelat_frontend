import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EventosViewModel extends BaseViewModel {
  final RepositorioEventos _repositorio;
  List<Evento> _eventos = [];

  EventosViewModel(this._repositorio);

  List<Evento> get eventos => List.unmodifiable(_eventos);

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _eventos = await _repositorio.listarEventos();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }
}

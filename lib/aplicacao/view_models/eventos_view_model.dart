import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EventosViewModel extends BaseViewModel {
  final RepositorioEventos _repositorio;
  List<Evento> _eventos = [];
  String _termoBusca = '';
  String _filtroStatus = 'Todos';
  String _filtroPeriodo = 'Todos';

  EventosViewModel(this._repositorio);

  List<Evento> get eventos {
    Iterable<Evento> resultado = _eventos;
    final termo = _termoBusca.trim().toLowerCase();

    if (termo.isNotEmpty) {
      resultado = resultado.where(
        (evento) =>
            evento.nome.toLowerCase().contains(termo) ||
            evento.programa.toLowerCase().contains(termo) ||
            evento.local.toLowerCase().contains(termo) ||
            evento.objetivo.toLowerCase().contains(termo),
      );
    }

    if (_filtroStatus == 'Confirmados') {
      resultado = resultado.where((evento) => evento.status == 'Confirmado');
    }

    if (_filtroPeriodo == 'Este mês') {
      final agora = DateTime.now();
      resultado = resultado.where((evento) {
        final data = evento.data;
        return data != null &&
            data.month == agora.month &&
            data.year == agora.year;
      });
    }

    return resultado.toList(growable: false);
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _eventos = await _repositorio.listarEventos();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  void definirBusca(String valor) {
    _termoBusca = valor;
    notifyListeners();
  }

  void definirFiltroStatus(String valor) {
    _filtroStatus = valor;
    notifyListeners();
  }

  void definirFiltroPeriodo(String valor) {
    _filtroPeriodo = valor;
    notifyListeners();
  }

  String get filtroStatus => _filtroStatus;
  String get filtroPeriodo => _filtroPeriodo;

  Future<bool> excluir(int eventoId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirEvento(eventoId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

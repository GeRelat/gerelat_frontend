import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EventoFormViewModel extends BaseViewModel {
  final RepositorioEventos _repositorio;
  List<OpcaoSelecao> _projetos = [];
  List<OpcaoSelecao> _classes = [];

  EventoFormViewModel(this._repositorio);

  List<OpcaoSelecao> get projetos => List.unmodifiable(_projetos);
  List<OpcaoSelecao> get classes => List.unmodifiable(_classes);

  Future<void> carregarOpcoes() async {
    iniciarCarregamento();
    try {
      _projetos = await _repositorio.listarProjetos();
      _classes = await _repositorio.listarClassesEvento();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    iniciarCarregamento();
    try {
      await _repositorio.criarEvento(
        projetoId: projetoId,
        classeEventoId: classeEventoId,
        nome: nome,
        data: data,
        local: local,
        endereco: endereco,
        objetivo: objetivo,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

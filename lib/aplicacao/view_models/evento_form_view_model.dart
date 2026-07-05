import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EventoFormViewModel extends BaseViewModel {
  final RepositorioEventos _repositorio;
  List<OpcaoSelecao> _projetos = [];
  List<OpcaoSelecao> _classes = [];
  Evento? _evento;

  EventoFormViewModel(this._repositorio);

  List<OpcaoSelecao> get projetos => List.unmodifiable(_projetos);
  List<OpcaoSelecao> get classes => List.unmodifiable(_classes);
  Evento? get evento => _evento;

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

  Future<void> carregarClassesProjeto(int projetoId) async {
    iniciarCarregamento();
    try {
      _classes = await _repositorio.listarClassesEvento(projetoId: projetoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> carregarEdicao(int eventoId) async {
    iniciarCarregamento();
    try {
      _evento = await _repositorio.obterEvento(eventoId);
      _projetos = await _repositorio.listarProjetos();
      final projetoId = _evento?.projetoId;
      _classes = projetoId == null
          ? await _repositorio.listarClassesEvento()
          : await _repositorio.listarClassesEvento(projetoId: projetoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? eventoId,
    required int projetoId,
    int? classeEventoId,
    String nomeNovaClasse = '',
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    iniciarCarregamento();
    try {
      var classeId = classeEventoId;
      final nomeClasse = nomeNovaClasse.trim();

      if (classeId == null && nomeClasse.isNotEmpty) {
        classeId = await _repositorio.criarClasseEvento(
          projetoId: projetoId,
          nomeClasse: nomeClasse,
        );
      }

      if (classeId == null || classeId <= 0) {
        throw Exception('Selecione ou crie uma classe de evento.');
      }

      if (eventoId == null) {
        await _repositorio.criarEvento(
          projetoId: projetoId,
          classeEventoId: classeId,
          nome: nome,
          data: data,
          local: local,
          endereco: endereco,
          objetivo: objetivo,
        );
      } else {
        await _repositorio.atualizarEvento(
          eventoId: eventoId,
          projetoId: projetoId,
          classeEventoId: classeId,
          nome: nome,
          data: data,
          local: local,
          endereco: endereco,
          objetivo: objetivo,
        );
      }
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

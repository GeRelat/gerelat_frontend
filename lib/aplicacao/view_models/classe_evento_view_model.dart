import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ClasseEventoViewModel extends BaseViewModel {
  final RepositorioEventos _repositorio;

  List<OpcaoSelecao> _projetos = [];
  int? _projetoSelecionadoId;
  List<ClasseEvento> _classes = [];

  // Token da requisição de classes mais recente. Trocar de projeto
  // rapidamente dispara uma nova chamada antes da anterior responder; sem
  // isso, uma resposta atrasada do projeto antigo poderia sobrescrever a
  // lista de classes já correta do projeto atual.
  int _tokenClasses = 0;

  ClasseEventoViewModel(this._repositorio);

  List<OpcaoSelecao> get projetos => List.unmodifiable(_projetos);
  int? get projetoSelecionadoId => _projetoSelecionadoId;
  List<ClasseEvento> get classes => List.unmodifiable(_classes);

  Future<void> carregarProjetos() async {
    iniciarCarregamento();
    try {
      _projetos = await _repositorio.listarProjetos();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> selecionarProjeto(int? projetoId) async {
    _projetoSelecionadoId = projetoId;
    _classes = [];
    final token = ++_tokenClasses;
    notifyListeners();
    if (projetoId == null) return;

    iniciarCarregamento();
    try {
      final classes = await _repositorio.listarClassesEventoDetalhadas(
        projetoId: projetoId,
      );
      if (token != _tokenClasses) return;
      _classes = classes;
      finalizarCarregamento();
    } catch (erro) {
      if (token != _tokenClasses) return;
      definirErro(erro);
    }
  }

  Future<bool> salvar({int? classeId, required String nomeClasse}) {
    return _executarAcaoClasse((projetoId) async {
      if (classeId == null) {
        await _repositorio.criarClasseEvento(
          projetoId: projetoId,
          nomeClasse: nomeClasse,
        );
      } else {
        await _repositorio.atualizarClasseEvento(
          classeId: classeId,
          nomeClasse: nomeClasse,
        );
      }
    });
  }

  Future<bool> excluir(int classeId) {
    return _executarAcaoClasse(
      (_) => _repositorio.excluirClasseEvento(classeId),
    );
  }

  /// Executa uma ação de escrita sobre o projeto selecionado e recarrega as
  /// classes desse projeto — mesmo tratamento usado por [salvar] e
  /// [excluir].
  Future<bool> _executarAcaoClasse(
    Future<void> Function(int projetoId) acao,
  ) async {
    final projetoId = _projetoSelecionadoId;
    if (projetoId == null) return false;

    iniciarCarregamento();
    try {
      await acao(projetoId);
      _classes = await _repositorio.listarClassesEventoDetalhadas(
        projetoId: projetoId,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

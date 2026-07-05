import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EquipeProjetoViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;

  List<OpcaoSelecao> _projetos = [];
  int? _projetoSelecionadoId;
  List<MembroEquipeProjeto> _membros = [];

  EquipeProjetoViewModel(this._repositorio);

  List<OpcaoSelecao> get projetos => List.unmodifiable(_projetos);
  int? get projetoSelecionadoId => _projetoSelecionadoId;
  List<MembroEquipeProjeto> get membros => List.unmodifiable(_membros);

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
    _membros = [];
    notifyListeners();
    if (projetoId == null) return;

    iniciarCarregamento();
    try {
      _membros = await _repositorio.listarEquipeProjeto(projetoId: projetoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? membroId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {
    final projetoId = _projetoSelecionadoId;
    if (projetoId == null) return false;

    iniciarCarregamento();
    try {
      if (membroId == null) {
        await _repositorio.criarMembroEquipeProjeto(
          projetoId: projetoId,
          nomeEquipe: nomeEquipe,
          nome: nome,
          cargo: cargo,
        );
      } else {
        await _repositorio.atualizarMembroEquipeProjeto(
          membroId: membroId,
          nomeEquipe: nomeEquipe,
          nome: nome,
          cargo: cargo,
        );
      }
      _membros = await _repositorio.listarEquipeProjeto(projetoId: projetoId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> excluir(int membroId) async {
    final projetoId = _projetoSelecionadoId;
    if (projetoId == null) return false;

    iniciarCarregamento();
    try {
      await _repositorio.excluirMembroEquipeProjeto(membroId);
      _membros = await _repositorio.listarEquipeProjeto(projetoId: projetoId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

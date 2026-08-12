import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ProgramaFormViewModel extends BaseViewModel {
  final RepositorioProgramas _repositorio;
  final RepositorioClientes _repositorioClientes;
  Programa? _programa;
  List<OpcaoSelecao> _clientes = [];

  ProgramaFormViewModel(this._repositorio, this._repositorioClientes);

  Programa? get programa => _programa;
  List<OpcaoSelecao> get clientes => List.unmodifiable(_clientes);

  Future<void> carregarClientes({int? clienteAtivoId}) async {
    try {
      _clientes = await _repositorioClientes.listarClientesSelecao(
        clienteId: clienteAtivoId,
      );
      notifyListeners();
    } catch (_) {
      // A lista de clientes é opcional no formulário; falha ao carregar
      // não deve impedir o cadastro/edição do programa.
    }
  }

  Future<void> carregar(int programaId, {int? clienteAtivoId}) async {
    iniciarCarregamento();
    try {
      _programa = await _repositorio.obterPrograma(programaId);
      await carregarClientes(clienteAtivoId: clienteAtivoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? programaId,
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  }) async {
    iniciarCarregamento();
    try {
      if (programaId == null) {
        await _repositorio.criarPrograma(
          nome: nome,
          leiCriacao: leiCriacao,
          convenioDados: convenioDados,
          rodape: rodape,
          logomarca: logomarca,
          clienteId: clienteId,
        );
      } else {
        await _repositorio.atualizarPrograma(
          programaId: programaId,
          nome: nome,
          leiCriacao: leiCriacao,
          convenioDados: convenioDados,
          rodape: rodape,
          logomarca: logomarca,
          clienteId: clienteId,
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

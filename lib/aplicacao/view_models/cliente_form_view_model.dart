import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ClienteFormViewModel extends BaseViewModel {
  final RepositorioClientes _repositorio;
  Cliente? _cliente;

  ClienteFormViewModel(this._repositorio);

  Cliente? get cliente => _cliente;

  Future<void> carregar(int clienteId) async {
    iniciarCarregamento();
    try {
      _cliente = await _repositorio.obterCliente(clienteId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? clienteId,
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
    String logomarca = '',
  }) {
    return _executarAcao(() async {
      if (clienteId == null) {
        await _repositorio.criarCliente(
          nome: nome,
          cnpj: cnpj,
          nomeContato: nomeContato,
          emailContato: emailContato,
          foneContato: foneContato,
          numeroContrato: numeroContrato,
          dataTerminoContrato: dataTerminoContrato,
          logomarca: logomarca,
        );
      } else {
        await _repositorio.atualizarCliente(
          clienteId: clienteId,
          nome: nome,
          cnpj: cnpj,
          nomeContato: nomeContato,
          emailContato: emailContato,
          foneContato: foneContato,
          numeroContrato: numeroContrato,
          dataTerminoContrato: dataTerminoContrato,
          logomarca: logomarca,
        );
      }
    });
  }

  Future<bool> excluir(int clienteId) {
    return _executarAcao(() => _repositorio.excluirCliente(clienteId));
  }

  /// Executa uma ação de escrita e reporta sucesso/erro — mesmo tratamento
  /// usado por [salvar] e [excluir].
  Future<bool> _executarAcao(Future<void> Function() acao) async {
    iniciarCarregamento();
    try {
      await acao();
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

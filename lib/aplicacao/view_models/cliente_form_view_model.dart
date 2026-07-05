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
    String cnpj = '',
    String nomeContato = '',
    String emailContato = '',
    String foneContato = '',
    String numeroContrato = '',
    required DateTime dataTerminoContrato,
  }) async {
    iniciarCarregamento();
    try {
      if (clienteId == null) {
        await _repositorio.criarCliente(
          nome: nome,
          cnpj: cnpj,
          nomeContato: nomeContato,
          emailContato: emailContato,
          foneContato: foneContato,
          numeroContrato: numeroContrato,
          dataTerminoContrato: dataTerminoContrato,
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
        );
      }
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> excluir(int clienteId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirCliente(clienteId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

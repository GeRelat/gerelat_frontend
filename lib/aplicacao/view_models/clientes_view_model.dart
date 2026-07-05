import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ClientesViewModel extends BaseViewModel {
  final RepositorioClientes _repositorio;
  List<Cliente> _clientes = [];
  String _termoBusca = '';

  ClientesViewModel(this._repositorio);

  List<Cliente> get clientes {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return List.unmodifiable(_clientes);
    return _clientes
        .where((cliente) {
          return cliente.nome.toLowerCase().contains(termo) ||
              cliente.cnpj.toLowerCase().contains(termo) ||
              cliente.nomeContato.toLowerCase().contains(termo) ||
              cliente.emailContato.toLowerCase().contains(termo);
        })
        .toList(growable: false);
  }

  int get totalClientes => _clientes.length;

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _clientes = await _repositorio.listarClientes();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  void definirBusca(String valor) {
    _termoBusca = valor;
    notifyListeners();
  }

  Future<bool> excluir(int clienteId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirCliente(clienteId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ClientesViewModel extends BaseViewModel {
  final RepositorioClientes _repositorio;
  List<Cliente> _clientes = [];
  String _termoBusca = '';
  String? _mensagemErroAcao;

  ClientesViewModel(this._repositorio);

  // Erro de uma ação pontual (excluir um item), separado de `mensagemErro`
  // — que é reservado para falha da carga da lista. Ver o mesmo padrão em
  // TemplatesViewModel/RelatoriosViewModel: reaproveitar
  // `iniciarCarregamento`/`definirErro` para ações de linha troca a grade
  // inteira pela tela de erro a cada falha pontual, mesmo com a lista já
  // carregada.
  String? get mensagemErroAcao => _mensagemErroAcao;

  List<Cliente> get clientes {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return List.unmodifiable(_clientes);
    return _clientes
        .where((cliente) => _correspondeABusca(cliente, termo))
        .toList(growable: false);
  }

  /// Verifica se o termo buscado aparece em algum dos campos identificáveis
  /// do cliente (nome, CNPJ, contato).
  bool _correspondeABusca(Cliente cliente, String termo) {
    return cliente.nome.toLowerCase().contains(termo) ||
        cliente.cnpj.toLowerCase().contains(termo) ||
        cliente.nomeContato.toLowerCase().contains(termo) ||
        cliente.emailContato.toLowerCase().contains(termo);
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
    try {
      await _repositorio.excluirCliente(clienteId);
      await carregar();
      return true;
    } catch (erro) {
      _mensagemErroAcao = erro.toString();
      notifyListeners();
      return false;
    }
  }
}

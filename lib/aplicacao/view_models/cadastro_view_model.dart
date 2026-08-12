import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

class CadastroViewModel extends BaseViewModel {
  final RepositorioAutenticacao _repositorio;
  List<OpcaoSelecao> _clientes = [];

  CadastroViewModel(this._repositorio);

  List<OpcaoSelecao> get clientes => List.unmodifiable(_clientes);

  Future<void> carregarClientes() async {
    try {
      _clientes = await _repositorio.listarClientesPublicos();
      notifyListeners();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
    int? clienteId,
  }) async {
    iniciarCarregamento();
    try {
      final resultado = await _repositorio.cadastrar(
        nomeCompleto: nomeCompleto,
        email: email,
        senha: senha,
        clienteId: clienteId,
      );
      if (resultado.sucesso) {
        finalizarCarregamento();
        return true;
      }
      definirErro(resultado.mensagemErro ?? 'Erro ao criar conta.');
      return false;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

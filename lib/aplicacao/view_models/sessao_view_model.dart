import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';

import 'package:gerelat_frontend/dominio/entidades/usuario.dart';

class SessaoViewModel extends BaseViewModel {
  static const _chaveClienteAtivoId = 'cliente_ativo_id';
  final RepositorioAutenticacao _repositorio;
  Usuario? _usuarioAtual;
  int? _clienteAtivoId;

  SessaoViewModel(this._repositorio);

  bool get estaAutenticado => _repositorio.estaAutenticado;
  Usuario? get usuarioAtual => _usuarioAtual;
  int? get clienteAtivoId => _clienteAtivoId;

  Future<void> selecionarCliente(int? clienteId) async {
    _clienteAtivoId = clienteId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (clienteId != null) {
        await prefs.setInt(_chaveClienteAtivoId, clienteId);
      } else {
        await prefs.remove(_chaveClienteAtivoId);
      }
    } catch (_) {}
  }

  Future<void> carregarUsuario() async {
    try {
      _usuarioAtual = await _repositorio.obterUsuarioAtual();
      var disponiveis = _usuarioAtual?.todosClientesDisponiveis ?? [];

      // Se houver algum cliente sem nome (ou formato placeholder), busca os nomes via endpoint público /clientes/publicos/
      if (disponiveis.any((c) => c.nome.isEmpty || c.nome.startsWith('Cliente #'))) {
        try {
          final publicos = await _repositorio.listarClientesPublicos();
          final mapaNomes = {for (var p in publicos) p.id: p.nome};
          final novosClientes = disponiveis.map((c) {
            final nomePublico = mapaNomes[c.id];
            if (nomePublico != null && nomePublico.isNotEmpty) {
              return ItemContextoCliente(
                id: c.id,
                nome: nomePublico,
                papel: c.papel,
                logomarca: c.logomarca,
              );
            }
            return c;
          }).toList();

          _usuarioAtual = Usuario(
            id: _usuarioAtual!.id,
            nomeCompleto: _usuarioAtual!.nomeCompleto,
            email: _usuarioAtual!.email,
            criadoEm: _usuarioAtual!.criadoEm,
            possuiContextoAcesso: _usuarioAtual!.possuiContextoAcesso,
            contextosAcesso: ContextosAcesso(
              adminGerelat: _usuarioAtual!.contextosAcesso.adminGerelat,
              clientesAdmin: novosClientes.where((c) => c.papel == 'admin').toList(),
              programas: _usuarioAtual!.contextosAcesso.programas,
              projetos: _usuarioAtual!.contextosAcesso.projetos,
              solicitacoesPendentes: _usuarioAtual!.contextosAcesso.solicitacoesPendentes,
            ),
          );
          disponiveis = _usuarioAtual?.todosClientesDisponiveis ?? [];
        } catch (_) {}
      }

      if (disponiveis.isNotEmpty) {
        int? idParaUsar;
        try {
          final prefs = await SharedPreferences.getInstance();
          final salvoId = prefs.getInt(_chaveClienteAtivoId);
          if (salvoId != null && disponiveis.any((c) => c.id == salvoId)) {
            idParaUsar = salvoId;
          }
        } catch (_) {}

        _clienteAtivoId = idParaUsar ?? disponiveis.first.id;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> inicializar() async {
    await _repositorio.inicializar();
    if (estaAutenticado) {
      await carregarUsuario();
    }
  }

  /// Avisa quem estiver ouvindo (ex: o redirect do GoRouter) que o estado de
  /// autenticação mudou: login, logout ou expiração de sessão.
  /// Ao receber uma notificação de login bem-sucedido, recarrega os dados do usuário.
  void notificarMudancaAutenticacao() {
    if (estaAutenticado && _usuarioAtual == null) {
      carregarUsuario();
    } else {
      notifyListeners();
    }
  }

  Future<bool> sair() async {
    iniciarCarregamento();
    try {
      await _repositorio.sair();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_chaveClienteAtivoId);
      } catch (_) {}
      _usuarioAtual = null;
      _clienteAtivoId = null;
      finalizarCarregamento();
      notifyListeners();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

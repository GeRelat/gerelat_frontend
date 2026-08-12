import 'package:flutter/foundation.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/solicitacao_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario_cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class GestaoMembrosViewModel extends ChangeNotifier {
  final RepositorioCatalogo _repositorio;

  GestaoMembrosViewModel(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  final Set<int> _processandoIds = {};
  bool isProcessando(int id) => _processandoIds.contains(id);

  String? _mensagemErro;
  String? get mensagemErro => _mensagemErro;

  String? _mensagemSucesso;
  String? get mensagemSucesso => _mensagemSucesso;

  int? _clienteId;
  int? get clienteId => _clienteId;

  List<SolicitacaoClienteModel> _solicitacoes = [];
  List<SolicitacaoClienteModel> get solicitacoes => _solicitacoes;

  List<UsuarioClienteModel> _usuarios = [];
  List<UsuarioClienteModel> get usuarios => _usuarios;

  List<MembroGeRelatModel> _membrosGeRelat = [];
  List<MembroGeRelatModel> get membrosGeRelat => _membrosGeRelat;

  List<UsuarioDisponivelModel> _usuariosDisponiveisGeRelat = [];
  List<UsuarioDisponivelModel> get usuariosDisponiveisGeRelat => _usuariosDisponiveisGeRelat;

  Future<void> carregar({int? clienteId}) async {
    if (clienteId != null) {
      _clienteId = clienteId;
    }
    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resSolicitacoes =
          await _repositorio.listarSolicitacoes(clienteId: _clienteId);
      _solicitacoes = resSolicitacoes;

      if (_clienteId != null) {
        final resUsuarios = await _repositorio.listarUsuariosCliente(
            clienteId: _clienteId!);
        _usuarios = resUsuarios;
      } else {
        _usuarios = [];
      }

      try {
        _membrosGeRelat = await _repositorio.listarMembrosGeRelat();
      } catch (_) {
        _membrosGeRelat = [];
      }
    } catch (e) {
      _mensagemErro = 'Falha ao carregar dados: $e';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> aprovarSolicitacao(
    int id, {
    bool eAdminCliente = false,
    List<Map<String, dynamic>> programas = const [],
    List<Map<String, dynamic>> projetos = const [],
  }) async {
    if (_processandoIds.contains(id)) return false;
    _processandoIds.add(id);
    _mensagemErro = null;
    _mensagemSucesso = null;
    notifyListeners();

    try {
      final ok = await _repositorio.aprovarSolicitacao(
        id,
        eAdminCliente: eAdminCliente,
        programas: programas,
        projetos: projetos,
      );
      if (ok) {
        _mensagemSucesso = 'Solicitação aprovada com sucesso!';
        await carregar(clienteId: _clienteId);
        return true;
      } else {
        _mensagemErro = 'Não foi possível aprovar a solicitação.';
      }
    } catch (e) {
      _mensagemErro = 'Erro ao aprovar solicitação: $e';
    } finally {
      _processandoIds.remove(id);
      notifyListeners();
    }
    return false;
  }

  Future<bool> recusarSolicitacao(int id) async {
    if (_processandoIds.contains(id)) return false;
    _processandoIds.add(id);
    _mensagemErro = null;
    _mensagemSucesso = null;
    notifyListeners();

    try {
      final ok = await _repositorio.recusarSolicitacao(id);
      if (ok) {
        _mensagemSucesso = 'Solicitação recusada com sucesso!';
        await carregar(clienteId: _clienteId);
        return true;
      } else {
        _mensagemErro = 'Não foi possível recusar a solicitação.';
      }
    } catch (e) {
      _mensagemErro = 'Erro ao recusar solicitação: $e';
    } finally {
      _processandoIds.remove(id);
      notifyListeners();
    }
    return false;
  }

  /// Remove TODOS os acessos de [userId] no cliente atual.
  Future<bool> removerUsuario(int userId) async {
    final cid = _clienteId;
    if (cid == null) return false;
    if (_processandoIds.contains(userId)) return false;
    _processandoIds.add(userId);
    _mensagemErro = null;
    _mensagemSucesso = null;
    notifyListeners();

    try {
      await _repositorio.removerUsuarioDoCliente(
          clienteId: cid, userId: userId);
      _mensagemSucesso = 'Usuário removido com sucesso!';
      await carregar(clienteId: cid);
      return true;
    } catch (e) {
      _mensagemErro = 'Erro ao remover usuário: $e';
    } finally {
      _processandoIds.remove(userId);
      notifyListeners();
    }
    return false;
  }

  /// Atualiza as permissões de [userId] no cliente atual, substituindo por completo.
  Future<bool> editarPermissoes(
    int userId, {
    required bool eAdminCliente,
    required List<int> programaIds,
    required List<int> projetoIds,
  }) async {
    final cid = _clienteId;
    if (cid == null) return false;
    if (_processandoIds.contains(userId)) return false;
    _processandoIds.add(userId);
    _mensagemErro = null;
    _mensagemSucesso = null;
    notifyListeners();

    try {
      await _repositorio.atualizarPermissoesUsuario(
        clienteId: cid,
        userId: userId,
        eAdminCliente: eAdminCliente,
        programaIds: programaIds,
        projetoIds: projetoIds,
      );
      _mensagemSucesso = 'Permissões atualizadas com sucesso!';
      await carregar(clienteId: cid);
      return true;
    } catch (e) {
      _mensagemErro = 'Erro ao atualizar permissões: $e';
    } finally {
      _processandoIds.remove(userId);
      notifyListeners();
    }
    return false;
  }

  Future<void> carregarUsuariosDisponiveisGeRelat() async {
    try {
      _usuariosDisponiveisGeRelat =
          await _repositorio.listarUsuariosDisponiveisGeRelat();
      notifyListeners();
    } catch (e) {
      _mensagemErro = 'Erro ao buscar usuários para Admin GeRelat: $e';
      notifyListeners();
    }
  }

  Future<bool> promoverAdminGeRelat(int userId) async {
    _mensagemErro = null;
    _mensagemSucesso = null;
    _carregando = true;
    notifyListeners();

    try {
      await _repositorio.criarMembroGeRelat(userId: userId);
      _mensagemSucesso = 'Novo Administrador do GeRelat adicionado com sucesso!';
      await carregar(clienteId: _clienteId);
      return true;
    } catch (e) {
      _mensagemErro = 'Erro ao promover usuário a Admin GeRelat: $e';
      _carregando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removerAdminGeRelat(int id) async {
    _mensagemErro = null;
    _mensagemSucesso = null;
    _carregando = true;
    notifyListeners();

    try {
      await _repositorio.excluirMembroGeRelat(id);
      _mensagemSucesso = 'Administrador do GeRelat removido com sucesso!';
      await carregar(clienteId: _clienteId);
      return true;
    } catch (e) {
      _mensagemErro = 'Erro ao remover Admin GeRelat: $e';
      _carregando = false;
      notifyListeners();
      return false;
    }
  }
}

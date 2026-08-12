import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/solicitacao_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario_cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

mixin RepositorioSolicitacoesHttpMixin implements RepositorioSolicitacoes {
  ServicoApiGerelat get api;

  @override
  Future<List<SolicitacaoClienteModel>> listarSolicitacoes({
    int? clienteId,
    String? status,
  }) async {
    final queryParams = <String>[];
    if (clienteId != null) queryParams.add('cliente=$clienteId');
    if (status != null) {
      queryParams.add('status=$status');
    } else {
      queryParams.add('status=pendente');
    }
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await api.listar('/solicitacoes-cliente/$queryString');
    return response
        .map((item) => SolicitacaoClienteModel.fromJson(item))
        .toList();
  }

  @override
  Future<bool> aprovarSolicitacao(
    int id, {
    bool eAdminCliente = false,
    List<Map<String, dynamic>> programas = const [],
    List<Map<String, dynamic>> projetos = const [],
  }) async {
    final response = await api.criar('/solicitacoes-cliente/$id/aprovar/', {
      'e_admin_cliente': eAdminCliente,
      'programas': programas,
      'projetos': projetos,
    });
    return response['status'] == 'aprovado' ||
        response['status'] == 'APROVADA' ||
        response['id'] != null;
  }

  @override
  Future<bool> recusarSolicitacao(int id) async {
    final response = await api.criar('/solicitacoes-cliente/$id/recusar/', {});
    return response['status'] == 'recusado' ||
        response['status'] == 'RECUSADA' ||
        response['id'] != null;
  }
}

mixin RepositorioMembrosClienteHttpMixin implements RepositorioMembrosCliente {
  ServicoApiGerelat get api;

  @override
  Future<List<UsuarioClienteModel>> listarUsuariosCliente(
      {required int clienteId}) async {
    final response = await api.listar('/clientes/$clienteId/usuarios/');
    return response
        .map((item) => UsuarioClienteModel.fromJson(item))
        .toList();
  }

  @override
  Future<void> removerUsuarioDoCliente({
    required int clienteId,
    required int userId,
  }) async {
    await api.criar('/clientes/$clienteId/remover-usuario/', {'user_id': userId});
  }

  @override
  Future<void> atualizarPermissoesUsuario({
    required int clienteId,
    required int userId,
    required bool eAdminCliente,
    required List<int> programaIds,
    required List<int> projetoIds,
  }) async {
    await api.criar('/clientes/$clienteId/atualizar-permissoes/', {
      'user_id': userId,
      'e_admin_cliente': eAdminCliente,
      'programas': programaIds.map((id) => {'id': id}).toList(),
      'projetos': projetoIds.map((id) => {'id': id}).toList(),
    });
  }

  @override
  Future<List<MembroClienteModel>> listarMembrosCliente({int? clienteId}) async {
    final url = clienteId != null
        ? '/membros-cliente/?cliente=$clienteId'
        : '/membros-cliente/';
    final response = await api.listar(url);
    return response
        .map((item) => MembroClienteModel.fromJson(item))
        .toList();
  }

  @override
  Future<void> criarMembroCliente({
    required int clienteId,
    required int userId,
  }) async {
    await api.criar('/membros-cliente/', {
      'cliente': clienteId,
      'user': userId,
    });
  }

  @override
  Future<void> excluirMembroCliente(int id) async {
    await api.excluir('/membros-cliente/$id/');
  }
}

mixin RepositorioMembrosGeRelatHttpMixin implements RepositorioMembrosGeRelat {
  ServicoApiGerelat get api;

  @override
  Future<List<MembroGeRelatModel>> listarMembrosGeRelat() async {
    final response = await api.listar('/membros-gerelat/');
    return response.map((item) => MembroGeRelatModel.fromJson(item)).toList();
  }

  @override
  Future<List<UsuarioDisponivelModel>> listarUsuariosDisponiveisGeRelat() async {
    final response = await api.listar('/membros-gerelat/usuarios-disponiveis/');
    return response.map((item) => UsuarioDisponivelModel.fromJson(item)).toList();
  }

  @override
  Future<void> criarMembroGeRelat({required int userId}) async {
    await api.criar('/membros-gerelat/', {'user': userId});
  }

  @override
  Future<void> excluirMembroGeRelat(int id) async {
    await api.excluir('/membros-gerelat/$id/');
  }
}

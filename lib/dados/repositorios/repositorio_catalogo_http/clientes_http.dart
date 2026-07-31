import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioClientesHttpMixin implements RepositorioClientes {
  ServicoApiGerelat get api;

  @override
  Future<List<Cliente>> listarClientes() async {
    final clientes = await api.listar('/clientes/');
    return clientes.map(_clienteDeMapa).toList();
  }

  @override
  Future<List<OpcaoSelecao>> listarClientesSelecao() async {
    final clientes = await api.listar('/clientes/');
    return paraOpcoes(
      clientes,
      campoNome: 'nome',
      fallback: 'Cliente sem nome',
    );
  }

  @override
  Future<Cliente> obterCliente(int clienteId) async {
    final cliente = await api.obter('/clientes/$clienteId/');
    return _clienteDeMapa(cliente);
  }

  @override
  Future<void> criarCliente({
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
  }) async {
    await api.criar('/clientes/', {
      'nome': nome,
      'cnpj': cnpj,
      'nome_contato': nomeContato,
      'email_contato': emailContato,
      'fone_contato': foneContato,
      'numero_contrato': numeroContrato,
      'data_termino_contrato': formatarDataParaApi(dataTerminoContrato),
    });
  }

  @override
  Future<void> atualizarCliente({
    required int clienteId,
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
  }) async {
    await api.atualizar('/clientes/$clienteId/', {
      'nome': nome,
      'cnpj': cnpj,
      'nome_contato': nomeContato,
      'email_contato': emailContato,
      'fone_contato': foneContato,
      'numero_contrato': numeroContrato,
      'data_termino_contrato': formatarDataParaApi(dataTerminoContrato),
    });
  }

  @override
  Future<void> excluirCliente(int clienteId) async {
    await api.excluir('/clientes/$clienteId/');
  }

  Cliente _clienteDeMapa(Map<String, dynamic> cliente) {
    return Cliente(
      id: paraInteiro(cliente['id']),
      nome: paraTexto(cliente['nome'], fallback: 'Cliente sem nome'),
      cnpj: paraTexto(cliente['cnpj']),
      nomeContato: paraTexto(cliente['nome_contato']),
      emailContato: paraTexto(cliente['email_contato']),
      foneContato: paraTexto(cliente['fone_contato']),
      numeroContrato: paraTexto(cliente['numero_contrato']),
      dataTerminoContrato: DateTime.tryParse(
        paraTexto(cliente['data_termino_contrato']),
      ),
    );
  }
}

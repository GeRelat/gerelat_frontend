import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioProgramasHttpMixin implements RepositorioProgramas {
  ServicoApiGerelat get api;

  @override
  Future<List<Programa>> listarProgramas() async {
    final programas = await api.listar('/programas/');
    final projetos = await api.listar('/projetos/');
    final eventos = await api.listar('/eventos/');
    final clientes = await api.listar('/clientes/');

    final projetosPorPrograma = <int, int>{};
    final programaPorProjeto = <int, int>{};

    for (final projeto in projetos) {
      final idProjeto = paraInteiro(projeto['id']);
      final idPrograma = paraInteiro(projeto['programa']);
      if (idProjeto == null || idPrograma == null) continue;

      programaPorProjeto[idProjeto] = idPrograma;
      projetosPorPrograma[idPrograma] =
          (projetosPorPrograma[idPrograma] ?? 0) + 1;
    }

    final eventosPorPrograma = <int, int>{};
    for (final evento in eventos) {
      final idProjeto = paraInteiro(evento['projeto']);
      final idPrograma = programaPorProjeto[idProjeto];
      if (idPrograma == null) continue;
      eventosPorPrograma[idPrograma] =
          (eventosPorPrograma[idPrograma] ?? 0) + 1;
    }

    final nomeClientePorId = mapaIdNome(clientes);

    return programas.map((programa) {
      final idPrograma = paraInteiro(programa['id']) ?? 0;
      final idCliente = paraInteiro(programa['cliente']);
      return Programa(
        id: idPrograma,
        nome: paraTexto(programa['nome'], fallback: 'Programa sem nome'),
        descricao: _descricaoPrograma(programa),
        projetos: projetosPorPrograma[idPrograma] ?? 0,
        eventos: eventosPorPrograma[idPrograma] ?? 0,
        status: 'Ativo',
        leiCriacao: paraTexto(programa['lei_criacao']),
        convenioDados: paraTexto(programa['convenio_dados']),
        rodape: paraTexto(programa['rodape']),
        logomarca: paraTexto(programa['logomarca']),
        clienteId: idCliente,
        clienteNome: idCliente == null
            ? ''
            : (nomeClientePorId[idCliente] ?? ''),
      );
    }).toList();
  }

  @override
  Future<Programa> obterPrograma(int programaId) async {
    final programa = await api.obter('/programas/$programaId/');
    final idCliente = paraInteiro(programa['cliente']);
    var nomeCliente = '';
    if (idCliente != null) {
      final cliente = await api.obter('/clientes/$idCliente/');
      nomeCliente = paraTexto(cliente['nome']);
    }

    // A API não filtra por query param, então contamos como em
    // `listarProgramas`: projetos ligados a este programa e eventos ligados
    // a esses projetos.
    final projetos = await api.listar('/projetos/');
    final idsProjetosDoPrograma = projetos
        .where((projeto) => paraInteiro(projeto['programa']) == programaId)
        .map((projeto) => paraInteiro(projeto['id']))
        .whereType<int>()
        .toSet();

    final eventos = await api.listar('/eventos/');
    final totalEventos = eventos
        .where(
          (evento) =>
              idsProjetosDoPrograma.contains(paraInteiro(evento['projeto'])),
        )
        .length;

    return Programa(
      id: paraInteiro(programa['id']),
      nome: paraTexto(programa['nome'], fallback: 'Programa sem nome'),
      descricao: _descricaoPrograma(programa),
      projetos: idsProjetosDoPrograma.length,
      eventos: totalEventos,
      status: 'Ativo',
      leiCriacao: paraTexto(programa['lei_criacao']),
      convenioDados: paraTexto(programa['convenio_dados']),
      rodape: paraTexto(programa['rodape']),
      logomarca: paraTexto(programa['logomarca']),
      clienteId: idCliente,
      clienteNome: nomeCliente,
    );
  }

  @override
  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  }) async {
    await api.criar('/programas/', {
      'nome': nome,
      'lei_criacao': leiCriacao,
      'convenio_dados': convenioDados,
      'rodape': rodape,
      'logomarca': logomarca,
      'cliente': clienteId,
    });
  }

  @override
  Future<void> atualizarPrograma({
    required int programaId,
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  }) async {
    await api.atualizar('/programas/$programaId/', {
      'nome': nome,
      'lei_criacao': leiCriacao,
      'convenio_dados': convenioDados,
      'rodape': rodape,
      'logomarca': logomarca,
      'cliente': clienteId,
    });
  }

  @override
  Future<void> excluirPrograma(int programaId) async {
    await api.excluir('/programas/$programaId/');
  }

  @override
  Future<List<OpcaoSelecao>> listarProgramasSelecao() async {
    final programas = await api.listar('/programas/');
    return paraOpcoes(
      programas,
      campoNome: 'nome',
      fallback: 'Programa sem nome',
    );
  }

  @override
  Future<void> criarProjeto({
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {
    await api.criar('/projetos/', {
      'programa': programaId,
      'nome': nome,
      'parceira': parceira,
      'sigla': sigla,
      'logomarca': logomarca,
    });
  }

  @override
  Future<List<Projeto>> listarProjetosDetalhados({int? programaId}) async {
    final projetos = await api.listar('/projetos/');
    return projetos
        .where(
          (projeto) =>
              programaId == null ||
              paraInteiro(projeto['programa']) == programaId,
        )
        .map(_projetoDeMapa)
        .toList();
  }

  @override
  Future<Projeto> obterProjeto(int projetoId) async {
    final projeto = await api.obter('/projetos/$projetoId/');
    return _projetoDeMapa(projeto);
  }

  @override
  Future<void> atualizarProjeto({
    required int projetoId,
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {
    await api.atualizar('/projetos/$projetoId/', {
      'programa': programaId,
      'nome': nome,
      'parceira': parceira,
      'sigla': sigla,
      'logomarca': logomarca,
    });
  }

  @override
  Future<void> excluirProjeto(int projetoId) async {
    await api.excluir('/projetos/$projetoId/');
  }

  Projeto _projetoDeMapa(Map<String, dynamic> projeto) {
    return Projeto(
      id: paraInteiro(projeto['id']),
      programaId: paraInteiro(projeto['programa']),
      nome: paraTexto(projeto['nome'], fallback: 'Projeto sem nome'),
      parceira: paraTexto(projeto['parceira']),
      sigla: paraTexto(projeto['sigla']),
      logomarca: paraTexto(projeto['logomarca']),
    );
  }

  String _descricaoPrograma(Map<String, dynamic> programa) {
    final lei = paraTexto(programa['lei_criacao']);
    final convenio = paraTexto(programa['convenio_dados']);
    final rodape = paraTexto(programa['rodape']);

    if (rodape.isNotEmpty) return rodape;
    if (lei.isNotEmpty && convenio.isNotEmpty) {
      return 'Lei de criação: $lei. Convênio: $convenio.';
    }
    if (lei.isNotEmpty) return 'Lei de criação: $lei.';
    if (convenio.isNotEmpty) return 'Convênio: $convenio.';
    return 'Programa cadastrado na API GeRelat.';
  }
}

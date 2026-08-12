import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioEventosHttpMixin implements RepositorioEventos {
  ServicoApiGerelat get api;

  @override
  Future<List<Evento>> listarEventos() async {
    final eventos = await api.listar('/eventos/');
    final projetos = await api.listar('/projetos/');
    final programas = await api.listar('/programas/');
    final classes = await api.listar('/classes-evento/');

    final programaPorId = mapaIdNome(programas);
    final classePorId = mapaIdNome(classes, campoNome: 'nome_classe');

    final programaPorProjeto = <int, String>{};
    for (final projeto in projetos) {
      final idProjeto = paraInteiro(projeto['id']);
      final idPrograma = paraInteiro(projeto['programa']);
      if (idProjeto == null || idPrograma == null) continue;
      programaPorProjeto[idProjeto] =
          programaPorId[idPrograma] ?? 'Programa nao informado';
    }

    return eventos.map((evento) {
      final idProjeto = paraInteiro(evento['projeto']);
      final idClasse = paraInteiro(evento['classe_evento']);
      final nomeNoPayload = paraTexto(evento['classe_evento_nome']);
      return Evento(
        id: paraInteiro(evento['id']),
        clienteId: paraInteiro(evento['cliente']),
        programaId: paraInteiro(evento['programa']),
        projetoId: idProjeto,
        classeEventoId: idClasse,
        nome: paraTexto(evento['nome'], fallback: 'Evento sem nome'),
        programa: idProjeto != null
            ? (programaPorProjeto[idProjeto] ?? 'Programa nao informado')
            : 'Escopo direto',
        data: DateTime.tryParse(paraTexto(evento['data'])),
        local: paraTexto(evento['local']),
        endereco: paraTexto(evento['endereco']),
        objetivo: paraTexto(evento['objetivo']),
        classeEventoNome: nomeNoPayload.isNotEmpty
            ? nomeNoPayload
            : (idClasse != null ? (classePorId[idClasse] ?? '') : ''),
      );
    }).toList();
  }

  @override
  Future<Evento> obterEvento(int eventoId) async {
    final evento = await api.obter('/eventos/$eventoId/');
    final projetoId = paraInteiro(evento['projeto']);
    final classeEventoId = paraInteiro(evento['classe_evento']);

    String programa = 'Programa nao informado';
    if (projetoId != null) {
      final projeto = await api.obter('/projetos/$projetoId/');
      final programaId = paraInteiro(projeto['programa']);
      if (programaId != null) {
        final programaMap = await api.obter('/programas/$programaId/');
        programa = paraTexto(programaMap['nome'], fallback: programa);
      }
    }

    String classeEventoNome = '';
    if (classeEventoId != null) {
      final classeEvento = await api.obter('/classes-evento/$classeEventoId/');
      classeEventoNome = paraTexto(classeEvento['nome_classe']);
    }

    return Evento(
      id: paraInteiro(evento['id']),
      clienteId: paraInteiro(evento['cliente']),
      programaId: paraInteiro(evento['programa']),
      projetoId: projetoId,
      classeEventoId: classeEventoId,
      nome: paraTexto(evento['nome'], fallback: 'Evento sem nome'),
      programa: programa,
      data: DateTime.tryParse(paraTexto(evento['data'])),
      local: paraTexto(evento['local']),
      endereco: paraTexto(evento['endereco']),
      objetivo: paraTexto(evento['objetivo']),
      classeEventoNome: classeEventoNome,
    );
  }

  @override
  Future<List<OpcaoSelecao>> listarProjetos() async {
    final projetos = await api.listar('/projetos/');
    return paraOpcoes(
      projetos,
      campoNome: 'nome',
      fallback: 'Projeto sem nome',
    );
  }

  @override
  Future<List<OpcaoSelecao>> listarClassesEvento({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
  }) async {
    final classes = await api.listar('/classes-evento/');
    final filtradas = classes.where((classe) {
      if (escopo != null && escopoId != null) {
        return paraInteiro(classe[escopo.valorApi]) == escopoId;
      }
      return projetoId == null || paraInteiro(classe['projeto']) == projetoId;
    });
    return paraOpcoes(
      filtradas.toList(),
      campoNome: 'nome_classe',
      fallback: 'Classe sem nome',
    );
  }

  @override
  Future<int> criarClasseEvento({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required String nomeClasse,
  }) async {
    final Map<String, dynamic> payload = {'nome_classe': nomeClasse};
    if (escopo != null && escopoId != null) {
      payload[escopo.valorApi] = escopoId;
    } else if (projetoId != null) {
      payload['projeto'] = projetoId;
    }
    final resposta = await api.criar('/classes-evento/', payload);
    return idCriado(resposta, 'id', 'classe de evento');
  }

  @override
  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
  }) async {
    final classes = await api.listar('/classes-evento/');
    final filtradas = classes.where((classe) {
      if (escopo != null && escopoId != null) {
        return paraInteiro(classe[escopo.valorApi]) == escopoId;
      }
      return projetoId == null || paraInteiro(classe['projeto']) == projetoId;
    });
    return filtradas
        .map(
          (classe) => ClasseEvento(
            id: paraInteiro(classe['id']),
            clienteId: paraInteiro(classe['cliente']),
            programaId: paraInteiro(classe['programa']),
            projetoId: paraInteiro(classe['projeto']),
            nomeClasse: paraTexto(
              classe['nome_classe'],
              fallback: 'Classe sem nome',
            ),
          ),
        )
        .toList();
  }

  @override
  Future<List<ClasseEvento>> listarClassesEventoDeProjetos(
    Set<int> projetoIds,
  ) async {
    return listarClassesEventoDoAlcance(projetoIds: projetoIds);
  }

  @override
  Future<List<ClasseEvento>> listarClassesEventoDoAlcance({
    int? clienteId,
    Set<int> programaIds = const {},
    Set<int> projetoIds = const {},
  }) async {
    final classes = await api.listar('/classes-evento/');
    return classes
        .map(
          (classe) => ClasseEvento(
            id: paraInteiro(classe['id']),
            clienteId: paraInteiro(classe['cliente']),
            programaId: paraInteiro(classe['programa']),
            projetoId: paraInteiro(classe['projeto']),
            nomeClasse: paraTexto(
              classe['nome_classe'],
              fallback: 'Classe sem nome',
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> atualizarClasseEvento({
    required int classeId,
    required String nomeClasse,
  }) async {
    await api.atualizar('/classes-evento/$classeId/', {
      'nome_classe': nomeClasse,
    });
  }

  @override
  Future<void> excluirClasseEvento(int classeId) async {
    await api.excluir('/classes-evento/$classeId/');
  }

  @override
  Future<void> criarEvento({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    final Map<String, dynamic> payload = {
      'classe_evento': classeEventoId,
      'nome': nome,
      'data': formatarDataParaApi(data),
      'local': local,
      'endereco': endereco,
      'objetivo': objetivo,
    };
    if (escopo != null && escopoId != null) {
      payload[escopo.valorApi] = escopoId;
    } else if (projetoId != null) {
      payload['projeto'] = projetoId;
    }

    await api.criar('/eventos/', payload);
  }

  @override
  Future<void> atualizarEvento({
    required int eventoId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    final Map<String, dynamic> payload = {
      'classe_evento': classeEventoId,
      'nome': nome,
      'data': formatarDataParaApi(data),
      'local': local,
      'endereco': endereco,
      'objetivo': objetivo,
    };
    if (escopo != null && escopoId != null) {
      payload[escopo.valorApi] = escopoId;
    } else if (projetoId != null) {
      payload['projeto'] = projetoId;
    }

    await api.atualizar('/eventos/$eventoId/', payload);
  }

  @override
  Future<void> excluirEvento(int eventoId) async {
    await api.excluir('/eventos/$eventoId/');
  }
}

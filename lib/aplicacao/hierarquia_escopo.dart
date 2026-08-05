import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

/// Cadeia Cliente > Programa > Projeto > Evento resolvida a partir do elo mais
/// profundo informado. Os elos acima são derivados; os abaixo ficam `null`.
typedef CadeiaEscopo = ({
  int? clienteId,
  int? programaId,
  int? projetoId,
  int? eventoId,
});

/// Snapshot da hierarquia carregado uma vez e consultado em memória.
///
/// Existe porque a API não filtra listagens por query param (não há filter
/// backends registrados em `config/settings/base.py`): para saber o programa de
/// um projeto, ou o cliente de um programa, o frontend precisa das listas
/// inteiras de qualquer forma. Centralizar aqui evita que cada view model
/// refaça as mesmas quatro requisições e reimplemente a subida da cadeia — que
/// no backend vive em `document_engine/variables.py::_resolve_chain`.
class HierarquiaEscopo {
  final List<Cliente> clientes;
  final List<Programa> programas;
  final List<Projeto> projetos;
  final List<Evento> eventos;

  const HierarquiaEscopo({
    this.clientes = const [],
    this.programas = const [],
    this.projetos = const [],
    this.eventos = const [],
  });

  /// [comEventos] evita a listagem de eventos nas telas que só trabalham com
  /// escopo de template (cliente/programa/projeto).
  static Future<HierarquiaEscopo> carregar(
    RepositorioCatalogo repositorio, {
    bool comEventos = true,
  }) async {
    return HierarquiaEscopo(
      clientes: await repositorio.listarClientes(),
      programas: await repositorio.listarProgramas(),
      projetos: await repositorio.listarProjetosDetalhados(),
      eventos: comEventos ? await repositorio.listarEventos() : const [],
    );
  }

  Programa? programaPorId(int? id) =>
      id == null ? null : _acharPorId(programas, id, (p) => p.id);

  Projeto? projetoPorId(int? id) =>
      id == null ? null : _acharPorId(projetos, id, (p) => p.id);

  Evento? eventoPorId(int? id) =>
      id == null ? null : _acharPorId(eventos, id, (e) => e.id);

  Cliente? clientePorId(int? id) =>
      id == null ? null : _acharPorId(clientes, id, (c) => c.id);

  /// Sobe a hierarquia a partir de uma instância-alvo, como
  /// `_resolve_chain` faz no backend.
  CadeiaEscopo cadeiaDe(NivelAplicacao nivel, int? id) {
    if (id == null) {
      return (clienteId: null, programaId: null, projetoId: null, eventoId: null);
    }
    switch (nivel) {
      case NivelAplicacao.cliente:
        return (
          clienteId: id,
          programaId: null,
          projetoId: null,
          eventoId: null,
        );
      case NivelAplicacao.programa:
        return (
          clienteId: programaPorId(id)?.clienteId,
          programaId: id,
          projetoId: null,
          eventoId: null,
        );
      case NivelAplicacao.projeto:
        final programaId = projetoPorId(id)?.programaId;
        return (
          clienteId: programaPorId(programaId)?.clienteId,
          programaId: programaId,
          projetoId: id,
          eventoId: null,
        );
      case NivelAplicacao.evento:
        final projetoId = eventoPorId(id)?.projetoId;
        final programaId = projetoPorId(projetoId)?.programaId;
        return (
          clienteId: programaPorId(programaId)?.clienteId,
          programaId: programaId,
          projetoId: projetoId,
          eventoId: id,
        );
    }
  }

  CadeiaEscopo cadeiaDeEscopo(NivelEscopo escopo, int? id) =>
      cadeiaDe(escopo.comoAplicacao, id);

  /// Nome da instância, para rótulos e mensagens.
  String nomeDe(NivelAplicacao nivel, int? id) {
    final nome = switch (nivel) {
      NivelAplicacao.cliente => clientePorId(id)?.nome,
      NivelAplicacao.programa => programaPorId(id)?.nome,
      NivelAplicacao.projeto => projetoPorId(id)?.nome,
      NivelAplicacao.evento => eventoPorId(id)?.nome,
    };
    return nome ?? '${nivel.rotulo} #$id';
  }

  String nomeDeEscopo(NivelEscopo escopo, int? id) =>
      nomeDe(escopo.comoAplicacao, id);

  /// Opções de um nível, opcionalmente restritas a um ancestral — é o que
  /// permite montar o cascateamento cliente → programa → projeto → evento.
  /// O rótulo inclui o pai porque as listas são globais (ex.: dois projetos
  /// podem ter o mesmo nome em programas diferentes).
  List<OpcaoSelecao> opcoesDe(
    NivelAplicacao nivel, {
    int? clienteId,
    int? programaId,
    int? projetoId,
  }) {
    switch (nivel) {
      case NivelAplicacao.cliente:
        return [
          for (final cliente in clientes)
            if (cliente.id != null)
              OpcaoSelecao(id: cliente.id!, nome: cliente.nome),
        ];
      case NivelAplicacao.programa:
        return [
          for (final programa in programas)
            if (programa.id != null &&
                (clienteId == null || programa.clienteId == clienteId))
              OpcaoSelecao(
                id: programa.id!,
                nome: _comSufixo(programa.nome, programa.clienteNome),
              ),
        ];
      case NivelAplicacao.projeto:
        return [
          for (final projeto in projetos)
            if (projeto.id != null &&
                (programaId == null || projeto.programaId == programaId) &&
                (clienteId == null ||
                    programaPorId(projeto.programaId)?.clienteId == clienteId))
              OpcaoSelecao(
                id: projeto.id!,
                nome: _comSufixo(
                  projeto.nome,
                  programaPorId(projeto.programaId)?.nome ?? '',
                ),
              ),
        ];
      case NivelAplicacao.evento:
        return [
          for (final evento in eventos)
            if (evento.id != null &&
                (projetoId == null || evento.projetoId == projetoId) &&
                (programaId == null ||
                    projetoPorId(evento.projetoId)?.programaId == programaId))
              OpcaoSelecao(
                id: evento.id!,
                nome: _comSufixo(
                  evento.nome,
                  projetoPorId(evento.projetoId)?.nome ?? '',
                ),
              ),
        ];
    }
  }

  List<OpcaoSelecao> opcoesDeEscopo(NivelEscopo escopo) =>
      opcoesDe(escopo.comoAplicacao);

  String _comSufixo(String nome, String pai) =>
      pai.isEmpty ? nome : '$nome — $pai';

  static T? _acharPorId<T>(List<T> itens, int id, int? Function(T) idDe) {
    for (final item in itens) {
      if (idDe(item) == id) return item;
    }
    return null;
  }
}

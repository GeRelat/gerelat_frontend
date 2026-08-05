import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_valor.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

/// `/campo-definicoes/` e `/campo-valores/`.
///
/// Nenhum dos dois endpoints aceita filtro por query string (a API não
/// registra filter backends nem paginação — ver `REST_FRAMEWORK` em
/// `config/settings/base.py`), então a filtragem é feita no cliente, como nos
/// demais mixins deste diretório.
mixin RepositorioCamposHttpMixin implements RepositorioCampos {
  ServicoApiGerelat get api;

  @override
  Future<List<CampoDefinicao>> listarDefinicoes({
    NivelEscopo? escopo,
    int? escopoId,
  }) async {
    final definicoes = await api.listar('/campo-definicoes/');
    return definicoes
        .map(_definicaoDeMapa)
        .where(
          (definicao) =>
              escopo == null ||
              (definicao.nivelEscopo == escopo &&
                  definicao.escopoId == escopoId),
        )
        .toList();
  }

  @override
  Future<List<CampoDefinicao>> listarDefinicoesVisiveis({
    int? clienteId,
    int? programaId,
    int? projetoId,
  }) async {
    if (clienteId == null && programaId == null && projetoId == null) {
      return const [];
    }
    final definicoes = await api.listar('/campo-definicoes/');
    return definicoes
        .map(_definicaoDeMapa)
        .where(
          (definicao) =>
              (clienteId != null && definicao.clienteId == clienteId) ||
              (programaId != null && definicao.programaId == programaId) ||
              (projetoId != null && definicao.projetoId == projetoId),
        )
        .toList();
  }

  @override
  Future<void> criarDefinicao({
    required NivelEscopo escopo,
    required int escopoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  }) async {
    await api.criar('/campo-definicoes/', {
      escopo.valorApi: escopoId,
      'nivel_aplicacao': nivelAplicacao.valorApi,
      'referencia': referencia,
      'descricao': descricao,
      'tipo': tipo.valorApi,
      'obrigatorio': obrigatorio,
    });
  }

  @override
  Future<void> atualizarDefinicao({
    required int definicaoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  }) async {
    // O escopo não vai no corpo de propósito: `CampoDefinicaoSerializer.validate`
    // reconstrói a instância a partir do registro salvo e só sobrescreve o que
    // vier no PATCH — mudar de escopo invalidaria os `CampoValor` já gravados.
    // Os demais campos precisam ir todos, porque o `full_clean` do serializer
    // roda sobre a instância remontada e `descricao`/`tipo` não têm default.
    await api.atualizar('/campo-definicoes/$definicaoId/', {
      'nivel_aplicacao': nivelAplicacao.valorApi,
      'referencia': referencia,
      'descricao': descricao,
      'tipo': tipo.valorApi,
      'obrigatorio': obrigatorio,
    });
  }

  @override
  Future<void> excluirDefinicao(int definicaoId) async {
    await api.excluir('/campo-definicoes/$definicaoId/');
  }

  @override
  Future<List<CampoValor>> listarValores({
    required NivelAplicacao alvo,
    required int alvoId,
  }) async {
    final valores = await api.listar('/campo-valores/');
    return valores
        .map(_valorDeMapa)
        .where((valor) => valor.nivelAlvo == alvo && valor.alvoId == alvoId)
        .toList();
  }

  @override
  Future<void> salvarValor({
    int? valorId,
    required int definicaoId,
    required NivelAplicacao alvo,
    required int alvoId,
    required Map<String, dynamic> valor,
  }) async {
    if (valorId == null) {
      await api.criar('/campo-valores/', {
        'definicao': definicaoId,
        alvo.valorApi: alvoId,
        'valor': valor,
      });
      return;
    }
    await api.atualizar('/campo-valores/$valorId/', {'valor': valor});
  }

  @override
  Future<void> excluirValor(int valorId) async {
    await api.excluir('/campo-valores/$valorId/');
  }

  CampoDefinicao _definicaoDeMapa(Map<String, dynamic> definicao) {
    return CampoDefinicao(
      id: paraInteiro(definicao['id']),
      clienteId: paraInteiro(definicao['cliente']),
      programaId: paraInteiro(definicao['programa']),
      projetoId: paraInteiro(definicao['projeto']),
      nivelAplicacao: NivelAplicacao.porValorApi(
        paraTexto(definicao['nivel_aplicacao']),
      ),
      referencia: paraTexto(definicao['referencia']),
      descricao: paraTexto(definicao['descricao']),
      tipo: TipoCampo.porValorApi(paraTexto(definicao['tipo'])),
      obrigatorio: definicao['obrigatorio'] == true,
    );
  }

  CampoValor _valorDeMapa(Map<String, dynamic> valor) {
    return CampoValor(
      id: paraInteiro(valor['id']),
      definicaoId: paraInteiro(valor['definicao']) ?? 0,
      clienteId: paraInteiro(valor['cliente']),
      programaId: paraInteiro(valor['programa']),
      projetoId: paraInteiro(valor['projeto']),
      eventoId: paraInteiro(valor['evento']),
      valor: valor['valor'] is Map
          ? Map<String, dynamic>.from(valor['valor'] as Map)
          : const {},
    );
  }
}

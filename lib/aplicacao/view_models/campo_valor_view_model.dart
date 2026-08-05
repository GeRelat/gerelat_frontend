import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_valor.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

/// Uma variável aplicável ao alvo selecionado, junto do valor já gravado
/// (`null` quando ainda não foi preenchida).
class VariavelDoAlvo {
  final CampoDefinicao definicao;
  final CampoValor? valor;

  /// Escopo onde a definição foi declarada, já resolvido para exibição
  /// (ex.: "Programa Mais Ciência").
  final String origem;

  const VariavelDoAlvo({
    required this.definicao,
    required this.valor,
    required this.origem,
  });

  bool get preenchida => valor != null && valor!.valor.isNotEmpty;

  bool get pendente => definicao.obrigatorio && !preenchida;
}

/// Preenchimento dos valores (`CampoValor`) de uma instância-alvo.
///
/// As definições visíveis vêm da cadeia de ancestrais do alvo — uma variável
/// declarada no cliente aparece para todos os eventos daquele cliente — e são
/// filtradas por `nivelAplicacao == nível do alvo`, exatamente a regra que
/// `CampoValor.clean` valida no backend.
class CampoValorViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;

  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  NivelAplicacao _alvo = NivelAplicacao.evento;
  int? _alvoId;
  List<VariavelDoAlvo> _variaveis = [];

  CampoValorViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelAplicacao get alvo => _alvo;
  int? get alvoId => _alvoId;
  List<VariavelDoAlvo> get variaveis => List.unmodifiable(_variaveis);

  List<OpcaoSelecao> get opcoesAlvo => _hierarquia.opcoesDe(_alvo);

  String get nomeAlvoSelecionado => _hierarquia.nomeDe(_alvo, _alvoId);

  int get totalPendentes => _variaveis.where((v) => v.pendente).length;

  Future<void> carregarHierarquia() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(_repositorio);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> selecionarAlvo(NivelAplicacao alvo, int? alvoId) async {
    _alvo = alvo;
    _alvoId = alvoId;
    _variaveis = [];
    notifyListeners();
    if (alvoId == null) return;

    iniciarCarregamento();
    try {
      _variaveis = await _carregarVariaveis(alvo, alvoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<List<VariavelDoAlvo>> _carregarVariaveis(
    NivelAplicacao alvo,
    int alvoId,
  ) async {
    final cadeia = _hierarquia.cadeiaDe(alvo, alvoId);
    final definicoes = await _repositorio.listarDefinicoesVisiveis(
      clienteId: cadeia.clienteId,
      programaId: cadeia.programaId,
      projetoId: cadeia.projetoId,
    );
    final valores = await _repositorio.listarValores(
      alvo: alvo,
      alvoId: alvoId,
    );
    final valorPorDefinicao = {
      for (final valor in valores) valor.definicaoId: valor,
    };

    return definicoes
        .where((definicao) => definicao.nivelAplicacao == alvo)
        .map(
          (definicao) => VariavelDoAlvo(
            definicao: definicao,
            valor: valorPorDefinicao[definicao.id],
            origem:
                '${definicao.nivelEscopo.rotulo} '
                '${_hierarquia.nomeDeEscopo(definicao.nivelEscopo, definicao.escopoId)}',
          ),
        )
        .toList();
  }

  Future<bool> salvarValor({
    required VariavelDoAlvo variavel,
    required Map<String, dynamic> valor,
  }) {
    final definicaoId = variavel.definicao.id;
    if (definicaoId == null) return Future.value(false);
    return _executarAcao(
      (alvo, alvoId) => _repositorio.salvarValor(
        valorId: variavel.valor?.id,
        definicaoId: definicaoId,
        alvo: alvo,
        alvoId: alvoId,
        valor: valor,
      ),
    );
  }

  Future<bool> limparValor(VariavelDoAlvo variavel) {
    final valorId = variavel.valor?.id;
    if (valorId == null) return Future.value(false);
    return _executarAcao((_, _) => _repositorio.excluirValor(valorId));
  }

  Future<int?> enviarImagem({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async {
    try {
      return await _repositorio.criarAsset(
        arquivoBytes: arquivoBytes,
        nomeArquivo: nomeArquivo,
      );
    } catch (erro) {
      definirErro(erro);
      return null;
    }
  }

  /// Executa uma escrita sobre o alvo selecionado e recarrega a lista.
  Future<bool> _executarAcao(
    Future<void> Function(NivelAplicacao alvo, int alvoId) acao,
  ) async {
    final alvoId = _alvoId;
    if (alvoId == null) return false;

    iniciarCarregamento();
    try {
      await acao(_alvo, alvoId);
      _variaveis = await _carregarVariaveis(_alvo, alvoId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

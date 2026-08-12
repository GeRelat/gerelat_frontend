import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_valor.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
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
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  NivelAplicacao _alvo = NivelAplicacao.projeto;
  int? _alvoId;
  List<VariavelDoAlvo> _variaveis = [];

  CampoValorViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;
  NivelAplicacao get alvo => _alvo;
  NivelEscopo? get alvoNivel => NivelEscopo.deAplicacao(_alvo);
  int? get alvoId => _alvoId;
  List<VariavelDoAlvo> get variaveis => List.unmodifiable(_variaveis);

  void definirContexto(int? clienteId, Usuario? usuarioAtual) {
    final mudou = _clienteAtivoId != clienteId || _usuarioAtual != usuarioAtual;
    _clienteAtivoId = clienteId;
    _usuarioAtual = usuarioAtual;

    if (mudou) {
      final opcoes = opcoesAlvo;
      if (opcoes.isNotEmpty) {
        if (!opcoes.any((o) => o.id == _alvoId)) {
          selecionarAlvo(_alvo, opcoes.first.id);
        }
      } else {
        selecionarAlvo(_alvo, null);
      }
    }
  }

  void definirClienteAtivoId(int? clienteId) {
    definirContexto(clienteId, _usuarioAtual);
  }

  bool podeEditarAlvo(NivelAplicacao alvo, int? alvoId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (alvoId == null) return false;

    switch (alvo) {
      case NivelAplicacao.cliente:
        return false;

      case NivelAplicacao.programa:
        return usuario.contextosAcesso.programas
            .any((p) => int.tryParse('${p['id']}') == alvoId);

      case NivelAplicacao.projeto:
        final eMembroDoProjeto = usuario.contextosAcesso.projetos
            .any((p) => int.tryParse('${p['id']}') == alvoId);
        if (eMembroDoProjeto) return true;

        final progPaiId = _hierarquia.projetoPorId(alvoId)?.programaId;
        final eMembroDoProgramaPai = progPaiId != null &&
            usuario.contextosAcesso.programas
                .any((p) => int.tryParse('${p['id']}') == progPaiId);
        return eMembroDoProgramaPai;

      case NivelAplicacao.evento:
        return false;
    }
  }

  bool get podeEditar => podeEditarAlvo(_alvo, _alvoId);

  List<OpcaoSelecao> get opcoesAlvo =>
      _hierarquia.opcoesDe(_alvo, clienteId: _clienteAtivoId);

  String get nomeAlvoSelecionado => _hierarquia.nomeDe(_alvo, _alvoId);

  int get totalPendentes => _variaveis.where((v) => v.pendente).length;

  Future<void> carregarHierarquia() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(_repositorio);
      final opcoes = opcoesAlvo;
      if (opcoes.isNotEmpty &&
          (_alvoId == null || !opcoes.any((o) => o.id == _alvoId))) {
        await selecionarAlvo(_alvo, opcoes.first.id);
      } else {
        finalizarCarregamento();
      }
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
    final alvoId = _alvoId;
    if (alvoId == null) return null;

    final cadeia = _hierarquia.cadeiaDe(_alvo, alvoId);
    final (escopo, escopoId) = switch (_alvo) {
      NivelAplicacao.cliente => (NivelEscopo.cliente, alvoId),
      NivelAplicacao.programa => (NivelEscopo.programa, alvoId),
      NivelAplicacao.projeto => (NivelEscopo.projeto, alvoId),
      NivelAplicacao.evento => (NivelEscopo.projeto, cadeia.projetoId),
    };
    if (escopoId == null) return null;

    try {
      final asset = await _repositorio.criarAsset(
        arquivoBytes: arquivoBytes,
        nomeArquivo: nomeArquivo,
        escopo: escopo,
        escopoId: escopoId,
      );
      return asset.id;
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

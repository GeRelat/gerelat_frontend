import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/utils/gaps_prosemirror.dart';

/// CRUD do *schema* das variáveis (`CampoDefinicao`) de um escopo.
///
/// Um escopo é uma instância de cliente, programa ou projeto; toda definição
/// declarada ali vale para as instâncias de `nivelAplicacao` abaixo dele. Os
/// valores em si ficam em `CampoValorViewModel`.
class CampoDefinicaoViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;

  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  NivelEscopo _escopo = NivelEscopo.programa;
  int? _escopoId;
  List<CampoDefinicao> _definicoes = [];

  CampoDefinicaoViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;
  NivelEscopo get escopo => _escopo;
  int? get escopoId => _escopoId;
  List<CampoDefinicao> get definicoes => List.unmodifiable(_definicoes);

  void definirContexto(int? clienteId, Usuario? usuarioAtual) {
    final mudou = _clienteAtivoId != clienteId || _usuarioAtual != usuarioAtual;
    _clienteAtivoId = clienteId;
    _usuarioAtual = usuarioAtual;

    if (mudou) {
      final opcoes = opcoesEscopo;
      if (opcoes.isNotEmpty) {
        if (!opcoes.any((o) => o.id == _escopoId)) {
          selecionarEscopo(_escopo, opcoes.first.id);
        }
      } else {
        selecionarEscopo(_escopo, null);
      }
    }
  }

  void definirClienteAtivoId(int? clienteId) {
    definirContexto(clienteId, _usuarioAtual);
  }

  bool podeEditarEscopo(NivelEscopo escopo, int? escopoId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (escopoId == null) return false;

    switch (escopo) {
      case NivelEscopo.cliente:
        return false;

      case NivelEscopo.programa:
        return usuario.contextosAcesso.programas
            .any((p) => int.tryParse('${p['id']}') == escopoId);

      case NivelEscopo.projeto:
        final eMembroDoProjeto = usuario.contextosAcesso.projetos
            .any((p) => int.tryParse('${p['id']}') == escopoId);
        if (eMembroDoProjeto) return true;

        final progPaiId = _hierarquia.projetoPorId(escopoId)?.programaId;
        final eMembroDoProgramaPai = progPaiId != null &&
            usuario.contextosAcesso.programas
                .any((p) => int.tryParse('${p['id']}') == progPaiId);
        return eMembroDoProgramaPai;
    }
  }

  bool podeEditarDefinicao(CampoDefinicao definicao) {
    return podeEditarEscopo(definicao.nivelEscopo, definicao.escopoId);
  }

  bool podeCriarNoPrograma(int? programaId) =>
      podeEditarEscopo(NivelEscopo.programa, programaId);

  List<Projeto> projetosDoPrograma(int? programaId) {
    if (programaId == null) return const [];
    return _hierarquia.projetos
        .where((p) => p.programaId == programaId)
        .toList();
  }

  List<Projeto> projetosPermitidosParaCriar(int? programaId) {
    return projetosDoPrograma(programaId)
        .where((p) => podeEditarEscopo(NivelEscopo.projeto, p.id))
        .toList();
  }

  bool podeCriarVariavel(int? programaId) {
    return podeCriarNoPrograma(programaId) ||
        projetosPermitidosParaCriar(programaId).isNotEmpty;
  }

  bool get podeEditar => podeEditarEscopo(_escopo, _escopoId);

  List<OpcaoSelecao> get opcoesEscopo =>
      _hierarquia.opcoesDeEscopo(_escopo, clienteId: _clienteAtivoId);

  /// Níveis que o escopo atual pode alcançar — espelha a constraint
  /// `campodef_nivel_geq_escopo` (uma definição não pode se aplicar a algo
  /// mais raso que o escopo onde foi declarada).
  List<NivelAplicacao> get niveisAplicacaoPermitidos =>
      NivelAplicacao.aPartirDe(_escopo);

  String get nomeEscopoSelecionado =>
      _hierarquia.nomeDeEscopo(_escopo, _escopoId);

  Future<void> carregarHierarquia() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _repositorio,
        comEventos: false,
      );
      final opcoes = opcoesEscopo;
      if (opcoes.isNotEmpty &&
          (_escopoId == null || !opcoes.any((o) => o.id == _escopoId))) {
        await selecionarEscopo(_escopo, opcoes.first.id);
      } else {
        finalizarCarregamento();
      }
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> selecionarEscopo(NivelEscopo escopo, int? escopoId) async {
    _escopo = escopo;
    _escopoId = escopoId;
    _definicoes = [];
    notifyListeners();
    if (escopoId == null) return;

    iniciarCarregamento();
    try {
      final todas = await _repositorio.listarDefinicoes();
      if (escopo == NivelEscopo.programa) {
        final projetoIds = _hierarquia.projetos
            .where((p) => p.programaId == escopoId)
            .map((p) => p.id)
            .whereType<int>()
            .toSet();
        _definicoes = todas.where((d) {
          if (d.nivelEscopo == NivelEscopo.programa && d.escopoId == escopoId) {
            return true;
          }
          if (d.nivelEscopo == NivelEscopo.projeto &&
              d.escopoId != null &&
              projetoIds.contains(d.escopoId)) {
            return true;
          }
          return false;
        }).toList();
      } else {
        _definicoes = todas
            .where((d) => d.nivelEscopo == escopo && d.escopoId == escopoId)
            .toList();
      }
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  /// Valida no cliente as duas regras que o backend só reporta como erro
  /// genérico: prefixo reservado (`CampoDefinicao.clean`) e unicidade de
  /// `(escopo, referencia)` (constraint `campodef_unique_referencia_per_escopo`).
  /// Retorna a mensagem de erro, ou `null` se a referência é aceitável.
  String? validarReferencia(
    String referencia, {
    NivelEscopo? escopo,
    int? escopoId,
    int? ignorandoDefinicaoId,
  }) {
    final texto = referencia.trim();
    if (texto.isEmpty) return 'Campo obrigatório';
    if (ehReferenciaDeSistema(texto)) {
      return 'O prefixo "$prefixoSistema" é reservado aos campos nativos.';
    }
    final escopoAlvo = escopo ?? _escopo;
    final escopoIdAlvo = escopoId ?? _escopoId;
    final duplicada = _definicoes.any(
      (definicao) =>
          definicao.id != ignorandoDefinicaoId &&
          definicao.nivelEscopo == escopoAlvo &&
          definicao.escopoId == escopoIdAlvo &&
          definicao.referencia.toLowerCase() == texto.toLowerCase(),
    );
    if (duplicada) {
      return 'Já existe uma variável com esta referência neste escopo.';
    }
    return null;
  }

  Future<bool> salvar({
    int? definicaoId,
    NivelEscopo? escopo,
    int? escopoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  }) {
    final escopoFinal = escopo ?? _escopo;
    final escopoIdFinal = escopoId ?? _escopoId;
    if (escopoIdFinal == null) return Future.value(false);

    return _executarAcao(() async {
      if (definicaoId == null) {
        await _repositorio.criarDefinicao(
          escopo: escopoFinal,
          escopoId: escopoIdFinal,
          nivelAplicacao: nivelAplicacao,
          referencia: referencia,
          descricao: descricao,
          tipo: tipo,
          obrigatorio: obrigatorio,
        );
      } else {
        await _repositorio.atualizarDefinicao(
          definicaoId: definicaoId,
          nivelAplicacao: nivelAplicacao,
          referencia: referencia,
          descricao: descricao,
          tipo: tipo,
          obrigatorio: obrigatorio,
        );
      }
    });
  }

  Future<bool> excluir(int definicaoId) {
    return _executarAcao(() => _repositorio.excluirDefinicao(definicaoId));
  }

  /// Executa uma escrita e recarrega a lista do escopo selecionado.
  Future<bool> _executarAcao(Future<void> Function() acao) async {
    final escopoId = _escopoId;
    if (escopoId == null) return false;

    iniciarCarregamento();
    try {
      await acao();
      await selecionarEscopo(_escopo, _escopoId);
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

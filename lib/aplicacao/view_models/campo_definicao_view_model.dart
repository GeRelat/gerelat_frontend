import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
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
  NivelEscopo _escopo = NivelEscopo.projeto;
  int? _escopoId;
  List<CampoDefinicao> _definicoes = [];

  CampoDefinicaoViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelEscopo get escopo => _escopo;
  int? get escopoId => _escopoId;
  List<CampoDefinicao> get definicoes => List.unmodifiable(_definicoes);

  List<OpcaoSelecao> get opcoesEscopo => _hierarquia.opcoesDeEscopo(_escopo);

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
      finalizarCarregamento();
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
      _definicoes = await _repositorio.listarDefinicoes(
        escopo: escopo,
        escopoId: escopoId,
      );
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  /// Valida no cliente as duas regras que o backend só reporta como erro
  /// genérico: prefixo reservado (`CampoDefinicao.clean`) e unicidade de
  /// `(escopo, referencia)` (constraint `campodef_unique_referencia_per_escopo`).
  /// Retorna a mensagem de erro, ou `null` se a referência é aceitável.
  String? validarReferencia(String referencia, {int? ignorandoDefinicaoId}) {
    final texto = referencia.trim();
    if (texto.isEmpty) return 'Campo obrigatório';
    if (ehReferenciaDeSistema(texto)) {
      return 'O prefixo "$prefixoSistema" é reservado aos campos nativos.';
    }
    final duplicada = _definicoes.any(
      (definicao) =>
          definicao.referencia == texto && definicao.id != ignorandoDefinicaoId,
    );
    if (duplicada) {
      return 'Já existe uma variável com esta referência neste escopo.';
    }
    return null;
  }

  Future<bool> salvar({
    int? definicaoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  }) {
    return _executarAcao((escopo, escopoId) async {
      if (definicaoId == null) {
        await _repositorio.criarDefinicao(
          escopo: escopo,
          escopoId: escopoId,
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
    return _executarAcao((_, _) => _repositorio.excluirDefinicao(definicaoId));
  }

  /// Executa uma escrita sobre o escopo selecionado e recarrega a lista —
  /// mesmo tratamento para [salvar] e [excluir].
  Future<bool> _executarAcao(
    Future<void> Function(NivelEscopo escopo, int escopoId) acao,
  ) async {
    final escopoId = _escopoId;
    if (escopoId == null) return false;

    iniciarCarregamento();
    try {
      await acao(_escopo, escopoId);
      _definicoes = await _repositorio.listarDefinicoes(
        escopo: _escopo,
        escopoId: escopoId,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

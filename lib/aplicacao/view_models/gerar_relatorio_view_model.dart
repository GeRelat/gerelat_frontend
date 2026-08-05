import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/variaveis_do_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/utils/gaps_prosemirror.dart';

class GerarRelatorioViewModel extends BaseViewModel {
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioCatalogo _catalogo;

  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  List<TemplateRelatorio> _templates = [];

  TemplateRelatorio? _template;
  List<VariavelDisponivel> _variaveisDisponiveis = [];
  Set<String> _refsUsadas = {};
  List<String> _refsNaoContempladas = [];
  List<String> _blocosManuais = [];
  NivelAplicacao? _nivelExigido;

  int? _clienteId;
  int? _programaId;
  int? _projetoId;
  int? _eventoId;

  GerarRelatorioViewModel(RepositorioCatalogo repositorio)
    : _templatesRepositorio = repositorio,
      _catalogo = repositorio;

  HierarquiaEscopo get hierarquia => _hierarquia;
  List<TemplateRelatorio> get templates => List.unmodifiable(_templates);
  TemplateRelatorio? get template => _template;

  int? get clienteId => _clienteId;
  int? get programaId => _programaId;
  int? get projetoId => _projetoId;
  int? get eventoId => _eventoId;

  /// Nível mais profundo que o documento do template exige para resolver todas
  /// as suas variáveis. `null` quando nenhuma variável depende de instância.
  /// Espelha `scan_required_nivel` do backend, que responde 400 se o nível
  /// exigido não vier no `POST /relatorios/`.
  NivelAplicacao? get nivelExigido => _nivelExigido;

  /// Variáveis referenciadas pelo template que não têm definição visível neste
  /// escopo — vão render `[referencia]` no documento gerado.
  List<String> get refsNaoContempladas => List.unmodifiable(_refsNaoContempladas);

  /// Rótulos dos blocos de texto livre que o usuário poderá editar no preview.
  List<String> get blocosManuais => List.unmodifiable(_blocosManuais);

  /// Variáveis obrigatórias usadas pelo template — servem de aviso quando o
  /// valor ainda não foi preenchido para a instância escolhida.
  List<VariavelDisponivel> get obrigatoriasUsadas => _variaveisDisponiveis
      .where(
        (variavel) =>
            variavel.obrigatorio && _refsUsadas.contains(variavel.referencia),
      )
      .toList();

  /// Níveis que o usuário precisa escolher: do nível do próprio template até o
  /// exigido pelo documento. Vazio quando o escopo do template já basta.
  List<NivelAplicacao> get niveisASelecionar {
    final template = _template;
    final exigido = _nivelExigido;
    if (template == null || exigido == null) return const [];
    return NivelAplicacao.values
        .where(
          (nivel) =>
              nivel.ordem > template.nivel.ordem && nivel.ordem <= exigido.ordem,
        )
        .toList();
  }

  /// `true` quando toda a cadeia exigida já foi informada.
  bool get escopoCompleto {
    final exigido = _nivelExigido;
    if (exigido == null) return _template != null;
    return switch (exigido) {
      NivelAplicacao.cliente => _clienteId != null,
      NivelAplicacao.programa => _programaId != null,
      NivelAplicacao.projeto => _projetoId != null,
      NivelAplicacao.evento => _eventoId != null,
    };
  }

  String? get mensagemEscopoIncompleto {
    if (escopoCompleto) return null;
    final exigido = _nivelExigido;
    if (exigido == null) return null;
    final rotulo = exigido.rotulo.toLowerCase();
    return 'Este template usa variáveis de nível $rotulo. '
        'Selecione o $rotulo para gerar o relatório.';
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(_catalogo);
      _templates = await _templatesRepositorio.listarTemplates();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  List<OpcaoSelecao> opcoesDe(NivelAplicacao nivel) => _hierarquia.opcoesDe(
    nivel,
    clienteId: _clienteId,
    programaId: _programaId,
    projetoId: _projetoId,
  );

  /// Carrega o documento e as variáveis do template escolhido e calcula, no
  /// cliente, o que o backend validaria só na hora de gerar: nível exigido e
  /// referências sem definição.
  Future<void> selecionarTemplate(int? templateId) async {
    _template = null;
    _variaveisDisponiveis = [];
    _refsUsadas = {};
    _refsNaoContempladas = [];
    _blocosManuais = [];
    _nivelExigido = null;
    _clienteId = null;
    _programaId = null;
    _projetoId = null;
    _eventoId = null;
    notifyListeners();
    if (templateId == null) return;

    iniciarCarregamento();
    try {
      final template = _templates.firstWhere(
        (candidato) => candidato.id == templateId,
        orElse: () => throw Exception('Template não encontrado.'),
      );
      _template = template;

      // A cadeia do próprio template já está definida pelo escopo dele; só os
      // níveis abaixo é que o usuário precisa escolher.
      final cadeia = _hierarquia.cadeiaDeEscopo(
        template.nivel,
        template.escopoId,
      );
      _clienteId = cadeia.clienteId;
      _programaId = cadeia.programaId;
      _projetoId = cadeia.projetoId;

      final escopoId = template.escopoId;
      final documento = await _templatesRepositorio.obterModeloTemplate(
        templateId,
      );
      _variaveisDisponiveis = escopoId == null
          ? []
          : await carregarVariaveisDoEscopo(
              _catalogo,
              _hierarquia,
              escopo: template.nivel,
              escopoId: escopoId,
            );

      _refsUsadas = extrairRefsDeVariaveis(documento);
      _blocosManuais = extrairLabelsDeBlocosManuais(documento);

      final nivelPorReferencia = {
        for (final variavel in _variaveisDisponiveis)
          variavel.referencia: variavel.nivelAplicacao,
      };
      _nivelExigido = nivelExigidoPorRefs(_refsUsadas, nivelPorReferencia);
      _refsNaoContempladas =
          _refsUsadas
              .where(
                (ref) =>
                    !ehReferenciaDeSistema(ref) &&
                    !nivelPorReferencia.containsKey(ref),
              )
              .toList()
            ..sort();

      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  /// Define um elo da cadeia, resolvendo os ancestrais e limpando os
  /// descendentes que deixaram de fazer sentido — a mesma direção de resolução
  /// que `RelatorioGenerateRequestSerializer.validate` faz no backend.
  void definirEscopo(NivelAplicacao nivel, int? id) {
    if (id == null) {
      switch (nivel) {
        case NivelAplicacao.cliente:
          _clienteId = null;
          _programaId = null;
          _projetoId = null;
          _eventoId = null;
        case NivelAplicacao.programa:
          _programaId = null;
          _projetoId = null;
          _eventoId = null;
        case NivelAplicacao.projeto:
          _projetoId = null;
          _eventoId = null;
        case NivelAplicacao.evento:
          _eventoId = null;
      }
      notifyListeners();
      return;
    }

    final cadeia = _hierarquia.cadeiaDe(nivel, id);
    _clienteId = cadeia.clienteId ?? _clienteId;
    _programaId = cadeia.programaId;
    _projetoId = cadeia.projetoId;
    _eventoId = cadeia.eventoId;
    notifyListeners();
  }

  /// Resolve as variáveis sobre o template e devolve o documento ProseMirror
  /// pronto para preview/edição no editor.
  Future<Map<String, dynamic>?> obterDocumentoPreview() async {
    final templateId = _template?.id;
    if (templateId == null) return null;

    iniciarCarregamento();
    try {
      final documento = await _templatesRepositorio.previsualizarTemplate(
        templateId: templateId,
        clienteId: _clienteId,
        programaId: _programaId,
        projetoId: _projetoId,
        eventoId: _eventoId,
      );
      finalizarCarregamento();
      return documento;
    } catch (erro) {
      definirErro(erro);
      return null;
    }
  }
}

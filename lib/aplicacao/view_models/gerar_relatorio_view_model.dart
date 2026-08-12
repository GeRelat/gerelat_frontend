import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/variaveis_do_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/utils/gaps_prosemirror.dart';

class GerarRelatorioViewModel extends BaseViewModel {
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioCatalogo _catalogo;

  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  List<TemplateRelatorio> _templates = [];

  TemplateRelatorio? _template;
  List<Evento>? _eventosDisponiveis;
  List<VariavelDisponivel> _variaveisDisponiveis = [];
  Set<String> _refsUsadas = {};
  List<String> _refsNaoContempladas = [];
  List<String> _blocosManuais = [];
  NivelAplicacao? _nivelExigido;

  int? _clienteId;
  int? _programaId;
  int? _projetoId;
  int? _eventoId;

  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  NivelEscopo _filtroNivel = NivelEscopo.projeto;
  int? _filtroEscopoId;

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

  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;
  NivelEscopo get filtroNivel => _filtroNivel;
  int? get filtroEscopoId => _filtroEscopoId;

  List<NivelEscopo> get niveisPermitidos {
    final usuario = _usuarioAtual;
    if (usuario == null) return NivelEscopo.values;
    if (usuario.isAdminGeRelat || usuario.eAdminDoCliente(_clienteAtivoId)) {
      return const [NivelEscopo.cliente, NivelEscopo.programa, NivelEscopo.projeto];
    }

    final eMembroPrograma = usuario.contextosAcesso.programas.any((p) {
      if (_clienteAtivoId == null) return true;
      final cId = int.tryParse('${p['cliente_id']}');
      return cId == _clienteAtivoId;
    });

    if (eMembroPrograma) {
      return const [NivelEscopo.programa, NivelEscopo.projeto];
    }

    final eMembroProjeto = usuario.contextosAcesso.projetos.any((p) {
      if (_clienteAtivoId == null) return true;
      final cId = int.tryParse('${p['cliente_id']}');
      return cId == _clienteAtivoId;
    });

    if (eMembroProjeto) {
      return const [NivelEscopo.projeto];
    }

    return const [NivelEscopo.projeto];
  }

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final mudou = _clienteAtivoId != clienteAtivoId || _usuarioAtual != usuarioAtual;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;

    _ajustarFiltros();

    if (mudou) {
      _template = null;
      notifyListeners();
    }
  }

  void _ajustarFiltros() {
    final permitidos = niveisPermitidos;
    if (permitidos.isNotEmpty && !permitidos.contains(_filtroNivel)) {
      _filtroNivel = permitidos.first;
    }
    final opcoes = opcoesFiltroEscopo;
    if (_filtroEscopoId != null && !opcoes.any((o) => o.id == _filtroEscopoId)) {
      _filtroEscopoId = null;
    }
  }

  void selecionarFiltroNivel(NivelEscopo nivel) {
    _filtroNivel = nivel;
    _filtroEscopoId = null;
    _template = null;
    notifyListeners();
  }

  void selecionarFiltroEscopoId(int? id) {
    _filtroEscopoId = id;
    _template = null;
    notifyListeners();
  }

  List<OpcaoSelecao> get opcoesFiltroEscopo =>
      _hierarquia.opcoesDeEscopo(_filtroNivel, clienteId: _clienteAtivoId);

  List<TemplateRelatorio> get templatesFiltrados {
    return _templates.where((t) {
      // 1. Cliente ativo
      if (_clienteAtivoId != null) {
        final cId = resolverClienteIdDoTemplate(t);
        if (cId != _clienteAtivoId) return false;
      }

      // 2. Filtro de Nível
      if (t.nivel != _filtroNivel) return false;

      // 3. Filtro específico de escopo (Programa ou Projeto)
      if (_filtroEscopoId != null) {
        if (_filtroNivel == NivelEscopo.programa && t.programaId != _filtroEscopoId) {
          return false;
        }
        if (_filtroNivel == NivelEscopo.projeto && t.projetoId != _filtroEscopoId) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int? resolverClienteIdDoTemplate(TemplateRelatorio t) {
    if (t.clienteId != null) return t.clienteId;
    if (t.programaId != null) {
      return _hierarquia.programaPorId(t.programaId)?.clienteId;
    }
    if (t.projetoId != null) {
      return _hierarquia.cadeiaDe(NivelAplicacao.projeto, t.projetoId).clienteId;
    }
    return null;
  }

  String nomeOrigemTemplate(TemplateRelatorio t) {
    switch (t.nivel) {
      case NivelEscopo.cliente:
        return 'Cliente: ${_hierarquia.nomeDe(NivelAplicacao.cliente, t.clienteId)}';
      case NivelEscopo.programa:
        return 'Programa: ${_hierarquia.nomeDe(NivelAplicacao.programa, t.programaId)}';
      case NivelEscopo.projeto:
        return 'Projeto: ${_hierarquia.nomeDe(NivelAplicacao.projeto, t.projetoId)}';
    }
  }

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

  /// Níveis que o usuário precisa escolher: os níveis abaixo do escopo do template
  /// cujas variáveis são usadas no documento (mais ancestrais necessários).
  /// Se houver variáveis de evento, a opção de Evento é posicionada em primeiro.
  List<NivelAplicacao> get niveisASelecionar {
    final template = _template;
    if (template == null) return const [];

    final exigidos = niveisExigidos;
    if (exigidos.isEmpty) return const [];

    final selecionar = <NivelAplicacao>{};
    for (final nivel in exigidos) {
      selecionar.add(nivel);
      if (nivel == NivelAplicacao.projeto && template.nivel == NivelEscopo.cliente) {
        selecionar.add(NivelAplicacao.programa);
      }
    }

    final lista = selecionar.toList();
    lista.sort((a, b) {
      if (a == NivelAplicacao.evento) return -1;
      if (b == NivelAplicacao.evento) return 1;
      return a.ordem.compareTo(b.ordem);
    });
    return lista;
  }

  /// Níveis cujas variáveis (ou referências de sistema) são efetivamente
  /// usadas no documento do template.
  Set<NivelAplicacao> get niveisExigidos {
    final template = _template;
    if (template == null) return {};

    final mapaRefs = {
      for (final v in _variaveisDisponiveis) v.referencia: v.nivelAplicacao
    };

    final exigidos = <NivelAplicacao>{};
    for (final ref in _refsUsadas) {
      if (ref.startsWith('sistema.cliente.') || ref.startsWith('cliente.')) {
        exigidos.add(NivelAplicacao.cliente);
      } else if (ref.startsWith('sistema.programa.') || ref.startsWith('programa.')) {
        exigidos.add(NivelAplicacao.programa);
      } else if (ref.startsWith('sistema.projeto.') || ref.startsWith('projeto.')) {
        exigidos.add(NivelAplicacao.projeto);
      } else if (ref.startsWith('sistema.evento.') || ref.startsWith('evento.')) {
        exigidos.add(NivelAplicacao.evento);
      } else if (mapaRefs.containsKey(ref)) {
        exigidos.add(mapaRefs[ref]!);
      }
    }

    return exigidos
        .where((nivel) => nivel.ordem > template.nivel.ordem)
        .toSet();
  }

  /// `true` quando toda a cadeia de níveis exigida pelo template já foi informada.
  bool get escopoCompleto {
    final template = _template;
    if (template == null) return false;
    final exigidos = niveisExigidos;
    if (exigidos.isEmpty) return true;

    for (final nivel in exigidos) {
      final preenchido = switch (nivel) {
        NivelAplicacao.cliente => _clienteId != null,
        NivelAplicacao.programa => _programaId != null,
        NivelAplicacao.projeto => _projetoId != null,
        NivelAplicacao.evento => _eventoId != null,
      };
      if (!preenchido) return false;
    }
    return true;
  }

  String? get mensagemEscopoIncompleto {
    if (escopoCompleto) return null;
    final niveisFaltando = niveisExigidos.where((nivel) {
      return switch (nivel) {
        NivelAplicacao.cliente => _clienteId == null,
        NivelAplicacao.programa => _programaId == null,
        NivelAplicacao.projeto => _projetoId == null,
        NivelAplicacao.evento => _eventoId == null,
      };
    }).map((n) => n.rotulo.toLowerCase()).toList();

    if (niveisFaltando.isEmpty) return null;
    return 'Este template requer a seleção de: ${niveisFaltando.join(', ')}. '
        'Selecione os valores correspondentes para gerar o relatório.';
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(_catalogo);
      _templates = await _templatesRepositorio.listarTemplates();
      _ajustarFiltros();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  List<OpcaoSelecao> opcoesDe(NivelAplicacao nivel) {
    if (nivel == NivelAplicacao.evento &&
        _template != null &&
        _eventosDisponiveis != null) {
      final templateNivel = _template!.nivel;
      final listaFiltrada = _eventosDisponiveis!.where((evento) {
        if (evento.id == null) return false;

        switch (templateNivel) {
          case NivelEscopo.cliente:
            return evento.clienteId == _clienteId;
          case NivelEscopo.programa:
            return evento.programaId == _programaId;
          case NivelEscopo.projeto:
            return evento.projetoId == _projetoId;
        }
      });

      return [
        for (final evento in listaFiltrada)
          OpcaoSelecao(
            id: evento.id!,
            nome: evento.classeEventoNome.isNotEmpty
                ? '${evento.nome} (${evento.classeEventoNome})'
                : evento.nome,
          ),
      ];
    }
    return _hierarquia.opcoesDe(
      nivel,
      clienteId: _clienteId,
      programaId: _programaId,
      projetoId: _projetoId,
    );
  }

  /// Carrega o documento e as variáveis do template escolhido e calcula, no
  /// cliente, o que o backend validaria só na hora de gerar: nível exigido e
  /// referências sem definição.
  Future<void> selecionarTemplate(int? templateId) async {
    _template = null;
    _eventosDisponiveis = null;
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

      _eventosDisponiveis = await _templatesRepositorio.listarEventosDisponiveis(
        templateId,
      );

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

    if (nivel == NivelAplicacao.evento) {
      _eventoId = id;
      final eventoSel = _eventosDisponiveis?.firstWhere(
        (e) => e.id == id,
        orElse: () => _hierarquia.eventoPorId(id) ?? const Evento(nome: '', programa: '', data: null),
      );
      if (eventoSel != null) {
        if (eventoSel.projetoId != null) {
          final c = _hierarquia.cadeiaDe(NivelAplicacao.projeto, eventoSel.projetoId);
          _projetoId = eventoSel.projetoId;
          _programaId = c.programaId ?? _programaId;
          _clienteId = c.clienteId ?? _clienteId;
        } else if (eventoSel.programaId != null) {
          final c = _hierarquia.cadeiaDe(NivelAplicacao.programa, eventoSel.programaId);
          _programaId = eventoSel.programaId;
          _clienteId = c.clienteId ?? _clienteId;
        } else if (eventoSel.clienteId != null) {
          _clienteId = eventoSel.clienteId;
        }
      }
    } else {
      final cadeia = _hierarquia.cadeiaDe(nivel, id);
      _clienteId = cadeia.clienteId ?? _clienteId;
      _programaId = cadeia.programaId ?? _programaId;

      if (nivel == NivelAplicacao.projeto) {
        _projetoId = id;
      } else if (nivel == NivelAplicacao.programa) {
        _programaId = id;
        _projetoId = null;
      } else if (nivel == NivelAplicacao.cliente) {
        _clienteId = id;
      }
    }
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

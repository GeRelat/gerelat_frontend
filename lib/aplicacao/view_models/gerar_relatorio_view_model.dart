import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/variaveis_do_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/utils/gaps_prosemirror.dart';

class GerarRelatorioViewModel extends BaseViewModel {
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioEquipePrograma _equipeProgramaRepositorio;
  final RepositorioEquipeProjeto _equipeProjetoRepositorio;
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

  // Signatários: pool de candidatos do escopo do template + seleção (começa
  // marcada com as assinaturas configuradas no template, editável só aqui).
  List<MembroEquipePrograma> _signatariosPrograma = [];
  List<MembroEquipeProjeto> _signatariosProjeto = [];
  Set<int> _equipeProgramaSelecionada = {};
  Set<int> _equipeProjetoSelecionada = {};

  int? _clienteId;
  int? _programaId;
  int? _projetoId;
  int? _eventoId;

  int? _clienteAtivoId;
  Usuario? _usuarioAtual;

  // Passo 1 e 2 do fluxo: o relatório é sempre gerado a partir de um projeto de
  // um programa. Definem quais templates aparecem e resolvem a cadeia de escopo.
  int? _programaSelecionadoId;
  int? _projetoSelecionadoId;

  GerarRelatorioViewModel(RepositorioCatalogo repositorio)
    : _templatesRepositorio = repositorio,
      _equipeProgramaRepositorio = repositorio,
      _equipeProjetoRepositorio = repositorio,
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
  int? get programaSelecionadoId => _programaSelecionadoId;
  int? get projetoSelecionadoId => _projetoSelecionadoId;

  List<OpcaoSelecao> get opcoesPrograma =>
      _hierarquia.opcoesDeEscopo(NivelEscopo.programa, clienteId: _clienteAtivoId);

  List<OpcaoSelecao> get opcoesProjeto => _hierarquia.opcoesDe(
    NivelAplicacao.projeto,
    clienteId: _clienteAtivoId,
    programaId: _programaSelecionadoId,
  );

  List<NivelEscopo> get niveisPermitidos {
    final usuario = _usuarioAtual;
    if (usuario == null) return NivelEscopo.selecionaveis;
    if (usuario.isAdminGeRelat || usuario.eAdminDoCliente(_clienteAtivoId)) {
      return NivelEscopo.selecionaveis;
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

    if (mudou) {
      _programaSelecionadoId = null;
      _projetoSelecionadoId = null;
      _limparTemplate();
      notifyListeners();
    }
  }

  /// Passo 1: programa. Zera o projeto e o template escolhidos.
  void selecionarPrograma(int? id) {
    _programaSelecionadoId = id;
    _projetoSelecionadoId = null;
    _limparTemplate();
    notifyListeners();
  }

  /// Passo 2: projeto (obrigatório). Zera o template escolhido.
  void selecionarProjeto(int? id) {
    _projetoSelecionadoId = id;
    _limparTemplate();
    notifyListeners();
  }

  /// Templates que servem para o projeto escolhido: os de nível programa do
  /// programa selecionado + os de nível projeto daquele projeto.
  List<TemplateRelatorio> get templatesFiltrados {
    if (_projetoSelecionadoId == null) return const [];
    return _templates.where((t) {
      if (t.nivel == NivelEscopo.programa) {
        return t.programaId == _programaSelecionadoId;
      }
      if (t.nivel == NivelEscopo.projeto) {
        return t.projetoId == _projetoSelecionadoId;
      }
      return false;
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

  // ── Signatários ──────────────────────────────────────────────
  List<MembroEquipePrograma> get signatariosPrograma =>
      List.unmodifiable(_signatariosPrograma);
  List<MembroEquipeProjeto> get signatariosProjeto =>
      List.unmodifiable(_signatariosProjeto);
  Set<int> get equipeProgramaSelecionada =>
      Set.unmodifiable(_equipeProgramaSelecionada);
  Set<int> get equipeProjetoSelecionada =>
      Set.unmodifiable(_equipeProjetoSelecionada);

  bool get temSignatariosDisponiveis =>
      _signatariosPrograma.isNotEmpty || _signatariosProjeto.isNotEmpty;

  String nomePrograma(int? id) =>
      _hierarquia.nomeDe(NivelAplicacao.programa, id);
  String nomeProjeto(int? id) => _hierarquia.nomeDe(NivelAplicacao.projeto, id);

  void alternarSignatarioPrograma(int membroId) {
    if (!_equipeProgramaSelecionada.remove(membroId)) {
      _equipeProgramaSelecionada.add(membroId);
    }
    notifyListeners();
  }

  void alternarSignatarioProjeto(int membroId) {
    if (!_equipeProjetoSelecionada.remove(membroId)) {
      _equipeProjetoSelecionada.add(membroId);
    }
    notifyListeners();
  }

  /// Assinaturas escolhidas, na ordem em que aparecem no pool, prontas para o
  /// payload de `POST /relatorios/`.
  List<Map<String, int>> get assinaturasEscolhidas => [
    for (final m in _signatariosPrograma)
      if (m.id != null && _equipeProgramaSelecionada.contains(m.id))
        {'equipe_programa': m.id!},
    for (final m in _signatariosProjeto)
      if (m.id != null && _equipeProjetoSelecionada.contains(m.id))
        {'equipe_projeto': m.id!},
  ];

  /// Mesma lista, resolvida para exibição na pré-visualização (espelha
  /// `services.assinaturas_relatorio.resolver_assinaturas` no backend).
  List<Map<String, String>> get assinaturasResolvidas => [
    for (final m in _signatariosPrograma)
      if (m.id != null && _equipeProgramaSelecionada.contains(m.id))
        {'nome': m.nome, 'cargo': m.cargo, 'nome_equipe': ''},
    for (final m in _signatariosProjeto)
      if (m.id != null && _equipeProjetoSelecionada.contains(m.id))
        {'nome': m.nome, 'cargo': m.cargo, 'nome_equipe': m.nomeEquipe},
  ];

  /// Variáveis obrigatórias usadas pelo template — servem de aviso quando o
  /// valor ainda não foi preenchido para a instância escolhida.
  List<VariavelDisponivel> get obrigatoriasUsadas => _variaveisDisponiveis
      .where(
        (variavel) =>
            variavel.obrigatorio && _refsUsadas.contains(variavel.referencia),
      )
      .toList();

  /// Como programa e projeto já foram escolhidos, a única escolha de nível que
  /// pode restar é o evento — e só quando o template usa variáveis de evento.
  List<NivelAplicacao> get niveisASelecionar {
    if (_template == null) return const [];
    return niveisExigidos.contains(NivelAplicacao.evento)
        ? const [NivelAplicacao.evento]
        : const [];
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

  /// `true` quando programa, projeto e (se o template usar variável de evento) o
  /// evento já foram informados.
  bool get escopoCompleto {
    if (_template == null) return false;
    if (_projetoSelecionadoId == null) return false;
    if (niveisASelecionar.contains(NivelAplicacao.evento)) {
      return _eventoId != null;
    }
    return true;
  }

  String? get mensagemEscopoIncompleto {
    if (escopoCompleto) return null;
    if (_projetoSelecionadoId == null) {
      return 'Selecione o programa e o projeto para gerar o relatório.';
    }
    if (niveisASelecionar.contains(NivelAplicacao.evento) && _eventoId == null) {
      return 'Este template usa variáveis de evento. Selecione o evento para o '
          'qual o relatório será gerado.';
    }
    return null;
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

  /// Eventos do projeto escolhido — a única escolha de nível que resta depois
  /// que programa e projeto já estão definidos.
  List<OpcaoSelecao> opcoesDe(NivelAplicacao nivel) {
    if (nivel == NivelAplicacao.evento) {
      final eventos = _eventosDisponiveis ?? const [];
      return [
        for (final evento in eventos)
          if (evento.id != null && evento.projetoId == _projetoSelecionadoId)
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

  /// Zera o template escolhido e tudo que dele deriva.
  void _limparTemplate() {
    _template = null;
    _eventosDisponiveis = null;
    _variaveisDisponiveis = [];
    _refsUsadas = {};
    _refsNaoContempladas = [];
    _blocosManuais = [];
    _nivelExigido = null;
    _signatariosPrograma = [];
    _signatariosProjeto = [];
    _equipeProgramaSelecionada = {};
    _equipeProjetoSelecionada = {};
    _clienteId = null;
    _programaId = null;
    _projetoId = null;
    _eventoId = null;
  }

  /// Carrega o documento e as variáveis do template escolhido e calcula, no
  /// cliente, o que o backend validaria só na hora de gerar: nível exigido e
  /// referências sem definição.
  Future<void> selecionarTemplate(int? templateId) async {
    _limparTemplate();
    notifyListeners();
    if (templateId == null) return;

    iniciarCarregamento();
    try {
      final template = _templates.firstWhere(
        (candidato) => candidato.id == templateId,
        orElse: () => throw Exception('Template não encontrado.'),
      );
      _template = template;

      // Programa e projeto já foram escolhidos nos passos anteriores; a cadeia
      // completa vem do projeto selecionado.
      final cadeia = _hierarquia.cadeiaDe(
        NivelAplicacao.projeto,
        _projetoSelecionadoId,
      );
      _clienteId = cadeia.clienteId;
      _programaId = cadeia.programaId ?? _programaSelecionadoId;
      _projetoId = _projetoSelecionadoId;

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

      await _carregarSignatarios(template, escopoId);

      // Registra cada variável sob a referência que a API devolveu E sob a
      // forma sem prefixo de escopo — o nó do template pode citar
      // `texto_padrao` enquanto a API, vista de um projeto, lista
      // `programa.texto_padrao` (a resolução no backend casa as duas).
      final nivelPorReferencia = <String, NivelAplicacao>{};
      for (final variavel in _variaveisDisponiveis) {
        nivelPorReferencia[variavel.referencia] = variavel.nivelAplicacao;
        nivelPorReferencia[semPrefixoEscopo(variavel.referencia)] =
            variavel.nivelAplicacao;
      }
      _nivelExigido = nivelExigidoPorRefs(_refsUsadas, nivelPorReferencia);
      _refsNaoContempladas =
          _refsUsadas
              .where(
                (ref) =>
                    !ehReferenciaDeSistema(ref) &&
                    !nivelPorReferencia.containsKey(ref) &&
                    !nivelPorReferencia.containsKey(semPrefixoEscopo(ref)),
              )
              .toList()
            ..sort();

      // O cálculo acima só enxerga as refs diretas do template — uma
      // dependência escondida dentro do valor de uma variável de texto rico
      // (ex.: um texto de nível Programa que cita uma variável de nível
      // Projeto) não aparece, porque o cliente não tem o conteúdo da
      // variável. O backend tem (`scan_required_nivel` desce dentro do
      // texto rico), então perguntamos a ele e só escalamos o nível exigido
      // se a resposta for mais profunda do que o que já tínhamos localmente
      // — nunca o contrário, para não regredir o aviso já calculado.
      final nivelTransitivo = await _templatesRepositorio.nivelExigidoTemplate(
        templateId: templateId,
        clienteId: _clienteId,
        programaId: _programaId,
        projetoId: _projetoId,
      );
      if (nivelTransitivo != null &&
          (_nivelExigido == null || nivelTransitivo.ordem > _nivelExigido!.ordem)) {
        _nivelExigido = nivelTransitivo;
      }

      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  /// Carrega o pool de signatários (equipes do escopo do template) e pré-marca
  /// as assinaturas já configuradas no template.
  Future<void> _carregarSignatarios(
    TemplateRelatorio template,
    int? escopoId,
  ) async {
    if (escopoId == null) return;

    final alcance = _hierarquia.descendentesDe(template.nivel, escopoId);
    _signatariosPrograma = await _equipeProgramaRepositorio
        .listarEquipeDeProgramas(alcance.programaIds);
    _signatariosProjeto = await _equipeProjetoRepositorio.listarEquipeDeProjetos(
      alcance.projetoIds,
    );

    final assinaturas = await _templatesRepositorio.listarAssinaturasTemplate(
      template.id!,
    );
    final idsPrograma = _signatariosPrograma.map((m) => m.id).toSet();
    final idsProjeto = _signatariosProjeto.map((m) => m.id).toSet();
    _equipeProgramaSelecionada = assinaturas
        .map((a) => a.equipeProgramaId)
        .whereType<int>()
        .where(idsPrograma.contains)
        .toSet();
    _equipeProjetoSelecionada = assinaturas
        .map((a) => a.equipeProjetoId)
        .whereType<int>()
        .where(idsProjeto.contains)
        .toSet();
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

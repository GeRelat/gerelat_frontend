import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplateFormViewModel extends BaseViewModel {
  final RepositorioEventos _eventosRepositorio;
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioEquipePrograma _equipeProgramaRepositorio;
  final RepositorioEquipeProjeto _equipeProjetoRepositorio;
  final RepositorioCatalogo _catalogo;

  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  NivelEscopo _nivel = NivelEscopo.projeto;
  int? _escopoId;
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;

  List<ClasseEvento> _classesDisponiveis = [];
  Set<int> _classesSelecionadas = {};
  Map<int, int> _vinculosCarregados = {};
  TemplateRelatorio? _template;

  List<MembroEquipePrograma> _membrosPrograma = [];
  List<MembroEquipeProjeto> _membrosProjeto = [];
  List<AssinaturaTemplate> _assinaturasCarregadas = [];
  Set<int> _equipeProgramaSelecionada = {};
  Set<int> _equipeProjetoSelecionada = {};

  // Guarda o id assim que `criarTemplate` responde com sucesso. Se uma etapa
  // seguinte de `salvar` (vínculo de classe/assinatura) falhar, o template já
  // existe no servidor; um novo clique em "Criar Template" deve continuar a
  // partir daqui (via `atualizarTemplate`), não criar um segundo registro.
  int? _idTemplateCriado;

  TemplateFormViewModel(RepositorioCatalogo repositorio)
    : _eventosRepositorio = repositorio,
      _templatesRepositorio = repositorio,
      _equipeProgramaRepositorio = repositorio,
      _equipeProjetoRepositorio = repositorio,
      _catalogo = repositorio;

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelEscopo get nivel => _nivel;
  int? get escopoId => _escopoId;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;

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

  List<OpcaoSelecao> get opcoesEscopo =>
      _hierarquia.opcoesDeEscopo(_nivel, clienteId: _clienteAtivoId);

  List<ClasseEvento> get classesDisponiveis =>
      List.unmodifiable(_classesDisponiveis);
  Set<int> get classesSelecionadas => Set.unmodifiable(_classesSelecionadas);
  TemplateRelatorio? get template => _template;

  List<MembroEquipePrograma> get membrosPrograma =>
      List.unmodifiable(_membrosPrograma);
  List<MembroEquipeProjeto> get membrosProjeto =>
      List.unmodifiable(_membrosProjeto);
  Set<int> get equipeProgramaSelecionada =>
      Set.unmodifiable(_equipeProgramaSelecionada);
  Set<int> get equipeProjetoSelecionada =>
      Set.unmodifiable(_equipeProjetoSelecionada);

  String nomeProjeto(int? projetoId) =>
      _hierarquia.nomeDe(NivelAplicacao.projeto, projetoId);

  String nomePrograma(int? programaId) =>
      _hierarquia.nomeDe(NivelAplicacao.programa, programaId);

  String nomeCliente(int? clienteId) =>
      _hierarquia.nomeDe(NivelAplicacao.cliente, clienteId);

  String nomeOrigemClasse(ClasseEvento classe) {
    if (classe.clienteId != null &&
        classe.programaId == null &&
        classe.projetoId == null) {
      return 'Cliente: ${nomeCliente(classe.clienteId)}';
    }
    if (classe.programaId != null && classe.projetoId == null) {
      return 'Programa: ${nomePrograma(classe.programaId)}';
    }
    if (classe.projetoId != null) {
      return 'Projeto: ${nomeProjeto(classe.projetoId)}';
    }
    return 'Geral';
  }

  Future<void> carregarOpcoes() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _catalogo,
        comEventos: false,
      );
      _ajustarSelecaoEscopo();
      final escopoId = _escopoId;
      if (escopoId != null) {
        await _carregarEscopo(_nivel, escopoId);
      }
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final mudou = _clienteAtivoId != clienteAtivoId || _usuarioAtual != usuarioAtual;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;

    _ajustarSelecaoEscopo();

    if (mudou && _escopoId != null) {
      _carregarEscopo(_nivel, _escopoId!);
    }
    notifyListeners();
  }

  void _ajustarSelecaoEscopo() {
    final permitidos = niveisPermitidos;
    if (permitidos.isNotEmpty && !permitidos.contains(_nivel)) {
      _nivel = permitidos.first;
    }
    final opcoes = opcoesEscopo;
    if (_escopoId != null && !opcoes.any((o) => o.id == _escopoId)) {
      _escopoId = opcoes.isNotEmpty ? opcoes.first.id : null;
    } else if (_escopoId == null && opcoes.isNotEmpty) {
      _escopoId = opcoes.first.id;
    }
  }

  /// Projetos e programas alcançados pelo escopo — em nível cliente ou
  /// programa, um template cobre todos os descendentes, então classes de
  /// evento e possíveis signatários vêm agregados de todos eles.
  ({int? clienteId, Set<int> programaIds, Set<int> projetoIds}) _descendentes(
    NivelEscopo nivel,
    int escopoId,
  ) {
    switch (nivel) {
      case NivelEscopo.projeto:
        final projeto = _hierarquia.projetoPorId(escopoId);
        final programa =
            projeto != null ? _hierarquia.programaPorId(projeto.programaId) : null;
        return (
          clienteId: programa?.clienteId,
          programaIds: {if (projeto?.programaId != null) projeto!.programaId!},
          projetoIds: {escopoId},
        );
      case NivelEscopo.programa:
        final programa = _hierarquia.programaPorId(escopoId);
        return (
          clienteId: programa?.clienteId,
          programaIds: {escopoId},
          projetoIds: _hierarquia.projetos
              .where((projeto) => projeto.programaId == escopoId)
              .map((projeto) => projeto.id)
              .whereType<int>()
              .toSet(),
        );
      case NivelEscopo.cliente:
        final programaIds = _hierarquia.programas
            .where((programa) => programa.clienteId == escopoId)
            .map((programa) => programa.id)
            .whereType<int>()
            .toSet();
        return (
          clienteId: escopoId,
          programaIds: programaIds,
          projetoIds: _hierarquia.projetos
              .where((projeto) => programaIds.contains(projeto.programaId))
              .map((projeto) => projeto.id)
              .whereType<int>()
              .toSet(),
        );
    }
  }

  Future<void> selecionarEscopo(NivelEscopo nivel, int? escopoId) async {
    _nivel = nivel;
    final opcoes = _hierarquia.opcoesDeEscopo(nivel, clienteId: _clienteAtivoId);
    if (escopoId != null) {
      _escopoId = escopoId;
    } else {
      _escopoId = opcoes.isNotEmpty ? opcoes.first.id : null;
    }
    if (_escopoId == null) {
      _limparEscopo();
      notifyListeners();
      return;
    }
    iniciarCarregamento();
    try {
      await _carregarEscopo(nivel, _escopoId!);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  void _limparEscopo() {
    _classesDisponiveis = [];
    _classesSelecionadas = {};
    _membrosPrograma = [];
    _membrosProjeto = [];
    _equipeProgramaSelecionada = {};
    _equipeProjetoSelecionada = {};
  }

  Future<void> _carregarEscopo(NivelEscopo nivel, int escopoId) async {
    final alcance = _descendentes(nivel, escopoId);

    _classesDisponiveis = await _eventosRepositorio.listarClassesEventoDetalhadas(
      escopo: nivel,
      escopoId: escopoId,
    );
    _membrosPrograma = await _equipeProgramaRepositorio.listarEquipeDeProgramas(
      alcance.programaIds,
    );
    _membrosProjeto = await _equipeProjetoRepositorio.listarEquipeDeProjetos(
      alcance.projetoIds,
    );

    // Trocar de escopo pode deixar para trás seleções que não existem mais
    // no novo alcance; descartá-las evita enviar vínculos inválidos no save.
    final idsClasses = _classesDisponiveis.map((c) => c.id).toSet();
    _classesSelecionadas = _classesSelecionadas
        .where(idsClasses.contains)
        .toSet();
    final idsPrograma = _membrosPrograma.map((m) => m.id).toSet();
    _equipeProgramaSelecionada = _equipeProgramaSelecionada
        .where(idsPrograma.contains)
        .toSet();
    final idsProjeto = _membrosProjeto.map((m) => m.id).toSet();
    _equipeProjetoSelecionada = _equipeProjetoSelecionada
        .where(idsProjeto.contains)
        .toSet();
  }

  void alternarClasse(int classeEventoId) {
    if (!_classesSelecionadas.remove(classeEventoId)) {
      _classesSelecionadas.add(classeEventoId);
    }
    notifyListeners();
  }

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

  Future<void> carregarEdicao(int templateId) async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _catalogo,
        comEventos: false,
      );
      final template = await _templatesRepositorio.obterTemplate(templateId);
      _template = template;
      _nivel = template.nivel;
      _escopoId = template.escopoId;

      final escopoId = _escopoId;
      if (escopoId != null) {
        await _carregarEscopo(_nivel, escopoId);
      }

      _vinculosCarregados = await _templatesRepositorio
          .listarVinculosClasseTemplate(templateId);
      _classesSelecionadas = _vinculosCarregados.keys.toSet();

      _assinaturasCarregadas = await _templatesRepositorio
          .listarAssinaturasTemplate(templateId);
      _equipeProgramaSelecionada = _assinaturasCarregadas
          .map((a) => a.equipeProgramaId)
          .whereType<int>()
          .toSet();
      _equipeProjetoSelecionada = _assinaturasCarregadas
          .map((a) => a.equipeProjetoId)
          .whereType<int>()
          .toSet();

      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  /// Cria/atualiza o template e retorna o id do template salvo (ou `null` em
  /// caso de erro). O `.docx` é opcional: se informado, é convertido em
  /// `modelo_json` para semear o editor; caso contrário, o template nasce com
  /// um documento vazio a ser preenchido no editor.
  Future<int?> salvar({
    int? templateId,
    required NivelEscopo escopo,
    required int escopoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  }) async {
    iniciarCarregamento();
    try {
      _log(
        'template salvar: templateId=$templateId escopo=${escopo.valorApi}:$escopoId nomeTemplate=$nomeTemplate arquivo=${arquivoBytes == null ? 'null' : '${arquivoBytes.length} bytes'} nomeArquivo=$nomeArquivo',
      );
      var idTemplate = templateId ?? _idTemplateCriado;
      if (idTemplate == null) {
        // O `.docx` é opcional: quando presente, vira o documento inicial do
        // editor; quando ausente, o template nasce vazio.
        Map<String, dynamic>? modeloJson;
        if (arquivoBytes != null && nomeArquivo != null) {
          modeloJson = await _templatesRepositorio.converterDocxParaModelo(
            arquivoBytes: arquivoBytes,
            nomeArquivo: nomeArquivo,
          );
        }
        idTemplate = await _templatesRepositorio.criarTemplateComModelo(
          escopo: escopo,
          escopoId: escopoId,
          nomeTemplate: nomeTemplate,
          modeloJson: modeloJson,
        );
        _log('template salvar: criado idTemplate=$idTemplate');
        _idTemplateCriado = idTemplate;
      } else {
        await _templatesRepositorio.atualizarTemplate(
          templateId: idTemplate,
          escopo: escopo,
          escopoId: escopoId,
          nomeTemplate: nomeTemplate,
          arquivoBytes: arquivoBytes,
          nomeArquivo: nomeArquivo,
        );
        // `idTemplate` aqui pode vir de uma edição normal ou de uma
        // tentativa anterior que criou o template mas falhou num passo
        // seguinte. Em ambos os casos, relê o que já está vinculado no
        // servidor antes de calcular o diff abaixo — sem isso, um reenvio
        // tentaria recriar um vínculo/assinatura que a tentativa anterior já
        // criou com sucesso, o que viola a constraint de unicidade no
        // backend e travaria o reenvio para sempre no mesmo erro.
        _vinculosCarregados = await _templatesRepositorio
            .listarVinculosClasseTemplate(idTemplate);
        _assinaturasCarregadas = await _templatesRepositorio
            .listarAssinaturasTemplate(idTemplate);
      }

      final classesAdicionadas = _classesSelecionadas.difference(
        _vinculosCarregados.keys.toSet(),
      );
      final classesRemovidas = _vinculosCarregados.keys.toSet().difference(
        _classesSelecionadas,
      );

      for (final classeId in classesAdicionadas) {
        _log(
          'template salvar: vinculando classe=$classeId ao template=$idTemplate',
        );
        await _templatesRepositorio.vincularTemplateClasse(
          templateId: idTemplate,
          classeEventoId: classeId,
        );
      }
      for (final classeId in classesRemovidas) {
        final vinculoId = _vinculosCarregados[classeId];
        if (vinculoId != null) {
          await _templatesRepositorio.desvincularTemplateClasse(vinculoId);
        }
      }

      await _salvarAssinaturas(idTemplate);

      _log('template salvar: finalizado com sucesso template=$idTemplate');

      finalizarCarregamento();
      return idTemplate;
    } catch (erro) {
      _log('template salvar: erro=$erro');
      definirErro(erro);
      return null;
    }
  }

  /// Log de depuração best-effort — nunca deve derrubar o fluxo do
  /// ViewModel, mesmo se o logger falhar.
  void _log(String mensagem) {
    try {
      developer.log(mensagem, name: 'TemplateFormViewModel');
    } catch (_) {}
  }

  Future<void> _salvarAssinaturas(int templateId) async {
    final assinaturaPorEquipePrograma = {
      for (final a in _assinaturasCarregadas)
        if (a.equipeProgramaId != null) a.equipeProgramaId!: a.id!,
    };
    final assinaturaPorEquipeProjeto = {
      for (final a in _assinaturasCarregadas)
        if (a.equipeProjetoId != null) a.equipeProjetoId!: a.id!,
    };

    final programaAdicionados = _equipeProgramaSelecionada.difference(
      assinaturaPorEquipePrograma.keys.toSet(),
    );
    final programaRemovidos = assinaturaPorEquipePrograma.keys
        .toSet()
        .difference(_equipeProgramaSelecionada);
    final projetoAdicionados = _equipeProjetoSelecionada.difference(
      assinaturaPorEquipeProjeto.keys.toSet(),
    );
    final projetoRemovidos = assinaturaPorEquipeProjeto.keys.toSet().difference(
      _equipeProjetoSelecionada,
    );

    for (final membroId in programaAdicionados) {
      await _templatesRepositorio.criarAssinaturaTemplate(
        templateId: templateId,
        equipeProgramaId: membroId,
      );
    }
    for (final membroId in projetoAdicionados) {
      await _templatesRepositorio.criarAssinaturaTemplate(
        templateId: templateId,
        equipeProjetoId: membroId,
      );
    }
    for (final membroId in programaRemovidos) {
      final assinaturaId = assinaturaPorEquipePrograma[membroId];
      if (assinaturaId != null) {
        await _templatesRepositorio.excluirAssinaturaTemplate(assinaturaId);
      }
    }
    for (final membroId in projetoRemovidos) {
      final assinaturaId = assinaturaPorEquipeProjeto[membroId];
      if (assinaturaId != null) {
        await _templatesRepositorio.excluirAssinaturaTemplate(assinaturaId);
      }
    }
  }
}

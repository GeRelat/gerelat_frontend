import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplateFormViewModel extends BaseViewModel {
  final RepositorioEventos _eventosRepositorio;
  final RepositorioTemplates _templatesRepositorio;
  final RepositorioProgramas _programasRepositorio;
  final RepositorioEquipePrograma _equipeProgramaRepositorio;
  final RepositorioEquipeProjeto _equipeProjetoRepositorio;

  List<OpcaoSelecao> _projetos = [];
  List<OpcaoSelecao> _classesDisponiveis = [];
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
      _programasRepositorio = repositorio,
      _equipeProgramaRepositorio = repositorio,
      _equipeProjetoRepositorio = repositorio;

  List<OpcaoSelecao> get projetos => List.unmodifiable(_projetos);
  List<OpcaoSelecao> get classesDisponiveis =>
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

  Future<void> carregarOpcoes() async {
    iniciarCarregamento();
    try {
      _projetos = await _eventosRepositorio.listarProjetos();
      try {
        developer.log(
          'template carregarOpcoes: projetos=${_projetos.length}',
          name: 'TemplateFormViewModel',
        );
        for (final projeto in _projetos) {
          developer.log(
            'template projeto opcoes id=${projeto.id} nome=${projeto.nome}',
            name: 'TemplateFormViewModel',
          );
        }
      } catch (_) {}
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> carregarClasses(int? projetoId) async {
    if (projetoId == null) {
      _classesDisponiveis = [];
      _classesSelecionadas = {};
      _membrosPrograma = [];
      _membrosProjeto = [];
      _equipeProgramaSelecionada = {};
      _equipeProjetoSelecionada = {};
      notifyListeners();
      return;
    }
    iniciarCarregamento();
    try {
      _classesDisponiveis = await _eventosRepositorio.listarClassesEvento(
        projetoId: projetoId,
      );
      final idsValidos = _classesDisponiveis.map((c) => c.id).toSet();
      _classesSelecionadas = _classesSelecionadas
          .where(idsValidos.contains)
          .toSet();
      await _carregarPossiveisSignatarios(projetoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> _carregarPossiveisSignatarios(int projetoId) async {
    _membrosProjeto = await _equipeProjetoRepositorio.listarEquipeProjeto(
      projetoId: projetoId,
    );
    final projeto = await _programasRepositorio.obterProjeto(projetoId);
    final programaId = projeto.programaId;
    _membrosPrograma = programaId == null
        ? []
        : await _equipeProgramaRepositorio.listarEquipePrograma(
            programaId: programaId,
          );

    final idsProgramaValidos = _membrosPrograma.map((m) => m.id).toSet();
    final idsProjetoValidos = _membrosProjeto.map((m) => m.id).toSet();
    _equipeProgramaSelecionada = _equipeProgramaSelecionada
        .where(idsProgramaValidos.contains)
        .toSet();
    _equipeProjetoSelecionada = _equipeProjetoSelecionada
        .where(idsProjetoValidos.contains)
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
      _template = await _templatesRepositorio.obterTemplate(templateId);
      _projetos = await _eventosRepositorio.listarProjetos();
      try {
        developer.log(
          'template carregarEdicao: templateId=$templateId projetos=${_projetos.length}',
          name: 'TemplateFormViewModel',
        );
        for (final projeto in _projetos) {
          developer.log(
            'template projeto edicao id=${projeto.id} nome=${projeto.nome}',
            name: 'TemplateFormViewModel',
          );
        }
      } catch (_) {}
      final projetoId = _template?.projetoId;
      _classesDisponiveis = projetoId == null
          ? []
          : await _eventosRepositorio.listarClassesEvento(projetoId: projetoId);
      _vinculosCarregados = await _templatesRepositorio
          .listarVinculosClasseTemplate(templateId);
      _classesSelecionadas = _vinculosCarregados.keys.toSet();

      if (projetoId != null) {
        await _carregarPossiveisSignatarios(projetoId);
      }
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
    required int projetoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  }) async {
    iniciarCarregamento();
    try {
      try {
        developer.log(
          'template salvar: templateId=$templateId projetoId=$projetoId nomeTemplate=$nomeTemplate arquivo=${arquivoBytes == null ? 'null' : '${arquivoBytes.length} bytes'} nomeArquivo=$nomeArquivo',
          name: 'TemplateFormViewModel',
        );
      } catch (_) {}
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
          projetoId: projetoId,
          nomeTemplate: nomeTemplate,
          modeloJson: modeloJson,
        );
        try {
          developer.log(
            'template salvar: criado idTemplate=$idTemplate',
            name: 'TemplateFormViewModel',
          );
        } catch (_) {}
        _idTemplateCriado = idTemplate;
      } else {
        await _templatesRepositorio.atualizarTemplate(
          templateId: idTemplate,
          projetoId: projetoId,
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
        try {
          developer.log(
            'template salvar: vinculando classe=$classeId ao template=$idTemplate',
            name: 'TemplateFormViewModel',
          );
        } catch (_) {}
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

      try {
        developer.log(
          'template salvar: finalizado com sucesso template=$idTemplate',
          name: 'TemplateFormViewModel',
        );
      } catch (_) {}

      finalizarCarregamento();
      return idTemplate;
    } catch (erro) {
      try {
        developer.log(
          'template salvar: erro=$erro',
          name: 'TemplateFormViewModel',
        );
      } catch (_) {}
      definirErro(erro);
      return null;
    }
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

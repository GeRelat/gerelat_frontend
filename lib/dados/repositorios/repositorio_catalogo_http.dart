import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RepositorioCatalogoHttp implements RepositorioCatalogo {
  final ServicoApiGerelat _api;

  RepositorioCatalogoHttp(this._api);

  @override
  Future<List<Programa>> listarProgramas() async {
    final programas = await _getLista('/programas/');
    final projetos = await _getLista('/projetos/');
    final eventos = await _getLista('/eventos/');

    final projetosPorPrograma = <int, int>{};
    final programaPorProjeto = <int, int>{};

    for (final projeto in projetos) {
      final idProjeto = _inteiro(projeto['id_projeto']);
      final idPrograma = _inteiro(projeto['programa']);
      if (idProjeto == null || idPrograma == null) continue;

      programaPorProjeto[idProjeto] = idPrograma;
      projetosPorPrograma[idPrograma] =
          (projetosPorPrograma[idPrograma] ?? 0) + 1;
    }

    final eventosPorPrograma = <int, int>{};
    for (final evento in eventos) {
      final idProjeto = _inteiro(evento['projeto']);
      final idPrograma = programaPorProjeto[idProjeto];
      if (idPrograma == null) continue;
      eventosPorPrograma[idPrograma] =
          (eventosPorPrograma[idPrograma] ?? 0) + 1;
    }

    return programas.map((programa) {
      final idPrograma = _inteiro(programa['id_programa']) ?? 0;
      return Programa(
        id: idPrograma,
        nome: _texto(programa['nome'], fallback: 'Programa sem nome'),
        descricao: _descricaoPrograma(programa),
        projetos: projetosPorPrograma[idPrograma] ?? 0,
        eventos: eventosPorPrograma[idPrograma] ?? 0,
        status: 'Ativo',
      );
    }).toList();
  }

  @override
  Future<List<Evento>> listarEventos() async {
    final eventos = await _getLista('/eventos/');
    final projetos = await _getLista('/projetos/');
    final programas = await _getLista('/programas/');

    final programaPorId = {
      for (final programa in programas)
        if (_inteiro(programa['id_programa']) != null)
          _inteiro(programa['id_programa'])!: _texto(programa['nome']),
    };

    final programaPorProjeto = <int, String>{};
    for (final projeto in projetos) {
      final idProjeto = _inteiro(projeto['id_projeto']);
      final idPrograma = _inteiro(projeto['programa']);
      if (idProjeto == null || idPrograma == null) continue;
      programaPorProjeto[idProjeto] =
          programaPorId[idPrograma] ?? 'Programa nao informado';
    }

    return eventos.map((evento) {
      final idProjeto = _inteiro(evento['projeto']);
      return Evento(
        id: _inteiro(evento['id_evento']),
        projetoId: idProjeto,
        classeEventoId: _inteiro(evento['classe_evento']),
        nome: _texto(evento['nome'], fallback: 'Evento sem nome'),
        programa: programaPorProjeto[idProjeto] ?? 'Programa nao informado',
        data: DateTime.tryParse(_texto(evento['data'])),
        status: 'Confirmado',
      );
    }).toList();
  }

  @override
  Future<List<Relatorio>> listarRelatorios() async {
    final relatorios = await _getLista('/relatorios/');
    final eventos = await _getLista('/eventos/');
    final templates = await _getLista('/templates/');

    final eventoPorId = {
      for (final evento in eventos)
        if (_inteiro(evento['id_evento']) != null)
          _inteiro(evento['id_evento'])!: _texto(evento['nome']),
    };

    final templatePorId = {
      for (final template in templates)
        if (_inteiro(template['id_template']) != null)
          _inteiro(template['id_template'])!: _texto(template['nome_template']),
    };

    return relatorios.map((relatorio) {
      final idRelatorio = _inteiro(relatorio['id_relatorio']) ?? 0;
      final idEvento = _inteiro(relatorio['evento']);
      final idTemplate = _inteiro(relatorio['template']);
      final nome = _texto(relatorio['nome']);

      return Relatorio(
        id: idRelatorio,
        eventoId: idEvento,
        templateId: idTemplate,
        titulo: nome.isEmpty ? 'Relatorio $idRelatorio' : nome,
        evento: eventoPorId[idEvento] ?? 'Evento nao informado',
        template: templatePorId[idTemplate] ?? 'Template nao informado',
        dataGeracao: _formatarDataTexto(_texto(relatorio['data_criacao'])),
        status: _texto(relatorio['status'], fallback: 'Pendente'),
      );
    }).toList();
  }

  @override
  Future<List<TemplateRelatorio>> listarTemplates() async {
    final templates = await _getLista('/templates/');

    return templates.map((template) {
      final arquivo = _texto(template['modelo_arquivo_base']);
      return TemplateRelatorio(
        id: _inteiro(template['id_template']),
        projetoId: _inteiro(template['projeto']),
        nome: _texto(template['nome_template'], fallback: 'Template sem nome'),
        descricao: arquivo.isEmpty
            ? 'Template disponivel para geracao de relatorios.'
            : 'Arquivo base: $arquivo',
        tipo: 'DOCX',
        status: 'Ativo',
      );
    }).toList();
  }

  @override
  Future<ResumoDashboard> obterResumoDashboard() async {
    final programas = await listarProgramas();
    final templates = await listarTemplates();
    final relatorios = await listarRelatorios();

    return ResumoDashboard(
      programas: programas.length,
      projetos: programas.fold(
        0,
        (total, programa) => total + programa.projetos,
      ),
      eventos: programas.fold(0, (total, programa) => total + programa.eventos),
      templates: templates.length,
      relatorios: relatorios.length,
    );
  }

  @override
  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
  }) async {
    await _api.criar(
      '/programas/',
      {
        'nome': nome,
        'lei_criacao': leiCriacao,
        'convenio_dados': convenioDados,
        'rodape': rodape,
        'logomarca': '',
      },
    );
  }

  @override
  Future<List<OpcaoSelecao>> listarProjetos() async {
    final projetos = await _getLista('/projetos/');
    return projetos
        .map(
          (projeto) => OpcaoSelecao(
            id: _inteiro(projeto['id_projeto']) ?? 0,
            nome: _texto(projeto['nome'], fallback: 'Projeto sem nome'),
          ),
        )
        .where((opcao) => opcao.id > 0)
        .toList();
  }

  @override
  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId}) async {
    final classes = await _getLista('/classes-evento/');
    return classes
        .where(
          (classe) =>
              projetoId == null || _inteiro(classe['projeto']) == projetoId,
        )
        .map(
          (classe) => OpcaoSelecao(
            id: _inteiro(classe['id_classe']) ?? 0,
            nome: _texto(
              classe['nome_classe'],
              fallback: 'Classe sem nome',
            ),
          ),
        )
        .where((opcao) => opcao.id > 0)
        .toList();
  }

  @override
  Future<void> criarEvento({
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    await _api.criar(
      '/eventos/',
      {
        'projeto': projetoId,
        'classe_evento': classeEventoId,
        'nome': nome,
        'data': _dataApi(data),
        'local': local,
        'endereco': endereco,
        'objetivo': objetivo,
      },
    );
  }

  @override
  Future<void> gerarRelatorio({
    required int templateId,
    int? eventoId,
  }) async {
    final dados = <String, dynamic>{'template': templateId};
    if (eventoId case final id?) dados['evento'] = id;
    await _api.criar(
      '/relatorios/gerar/',
      dados,
    );
  }

  Future<List<Map<String, dynamic>>> _getLista(String caminho) async {
    return _api.listar(caminho);
  }

  int? _inteiro(Object? valor) {
    if (valor is int) return valor;
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  String _texto(Object? valor, {String fallback = ''}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  String _descricaoPrograma(Map<String, dynamic> programa) {
    final lei = _texto(programa['lei_criacao']);
    final convenio = _texto(programa['convenio_dados']);
    final rodape = _texto(programa['rodape']);

    if (rodape.isNotEmpty) return rodape;
    if (lei.isNotEmpty && convenio.isNotEmpty) {
      return 'Lei de criacao: $lei. Convenio: $convenio.';
    }
    if (lei.isNotEmpty) return 'Lei de criacao: $lei.';
    if (convenio.isNotEmpty) return 'Convenio: $convenio.';
    return 'Programa cadastrado na API GeRelat.';
  }

  String _dataApi(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$ano-$mes-$dia';
  }

  String _formatarDataTexto(String valor) {
    if (valor.isEmpty) return 'Data não informada';
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}

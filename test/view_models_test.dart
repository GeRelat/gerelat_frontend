import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gerelat_frontend/aplicacao/view_models/cadastro_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/evento_form_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/login_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programa_form_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

void main() {
  group('autenticação', () {
    test('LoginViewModel informa sucesso', () async {
      final repositorio = _RepositorioAutenticacaoFake();
      final viewModel = LoginViewModel(repositorio);

      final sucesso = await viewModel.login(
        email: 'teste@gerelat.dev',
        senha: '12345678',
      );

      expect(sucesso, isTrue);
      expect(viewModel.carregando, isFalse);
      expect(repositorio.emailRecebido, 'teste@gerelat.dev');
    });

    test('CadastroViewModel propaga erro do repositório', () async {
      final repositorio = _RepositorioAutenticacaoFake(
        resultadoCadastro: const ResultadoLogin.erro('E-mail já utilizado.'),
      );
      final viewModel = CadastroViewModel(repositorio);

      final sucesso = await viewModel.cadastrar(
        nomeCompleto: 'Pessoa Teste',
        email: 'teste@gerelat.dev',
        senha: '12345678',
      );

      expect(sucesso, isFalse);
      expect(viewModel.mensagemErro, 'E-mail já utilizado.');
    });

    test('LoginViewModel propaga credenciais inválidas', () async {
      final repositorio = _RepositorioAutenticacaoFake(
        resultadoLogin: const ResultadoLogin.erro('Credenciais inválidas.'),
      );
      final viewModel = LoginViewModel(repositorio);

      final sucesso = await viewModel.login(
        email: 'teste@gerelat.dev',
        senha: 'senha-incorreta',
      );

      expect(sucesso, isFalse);
      expect(viewModel.mensagemErro, 'Credenciais inválidas.');
    });
  });

  group('formulários de domínio', () {
    test('ProgramaFormViewModel envia comando de criação', () async {
      final repositorio = _RepositorioCatalogoFake();
      final viewModel = ProgramaFormViewModel(repositorio, repositorio);

      final sucesso = await viewModel.salvar(
        nome: 'Programa Teste',
        leiCriacao: 'Lei 1',
        convenioDados: 'Convênio 1',
      );

      expect(sucesso, isTrue);
      expect(repositorio.programaCriado, 'Programa Teste');
    });

    test('EventoFormViewModel carrega opções e cria evento', () async {
      final repositorio = _RepositorioCatalogoFake();
      final viewModel = EventoFormViewModel(repositorio);

      await viewModel.carregarOpcoes();
      final sucesso = await viewModel.salvar(
        projetoId: 1,
        classeEventoId: 2,
        nome: 'Evento Teste',
        data: DateTime(2026, 6, 21),
      );

      expect(viewModel.projetos, hasLength(1));
      expect(viewModel.classes, hasLength(1));
      expect(sucesso, isTrue);
      expect(repositorio.eventoCriado, 'Evento Teste');
    });

    test('GerarRelatorioViewModel usa IDs selecionados', () async {
      final repositorio = _RepositorioCatalogoFake();
      final viewModel = GerarRelatorioViewModel(repositorio);

      await viewModel.carregar();
      final documento = await viewModel.obterDocumentoPreview(
        templateId: 4,
        eventoId: 3,
      );

      expect(viewModel.templates, hasLength(1));
      expect(viewModel.eventos, hasLength(1));
      expect(documento, isNotNull);
      expect(repositorio.previsualizacaoRecebida, (template: 4, evento: 3));
    });
  });
}

class _RepositorioAutenticacaoFake implements RepositorioAutenticacao {
  final ResultadoLogin resultadoLogin;
  final ResultadoLogin resultadoCadastro;
  String? emailRecebido;

  _RepositorioAutenticacaoFake({
    this.resultadoLogin = const ResultadoLogin.sucesso(),
    this.resultadoCadastro = const ResultadoLogin.sucesso(),
  });

  @override
  bool get estaAutenticado => false;

  @override
  Future<void> inicializar() async {}

  @override
  Future<Usuario?> obterUsuarioAtual() async => null;

  @override
  Future<ResultadoLogin> login({
    required String email,
    required String senha,
  }) async {
    emailRecebido = email;
    return resultadoLogin;
  }

  @override
  Future<ResultadoLogin> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async => resultadoCadastro;

  @override
  Future<ResultadoLogin> solicitarRecuperacaoSenha({
    required String email,
  }) async => const ResultadoLogin.sucesso();

  @override
  Future<ResultadoLogin> confirmarRecuperacaoSenha({
    required String uid,
    required String token,
    required String novaSenha,
  }) async => const ResultadoLogin.sucesso();

  @override
  Future<ResultadoLogin> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async => const ResultadoLogin.sucesso();

  @override
  Future<void> sair() async {}
}

class _RepositorioCatalogoFake implements RepositorioCatalogo {
  String? programaCriado;
  String? projetoCriado;
  String? eventoCriado;
  String? templateCriado;
  ({int template, int? evento})? relatorioGerado;
  ({int template, int? evento})? previsualizacaoRecebida;

  @override
  Future<List<Cliente>> listarClientes() async => const [];

  @override
  Future<List<OpcaoSelecao>> listarClientesSelecao() async => const [];

  @override
  Future<Cliente> obterCliente(int clienteId) async =>
      const Cliente(nome: 'Cliente');

  @override
  Future<void> criarCliente({
    required String nome,
    String cnpj = '',
    String nomeContato = '',
    String emailContato = '',
    String foneContato = '',
    String numeroContrato = '',
    required DateTime dataTerminoContrato,
  }) async {}

  @override
  Future<void> atualizarCliente({
    required int clienteId,
    required String nome,
    String cnpj = '',
    String nomeContato = '',
    String emailContato = '',
    String foneContato = '',
    String numeroContrato = '',
    required DateTime dataTerminoContrato,
  }) async {}

  @override
  Future<void> excluirCliente(int clienteId) async {}

  @override
  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  }) async {
    programaCriado = nome;
  }

  @override
  Future<Programa> obterPrograma(int programaId) async => const Programa(
    id: 1,
    nome: 'Programa',
    descricao: 'Descrição',
    projetos: 0,
    eventos: 0,
    status: 'Ativo',
  );

  @override
  Future<void> atualizarPrograma({
    required int programaId,
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  }) async {
    programaCriado = nome;
  }

  @override
  Future<void> excluirPrograma(int programaId) async {}

  @override
  Future<List<OpcaoSelecao>> listarProgramasSelecao() async => const [
    OpcaoSelecao(id: 1, nome: 'Programa'),
  ];

  @override
  Future<List<MembroEquipePrograma>> listarEquipePrograma({
    required int programaId,
  }) async => const [];

  @override
  Future<void> criarMembroEquipe({
    required int programaId,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> atualizarMembroEquipe({
    required int membroId,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> excluirMembroEquipe(int membroId) async {}

  @override
  Future<List<MembroEquipeProjeto>> listarEquipeProjeto({
    required int projetoId,
  }) async => const [];

  @override
  Future<void> criarMembroEquipeProjeto({
    required int projetoId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> atualizarMembroEquipeProjeto({
    required int membroId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  }) async {}

  @override
  Future<void> excluirMembroEquipeProjeto(int membroId) async {}

  @override
  Future<List<ProjetoCampo>> listarCamposProjeto({
    required int projetoId,
  }) async => const [];

  @override
  Future<void> criarCampoProjeto({
    required int projetoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {}

  @override
  Future<void> atualizarCampoProjeto({
    required int campoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {}

  @override
  Future<void> excluirCampoProjeto(int campoId) async {}

  @override
  Future<int> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    String descricao = '',
  }) async => 1;

  @override
  Future<List<Asset>> listarAssets() async => const [];

  @override
  Future<Asset> obterAsset(int assetId) async => const Asset();

  @override
  Future<void> atualizarAsset({
    required int assetId,
    required String descricao,
  }) async {}

  @override
  Future<void> excluirAsset(int assetId) async {}

  @override
  Future<void> criarProjeto({
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {
    projetoCriado = nome;
  }

  @override
  Future<List<Projeto>> listarProjetosDetalhados({int? programaId}) async =>
      const [];

  @override
  Future<Projeto> obterProjeto(int projetoId) async =>
      const Projeto(nome: 'Projeto');

  @override
  Future<void> atualizarProjeto({
    required int projetoId,
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  }) async {
    projetoCriado = nome;
  }

  @override
  Future<void> excluirProjeto(int projetoId) async {}

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
    eventoCriado = nome;
  }

  @override
  Future<Evento> obterEvento(int eventoId) async => Evento(
    id: eventoId,
    projetoId: 1,
    classeEventoId: 2,
    nome: 'Evento',
    programa: 'Programa',
    data: DateTime(2026, 6, 21),
    status: 'Confirmado',
  );

  @override
  Future<int> criarClasseEvento({
    required int projetoId,
    required String nomeClasse,
  }) async => 2;

  @override
  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({
    required int projetoId,
  }) async => const [];

  @override
  Future<void> atualizarClasseEvento({
    required int classeId,
    required String nomeClasse,
  }) async {}

  @override
  Future<void> excluirClasseEvento(int classeId) async {}

  @override
  Future<Uint8List> baixarRelatorio(int relatorioId) async => Uint8List(0);

  @override
  Future<void> atualizarRelatorio({
    required int relatorioId,
    required String nome,
  }) async {}

  @override
  Future<void> excluirRelatorio(int relatorioId) async {}

  @override
  Future<Map<int, int>> listarVinculosClasseTemplate(int templateId) async =>
      const {};

  @override
  Future<void> vincularTemplateClasse({
    required int templateId,
    required int classeEventoId,
  }) async {}

  @override
  Future<void> desvincularTemplateClasse(int vinculoId) async {}

  @override
  Future<void> excluirTemplate(int templateId) async {}

  @override
  Future<int> criarTemplateComModelo({
    required int projetoId,
    required String nomeTemplate,
    Map<String, dynamic>? modeloJson,
  }) async {
    templateCriado = nomeTemplate;
    return 4;
  }

  @override
  Future<Map<String, dynamic>> converterDocxParaModelo({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async => const {'type': 'doc', 'content': <Map<String, dynamic>>[]};

  @override
  Future<Map<String, dynamic>> obterModeloTemplate(int templateId) async =>
      const {'type': 'doc', 'content': <Map<String, dynamic>>[]};

  @override
  Future<void> salvarModeloTemplate({
    required int templateId,
    required Map<String, dynamic> modeloJson,
  }) async {}

  @override
  Future<int> gerarRelatorioComDocumento({
    required int templateId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    String? nome,
  }) async {
    relatorioGerado = (template: templateId, evento: eventoId);
    return 1;
  }

  @override
  Future<List<AssinaturaTemplate>> listarAssinaturasTemplate(
    int templateId,
  ) async => const [];

  @override
  Future<void> criarAssinaturaTemplate({
    required int templateId,
    int? equipeProgramaId,
    int? equipeProjetoId,
  }) async {}

  @override
  Future<void> excluirAssinaturaTemplate(int assinaturaId) async {}

  @override
  Future<Uint8List> baixarArquivoTemplate(int templateId) async => Uint8List(0);

  @override
  Future<Map<String, dynamic>> previsualizarTemplate({
    required int templateId,
    int? eventoId,
  }) async {
    previsualizacaoRecebida = (template: templateId, evento: eventoId);
    return const {'type': 'doc', 'content': <Map<String, dynamic>>[]};
  }

  @override
  Future<TemplateRelatorio> obterTemplate(int templateId) async =>
      const TemplateRelatorio(
        id: 4,
        projetoId: 1,
        nome: 'Template',
        descricao: 'Descrição',
        tipo: 'DOCX',
        status: 'Ativo',
      );

  @override
  Future<void> atualizarTemplate({
    required int templateId,
    required int projetoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  }) async {
    templateCriado = nomeTemplate;
  }

  @override
  Future<List<OpcaoSelecao>> listarProjetos() async => const [
    OpcaoSelecao(id: 1, nome: 'Projeto'),
  ];

  @override
  Future<List<OpcaoSelecao>> listarClassesEvento({int? projetoId}) async =>
      const [OpcaoSelecao(id: 2, nome: 'Oficina')];

  @override
  Future<List<Evento>> listarEventos() async => [
    Evento(
      id: 3,
      nome: 'Evento',
      programa: 'Programa',
      data: DateTime(2026, 6, 21),
      status: 'Confirmado',
    ),
  ];

  @override
  Future<List<TemplateRelatorio>> listarTemplates() async => const [
    TemplateRelatorio(
      id: 4,
      nome: 'Template',
      descricao: 'Descrição',
      tipo: 'DOCX',
      status: 'Ativo',
    ),
  ];

  @override
  Future<List<Programa>> listarProgramas() async => const [];

  @override
  Future<void> atualizarEvento({
    required int eventoId,
    required int projetoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    eventoCriado = nome;
  }

  @override
  Future<void> excluirEvento(int eventoId) async {}

  @override
  Future<List<Relatorio>> listarRelatorios() async => const [];

  @override
  Future<ResumoDashboard> obterResumoDashboard() async => const ResumoDashboard(
    programas: 0,
    projetos: 0,
    eventos: 0,
    templates: 0,
    relatorios: 0,
  );
}

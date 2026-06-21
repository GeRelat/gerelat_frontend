import 'package:flutter_test/flutter_test.dart';
import 'package:gerelat_frontend/aplicacao/view_models/cadastro_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/evento_form_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/login_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programa_form_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
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
      final viewModel = ProgramaFormViewModel(repositorio);

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
      final sucesso = await viewModel.gerar(templateId: 4, eventoId: 3);

      expect(sucesso, isTrue);
      expect(repositorio.relatorioGerado, (template: 4, evento: 3));
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
  Future<void> sair() async {}
}

class _RepositorioCatalogoFake implements RepositorioCatalogo {
  String? programaCriado;
  String? eventoCriado;
  ({int template, int? evento})? relatorioGerado;

  @override
  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
  }) async {
    programaCriado = nome;
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
    eventoCriado = nome;
  }

  @override
  Future<void> gerarRelatorio({
    required int templateId,
    int? eventoId,
  }) async {
    relatorioGerado = (template: templateId, evento: eventoId);
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
  Future<List<Relatorio>> listarRelatorios() async => const [];

  @override
  Future<ResumoDashboard> obterResumoDashboard() async =>
      const ResumoDashboard(
        programas: 0,
        projetos: 0,
        eventos: 0,
        templates: 0,
        relatorios: 0,
      );
}

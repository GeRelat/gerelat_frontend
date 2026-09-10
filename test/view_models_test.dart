import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gerelat_frontend/aplicacao/view_models/cadastro_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/campo_definicao_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/campo_valor_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/evento_form_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/login_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/programa_form_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/templates_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/agendamento_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/solicitacao_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_valor.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/utils/gaps_prosemirror.dart';

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
        clienteId: 1,
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

    test('GerarRelatorioViewModel envia a cadeia de escopo do template', () async {
      final repositorio = _RepositorioCatalogoFake();
      final viewModel = GerarRelatorioViewModel(repositorio);

      await viewModel.carregar();
      viewModel.selecionarPrograma(10);
      viewModel.selecionarProjeto(1);
      await viewModel.selecionarTemplate(4);
      final documento = await viewModel.obterDocumentoPreview();

      expect(viewModel.templates, hasLength(1));
      expect(documento, isNotNull);
      // O template é de projeto: cliente e programa saem resolvidos da
      // hierarquia, sem o usuário escolher nada.
      expect(repositorio.previsualizacaoRecebida, (
        template: 4,
        cliente: 100,
        programa: 10,
        projeto: 1,
        evento: null,
      ));
    });
  });

  group('escopo exigido para gerar relatório', () {
    Map<String, dynamic> docComVariavel(String tipo, String ref) => {
      'type': 'doc',
      'content': [
        {
          'type': 'paragraph',
          'content': [
            {
              'type': tipo,
              'attrs': {'ref': ref},
            },
          ],
        },
      ],
    };

    test('variável de nível evento passa a exigir um evento', () async {
      final repositorio = _RepositorioCatalogoFake(
        modeloTemplate: docComVariavel('var_text', 'objetivo'),
        variaveisDisponiveis: const [
          VariavelDisponivel(
            referencia: 'objetivo',
            descricao: 'Objetivo',
            tipo: TipoCampo.texto,
            nivelAplicacao: NivelAplicacao.evento,
            origem: OrigemVariavel.customizado,
          ),
        ],
      );
      final viewModel = GerarRelatorioViewModel(repositorio);

      await viewModel.carregar();
      viewModel.selecionarPrograma(10);
      viewModel.selecionarProjeto(1);
      await viewModel.selecionarTemplate(4);

      expect(viewModel.nivelExigido, NivelAplicacao.evento);
      expect(viewModel.niveisASelecionar, [NivelAplicacao.evento]);
      expect(viewModel.escopoCompleto, isFalse);

      viewModel.definirEscopo(NivelAplicacao.evento, 3);

      expect(viewModel.escopoCompleto, isTrue);
      expect(viewModel.projetoId, 1);
      expect(viewModel.programaId, 10);
      expect(viewModel.clienteId, 100);
    });

    test('referência sem definição vira aviso de variável não contemplada', () async {
      final repositorio = _RepositorioCatalogoFake(
        modeloTemplate: docComVariavel('var_text', 'nao_existe'),
      );
      final viewModel = GerarRelatorioViewModel(repositorio);

      await viewModel.carregar();
      viewModel.selecionarPrograma(10);
      viewModel.selecionarProjeto(1);
      await viewModel.selecionarTemplate(4);

      expect(viewModel.refsNaoContempladas, ['nao_existe']);
      // Sem nível conhecido, nada mais precisa ser escolhido — o backend
      // também ignora refs desconhecidas em `scan_required_nivel`.
      expect(viewModel.nivelExigido, isNull);
      expect(viewModel.escopoCompleto, isTrue);
    });

    test('campo de sistema resolve o nível pelo próprio nome', () async {
      final repositorio = _RepositorioCatalogoFake(
        modeloTemplate: docComVariavel('var_text', 'sistema.evento.local'),
      );
      final viewModel = GerarRelatorioViewModel(repositorio);

      await viewModel.carregar();
      viewModel.selecionarPrograma(10);
      viewModel.selecionarProjeto(1);
      await viewModel.selecionarTemplate(4);

      expect(viewModel.nivelExigido, NivelAplicacao.evento);
      expect(viewModel.refsNaoContempladas, isEmpty);
    });

    test(
      'dependência escondida num texto rico escala o nível exigido para o '
      'que o backend calcular',
      () async {
        // O template só cita diretamente "texto_padrao" (nível Programa) —
        // sem a resposta do backend, o cliente concluiria erroneamente que
        // nenhum nível abaixo de Programa é exigido.
        final repositorio = _RepositorioCatalogoFake(
          modeloTemplate: docComVariavel('var_richtext', 'texto_padrao'),
          variaveisDisponiveis: const [
            VariavelDisponivel(
              referencia: 'texto_padrao',
              descricao: 'Parágrafo padrão',
              tipo: TipoCampo.textoRico,
              nivelAplicacao: NivelAplicacao.programa,
              origem: OrigemVariavel.customizado,
            ),
          ],
          nivelExigidoBackend: NivelAplicacao.projeto,
        );
        final viewModel = GerarRelatorioViewModel(repositorio);

        await viewModel.carregar();
        viewModel.selecionarPrograma(10);
        viewModel.selecionarProjeto(1);
        await viewModel.selecionarTemplate(4);

        expect(viewModel.nivelExigido, NivelAplicacao.projeto);
        expect(repositorio.nivelExigidoRecebido?.template, 4);
      },
    );

    test('bloco manual não conta como variável não contemplada', () async {
      final repositorio = _RepositorioCatalogoFake(
        modeloTemplate: const {
          'type': 'doc',
          'content': [
            {
              'type': 'custom_text',
              'attrs': {'label': 'Observações da equipe'},
              'content': <Map<String, dynamic>>[],
            },
          ],
        },
      );
      final viewModel = GerarRelatorioViewModel(repositorio);

      await viewModel.carregar();
      viewModel.selecionarPrograma(10);
      viewModel.selecionarProjeto(1);
      await viewModel.selecionarTemplate(4);

      expect(viewModel.refsNaoContempladas, isEmpty);
      expect(viewModel.blocosManuais, ['Observações da equipe']);
      expect(viewModel.nivelExigido, isNull);
    });
  });

  group('variáveis customizáveis', () {
    const definicaoDeEvento = CampoDefinicao(
      id: 7,
      programaId: 10,
      nivelAplicacao: NivelAplicacao.evento,
      referencia: 'objetivo',
      descricao: 'Objetivo',
      tipo: TipoCampo.texto,
      obrigatorio: true,
    );

    test('CampoValorViewModel lista as definições herdadas dos ancestrais', () async {
      final repositorio = _RepositorioCatalogoFake(
        definicoes: const [
          definicaoDeEvento,
          // Mesmo escopo, mas de nível projeto: não se aplica a um evento.
          CampoDefinicao(
            id: 8,
            programaId: 10,
            nivelAplicacao: NivelAplicacao.projeto,
            referencia: 'parceira_local',
            descricao: 'Parceira local',
            tipo: TipoCampo.texto,
          ),
        ],
      );
      final viewModel = CampoValorViewModel(repositorio);

      await viewModel.carregarHierarquia();
      await viewModel.selecionarAlvo(NivelAplicacao.evento, 3);

      expect(viewModel.variaveis, hasLength(1));
      final variavel = viewModel.variaveis.single;
      expect(variavel.definicao.referencia, 'objetivo');
      // Definida no programa ancestral, não no próprio evento.
      expect(variavel.origem, 'Programa Programa');
      expect(variavel.preenchida, isFalse);
      expect(viewModel.totalPendentes, 1);
    });

    test('CampoValorViewModel casa o valor já gravado com sua definição', () async {
      final repositorio = _RepositorioCatalogoFake(
        definicoes: const [definicaoDeEvento],
        valores: const [
          CampoValor(
            id: 55,
            definicaoId: 7,
            eventoId: 3,
            valor: {'type': 'doc', 'content': <Map<String, dynamic>>[]},
          ),
        ],
      );
      final viewModel = CampoValorViewModel(repositorio);

      await viewModel.carregarHierarquia();
      await viewModel.selecionarAlvo(NivelAplicacao.evento, 3);

      expect(viewModel.variaveis.single.valor?.id, 55);
      expect(viewModel.totalPendentes, 0);

      await viewModel.salvarValor(
        variavel: viewModel.variaveis.single,
        valor: const {'type': 'doc', 'content': <Map<String, dynamic>>[]},
      );

      expect(repositorio.valorSalvo, (
        definicao: 7,
        alvo: NivelAplicacao.evento,
        alvoId: 3,
      ));
    });

    test('CampoDefinicaoViewModel rejeita prefixo reservado e duplicata', () async {
      final repositorio = _RepositorioCatalogoFake(
        definicoes: const [definicaoDeEvento],
      );
      final viewModel = CampoDefinicaoViewModel(repositorio);

      await viewModel.carregarHierarquia();
      await viewModel.selecionarEscopo(NivelEscopo.programa, 10);

      expect(viewModel.validarReferencia('sistema.evento.local'), isNotNull);
      expect(viewModel.validarReferencia('objetivo'), isNotNull);
      // Editar a própria definição não pode acusar duplicata contra si mesma.
      expect(
        viewModel.validarReferencia('objetivo', ignorandoDefinicaoId: 7),
        isNull,
      );
      expect(viewModel.validarReferencia('local_evento'), isNull);
    });

    test('escopo de programa só permite níveis iguais ou mais profundos', () async {
      final repositorio = _RepositorioCatalogoFake();
      final viewModel = CampoDefinicaoViewModel(repositorio);

      await viewModel.carregarHierarquia();
      await viewModel.selecionarEscopo(NivelEscopo.programa, 10);

      expect(viewModel.niveisAplicacaoPermitidos, [
        NivelAplicacao.programa,
        NivelAplicacao.projeto,
        NivelAplicacao.evento,
      ]);

      await viewModel.salvar(
        nivelAplicacao: NivelAplicacao.projeto,
        referencia: 'local_evento',
        descricao: 'Local do evento',
        tipo: TipoCampo.texto,
        obrigatorio: false,
      );

      expect(repositorio.definicaoCriada, (
        escopo: NivelEscopo.programa,
        escopoId: 10,
        ref: 'local_evento',
      ));
    });
  });

  group('scanner de gaps ProseMirror', () {
    const documento = {
      'type': 'doc',
      'content': [
        {
          'type': 'paragraph',
          'content': [
            {
              'type': 'var_text',
              'attrs': {'ref': 'objetivo'},
            },
          ],
        },
        {
          'type': 'var_image',
          'attrs': {'ref': 'foto_capa'},
        },
        {
          'type': 'custom_text',
          'attrs': {'label': 'Bloco livre'},
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {
                  'type': 'variable',
                  'attrs': {'ref': 'sistema.projeto.sigla'},
                },
              ],
            },
          ],
        },
      ],
    };

    test('coleta refs de variáveis, inclusive as aninhadas', () {
      expect(extrairRefsDeVariaveis(documento), {
        'objetivo',
        'foto_capa',
        'sistema.projeto.sigla',
      });
    });

    test('separa os rótulos dos blocos manuais das variáveis', () {
      expect(extrairLabelsDeBlocosManuais(documento), ['Bloco livre']);
      expect(
        extrairRefsDeVariaveis(documento),
        isNot(contains('Bloco livre')),
      );
    });

    test('nível exigido é o mais profundo entre as refs conhecidas', () {
      final nivel = nivelExigidoPorRefs(const [
        'objetivo',
        'sistema.cliente.nome',
        'desconhecida',
      ], const {'objetivo': NivelAplicacao.projeto});

      expect(nivel, NivelAplicacao.projeto);
    });

    test('sem refs conhecidas, nenhum nível é exigido', () {
      expect(nivelExigidoPorRefs(const ['desconhecida'], const {}), isNull);
    });
  });

  group('TemplatesViewModel - permissões e escopo', () {
    test('membro de projeto pode ver templates de programa e projeto em niveisPermitidos', () {
      final catalogo = _RepositorioCatalogoFake();
      final viewModel = TemplatesViewModel(catalogo);
      final usuario = Usuario(
        id: 10,
        nomeCompleto: 'Membro Projeto',
        email: 'membro@proj.com',
        contextosAcesso: const ContextosAcesso(
          projetos: [
            {'id': 1, 'nome': 'Projeto 1', 'cliente_id': 1}
          ],
        ),
      );

      viewModel.definirContexto(1, usuario);
      expect(viewModel.niveisPermitidos, [NivelEscopo.programa, NivelEscopo.projeto]);
    });

    test('membro de projeto pode editar templates de seu projeto mas não de programa', () {
      final catalogo = _RepositorioCatalogoFake();
      final viewModel = TemplatesViewModel(catalogo);
      final usuario = Usuario(
        id: 10,
        nomeCompleto: 'Membro Projeto',
        email: 'membro@proj.com',
        contextosAcesso: const ContextosAcesso(
          projetos: [
            {'id': 1, 'nome': 'Projeto 1', 'cliente_id': 1}
          ],
        ),
      );

      viewModel.definirContexto(1, usuario);

      const templatePrograma = TemplateRelatorio(
        id: 1,
        nivel: NivelEscopo.programa,
        programaId: 1,
        nome: 'Template Programa',
        descricao: '',
        tipo: 'DOCX',
        status: 'Ativo',
      );

      const templateProjeto = TemplateRelatorio(
        id: 2,
        nivel: NivelEscopo.projeto,
        projetoId: 1,
        nome: 'Template Projeto',
        descricao: '',
        tipo: 'DOCX',
        status: 'Ativo',
      );

      expect(viewModel.podeEditarTemplate(templatePrograma), isFalse);
      expect(viewModel.podeExcluirTemplate(templatePrograma), isFalse);
      expect(viewModel.podeEditarTemplate(templateProjeto), isTrue);
      expect(viewModel.podeExcluirTemplate(templateProjeto), isTrue);
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
    int? clienteId,
  }) async => resultadoCadastro;

  @override
  Future<List<OpcaoSelecao>> listarClientesPublicos() async => const [];

  @override
  Future<ResultadoLogin> solicitarAcessoCliente({
    required int clienteId,
    int? programaId,
    int? projetoId,
    String? papelSolicitado,
  }) async => const ResultadoLogin.sucesso();

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
  /// Documento e variáveis usados pelo `GerarRelatorioViewModel` — deixados
  /// configuráveis para exercitar o cálculo de nível exigido e de referências
  /// não contempladas.
  final Map<String, dynamic> modeloTemplate;
  final List<VariavelDisponivel> variaveisDisponiveis;
  final List<CampoDefinicao> definicoes;
  final List<CampoValor> valores;

  /// Resposta simulada de `GET /templates/<id>/nivel-exigido/` — representa o
  /// que o backend enxergaria ao descer dentro do valor de variáveis de texto
  /// rico, que o cliente não tem como calcular sozinho. `null` por padrão
  /// (sem dependência transitiva), para não afetar os testes que não a
  /// configuram explicitamente.
  final NivelAplicacao? nivelExigidoBackend;

  _RepositorioCatalogoFake({
    this.modeloTemplate = const {
      'type': 'doc',
      'content': <Map<String, dynamic>>[],
    },
    this.variaveisDisponiveis = const [],
    this.definicoes = const [],
    this.valores = const [],
    this.nivelExigidoBackend,
  });

  String? programaCriado;
  String? projetoCriado;
  String? eventoCriado;
  String? templateCriado;
  ({NivelEscopo escopo, int escopoId, String ref})? definicaoCriada;
  ({int definicao, NivelAplicacao alvo, int alvoId})? valorSalvo;
  ({int template, int? evento})? relatorioGerado;
  ({int template, int? cliente, int? programa, int? projeto, int? evento})?
  previsualizacaoRecebida;
  ({int template, int? cliente, int? programa, int? projeto})?
  nivelExigidoRecebido;

  // Hierarquia mínima e consistente: Cliente 100 > Programa 10 > Projeto 1 >
  // Evento 3. É o que permite aos view models resolverem a cadeia de escopo.
  @override
  Future<List<Cliente>> listarClientes() async => const [
    Cliente(id: 100, nome: 'Cliente'),
  ];

  @override
  Future<List<OpcaoSelecao>> listarClientesSelecao({int? clienteId}) async => const [];

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
    String logomarca = '',
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
    String logomarca = '',
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
  Future<List<OpcaoSelecao>> listarProgramasSelecao({int? clienteId}) async => const [
    OpcaoSelecao(id: 1, nome: 'Programa'),
  ];

  @override
  Future<List<MembroEquipePrograma>> listarEquipePrograma({
    required int programaId,
  }) async => const [];

  @override
  Future<List<MembroEquipePrograma>> listarEquipeDeProgramas(
    Set<int> programaIds,
  ) async => const [];

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
  Future<List<MembroEquipeProjeto>> listarEquipeDeProjetos(
    Set<int> projetoIds,
  ) async => const [];

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
  Future<List<CampoDefinicao>> listarDefinicoes({
    NivelEscopo? escopo,
    int? escopoId,
  }) async => definicoes;

  @override
  Future<List<CampoDefinicao>> listarDefinicoesVisiveis({
    int? clienteId,
    int? programaId,
    int? projetoId,
  }) async => definicoes;

  @override
  Future<void> criarDefinicao({
    required NivelEscopo escopo,
    required int escopoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  }) async {
    definicaoCriada = (escopo: escopo, escopoId: escopoId, ref: referencia);
  }

  @override
  Future<void> atualizarDefinicao({
    required int definicaoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  }) async {}

  @override
  Future<void> excluirDefinicao(int definicaoId) async {}

  @override
  Future<List<CampoValor>> listarValores({
    required NivelAplicacao alvo,
    required int alvoId,
  }) async => valores;

  @override
  Future<void> salvarValor({
    int? valorId,
    required int definicaoId,
    required NivelAplicacao alvo,
    required int alvoId,
    required Map<String, dynamic> valor,
  }) async {
    valorSalvo = (definicao: definicaoId, alvo: alvo, alvoId: alvoId);
  }

  @override
  Future<void> excluirValor(int valorId) async {}

  @override
  Future<Asset> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    NivelEscopo? escopo,
    int? escopoId,
    String descricao = '',
  }) async => const Asset(id: 1, urlArquivo: '/assets/test.png');

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
      const [Projeto(id: 1, programaId: 10, nome: 'Projeto')];

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
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
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
  );

  @override
  Future<int> criarClasseEvento({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required String nomeClasse,
  }) async => 2;

  @override
  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
  }) async => const [];

  @override
  Future<List<ClasseEvento>> listarClassesEventoDeProjetos(
    Set<int> projetoIds,
  ) async => const [];

  @override
  Future<List<ClasseEvento>> listarClassesEventoDoAlcance({
    int? clienteId,
    Set<int> programaIds = const {},
    Set<int> projetoIds = const {},
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
    String? nome,
    Map<String, dynamic>? documentoJson,
  }) async {}

  @override
  Future<void> excluirRelatorio(int relatorioId) async {}

  @override
  Future<void> agendarRelatorio({
    required String nome,
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    required String tipoAgendamento,
    DateTime? dataHoraExecucao,
    String? recorrencia,
    String? horarioExecucao,
    int? diaSemana,
    int? diaMes,
    bool ativo = true,
  }) async {}

  @override
  Future<List<AgendamentoRelatorio>> listarAgendamentos({
    int? clienteId,
  }) async =>
      const [];

  @override
  Future<void> alterarStatusAgendamento({
    required int agendamentoId,
    required bool ativo,
  }) async {}

  @override
  Future<void> excluirAgendamento(int agendamentoId) async {}

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
    required NivelEscopo escopo,
    required int escopoId,
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
      modeloTemplate;

  @override
  Future<void> salvarModeloTemplate({
    required int templateId,
    required Map<String, dynamic> modeloJson,
  }) async {}

  @override
  Future<int> gerarRelatorioComDocumento({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    String? nome,
    List<Map<String, int>> assinaturas = const [],
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
  Future<List<Evento>> listarEventosDisponiveis(int templateId) async =>
      const [];

  @override
  Future<Map<String, dynamic>> previsualizarTemplate({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
  }) async {
    previsualizacaoRecebida = (
      template: templateId,
      cliente: clienteId,
      programa: programaId,
      projeto: projetoId,
      evento: eventoId,
    );
    return const {'type': 'doc', 'content': <Map<String, dynamic>>[]};
  }

  @override
  Future<NivelAplicacao?> nivelExigidoTemplate({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
  }) async {
    nivelExigidoRecebido = (
      template: templateId,
      cliente: clienteId,
      programa: programaId,
      projeto: projetoId,
    );
    return nivelExigidoBackend;
  }

  @override
  Future<List<VariavelDisponivel>> listarVariaveisDisponiveis({
    required NivelEscopo escopo,
    required int escopoId,
  }) async => variaveisDisponiveis;

  @override
  Future<List<SolicitacaoClienteModel>> listarSolicitacoes({
    int? clienteId,
    String? status,
  }) async => const [];

  @override
  Future<bool> aprovarSolicitacao(
    int id, {
    bool eAdminCliente = false,
    List<Map<String, dynamic>> programas = const [],
    List<Map<String, dynamic>> projetos = const [],
  }) async =>
      true;

  @override
  Future<bool> recusarSolicitacao(int id) async => true;

  @override
  Future<List<MembroClienteModel>> listarMembrosCliente({int? clienteId}) async => const [];

  @override
  Future<void> criarMembroCliente({required int clienteId, required int userId}) async {}

  @override
  Future<void> excluirMembroCliente(int id) async {}

  @override
  Future<List<UsuarioClienteModel>> listarUsuariosCliente(
          {required int clienteId}) async =>
      const [];

  @override
  Future<void> removerUsuarioDoCliente(
      {required int clienteId, required int userId}) async {}

  @override
  Future<void> atualizarPermissoesUsuario({
    required int clienteId,
    required int userId,
    required bool eAdminCliente,
    required List<int> programaIds,
    required List<int> projetoIds,
  }) async {}

  @override
  Future<List<MembroGeRelatModel>> listarMembrosGeRelat() async => const [];

  @override
  Future<List<UsuarioDisponivelModel>> listarUsuariosDisponiveisGeRelat() async => const [];

  @override
  Future<void> criarMembroGeRelat({required int userId}) async {}

  @override
  Future<void> excluirMembroGeRelat(int id) async {}

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
    required NivelEscopo escopo,
    required int escopoId,
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
  Future<List<OpcaoSelecao>> listarClassesEvento({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
  }) async => const [OpcaoSelecao(id: 2, nome: 'Oficina')];

  @override
  Future<List<Evento>> listarEventos() async => [
    Evento(
      id: 3,
      projetoId: 1,
      nome: 'Evento',
      programa: 'Programa',
      data: DateTime(2026, 6, 21),
    ),
  ];

  @override
  Future<List<TemplateRelatorio>> listarTemplates() async => const [
    TemplateRelatorio(
      id: 4,
      nivel: NivelEscopo.projeto,
      projetoId: 1,
      nome: 'Template',
      descricao: 'Descrição',
      tipo: 'DOCX',
      status: 'Ativo',
    ),
  ];

  @override
  Future<List<Programa>> listarProgramas() async => const [
    Programa(
      id: 10,
      clienteId: 100,
      nome: 'Programa',
      descricao: 'Descrição',
      projetos: 1,
      eventos: 1,
      status: 'Ativo',
    ),
  ];

  @override
  Future<void> atualizarEvento({
    required int eventoId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
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
  Future<ResumoDashboard> obterResumoDashboard({int? clienteId}) async =>
      const ResumoDashboard(
        programas: 0,
        projetos: 0,
        eventos: 0,
        templates: 0,
        relatorios: 0,
      );
}

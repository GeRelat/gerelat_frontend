import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/main.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/paginas/configuracoes/pagina_configuracoes.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_detalhe_programa.dart';

class _FakeAuthRepo implements RepositorioAutenticacao {
  Usuario? usuario;

  @override
  bool get estaAutenticado => usuario != null;

  @override
  Future<Usuario?> obterUsuarioAtual() async => usuario;

  @override
  Future<void> inicializar() async {}

  @override
  Future<ResultadoLogin> login({required String email, required String senha}) async =>
      const ResultadoLogin.sucesso();

  @override
  Future<ResultadoLogin> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
    int? clienteId,
  }) async =>
      const ResultadoLogin.sucesso();

  @override
  Future<List<OpcaoSelecao>> listarClientesPublicos() async => const [];

  @override
  Future<ResultadoLogin> solicitarAcessoCliente({
    required int clienteId,
    int? programaId,
    int? projetoId,
    String? papelSolicitado,
  }) async =>
      const ResultadoLogin.sucesso();

  @override
  Future<ResultadoLogin> solicitarRecuperacaoSenha({required String email}) async =>
      const ResultadoLogin.sucesso();

  @override
  Future<ResultadoLogin> confirmarRecuperacaoSenha({
    required String uid,
    required String token,
    required String novaSenha,
  }) async =>
      const ResultadoLogin.sucesso();

  @override
  Future<ResultadoLogin> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async =>
      const ResultadoLogin.sucesso();

  @override
  Future<void> sair() async {}
}

class _FakeCatalogoRepo extends Fake implements RepositorioCatalogo {
  Cliente? clienteRetorno;
  Programa? programaRetorno;

  @override
  Future<Cliente> obterCliente(int clienteId) async {
    return clienteRetorno ??
        Cliente(
          id: clienteId,
          nome: 'Cliente de Teste',
          cnpj: '12.345.678/0001-90',
          nomeContato: 'João da Silva',
          emailContato: 'joao@cliente.com',
          foneContato: '(11) 98765-4321',
          numeroContrato: 'CT-2026/001',
          dataTerminoContrato: DateTime(2027, 12, 31),
        );
  }

  @override
  Future<Programa> obterPrograma(int programaId) async {
    return programaRetorno ??
        Programa(
          id: programaId,
          nome: 'Programa de Teste',
          descricao: 'Descrição de teste do programa',
          clienteId: 10,
          clienteNome: 'Cliente de Teste',
          projetos: 3,
          eventos: 5,
          status: 'ativo',
        );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('exibe tela de login quando nao ha sessao', (tester) async {
    await tester.pumpWidget(const AplicativoGeRelat());
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });

  testWidgets('AppShell oculta Clientes para usuario comum e exibe para admin GeRelat', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepo = _FakeAuthRepo();
    final sessao = SessaoViewModel(authRepo);

    // 1. Usuário comum (não admin GeRelat)
    authRepo.usuario = const Usuario(
      id: 1,
      email: 'comum@teste.com',
      nomeCompleto: 'Usuário Comum',
      possuiContextoAcesso: true,
      contextosAcesso: ContextosAcesso(
        adminGerelat: false,
        programas: [
          {
            'programa_id': 1,
            'programa_nome': 'Programa 1',
            'cliente_id': 10,
            'cliente_nome': 'Prefeitura ABC',
          }
        ],
      ),
    );
    await sessao.inicializar();

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          secaoAtual: SecaoApp.dashboard,
          titulo: 'Dashboard',
          sessao: sessao,
          child: const Text('Conteúdo'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Clientes'), findsNothing);
    expect(find.text('Programas'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);

    // 2. Admin GeRelat
    authRepo.usuario = const Usuario(
      id: 2,
      email: 'admin@gerelat.dev',
      nomeCompleto: 'Admin GeRelat',
      possuiContextoAcesso: true,
      contextosAcesso: ContextosAcesso(
        adminGerelat: true,
      ),
    );
    await sessao.inicializar();

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          secaoAtual: SecaoApp.dashboard,
          titulo: 'Dashboard',
          sessao: sessao,
          child: const Text('Conteúdo'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Clientes'), findsOneWidget);
  });

  testWidgets('PaginaConfiguracoes exibe informacoes da organizacao ativa e omite contrato para nao-admin', (tester) async {
    final authRepo = _FakeAuthRepo();
    final catalogoRepo = _FakeCatalogoRepo();
    final sessao = SessaoViewModel(authRepo);

    // 1. Membro comum: não deve ver número do contrato nem vigência
    authRepo.usuario = const Usuario(
      id: 1,
      email: 'membro@teste.com',
      nomeCompleto: 'Membro Projeto',
      possuiContextoAcesso: true,
      contextosAcesso: ContextosAcesso(
        programas: [
          {
            'programa_id': 1,
            'programa_nome': 'Programa 1',
            'cliente_id': 10,
            'cliente_nome': 'Prefeitura de Teste',
          }
        ],
      ),
    );
    await sessao.inicializar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginaConfiguracoes(
            repositorioAutenticacao: authRepo,
            repositorioCatalogo: catalogoRepo,
            sessaoViewModel: sessao,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurações do GeRelat'), findsOneWidget);
    expect(find.text('Membro Projeto'), findsOneWidget);
    expect(find.text('Cliente de Teste'), findsOneWidget);
    expect(find.text('CNPJ: 12.345.678/0001-90'), findsOneWidget);
    expect(find.text('Organização Ativa'), findsOneWidget);
    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('joao@cliente.com'), findsOneWidget);
    expect(find.text('(11) 98765-4321'), findsOneWidget);
    // Para não-admin, os dados de contrato devem ser omitidos
    expect(find.text('Número do Contrato'), findsNothing);
    expect(find.text('CT-2026/001'), findsNothing);
    expect(find.text('Vigência do Contrato'), findsNothing);
    expect(find.text('31/12/2027'), findsNothing);
    expect(find.text('Alterar senha'), findsOneWidget);

    // 2. Admin do Cliente: deve ver número do contrato e vigência
    authRepo.usuario = const Usuario(
      id: 2,
      email: 'admin.cliente@teste.com',
      nomeCompleto: 'Admin Cliente',
      possuiContextoAcesso: true,
      contextosAcesso: ContextosAcesso(
        clientesAdmin: [
          ItemContextoCliente(
            id: 10,
            nome: 'Prefeitura de Teste',
            papel: 'admin',
          ),
        ],
      ),
    );
    await sessao.inicializar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginaConfiguracoes(
            repositorioAutenticacao: authRepo,
            repositorioCatalogo: catalogoRepo,
            sessaoViewModel: sessao,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin Cliente'), findsOneWidget);
    expect(find.text('Número do Contrato'), findsOneWidget);
    expect(find.text('CT-2026/001'), findsOneWidget);
    expect(find.text('Vigência do Contrato'), findsOneWidget);
    expect(find.text('31/12/2027'), findsOneWidget);
  });

  testWidgets('PaginaDetalhePrograma oculta botao Editar programa para membro exclusivo de projeto e exibe para membro do programa/admin', (tester) async {
    final authRepo = _FakeAuthRepo();
    final catalogoRepo = _FakeCatalogoRepo();
    final sessao = SessaoViewModel(authRepo);

    // 1. Membro exclusivo de projeto (não é membro do programa nem admin)
    authRepo.usuario = const Usuario(
      id: 1,
      email: 'membro.projeto@teste.com',
      nomeCompleto: 'Membro Projeto',
      possuiContextoAcesso: true,
      contextosAcesso: ContextosAcesso(
        programas: [],
        projetos: [
          {
            'id': 101,
            'projeto_id': 101,
            'projeto_nome': 'Projeto A',
            'programa_id': 1,
            'cliente_id': 10,
          }
        ],
      ),
    );
    await sessao.inicializar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginaDetalhePrograma(
            programaId: 1,
            repositorioCatalogo: catalogoRepo,
            sessaoViewModel: sessao,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Programa de Teste'), findsOneWidget);
    expect(find.text('Descrição de teste do programa'), findsOneWidget);
    // "Editar programa" deve estar oculto
    expect(find.text('Editar programa'), findsNothing);

    // 2. Membro do programa
    authRepo.usuario = const Usuario(
      id: 2,
      email: 'membro.programa@teste.com',
      nomeCompleto: 'Membro Programa',
      possuiContextoAcesso: true,
      contextosAcesso: ContextosAcesso(
        programas: [
          {
            'id': 1,
            'programa_id': 1,
            'programa_nome': 'Programa de Teste',
            'cliente_id': 10,
          }
        ],
      ),
    );
    await sessao.inicializar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginaDetalhePrograma(
            programaId: 1,
            repositorioCatalogo: catalogoRepo,
            sessaoViewModel: sessao,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar programa'), findsOneWidget);
  });
}

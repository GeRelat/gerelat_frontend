import 'package:flutter/material.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/navegacao/pagina_nao_encontrada.dart';
import 'package:gerelat_frontend/paginas/assets/pagina_assets.dart';
import 'package:gerelat_frontend/paginas/cadastro/pagina_cadastro.dart';
import 'package:gerelat_frontend/paginas/clientes/pagina_clientes.dart';
import 'package:gerelat_frontend/paginas/clientes/pagina_formulario_cliente.dart';
import 'package:gerelat_frontend/paginas/configuracoes/pagina_configuracoes.dart';
import 'package:gerelat_frontend/paginas/dashboard/dashboard.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_classes_evento.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_eventos.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_formulario_evento.dart';
import 'package:gerelat_frontend/paginas/login/pagina_login.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_campos_projeto.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_equipe_programa.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_equipe_projeto.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_formulario_programa.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_formulario_projeto.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_programas.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_projetos_programa.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_email_enviado.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_nova_senha.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_recuperar_senha.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_gerar_relatorio.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_relatorios.dart';
import 'package:gerelat_frontend/paginas/sucesso_cadastro/pagina_sucesso_cadastro.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_formulario_template.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_templates.dart';
import 'package:go_router/go_router.dart';

const _rotasPublicas = <String>[
  '/login',
  '/cadastro',
  '/cadastro/sucesso',
  '/recuperar-senha',
  '/recuperar-senha/enviado',
  '/redefinir-senha',
];

/// Deriva o que o [AppShell] precisa mostrar (seção ativa do menu + título)
/// a partir do caminho da rota, evitando repetir essa informação em cada página.
({SecaoApp secao, String titulo}) _chromeParaRota(String caminho) {
  if (caminho.startsWith('/clientes')) {
    final titulo = caminho.endsWith('/editar')
        ? 'Editar Cliente'
        : caminho.endsWith('/novo')
        ? 'Novo Cliente'
        : 'Gestao de Clientes';
    return (secao: SecaoApp.clientes, titulo: titulo);
  }
  if (caminho.startsWith('/programas')) {
    final titulo = caminho.contains('/projetos/novo')
        ? 'Novo Projeto'
        : caminho.contains('/projetos/') && caminho.endsWith('/editar')
        ? 'Editar Projeto'
        : caminho.endsWith('/projetos')
        ? 'Projetos do Programa'
        : caminho.endsWith('/editar')
        ? 'Editar Programa'
        : caminho.endsWith('/equipe')
        ? 'Equipe do Programa'
        : caminho.endsWith('/novo')
        ? 'Novo Programa'
        : 'Gestao de Programas';
    return (secao: SecaoApp.programas, titulo: titulo);
  }
  if (caminho.startsWith('/projetos')) {
    final titulo = caminho.endsWith('/campos')
        ? 'Textos do Projeto'
        : 'Equipe da Parceira';
    return (secao: SecaoApp.programas, titulo: titulo);
  }
  if (caminho.startsWith('/eventos')) {
    final titulo = caminho.endsWith('/classes-evento')
        ? 'Classes de Evento'
        : caminho.endsWith('/editar')
        ? 'Editar Evento'
        : caminho.endsWith('/novo')
        ? 'Novo Evento'
        : 'Gestao de Eventos';
    return (secao: SecaoApp.eventos, titulo: titulo);
  }
  if (caminho.startsWith('/templates')) {
    final titulo = caminho.endsWith('/editar')
        ? 'Editar Template'
        : caminho.endsWith('/novo')
        ? 'Novo Template'
        : 'Templates';
    return (secao: SecaoApp.templates, titulo: titulo);
  }
  if (caminho.startsWith('/relatorios')) {
    final titulo = caminho.endsWith('/gerar')
        ? 'Gerar Relatório'
        : 'Relatorios';
    return (secao: SecaoApp.relatorios, titulo: titulo);
  }
  if (caminho.startsWith('/assets')) {
    return (secao: SecaoApp.assets, titulo: 'Galeria de Imagens');
  }
  if (caminho.startsWith('/configuracoes')) {
    return (secao: SecaoApp.dashboard, titulo: 'Configuracoes');
  }
  return (secao: SecaoApp.dashboard, titulo: 'Dashboard');
}

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  refreshListenable: DependenciasApp.instancia.sessao,
  redirect: (context, state) {
    final autenticado = DependenciasApp.instancia.sessao.estaAutenticado;
    final indoParaRotaPublica = _rotasPublicas.any(
      (rota) => state.matchedLocation == rota,
    );

    if (!autenticado && !indoParaRotaPublica) return '/login';
    if (autenticado && indoParaRotaPublica) return '/dashboard';
    return null;
  },
  errorBuilder: (context, state) {
    final autenticado = DependenciasApp.instancia.sessao.estaAutenticado;
    return PaginaNaoEncontrada(
      rotaDestino: autenticado ? '/dashboard' : '/login',
    );
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const PaginaLogin()),
    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const PaginaCadastro(),
    ),
    GoRoute(
      path: '/cadastro/sucesso',
      builder: (context, state) => const PaginaSucessoCadastro(),
    ),
    GoRoute(
      path: '/recuperar-senha',
      builder: (context, state) => const PaginaRecuperarSenha(),
    ),
    GoRoute(
      path: '/recuperar-senha/enviado',
      builder: (context, state) => const PaginaEmailEnviado(),
    ),
    GoRoute(
      path: '/redefinir-senha',
      builder: (context, state) {
        final uid = state.uri.queryParameters['uid'];
        final token = state.uri.queryParameters['token'];
        if (uid == null || token == null) {
          return const PaginaRecuperarSenha();
        }
        return PaginaNovaSenha(uid: uid, token: token);
      },
    ),
    ShellRoute(
      builder: (context, state, child) {
        final chrome = _chromeParaRota(state.matchedLocation);
        return AppShell(
          secaoAtual: chrome.secao,
          titulo: chrome.titulo,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/clientes',
          builder: (context, state) => const PaginaClientes(),
        ),
        GoRoute(
          path: '/clientes/novo',
          builder: (context, state) => const PaginaFormularioCliente(),
        ),
        GoRoute(
          path: '/clientes/:id/editar',
          builder: (context, state) => PaginaFormularioCliente(
            edicao: true,
            clienteId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/programas',
          builder: (context, state) => const PaginaProgramas(),
        ),
        GoRoute(
          path: '/programas/novo',
          builder: (context, state) => const PaginaFormularioPrograma(),
        ),
        GoRoute(
          path: '/programas/:id/editar',
          builder: (context, state) => PaginaFormularioPrograma(
            edicao: true,
            programaId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/programas/projetos/novo',
          builder: (context, state) => PaginaFormularioProjeto(
            programaIdInicial: state.extra as int?,
          ),
        ),
        GoRoute(
          path: '/programas/projetos/:id/editar',
          builder: (context, state) => PaginaFormularioProjeto(
            edicao: true,
            projetoId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/programas/:id/projetos',
          builder: (context, state) => PaginaProjetosPrograma(
            programaId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/programas/:id/equipe',
          builder: (context, state) => PaginaEquipePrograma(
            programaId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/projetos/equipe',
          builder: (context, state) => const PaginaEquipeProjeto(),
        ),
        GoRoute(
          path: '/projetos/campos',
          builder: (context, state) => const PaginaCamposProjeto(),
        ),
        GoRoute(
          path: '/eventos',
          builder: (context, state) => const PaginaEventos(),
        ),
        GoRoute(
          path: '/eventos/classes-evento',
          builder: (context, state) => const PaginaClassesEvento(),
        ),
        GoRoute(
          path: '/eventos/novo',
          builder: (context, state) => const PaginaFormularioEvento(),
        ),
        GoRoute(
          path: '/eventos/:id/editar',
          builder: (context, state) => PaginaFormularioEvento(
            edicao: true,
            eventoId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/templates',
          builder: (context, state) => const PaginaTemplates(),
        ),
        GoRoute(
          path: '/templates/novo',
          builder: (context, state) => const PaginaFormularioTemplate(),
        ),
        GoRoute(
          path: '/templates/:id/editar',
          builder: (context, state) => PaginaFormularioTemplate(
            edicao: true,
            templateId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/relatorios',
          builder: (context, state) => const PaginaRelatorios(),
        ),
        GoRoute(
          path: '/relatorios/gerar',
          builder: (context, state) => const PaginaGerarRelatorio(),
        ),
        GoRoute(
          path: '/assets',
          builder: (context, state) => const PaginaAssets(),
        ),
        GoRoute(
          path: '/configuracoes',
          builder: (context, state) => const PaginaConfiguracoes(),
        ),
      ],
    ),
  ],
);

import 'package:flutter/material.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/navegacao/pagina_nao_encontrada.dart';
import 'package:gerelat_frontend/paginas/assets/pagina_assets.dart';
import 'package:gerelat_frontend/paginas/cadastro/pagina_cadastro.dart';

import 'package:gerelat_frontend/paginas/clientes/pagina_clientes.dart';
import 'package:gerelat_frontend/paginas/clientes/pagina_formulario_cliente.dart';
import 'package:gerelat_frontend/paginas/clientes/pagina_membros.dart';
import 'package:gerelat_frontend/paginas/configuracoes/pagina_configuracoes.dart';
import 'package:gerelat_frontend/paginas/dashboard/dashboard.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_classes_evento.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_eventos.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_formulario_evento.dart';
import 'package:gerelat_frontend/paginas/login/pagina_login.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_equipe_programa.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_equipe_projeto.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_formulario_programa.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_detalhe_programa.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_formulario_projeto.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_programas.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_projetos_programa.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_email_enviado.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_nova_senha.dart';
import 'package:gerelat_frontend/paginas/recuperar_senha/pagina_recuperar_senha.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_agendar_relatorio.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_editor_relatorio.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_gerar_relatorio.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_relatorios.dart';
import 'package:gerelat_frontend/paginas/solicitar_acesso/pagina_solicitar_acesso.dart';
import 'package:gerelat_frontend/paginas/sucesso_cadastro/pagina_sucesso_cadastro.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_editor_template.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_formulario_template.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_templates.dart';
import 'package:gerelat_frontend/paginas/variaveis/pagina_variaveis.dart';
import 'package:go_router/go_router.dart';

/// Faz o parse seguro de um parâmetro numérico de rota (`:id` etc.).
/// Retorna `null` quando o parâmetro está ausente ou não é um inteiro válido,
/// em vez de lançar [FormatException] dentro do `builder` — uma exceção ali
/// não é interceptada pelo `errorBuilder` do [GoRouter], que só trata falhas
/// de matching de rota.
int? _idDaRota(GoRouterState state, [String parametro = 'id']) {
  return int.tryParse(state.pathParameters[parametro] ?? '');
}

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
    if (caminho == '/clientes/membros' ||
        caminho == '/clientes/aprovacoes') {
      return (secao: SecaoApp.membros, titulo: 'Membros do Cliente');
    }
    final titulo = caminho.endsWith('/editar')
        ? 'Editar Cliente'
        : caminho.endsWith('/novo')
        ? 'Novo Cliente'
        : 'Gestão de Clientes';
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
        : RegExp(r'^/programas/\d+$').hasMatch(caminho)
        ? 'Programa'
        : 'Gestão de Programas';
    return (secao: SecaoApp.programas, titulo: titulo);
  }
  if (caminho.startsWith('/variaveis')) {
    return (secao: SecaoApp.variaveis, titulo: 'Variáveis');
  }
  if (caminho.startsWith('/projetos')) {
    return (secao: SecaoApp.programas, titulo: 'Equipe da Parceira');
  }
  if (caminho.startsWith('/eventos')) {
    final titulo = caminho.endsWith('/classes-evento')
        ? 'Classes de Evento'
        : caminho.endsWith('/editar')
        ? 'Editar Evento'
        : caminho.endsWith('/novo')
        ? 'Novo Evento'
        : 'Gestão de Eventos';
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
    final titulo = caminho.endsWith('/agendar')
        ? 'Geração Autônoma'
        : caminho.endsWith('/gerar')
            ? 'Gerar Relatório'
            : 'Relatórios';
    return (secao: SecaoApp.relatorios, titulo: titulo);
  }
  if (caminho.startsWith('/assets')) {
    return (secao: SecaoApp.assets, titulo: 'Imagens');
  }
  if (caminho.startsWith('/configuracoes')) {
    return (secao: SecaoApp.configuracoes, titulo: 'Configurações');
  }
  return (secao: SecaoApp.dashboard, titulo: 'Dashboard');
}

/// Monta o [GoRouter] da aplicação a partir de [dependencias] — ponto único
/// de composição: lê `DependenciasApp` uma única vez (em [appRouter], mais
/// abaixo) e distribui os serviços já resolvidos para cada rota.
GoRouter _construirAppRouter(DependenciasApp dependencias) {
  final repositorioCatalogo = dependencias.repositorioCatalogo;
  final repositorioAutenticacao = dependencias.repositorioAutenticacao;
  final sessao = dependencias.sessao;
  final urlBase = dependencias.clienteHttp.urlBase;

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: sessao,
    redirect: (context, state) {
      final autenticado = sessao.estaAutenticado;
      final indoParaRotaPublica = _rotasPublicas.any(
        (rota) => state.matchedLocation == rota,
      );

      if (!autenticado && !indoParaRotaPublica) return '/login';

      // `/redefinir-senha` precisa funcionar mesmo com uma sessão válida no
      // navegador: o link do e-mail de recuperação não sabe se quem clicou
      // está logado, e há motivo legítimo para seguir o fluxo mesmo
      // autenticado (ex.: sessão antiga ainda válida em outra aba). Sem essa
      // exceção, o redirect abaixo descartava `uid`/`token` da URL e mandava
      // direto para `/dashboard`, quebrando o link do e-mail em silêncio.
      final indoParaRedefinirSenha =
          state.matchedLocation == '/redefinir-senha';
      if (autenticado && indoParaRotaPublica && !indoParaRedefinirSenha) {
        return '/dashboard';
      }

      // Usuário autenticado mas sem nenhum vínculo de acesso: redireciona para
      // a tela de solicitação de acesso, exceto se já estiver lá.
      final indoParaSolicitarAcesso =
          state.matchedLocation == '/solicitar-acesso';
      if (autenticado && !indoParaRotaPublica && !indoParaSolicitarAcesso) {
        final usuario = sessao.usuarioAtual;
        if (usuario != null && !usuario.possuiContextoAcesso) {
          return '/solicitar-acesso';
        }
      }

      return null;
    },
    errorBuilder: (context, state) {
      final autenticado = sessao.estaAutenticado;
      return PaginaNaoEncontrada(
        rotaDestino: autenticado ? '/dashboard' : '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => PaginaLogin(
          repositorioAutenticacao: repositorioAutenticacao,
          sessao: sessao,
        ),
      ),
      GoRoute(
        path: '/cadastro',
        builder: (context, state) =>
            PaginaCadastro(repositorioAutenticacao: repositorioAutenticacao),
      ),
      GoRoute(
        path: '/cadastro/sucesso',
        builder: (context, state) => const PaginaSucessoCadastro(),
      ),
      GoRoute(
        path: '/recuperar-senha',
        builder: (context, state) => PaginaRecuperarSenha(
          repositorioAutenticacao: repositorioAutenticacao,
        ),
      ),
      GoRoute(
        path: '/solicitar-acesso',
        builder: (context, state) => PaginaSolicitarAcesso(
          repositorioAutenticacao: repositorioAutenticacao,
          sessao: sessao,
        ),
      ),
      GoRoute(
        path: '/recuperar-senha/enviado',
        builder: (context, state) => PaginaEmailEnviado(
          email: state.extra as String?,
          repositorioAutenticacao: repositorioAutenticacao,
        ),
      ),
      GoRoute(
        path: '/redefinir-senha',
        builder: (context, state) {
          final uid = state.uri.queryParameters['uid'];
          final token = state.uri.queryParameters['token'];
          if (uid == null || token == null) {
            return PaginaRecuperarSenha(
              repositorioAutenticacao: repositorioAutenticacao,
            );
          }
          return PaginaNovaSenha(
            uid: uid,
            token: token,
            repositorioAutenticacao: repositorioAutenticacao,
          );
        },
      ),
      // Editores em tela cheia (fora do AppShell): a superfície de edição
      // ProseMirror precisa de uma altura limitada e de todo o espaço da tela.
      GoRoute(
        path: '/templates/:id/editor',
        builder: (context, state) {
          final templateId = _idDaRota(state);
          if (templateId == null) {
            return const PaginaNaoEncontrada(rotaDestino: '/templates');
          }
          return PaginaEditorTemplate(
            templateId: templateId,
            repositorioCatalogo: repositorioCatalogo,
          );
        },
      ),
      GoRoute(
        path: '/relatorios/editor',
        builder: (context, state) {
          final args = state.extra;
          if (args is! ArgumentosEditorRelatorio) {
            return const PaginaNaoEncontrada(rotaDestino: '/relatorios/gerar');
          }
          return PaginaEditorRelatorio(
            argumentos: args,
            repositorioCatalogo: repositorioCatalogo,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          final chrome = _chromeParaRota(state.matchedLocation);
          return AppShell(
            secaoAtual: chrome.secao,
            titulo: chrome.titulo,
            sessao: sessao,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => DashboardPage(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/clientes',
            redirect: (context, state) =>
                sessao.usuarioAtual?.isAdminGeRelat == true ? null : '/dashboard',
            builder: (context, state) => PaginaClientes(
              repositorioCatalogo: repositorioCatalogo,
              urlBase: urlBase,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/clientes/aprovacoes',
            redirect: (context, state) => '/clientes/membros',
          ),
          GoRoute(
            path: '/clientes/membros',
            builder: (context, state) => PaginaMembros(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/clientes/novo',
            redirect: (context, state) =>
                sessao.usuarioAtual?.isAdminGeRelat == true ? null : '/dashboard',
            builder: (context, state) => PaginaFormularioCliente(
              repositorioCatalogo: repositorioCatalogo,
              urlBase: urlBase,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/clientes/:id/editar',
            redirect: (context, state) =>
                sessao.usuarioAtual?.isAdminGeRelat == true ? null : '/dashboard',
            builder: (context, state) {
              final clienteId = _idDaRota(state);
              if (clienteId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/dashboard');
              }
              return PaginaFormularioCliente(
                edicao: true,
                clienteId: clienteId,
                repositorioCatalogo: repositorioCatalogo,
                urlBase: urlBase,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/programas',
            builder: (context, state) => PaginaProgramas(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/programas/novo',
            redirect: (context, state) {
              final usuario = sessao.usuarioAtual;
              final clienteAtivoId = sessao.clienteAtivoId;
              final podeCriar =
                  usuario?.eAdminDoCliente(clienteAtivoId) ?? false;
              return podeCriar ? null : '/programas';
            },
            builder: (context, state) => PaginaFormularioPrograma(
              repositorioCatalogo: repositorioCatalogo,
              urlBase: urlBase,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/programas/:id/editar',
            redirect: (context, state) {
              final programaId = _idDaRota(state);
              if (programaId == null) return '/programas';
              final usuario = sessao.usuarioAtual;
              final clienteAtivoId = sessao.clienteAtivoId;
              final eAdminCliente =
                  usuario?.eAdminDoCliente(clienteAtivoId) ?? false;
              final eMembroDoPrograma = usuario?.contextosAcesso.programas.any(
                    (p) =>
                        int.tryParse('${p['id']}') == programaId ||
                        int.tryParse('${p['programa_id']}') == programaId,
                  ) ??
                  false;
              final podeEditar = eAdminCliente || eMembroDoPrograma;
              return podeEditar ? null : '/programas/$programaId';
            },
            builder: (context, state) {
              final programaId = _idDaRota(state);
              if (programaId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/programas');
              }
              return PaginaFormularioPrograma(
                edicao: true,
                programaId: programaId,
                repositorioCatalogo: repositorioCatalogo,
                urlBase: urlBase,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/programas/projetos/novo',
            builder: (context, state) => PaginaFormularioProjeto(
              programaIdInicial: state.extra as int?,
              repositorioCatalogo: repositorioCatalogo,
              urlBase: urlBase,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/programas/projetos/:id/editar',
            builder: (context, state) {
              final projetoId = _idDaRota(state);
              if (projetoId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/programas');
              }
              return PaginaFormularioProjeto(
                edicao: true,
                projetoId: projetoId,
                repositorioCatalogo: repositorioCatalogo,
                urlBase: urlBase,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/programas/:id',
            builder: (context, state) {
              final programaId = _idDaRota(state);
              if (programaId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/programas');
              }
              final aba = int.tryParse(state.uri.queryParameters['aba'] ?? '');
              return PaginaDetalhePrograma(
                programaId: programaId,
                repositorioCatalogo: repositorioCatalogo,
                sessaoViewModel: sessao,
                abaInicial: aba ?? 0,
              );
            },
          ),
          GoRoute(
            path: '/programas/:id/projetos',
            builder: (context, state) {
              final programaId = _idDaRota(state);
              if (programaId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/programas');
              }
              return PaginaProjetosPrograma(
                programaId: programaId,
                repositorioCatalogo: repositorioCatalogo,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/programas/:id/equipe',
            builder: (context, state) {
              final programaId = _idDaRota(state);
              if (programaId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/programas');
              }
              return PaginaEquipePrograma(
                programaId: programaId,
                repositorioCatalogo: repositorioCatalogo,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/projetos/equipe',
            builder: (context, state) =>
                PaginaEquipeProjeto(repositorioCatalogo: repositorioCatalogo),
          ),
          GoRoute(
            path: '/variaveis',
            builder: (context, state) => PaginaVariaveis(
              repositorioCatalogo: repositorioCatalogo,
              urlBase: urlBase,
              sessaoViewModel: sessao,
            ),
          ),
          // Rotas antigas — redirecionam para a tela unificada.
          GoRoute(
            path: '/variaveis/definicoes',
            redirect: (context, state) => '/variaveis',
          ),
          GoRoute(
            path: '/variaveis/valores',
            redirect: (context, state) => '/variaveis',
          ),
          GoRoute(
            path: '/eventos',
            builder: (context, state) => PaginaEventos(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/eventos/classes-evento',
            builder: (context, state) => PaginaClassesEvento(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/eventos/novo',
            builder: (context, state) => PaginaFormularioEvento(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/eventos/:id/editar',
            builder: (context, state) {
              final eventoId = _idDaRota(state);
              if (eventoId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/eventos');
              }
              return PaginaFormularioEvento(
                edicao: true,
                eventoId: eventoId,
                repositorioCatalogo: repositorioCatalogo,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/templates',
            builder: (context, state) => PaginaTemplates(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/templates/novo',
            builder: (context, state) => PaginaFormularioTemplate(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/templates/:id/editar',
            builder: (context, state) {
              final templateId = _idDaRota(state);
              if (templateId == null) {
                return const PaginaNaoEncontrada(rotaDestino: '/templates');
              }
              return PaginaFormularioTemplate(
                edicao: true,
                templateId: templateId,
                repositorioCatalogo: repositorioCatalogo,
                sessaoViewModel: sessao,
              );
            },
          ),
          GoRoute(
            path: '/relatorios',
            builder: (context, state) => PaginaRelatorios(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/relatorios/gerar',
            builder: (context, state) {
              final extra = state.extra;
              int? templateId;
              int? programaId;
              int? projetoId;
              if (extra is Map<String, dynamic>) {
                templateId = extra['templateId'] as int?;
                programaId = extra['programaId'] as int?;
                projetoId = extra['projetoId'] as int?;
              }
              return PaginaGerarRelatorio(
                repositorioCatalogo: repositorioCatalogo,
                sessaoViewModel: sessao,
                templateIdInicial: templateId,
                programaIdInicial: programaId,
                projetoIdInicial: projetoId,
              );
            },
          ),
          GoRoute(
            path: '/relatorios/agendar',
            builder: (context, state) => PaginaAgendarRelatorio(
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => PaginaAssets(
              repositorioCatalogo: repositorioCatalogo,
              urlBase: urlBase,
              sessaoViewModel: sessao,
            ),
          ),
          GoRoute(
            path: '/configuracoes',
            builder: (context, state) => PaginaConfiguracoes(
              repositorioAutenticacao: repositorioAutenticacao,
              repositorioCatalogo: repositorioCatalogo,
              sessaoViewModel: sessao,
              urlBase: urlBase,
            ),
          ),
        ],
      ),
    ],
  );
}

final appRouter = _construirAppRouter(DependenciasApp.instancia);

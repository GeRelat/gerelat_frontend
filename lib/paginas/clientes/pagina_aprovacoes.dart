import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gestao_membros_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/solicitacao_cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaAprovacoes extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaAprovacoes({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaAprovacoes> createState() => _PaginaAprovacoesState();
}

class _PaginaAprovacoesState extends State<PaginaAprovacoes> {
  late final GestaoMembrosViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GestaoMembrosViewModel(widget.repositorioCatalogo);
    widget.sessaoViewModel.addListener(_aoMudarSessao);
    _carregarDadosSePermitido();
  }

  void _aoMudarSessao() {
    _carregarDadosSePermitido();
  }

  void _carregarDadosSePermitido() {
    if (!mounted) return;
    final clienteId = widget.sessaoViewModel.clienteAtivoId;
    final temPermissao =
        widget.sessaoViewModel.usuarioAtual?.eAdminDoCliente(clienteId) ?? false;

    if (!temPermissao) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/clientes/membros');
        }
      });
      return;
    }

    if (_viewModel.clienteId != clienteId) {
      _viewModel.carregar(clienteId: clienteId);
    }
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clienteId = widget.sessaoViewModel.clienteAtivoId;
    final temPermissao = widget.sessaoViewModel.usuarioAtual?.eAdminDoCliente(clienteId) ?? false;

    if (!temPermissao) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: EstadoVazio(
          icone: LucideIcons.shield_alert,
          titulo: 'Acesso Restrito',
          descricao:
              'Você não tem permissão para visualizar ou gerenciar as solicitações de acesso deste cliente.',
          acao: '',
        ),
      );
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(),
              const SizedBox(height: 24),
              _conteudo(),
            ],
          ),
        );
      },
    );
  }

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aprovações de Acesso',
          style: Tipografia.headlineMedium.copyWith(
            color: Cores.textoPrincipal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gerencie as solicitações de acesso pendentes para o cliente selecionado.',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
      ],
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null && _viewModel.solicitacoes.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Erro ao carregar dados',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: () => _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId),
      );
    }

    return _secaoSolicitacoes();
  }

  Widget _secaoSolicitacoes() {
    final solicitacoes = _viewModel.solicitacoes;

    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.user_plus, color: Cores.azulAcao),
              const SizedBox(width: 10),
              Text(
                'Solicitações de Acesso Pendentes',
                style: Tipografia.titleLarge.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: solicitacoes.isNotEmpty
                      ? Cores.ambarAlerta.withValues(alpha: 0.2)
                      : Cores.fundoSecao,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${solicitacoes.length}',
                  style: Tipografia.labelMedium.copyWith(
                    color: solicitacoes.isNotEmpty
                        ? Cores.ambarAlerta
                        : Cores.cinzaEscuro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (solicitacoes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhuma solicitação de acesso pendente no momento.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: solicitacoes.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Cores.bordaSutil),
              itemBuilder: (context, index) {
                final sol = solicitacoes[index];
                return _itemSolicitacao(sol);
              },
            ),
        ],
      ),
    );
  }

  Widget _itemSolicitacao(SolicitacaoClienteModel sol) {
    final nomeUsuario = sol.userNome.isNotEmpty
        ? sol.userNome
        : (sol.userEmail.isNotEmpty ? sol.userEmail : 'Usuário #${sol.user}');
    final nomeCliente = sol.clienteNome.isNotEmpty
        ? sol.clienteNome
        : 'ID #${sol.cliente}';
    final processando = _viewModel.isProcessando(sol.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeUsuario,
                  style: Tipografia.titleMedium.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: $nomeCliente',
                  style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
                ),
                if (sol.createdAt != null)
                  Text(
                    'Solicitado em: ${sol.createdAt!.toIso8601String().split('T').first}',
                    style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
                  ),
              ],
            ),
          ),
          if (processando)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exibirDialogoAprovacao(sol),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.verdeSucesso,
                    foregroundColor: Cores.branco,
                  ),
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Aprovar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await _viewModel.recusarSolicitacao(sol.id);
                    if (mounted) {
                      final msg = ok
                          ? 'Solicitação recusada.'
                          : (_viewModel.mensagemErro ?? 'Erro ao recusar solicitação.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: ok ? Cores.cinzaEscuro : Cores.vermelhoErro,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Cores.vermelhoErro,
                    side: const BorderSide(color: Cores.vermelhoErro),
                  ),
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Recusar'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _exibirDialogoAprovacao(SolicitacaoClienteModel sol) async {
    bool eAdminCliente = false;
    final Set<int> programasSelecionados = {};
    final Set<int> projetosSelecionados = {};

    List<Programa> todosProgramas = [];
    List<Projeto> todosProjetos = [];
    bool carregandoOpcoes = true;
    String? erroModal;

    try {
      final progResult = await widget.repositorioCatalogo.listarProgramas();
      final projResult =
          await widget.repositorioCatalogo.listarProjetosDetalhados();
      todosProgramas =
          progResult.where((p) => p.clienteId == sol.cliente).toList();
      final progIdsDoCliente =
          todosProgramas.map((p) => p.id).whereType<int>().toSet();
      todosProjetos = projResult
          .where((p) =>
              p.programaId != null &&
              progIdsDoCliente.contains(p.programaId))
          .toList();
    } catch (e) {
      erroModal = 'Erro ao carregar programas/projetos: $e';
    } finally {
      carregandoOpcoes = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final erroForm = erroModal;
            final nomeUsuario = sol.userNome.isNotEmpty
                ? sol.userNome
                : (sol.userEmail.isNotEmpty
                    ? sol.userEmail
                    : 'Usuário #${sol.user}');

            final projetosCobertos = todosProjetos
                .where((p) =>
                    p.programaId != null &&
                    programasSelecionados.contains(p.programaId))
                .toSet();
            final projetosIndependentes = todosProjetos
                .where((p) => !projetosCobertos.contains(p))
                .toList();

            return AlertDialog(
              title: Text('Aprovar Solicitação — $nomeUsuario'),
              content: SizedBox(
                width: 520,
                child: carregandoOpcoes
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecione o nível de acesso a ser concedido.',
                              style: Tipografia.bodySmall
                                  .copyWith(color: Cores.cinzaEscuro),
                            ),
                            const SizedBox(height: 16),

                            // ── Administrador do Cliente ──────────────────
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Administrador do Cliente',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Acesso administrativo total — inclui todos os '
                                'programas e projetos deste cliente.',
                              ),
                              value: eAdminCliente,
                              onChanged: (val) {
                                setDialogState(() {
                                  eAdminCliente = val ?? false;
                                  if (eAdminCliente) {
                                    programasSelecionados.clear();
                                    projetosSelecionados.clear();
                                  }
                                });
                              },
                            ),

                            // ── Programas & Projetos (only when not admin) ─
                            if (!eAdminCliente) ...[
                              const Divider(height: 24),
                              const Text(
                                'Programas',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Acesso a um programa inclui automaticamente '
                                'todos os seus projetos.',
                                style: Tipografia.bodySmall
                                    .copyWith(color: Cores.cinzaEscuro),
                              ),
                              const SizedBox(height: 8),
                              if (todosProgramas.isEmpty)
                                const Text(
                                  'Nenhum programa cadastrado para este cliente.',
                                  style:
                                      TextStyle(color: Cores.cinzaMedio),
                                )
                              else
                                ...todosProgramas.map((prog) {
                                  final progId = prog.id;
                                  if (progId == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final selecionado =
                                      programasSelecionados.contains(progId);
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(prog.nome),
                                    value: selecionado,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          programasSelecionados.add(progId);
                                          for (final proj in todosProjetos) {
                                            if (proj.programaId == progId) {
                                              projetosSelecionados
                                                  .remove(proj.id);
                                            }
                                          }
                                        } else {
                                          programasSelecionados
                                              .remove(progId);
                                        }
                                      });
                                    },
                                  );
                                }),

                              // ── Projetos individuais ──────────────────
                              const Divider(height: 24),
                              const Text(
                                'Projetos individuais',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Projetos cujo programa já está selecionado '
                                'acima não aparecem aqui (acesso já herdado).',
                                style: Tipografia.bodySmall
                                    .copyWith(color: Cores.cinzaEscuro),
                              ),
                              const SizedBox(height: 8),
                              if (projetosIndependentes.isEmpty)
                                const Text(
                                  'Nenhum projeto adicional disponível.',
                                  style:
                                      TextStyle(color: Cores.cinzaMedio),
                                )
                              else
                                ...projetosIndependentes.map((proj) {
                                  final projId = proj.id;
                                  if (projId == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final selecionado =
                                      projetosSelecionados.contains(projId);
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(proj.nome),
                                    value: selecionado,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          projetosSelecionados.add(projId);
                                        } else {
                                          projetosSelecionados
                                              .remove(projId);
                                        }
                                      });
                                    },
                                  );
                                }),
                            ],

                            if (erroForm != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                erroForm,
                                style: const TextStyle(
                                    color: Cores.vermelhoErro),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: carregandoOpcoes
                      ? null
                      : () async {
                          if (!eAdminCliente &&
                              programasSelecionados.isEmpty &&
                              projetosSelecionados.isEmpty) {
                            setDialogState(() {
                              erroModal =
                                  'Selecione ao menos um nível de acesso para aprovar.';
                            });
                            return;
                          }

                          final listProgs = programasSelecionados
                              .map((id) => {'id': id})
                              .toList();
                          final listProjs = projetosSelecionados
                              .map((id) => {'id': id})
                              .toList();

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(dialogContext).pop();

                          final ok = await _viewModel.aprovarSolicitacao(
                            sol.id,
                            eAdminCliente: eAdminCliente,
                            programas: listProgs,
                            projetos: listProjs,
                          );

                          if (mounted) {
                            final msg = ok
                                ? 'Solicitação aprovada! Acessos concedidos com sucesso.'
                                : (_viewModel.mensagemErro ??
                                    'Erro ao aprovar solicitação.');
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: ok
                                    ? Cores.verdeSucesso
                                    : Cores.vermelhoErro,
                              ),
                            );
                          }
                        },
                  child: const Text('Aprovar e Conceder Acesso'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

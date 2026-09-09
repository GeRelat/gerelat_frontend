import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gestao_membros_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario_cliente.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaMembros extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaMembros({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaMembros> createState() => _PaginaMembrosState();
}

class _PaginaMembrosState extends State<PaginaMembros> {
  late final GestaoMembrosViewModel _viewModel;
  int _abaSelecionada = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = GestaoMembrosViewModel(widget.repositorioCatalogo);
    widget.sessaoViewModel.addListener(_aoMudarSessao);
    _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId);
  }

  void _aoMudarSessao() {
    if (_viewModel.clienteId != widget.sessaoViewModel.clienteAtivoId) {
      _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId);
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
    final me = widget.sessaoViewModel.usuarioAtual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão de Membros',
          style: Tipografia.headlineMedium.copyWith(
            color: Cores.textoPrincipal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Visualize e gerencie os usuários e permissões do sistema.',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        if (me?.isAdminGeRelat == true) ...[
          const SizedBox(height: 16),
          SeletorAbas(
            selecionado: _abaSelecionada,
            aoSelecionar: (i) => setState(() => _abaSelecionada = i),
            itens: const [
              (rotulo: 'Membros do Cliente', icone: LucideIcons.users),
              (
                rotulo: 'Admins GeRelat (Plataforma)',
                icone: LucideIcons.shield_check,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_abaSelecionada == 1 &&
        widget.sessaoViewModel.usuarioAtual?.isAdminGeRelat == true) {
      return _secaoAdminsGeRelat();
    }

    if (_viewModel.mensagemErro != null && _viewModel.usuarios.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Erro ao carregar dados',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: () => _viewModel.carregar(clienteId: widget.sessaoViewModel.clienteAtivoId),
      );
    }

    return _secaoMembros();
  }

  Widget _secaoMembros() {
    final usuarios = _viewModel.usuarios;

    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.users, color: Cores.azulAcao),
              const SizedBox(width: 10),
              Text(
                'Usuários com Acesso',
                style: Tipografia.titleLarge.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Cores.fundoSecao,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${usuarios.length}',
                  style: Tipografia.labelMedium.copyWith(
                    color: Cores.cinzaEscuro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Todos os usuários com qualquer nível de acesso a este cliente.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
          ),
          const SizedBox(height: 16),
          if (usuarios.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhum usuário com acesso a este cliente.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: usuarios.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Cores.bordaSutil),
              itemBuilder: (context, index) {
                return _itemUsuario(usuarios[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _itemUsuario(UsuarioClienteModel usuario) {
    final usuarioLogadoId = widget.sessaoViewModel.usuarioAtual?.id;
    final clienteIdAtivo = widget.sessaoViewModel.clienteAtivoId;
    final eAdminDoCliente =
        widget.sessaoViewModel.usuarioAtual?.eAdminDoCliente(clienteIdAtivo) ?? false;
    final eOProprioUsuario =
        usuarioLogadoId != null && usuario.user == usuarioLogadoId;

    final nomeUsuario = usuario.userNome.isNotEmpty
        ? usuario.userNome
        : (usuario.userEmail.isNotEmpty
            ? usuario.userEmail
            : 'Usuário #${usuario.user}');

    final processando = _viewModel.isProcessando(usuario.user);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + badge "Você"
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      nomeUsuario,
                      style: Tipografia.titleMedium
                          .copyWith(color: Cores.textoPrincipal),
                    ),
                    if (eOProprioUsuario)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Cores.azulAcao.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Você',
                          style: Tipografia.bodySmall.copyWith(
                            color: Cores.azulAcao,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (usuario.userEmail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      usuario.userEmail,
                      style: Tipografia.bodySmall
                          .copyWith(color: Cores.cinzaMedio),
                    ),
                  ),
                const SizedBox(height: 6),
                // Access badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (usuario.isAdminCliente)
                      _badge(
                        'Administrador do Cliente',
                        Cores.ambarAlerta,
                        LucideIcons.shield_check,
                      ),
                    ...usuario.acessosPrograma.map(
                      (a) => _badge(
                        'Programa: ${a.programaNome}',
                        Cores.azulAcao,
                        LucideIcons.layout_list,
                      ),
                    ),
                    ...usuario.acessosProjeto.map(
                      (a) => _badge(
                        'Projeto: ${a.projetoNome}',
                        Cores.verdeSucesso,
                        LucideIcons.folder,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (processando)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (eAdminDoCliente) ...[
            if (eOProprioUsuario)
              Tooltip(
                message: 'Você não pode se remover.',
                child: Icon(
                  LucideIcons.trash_2,
                  size: 18,
                  color: Cores.cinzaMedio.withValues(alpha: 0.4),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar permissões deste usuário',
                    onPressed: () => _exibirDialogoEdicaoPermissoes(usuario),
                    icon: const Icon(
                      LucideIcons.pencil,
                      size: 18,
                      color: Cores.azulAcao,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover todos os acessos deste usuário',
                    onPressed: () => _confirmarRemocaoUsuario(usuario),
                    icon: const Icon(
                      LucideIcons.trash_2,
                      size: 18,
                      color: Cores.vermelhoErro,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String texto, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: cor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Tipografia.bodySmall.copyWith(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exibirDialogoEdicaoPermissoes(
      UsuarioClienteModel usuario) async {
    bool eAdminCliente = usuario.isAdminCliente;
    final Set<int> programasSelecionados =
        usuario.acessosPrograma.map((a) => a.programaId).toSet();
    final Set<int> projetosSelecionados =
        usuario.acessosProjeto.map((a) => a.projetoId).toSet();

    List<Programa> todosProgramas = [];
    List<Projeto> todosProjetos = [];
    bool carregandoOpcoes = true;
    String? erroModal;

    final clienteId = _viewModel.clienteId;
    if (clienteId == null) return;

    try {
      final progResult = await widget.repositorioCatalogo.listarProgramas();
      final projResult =
          await widget.repositorioCatalogo.listarProjetosDetalhados();
      todosProgramas =
          progResult.where((p) => p.clienteId == clienteId).toList();
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

    final nomeUsuario = usuario.userNome.isNotEmpty
        ? usuario.userNome
        : (usuario.userEmail.isNotEmpty
            ? usuario.userEmail
            : 'Usuário #${usuario.user}');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final erroForm = erroModal;

            final projetosCobertos = todosProjetos
                .where((p) =>
                    p.programaId != null &&
                    programasSelecionados.contains(p.programaId))
                .toSet();
            final projetosIndependentes = todosProjetos
                .where((p) => !projetosCobertos.contains(p))
                .toList();

            for (final p in projetosCobertos) {
              if (p.id != null) projetosSelecionados.remove(p.id);
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(LucideIcons.pencil, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editar Permissões — $nomeUsuario',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Cores.ambarAlerta.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        Cores.ambarAlerta.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.info,
                                      size: 14, color: Cores.ambarAlerta),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'As permissões atuais já estão pré-selecionadas. '
                                      'Altere conforme necessário e confirme.',
                                      style: Tipografia.bodySmall.copyWith(
                                          color: Cores.ambarAlerta),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Administrador do Cliente',
                                style: TextStyle(fontWeight: FontWeight.bold),
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

                            if (!eAdminCliente) ...[
                              const Divider(height: 24),
                              const Text(
                                'Programas',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
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
                                  style: TextStyle(color: Cores.cinzaMedio),
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
                                          programasSelecionados.remove(progId);
                                        }
                                      });
                                    },
                                  );
                                }),

                              const Divider(height: 24),
                              const Text(
                                'Projetos individuais',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
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
                                  style: TextStyle(color: Cores.cinzaMedio),
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
                                          projetosSelecionados.remove(projId);
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
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.save, size: 16),
                  label: const Text('Salvar Permissões'),
                  onPressed: carregandoOpcoes
                      ? null
                      : () async {
                          if (!eAdminCliente &&
                              programasSelecionados.isEmpty &&
                              projetosSelecionados.isEmpty) {
                            setDialogState(() {
                              erroModal =
                                  'Selecione ao menos um nível de acesso ou remova o usuário completamente.';
                            });
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(dialogContext).pop();

                          final ok = await _viewModel.editarPermissoes(
                            usuario.user,
                            eAdminCliente: eAdminCliente,
                            programaIds: programasSelecionados.toList(),
                            projetoIds: projetosSelecionados.toList(),
                          );

                          if (mounted) {
                            final msg = ok
                                ? 'Permissões de $nomeUsuario atualizadas com sucesso.'
                                : (_viewModel.mensagemErro ??
                                    'Erro ao atualizar permissões.');
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
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarRemocaoUsuario(UsuarioClienteModel usuario) async {
    final nomeUsuario =
        usuario.userNome.isNotEmpty ? usuario.userNome : 'o usuário';
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Remover Acesso',
      mensagem:
          'Deseja remover TODOS os acessos de $nomeUsuario a este cliente? '
          'Isso inclui acesso de administrador, programas e projetos.',
    );

    if (!confirmou || !mounted) return;

    final ok = await _viewModel.removerUsuario(usuario.user);
    if (mounted) {
      final msg = ok
          ? 'Usuário removido com sucesso.'
          : (_viewModel.mensagemErro ?? 'Erro ao remover usuário.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? Cores.verdeSucesso : Cores.vermelhoErro,
        ),
      );
    }
  }

  Widget _secaoAdminsGeRelat() {
    final admins = _viewModel.membrosGeRelat;

    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final telaPequena = constraints.maxWidth < 650;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.shield_check, color: Cores.azulAcao),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Administradores da Plataforma GeRelat',
                          style: Tipografia.titleLarge.copyWith(
                            color: Cores.textoPrincipal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Cores.fundoSecao,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${admins.length}',
                          style: Tipografia.labelMedium.copyWith(
                            color: Cores.cinzaEscuro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!telaPequena) ...[
                        const SizedBox(width: 16),
                        BotaoPrimario(
                          texto: 'Novo Admin GeRelat',
                          icone: LucideIcons.user_plus,
                          onPressed: _exibirDialogoNovoAdminGeRelat,
                        ),
                      ],
                    ],
                  ),
                  if (telaPequena) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: BotaoPrimario(
                        texto: 'Novo Admin GeRelat',
                        icone: LucideIcons.user_plus,
                        onPressed: _exibirDialogoNovoAdminGeRelat,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Usuários com nível total de administração sobre todos os clientes e dados da plataforma.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
          ),
          const SizedBox(height: 16),
          if (admins.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhum Administrador GeRelat encontrado.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: admins.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Cores.bordaSutil),
              itemBuilder: (context, index) {
                return _itemAdminGeRelat(admins[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _itemAdminGeRelat(MembroGeRelatModel membro) {
    final usuarioLogadoId = widget.sessaoViewModel.usuarioAtual?.id;
    final eOProprioUsuario =
        usuarioLogadoId != null && membro.user == usuarioLogadoId;
    final nomeUsuario = membro.userNome.isNotEmpty
        ? membro.userNome
        : (membro.userEmail.isNotEmpty ? membro.userEmail : 'Usuário #${membro.user}');
    final totalAdmins = _viewModel.membrosGeRelat.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Cores.azulAcao.withValues(alpha: 0.1),
            child: const Icon(LucideIcons.shield, color: Cores.azulAcao, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      nomeUsuario,
                      style: Tipografia.titleMedium.copyWith(
                        color: Cores.textoPrincipal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (eOProprioUsuario)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Cores.azulAcao.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Você',
                          style: Tipografia.bodySmall.copyWith(
                            color: Cores.azulAcao,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (membro.userEmail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      membro.userEmail,
                      style: Tipografia.bodySmall
                          .copyWith(color: Cores.cinzaMedio),
                    ),
                  ),
                const SizedBox(height: 6),
                _badge('Admin GeRelat', Cores.azulAcao, LucideIcons.shield_check),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: totalAdmins <= 1
                ? 'Não é possível remover o único admin'
                : (eOProprioUsuario
                    ? 'Você não pode remover o próprio acesso aqui'
                    : 'Remover Admin GeRelat'),
            onPressed: eOProprioUsuario || totalAdmins <= 1
                ? null
                : () => _confirmarRemocaoAdminGeRelat(membro),
            icon: Icon(
              LucideIcons.trash_2,
              size: 18,
              color: (eOProprioUsuario || totalAdmins <= 1)
                  ? Cores.cinzaMedio
                  : Cores.vermelhoErro,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exibirDialogoNovoAdminGeRelat() async {
    await _viewModel.carregarUsuariosDisponiveisGeRelat();
    if (!mounted) return;

    int? usuarioSelecionadoId;
    String? erroModal;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final disponiveis = _viewModel.usuariosDisponiveisGeRelat;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(LucideIcons.user_plus, color: Cores.azulAcao),
                  SizedBox(width: 10),
                  Text('Novo Admin GeRelat'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecione um usuário para conceder acesso de Administrador da Plataforma GeRelat.',
                      style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
                    ),
                    const SizedBox(height: 16),
                    if (disponiveis.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Todos os usuários cadastrados já possuem acesso de Admin GeRelat.',
                          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
                        ),
                      )
                    else ...[
                      Text(
                        'Usuário',
                        style: Tipografia.labelMedium.copyWith(
                          color: Cores.textoPrincipal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: usuarioSelecionadoId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Selecione o usuário...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: disponiveis.map((u) {
                          final rotulo = u.nome.isNotEmpty
                              ? '${u.nome} (${u.email})'
                              : u.email;
                          return DropdownMenuItem<int>(
                            value: u.id,
                            child: Text(rotulo, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            usuarioSelecionadoId = val;
                            erroModal = null;
                          });
                        },
                      ),
                    ],
                    if (erroModal != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        erroModal!,
                        style: const TextStyle(color: Cores.vermelhoErro),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                if (disponiveis.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Promover a Admin'),
                    onPressed: () async {
                      if (usuarioSelecionadoId == null) {
                        setDialogState(() {
                          erroModal = 'Selecione um usuário para continuar.';
                        });
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(dialogContext).pop();

                      final ok = await _viewModel.promoverAdminGeRelat(usuarioSelecionadoId!);
                      if (mounted) {
                        final msg = ok
                            ? 'Administrador do GeRelat adicionado com sucesso.'
                            : (_viewModel.mensagemErro ?? 'Erro ao adicionar Admin GeRelat.');
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: ok ? Cores.verdeSucesso : Cores.vermelhoErro,
                          ),
                        );
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarRemocaoAdminGeRelat(MembroGeRelatModel membro) async {
    final nomeUsuario = membro.userNome.isNotEmpty
        ? membro.userNome
        : (membro.userEmail.isNotEmpty ? membro.userEmail : 'o usuário');

    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Remover Admin GeRelat',
      mensagem:
          'Deseja remover o acesso de Administrador da Plataforma GeRelat de $nomeUsuario? '
          'O usuário perderá os privilégios globais de administração.',
    );

    if (!confirmou || !mounted) return;

    final ok = await _viewModel.removerAdminGeRelat(membro.id);
    if (mounted) {
      final msg = ok
          ? 'Administrador removido com sucesso.'
          : (_viewModel.mensagemErro ?? 'Erro ao remover Administrador.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? Cores.verdeSucesso : Cores.vermelhoErro,
        ),
      );
    }
  }
}

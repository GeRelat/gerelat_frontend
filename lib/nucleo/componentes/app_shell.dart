import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/nucleo/servicos/cliente_http.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

enum SecaoApp {
  dashboard,
  clientes,
  membros,
  programas,
  variaveis,
  eventos,
  relatorios,
  templates,
  assets,
  configuracoes,
}

class AppShell extends StatelessWidget {
  final SecaoApp secaoAtual;
  final String titulo;
  final Widget child;
  final SessaoViewModel sessao;

  const AppShell({
    super.key,
    required this.secaoAtual,
    required this.titulo,
    required this.child,
    required this.sessao,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessao,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Abaixo de 800 px, o sistema utiliza o layout móvel.
            final telaPequena = constraints.maxWidth < 800;

            if (telaPequena) {
              return _construirLayoutCelular();
            }

            return _construirLayoutDesktop();
          },
        );
      },
    );
  }

  /// Layout utilizado em celulares e tablets menores.
  ///
  /// O menu lateral deixa de ocupar espaço fixo e passa a ser um Drawer.
  Widget _construirLayoutCelular() {
    return Scaffold(
      backgroundColor: Cores.fundoCanvas,
      drawer: Drawer(
        width: 280,
        backgroundColor: Cores.fundoDestaqueSutil,
        child: SafeArea(
          child: _SideNav(
            secaoAtual: secaoAtual,
            sessao: sessao,
            fecharAoNavegar: true,
          ),
        ),
      ),
      body: Column(
        children: [
          _TopAppBar(titulo: titulo, sessao: sessao, exibirBotaoMenu: true),
          Expanded(
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }

  /// Layout utilizado em computadores e telas maiores.
  Widget _construirLayoutDesktop() {
    return Scaffold(
      backgroundColor: Cores.fundoCanvas,
      body: Row(
        children: [
          _SideNav(secaoAtual: secaoAtual, sessao: sessao),
          Expanded(
            child: Column(
              children: [
                _TopAppBar(titulo: titulo, sessao: sessao),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  final String titulo;
  final SessaoViewModel sessao;
  final bool exibirBotaoMenu;

  const _TopAppBar({
    required this.titulo,
    required this.sessao,
    this.exibirBotaoMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: exibirBotaoMenu ? 12 : 32),
      decoration: BoxDecoration(
        color: Cores.branco.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          if (exibirBotaoMenu)
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'Abrir menu',
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(LucideIcons.menu, size: 22),
                  color: Cores.textoPrincipal,
                  style: IconButton.styleFrom(
                    backgroundColor: Cores.fundoSecao,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),

          if (exibirBotaoMenu) const SizedBox(width: 8),

          // Fundo transparente e estados de hover/focus/pressed padrão do
          // Material — igual aos demais IconButton do app (ex.: editar/
          // excluir nos cartões de lista), sem o `style` "quadrado" usado
          // pelo botão de menu acima.
          Builder(
            builder: (context) {
              bool podeVoltar = false;
              try {
                podeVoltar = context.canPop();
              } catch (_) {
                podeVoltar = false;
              }
              if (!podeVoltar) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Voltar',
                  onPressed: () {
                    try {
                      context.pop();
                    } catch (_) {}
                  },
                  icon: const Icon(LucideIcons.arrow_left, size: 20),
                  color: Cores.textoPrincipal,
                ),
              );
            },
          ),

          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: exibirBotaoMenu
                  ? Tipografia.titleLargeDestaque.copyWith(
                      color: Cores.textoPrincipal,
                    )
                  : Tipografia.headlineSmall.copyWith(
                      color: Cores.textoPrincipal,
                      fontWeight: FontWeight.w800,
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // No celular, alguns ícones são ocultados para evitar overflow.
          if (!exibirBotaoMenu) ...[
            IconButton(
              tooltip: 'Notificações',
              onPressed: () => _exibirModalNotificacoes(context),
              icon: const Icon(LucideIcons.bell, size: 20),
              color: Cores.cinzaEscuro,
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Ajuda',
              onPressed: () => _exibirModalAjuda(context),
              icon: const Icon(Icons.help_outline, size: 20),
              color: Cores.cinzaEscuro,
            ),
            const SizedBox(width: 12),
          ],

          _MenuPerfilAvatar(sessao: sessao),
        ],
      ),
    );
  }

  void _exibirModalNotificacoes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Cores.branco,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Cores.azulAcao.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.bell,
                            size: 20,
                            color: Cores.azulAcao,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Notificações',
                          style: Tipografia.titleLarge.copyWith(
                            color: Cores.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 20, color: Cores.cinzaEscuro),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Cores.fundoCanvas,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.bell_off,
                      size: 32,
                      color: Cores.cinzaMedio,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ainda não há notificações',
                  style: Tipografia.titleMedium.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Você receberá alertas sobre relatórios, agendamentos e atualizações por aqui.',
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azulAcao,
                      foregroundColor: Cores.branco,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Entendido',
                      style: Tipografia.labelLarge.copyWith(color: Cores.branco),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exibirModalAjuda(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Cores.branco,
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Cores.azulAcao.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            size: 20,
                            color: Cores.azulAcao,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Precisa de ajuda?',
                          style: Tipografia.titleLarge.copyWith(
                            color: Cores.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 20, color: Cores.cinzaEscuro),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Estamos à disposição para ajudar. Se você precisar de auxílio ou tiver qualquer dúvida sobre o sistema, envie um e-mail para:',
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Cores.fundoCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Cores.bordaSutil),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Cores.branco,
                          shape: BoxShape.circle,
                          border: Border.all(color: Cores.bordaSutil),
                        ),
                        child: const Icon(
                          LucideIcons.mail,
                          size: 20,
                          color: Cores.azulAcao,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suporte GeRelat',
                              style: Tipografia.bodySmall.copyWith(
                                color: Cores.cinzaEscuro,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              'contato@gerelat.tech',
                              style: Tipografia.titleMedium.copyWith(
                                color: Cores.azulAcao,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar e-mail',
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: 'contato@gerelat.tech'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('E-mail copiado para a área de transferência!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(
                          LucideIcons.copy,
                          size: 18,
                          color: Cores.cinzaEscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azulAcao,
                      foregroundColor: Cores.branco,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Entendido',
                      style: Tipografia.labelLarge.copyWith(color: Cores.branco),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Um item de navegação da sidebar: ícone, rótulo, [SecaoApp] que ele
/// representa (para destacar como ativo) e rota para onde navega.
///
/// Mantido como dado (não widget) para que os itens do menu principal
/// possam ser declarados numa lista só, em vez de repetir a construção de
/// `_NavItem` uma vez por item.
typedef _ItemMenu = ({
  IconData icone,
  String rotulo,
  SecaoApp secao,
  String rota,
});

const _itensMenuPrincipal = <_ItemMenu>[
  (
    icone: LucideIcons.house,
    rotulo: 'Dashboard',
    secao: SecaoApp.dashboard,
    rota: '/dashboard',
  ),
  (
    icone: LucideIcons.building_2,
    rotulo: 'Clientes',
    secao: SecaoApp.clientes,
    rota: '/clientes',
  ),
  (
    icone: LucideIcons.users,
    rotulo: 'Membros',
    secao: SecaoApp.membros,
    rota: '/clientes/membros',
  ),
  (
    icone: LucideIcons.folder_kanban,
    rotulo: 'Programas',
    secao: SecaoApp.programas,
    rota: '/programas',
  ),
  (
    icone: LucideIcons.variable,
    rotulo: 'Variáveis',
    secao: SecaoApp.variaveis,
    rota: '/variaveis',
  ),
  (
    icone: LucideIcons.calendar,
    rotulo: 'Eventos',
    secao: SecaoApp.eventos,
    rota: '/eventos',
  ),
  (
    icone: LucideIcons.file_text,
    rotulo: 'Relatórios',
    secao: SecaoApp.relatorios,
    rota: '/relatorios',
  ),
  (
    icone: LucideIcons.copy,
    rotulo: 'Templates',
    secao: SecaoApp.templates,
    rota: '/templates',
  ),
  (
    icone: LucideIcons.image,
    rotulo: 'Imagens',
    secao: SecaoApp.assets,
    rota: '/assets',
  ),
];

class _SideNav extends StatelessWidget {
  final SecaoApp secaoAtual;
  final SessaoViewModel sessao;

  /// Quando verdadeiro, fecha o Drawer antes de navegar.
  final bool fecharAoNavegar;

  const _SideNav({
    required this.secaoAtual,
    required this.sessao,
    this.fecharAoNavegar = false,
  });

  Widget _construirSeletorContexto(BuildContext context) {
    final usuario = sessao.usuarioAtual;
    final clientes = usuario?.todosClientesDisponiveis ?? [];
    final clienteAtivoId = sessao.clienteAtivoId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Cores.bordaSutil),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.building, size: 14, color: Cores.cinzaEscuro),
              const SizedBox(width: 6),
              Text(
                'ORGANIZAÇÃO',
                style: Tipografia.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Cores.cinzaEscuro,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (clientes.isNotEmpty)
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: ValueKey(clienteAtivoId),
                value: clientes.any((c) => c.id == clienteAtivoId) ? clienteAtivoId : clientes.first.id,
                isExpanded: true,
                icon: const Icon(LucideIcons.chevron_down, size: 16),
                items: clientes.map((c) {
                  final nomeExibicao = (c.nome.isNotEmpty && !c.nome.startsWith('Cliente #'))
                      ? c.nome
                      : 'Cliente #${c.id}';
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(
                      nomeExibicao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tipografia.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Cores.textoPrincipal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (novoId) {
                  if (novoId != null) {
                    sessao.selecionarCliente(novoId);
                  }
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Nenhum cliente ativo',
                style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
              ),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: Cores.bordaSutil),
            ),
            onPressed: () {
              context.go('/solicitar-acesso');
            },
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Solicitar outro cliente', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessao,
      builder: (context, _) {
        final usuario = sessao.usuarioAtual;
        final itensFiltrados = _itensMenuPrincipal.where((item) {
          if (item.secao == SecaoApp.clientes && usuario?.isAdminGeRelat != true) {
            return false;
          }
          return true;
        }).toList();

        return Container(
          width: 256,
          color: Cores.fundoDestaqueSutil,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: Image(
                        image: AssetImage(
                          'assets/images/logo_gerelat_icone_azul.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GeRelat',
                      style: Tipografia.titleLargeDestaque.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),

              _construirSeletorContexto(context),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final item in itensFiltrados)
                      _NavItem(
                        icon: item.icone,
                        label: item.rotulo,
                        ativo: secaoAtual == item.secao,
                        onTap: () {
                          _navegar(context, item.rota);
                        },
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Cores.bordaSutil),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  children: [
                    _NavItem(
                      icon: LucideIcons.settings,
                      label: 'Configurações',
                      ativo: secaoAtual == SecaoApp.configuracoes,
                      onTap: () {
                        _navegar(context, '/configuracoes');
                      },
                    ),
                    _NavItem(
                      icon: LucideIcons.log_out,
                      label: 'Sair',
                      ativo: false,
                      onTap: () {
                        _sair(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Fecha o Drawer, quando necessário, e depois realiza a navegação.
  void _navegar(BuildContext context, String rota) {
    if (fecharAoNavegar) {
      Navigator.of(context).pop();
    }

    context.go(rota);
  }

  Future<void> _sair(BuildContext context) async {
    if (fecharAoNavegar) {
      Navigator.of(context).pop();
    }

    final saiu = await sessao.sair();

    if (!saiu || !context.mounted) {
      return;
    }

    context.go('/login');
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: ativo ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: ativo ? Cores.azulAcao : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.bodyMedium.copyWith(
                      color: ativo ? Cores.azulAcao : const Color(0xFF475569),
                      fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuPerfilAvatar extends StatefulWidget {
  final SessaoViewModel sessao;

  const _MenuPerfilAvatar({required this.sessao});

  @override
  State<_MenuPerfilAvatar> createState() => _MenuPerfilAvatarState();
}

class _MenuPerfilAvatarState extends State<_MenuPerfilAvatar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool get _menuAberto => _overlayEntry != null;

  void _alternarMenu() {
    if (_menuAberto) {
      _fecharMenu();
    } else {
      _abrirMenu();
    }
  }

  void _fecharMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  void _abrirMenu() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _fecharMenu,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            width: 250,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: Material(
                color: Colors.transparent,
                child: _CardMenuPerfil(
                  sessao: widget.sessao,
                  aoFechar: _fecharMenu,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.sessao.usuarioAtual;
    final clienteAtivoId = widget.sessao.clienteAtivoId;
    final clientes = usuario?.todosClientesDisponiveis ?? [];

    ItemContextoCliente? clienteAtivo;
    if (clienteAtivoId != null) {
      for (final c in clientes) {
        if (c.id == clienteAtivoId) {
          clienteAtivo = c;
          break;
        }
      }
    }
    clienteAtivo ??= clientes.isNotEmpty ? clientes.first : null;

    final logoUrl = clienteAtivo?.logomarca.trim() ?? '';
    final temLogo = logoUrl.isNotEmpty;
    final urlCompleta = logoUrl.startsWith('http')
        ? logoUrl
        : '${ClienteHttp.urlBasePadrao}$logoUrl';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'Perfil e Configurações',
        child: InkWell(
          onTap: _alternarMenu,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 36,
            height: 36,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Cores.azulAcao.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _menuAberto ? Cores.azulAcao : Cores.bordaSutil,
                width: 1.5,
              ),
            ),
            child: temLogo
                ? Image.network(
                    urlCompleta,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        LucideIcons.user,
                        size: 18,
                        color: Cores.azulAcao,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      LucideIcons.user,
                      size: 18,
                      color: Cores.azulAcao,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CardMenuPerfil extends StatelessWidget {
  final SessaoViewModel sessao;
  final VoidCallback aoFechar;

  const _CardMenuPerfil({
    required this.sessao,
    required this.aoFechar,
  });

  @override
  Widget build(BuildContext context) {
    final usuario = sessao.usuarioAtual;
    final clienteAtivoId = sessao.clienteAtivoId;
    final clientes = usuario?.todosClientesDisponiveis ?? [];

    ItemContextoCliente? clienteAtivo;
    if (clienteAtivoId != null) {
      for (final c in clientes) {
        if (c.id == clienteAtivoId) {
          clienteAtivo = c;
          break;
        }
      }
    }
    clienteAtivo ??= clientes.isNotEmpty ? clientes.first : null;

    final nomeOrganizacao = (clienteAtivo != null &&
            clienteAtivo.nome.isNotEmpty &&
            !clienteAtivo.nome.startsWith('Cliente #'))
        ? clienteAtivo.nome
        : (clientes.isNotEmpty ? clientes.first.nome : 'Sem organização');

    final nomeUsuario = (usuario != null && usuario.nomeCompleto.isNotEmpty)
        ? usuario.nomeCompleto
        : 'Usuário';

    final logoUrl = clienteAtivo?.logomarca.trim() ?? '';
    final temLogo = logoUrl.isNotEmpty;
    final urlCompleta = logoUrl.startsWith('http')
        ? logoUrl
        : '${ClienteHttp.urlBasePadrao}$logoUrl';

    final eAdmin = usuario != null &&
        (usuario.isAdminGeRelat ||
            usuario.isAdminCliente ||
            usuario.eAdminDoCliente(clienteAtivoId));

    final cargo = eAdmin ? 'Administrador' : 'Membro';

    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 12,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Cores.branco,
                border: Border(
                  top: BorderSide(color: Cores.bordaSutil),
                  left: BorderSide(color: Cores.bordaSutil),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 250,
            decoration: BoxDecoration(
              color: Cores.branco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Cores.bordaSutil),
              boxShadow: [
                BoxShadow(
                  color: Cores.pretoProfundo.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Cores.azulAcao.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: temLogo
                          ? Image.network(
                              urlCompleta,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  LucideIcons.user,
                                  size: 22,
                                  color: Cores.azulAcao,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                LucideIcons.user,
                                size: 22,
                                color: Cores.azulAcao,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeOrganizacao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Tipografia.bodySmall.copyWith(
                              color: Cores.cinzaEscuro,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nomeUsuario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Tipografia.titleMedium.copyWith(
                              fontSize: 14,
                              color: Cores.textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: eAdmin
                                  ? Cores.azulAcao.withValues(alpha: 0.1)
                                  : Cores.cinzaCampo,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cargo,
                              style: Tipografia.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: eAdmin
                                    ? Cores.azulAcao
                                    : Cores.cinzaEscuro,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: Cores.bordaSutil),
                const SizedBox(height: 8),
                _ItemMenuPerfil(
                  icone: LucideIcons.settings,
                  rotulo: 'Configurações',
                  onTap: () {
                    aoFechar();
                    context.go('/configuracoes');
                  },
                ),
                _ItemMenuPerfil(
                  icone: LucideIcons.log_out,
                  rotulo: 'Sair',
                  cor: Cores.vermelhoErro,
                  onTap: () async {
                    aoFechar();
                    await sessao.sair();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemMenuPerfil extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final Color? cor;
  final VoidCallback onTap;

  const _ItemMenuPerfil({
    required this.icone,
    required this.rotulo,
    this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = cor ?? Cores.textoPrincipal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icone, size: 18, color: corTexto),
            const SizedBox(width: 12),
            Text(
              rotulo,
              style: Tipografia.bodyMedium.copyWith(
                color: corTexto,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

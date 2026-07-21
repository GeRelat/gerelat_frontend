import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

enum SecaoApp { dashboard, clientes, programas, variaveis, eventos, relatorios, templates, assets, configuracoes }

class AppShell extends StatelessWidget {
  final SecaoApp secaoAtual;
  final String titulo;
  final Widget child;

  const AppShell({super.key, required this.secaoAtual, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
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
  }

  /// Layout utilizado em celulares e tablets menores.
  ///
  /// O menu lateral deixa de ocupar espaço fixo e passa a ser um Drawer.
  Widget _construirLayoutCelular() {
    return Scaffold(
      backgroundColor: Cores.fundoCanvas,
      drawer: Drawer(
        width: 280,
        backgroundColor: const Color(0xFFF1F5F9),
        child: SafeArea(child: _SideNav(secaoAtual: secaoAtual, fecharAoNavegar: true)),
      ),
      body: Column(
        children: [
          _TopAppBar(titulo: titulo, exibirBotaoMenu: true),
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
          _SideNav(secaoAtual: secaoAtual),
          Expanded(
            child: Column(
              children: [
                _TopAppBar(titulo: titulo),
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
  final bool exibirBotaoMenu;

  const _TopAppBar({required this.titulo, this.exibirBotaoMenu = false});

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),

          if (exibirBotaoMenu) const SizedBox(width: 8),

          if (context.canPop())
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Voltar',
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(LucideIcons.arrow_left, size: 20),
                color: Cores.textoPrincipal,
                style: IconButton.styleFrom(
                  backgroundColor: Cores.fundoSecao,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: exibirBotaoMenu ? Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w800) : Tipografia.headlineSmall.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(width: 8),

          // No celular, alguns ícones são ocultados para evitar overflow.
          if (!exibirBotaoMenu) ...[const Icon(LucideIcons.bell, size: 20, color: Cores.cinzaEscuro), const SizedBox(width: 16), const Icon(Icons.help_outline, size: 20, color: Cores.cinzaEscuro), const SizedBox(width: 16)],

          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Cores.cinzaCampo, borderRadius: BorderRadius.circular(999)),
            child: ClipOval(child: Image.asset('assets/images/logo_brisa.png', fit: BoxFit.contain)),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final SecaoApp secaoAtual;

  /// Quando verdadeiro, fecha o Drawer antes de navegar.
  final bool fecharAoNavegar;

  const _SideNav({required this.secaoAtual, this.fecharAoNavegar = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Cores.azulAcao, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.chart_bar, color: Cores.branco),
                ),
                const SizedBox(width: 12),
                Text(
                  'GeRelat',
                  style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _NavItem(
                  icon: LucideIcons.house,
                  label: 'Dashboard',
                  ativo: secaoAtual == SecaoApp.dashboard,
                  onTap: () {
                    _navegar(context, '/dashboard');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.building_2,
                  label: 'Clientes',
                  ativo: secaoAtual == SecaoApp.clientes,
                  onTap: () {
                    _navegar(context, '/clientes');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.folder_kanban,
                  label: 'Programas',
                  ativo: secaoAtual == SecaoApp.programas,
                  onTap: () {
                    _navegar(context, '/programas');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.variable,
                  label: 'Variáveis',
                  ativo: secaoAtual == SecaoApp.variaveis,
                  onTap: () {
                    _navegar(context, '/projetos/campos');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.calendar,
                  label: 'Eventos',
                  ativo: secaoAtual == SecaoApp.eventos,
                  onTap: () {
                    _navegar(context, '/eventos');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.file_text,
                  label: 'Relatórios',
                  ativo: secaoAtual == SecaoApp.relatorios,
                  onTap: () {
                    _navegar(context, '/relatorios');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.copy,
                  label: 'Templates',
                  ativo: secaoAtual == SecaoApp.templates,
                  onTap: () {
                    _navegar(context, '/templates');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.image,
                  label: 'Imagens',
                  ativo: secaoAtual == SecaoApp.assets,
                  onTap: () {
                    _navegar(context, '/assets');
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

    final saiu = await DependenciasApp.instancia.sessao.sair();

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

  const _NavItem({required this.icon, required this.label, required this.ativo, required this.onTap});

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
                Icon(icon, size: 19, color: ativo ? Cores.azulAcao : const Color(0xFF64748B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.bodyMedium.copyWith(color: ativo ? Cores.azulAcao : const Color(0xFF475569), fontWeight: ativo ? FontWeight.w700 : FontWeight.w500),
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

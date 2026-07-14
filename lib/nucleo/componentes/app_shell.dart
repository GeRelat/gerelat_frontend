import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

enum SecaoApp {
  dashboard,
  clientes,
  programas,
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

  const AppShell({
    super.key,
    required this.secaoAtual,
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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

  const _TopAppBar({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Cores.branco.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          if (context.canPop())
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.pop(),
                icon: const Icon(LucideIcons.arrow_left, size: 20),
                color: Cores.textoPrincipal,
                style: IconButton.styleFrom(
                  backgroundColor: Cores.fundoSecao,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Text(
            titulo,
            style: Tipografia.headlineSmall.copyWith(
              color: Cores.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const Icon(LucideIcons.bell, size: 20, color: Cores.cinzaEscuro),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline, size: 20, color: Cores.cinzaEscuro),
          const SizedBox(width: 16),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Cores.cinzaCampo,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_brisa.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final SecaoApp secaoAtual;

  const _SideNav({required this.secaoAtual});

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
                  decoration: BoxDecoration(
                    color: Cores.azulAcao,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.chart_bar, color: Cores.branco),
                ),
                const SizedBox(width: 12),
                Text(
                  'GeRelat',
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                    fontWeight: FontWeight.w800,
                  ),
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
                  onTap: () => context.go('/dashboard'),
                ),
                _NavItem(
                  icon: LucideIcons.building_2,
                  label: 'Clientes',
                  ativo: secaoAtual == SecaoApp.clientes,
                  onTap: () => context.go('/clientes'),
                ),
                _NavItem(
                  icon: LucideIcons.folder_kanban,
                  label: 'Programas',
                  ativo: secaoAtual == SecaoApp.programas,
                  onTap: () => context.go('/programas'),
                ),
                _NavItem(
                  icon: LucideIcons.calendar,
                  label: 'Eventos',
                  ativo: secaoAtual == SecaoApp.eventos,
                  onTap: () => context.go('/eventos'),
                ),
                _NavItem(
                  icon: LucideIcons.file_text,
                  label: 'Relatorios',
                  ativo: secaoAtual == SecaoApp.relatorios,
                  onTap: () => context.go('/relatorios'),
                ),
                _NavItem(
                  icon: LucideIcons.copy,
                  label: 'Templates',
                  ativo: secaoAtual == SecaoApp.templates,
                  onTap: () => context.go('/templates'),
                ),
                _NavItem(
                  icon: LucideIcons.image,
                  label: 'Imagens',
                  ativo: secaoAtual == SecaoApp.assets,
                  onTap: () => context.go('/assets'),
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
                  label: 'Configuracoes',
                  ativo: secaoAtual == SecaoApp.configuracoes,
                  onTap: () => context.go('/configuracoes'),
                ),
                _NavItem(
                  icon: LucideIcons.log_out,
                  label: 'Sair',
                  ativo: false,
                  onTap: () => _sair(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final saiu = await DependenciasApp.instancia.sessao.sair();
    if (!saiu) return;
    if (!context.mounted) return;
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

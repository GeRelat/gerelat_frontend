import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/dashboard/dashboard.dart';
import 'package:gerelat_frontend/paginas/eventos/pagina_eventos.dart';
import 'package:gerelat_frontend/paginas/login/pagina_login.dart';
import 'package:gerelat_frontend/paginas/programas/pagina_programas.dart';
import 'package:gerelat_frontend/paginas/relatorios/pagina_relatorios.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_templates.dart';

enum SecaoApp { dashboard, programas, eventos, relatorios, templates }

class AppShell extends StatelessWidget {
  final SecaoApp secaoAtual;
  final String titulo;
  final String dicaPesquisa;
  final Widget child;

  const AppShell({
    super.key,
    required this.secaoAtual,
    required this.titulo,
    required this.child,
    this.dicaPesquisa = 'Pesquisar...',
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
                _TopAppBar(titulo: titulo, dicaPesquisa: dicaPesquisa),
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
  final String dicaPesquisa;

  const _TopAppBar({required this.titulo, required this.dicaPesquisa});

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
          Text(
            titulo,
            style: Tipografia.headlineSmall.copyWith(
              color: Cores.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Cores.cinzaCampo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: Cores.cinzaEscuro,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dicaPesquisa,
                      overflow: TextOverflow.ellipsis,
                      style: Tipografia.bodyMedium.copyWith(
                        color: Cores.cinzaMedio,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
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
                  onTap: () => _abrir(context, const DashboardPage()),
                ),
                _NavItem(
                  icon: LucideIcons.folder_kanban,
                  label: 'Programas',
                  ativo: secaoAtual == SecaoApp.programas,
                  onTap: () => _abrir(context, const PaginaProgramas()),
                ),
                _NavItem(
                  icon: LucideIcons.calendar,
                  label: 'Eventos',
                  ativo: secaoAtual == SecaoApp.eventos,
                  onTap: () => _abrir(context, const PaginaEventos()),
                ),
                _NavItem(
                  icon: LucideIcons.file_text,
                  label: 'Relatorios',
                  ativo: secaoAtual == SecaoApp.relatorios,
                  onTap: () => _abrir(context, const PaginaRelatorios()),
                ),
                _NavItem(
                  icon: LucideIcons.copy,
                  label: 'Templates',
                  ativo: secaoAtual == SecaoApp.templates,
                  onTap: () => _abrir(context, const PaginaTemplates()),
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
                  ativo: false,
                  onTap: () {},
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

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => pagina));
  }

  Future<void> _sair(BuildContext context) async {
    final viewModel = SessaoViewModel(
      DependenciasApp.instancia.repositorioAutenticacao,
    );
    final saiu = await viewModel.sair();
    viewModel.dispose();
    if (!saiu) return;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PaginaLogin()),
      (_) => false,
    );
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

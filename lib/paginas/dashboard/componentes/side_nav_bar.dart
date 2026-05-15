import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class SideNavBar extends StatelessWidget {
  const SideNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cores.cinzaNavFundo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirLogo(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ItemNav(icone: Icons.dashboard_outlined, rotulo: 'Dashboard', ativo: true, onPressed: null),
                  _ItemNav(icone: Icons.folder_outlined, rotulo: 'Programas', onPressed: null),
                  _ItemNav(icone: Icons.event_outlined, rotulo: 'Eventos', onPressed: null),
                  _ItemNav(icone: Icons.bar_chart_outlined, rotulo: 'Relatórios', onPressed: null),
                  _ItemNav(icone: Icons.description_outlined, rotulo: 'Templates', onPressed: null),
                ],
              ),
            ),
          ),
          _construirRodape(),
        ],
      ),
    );
  }

  Widget _construirLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Cores.azulDashLink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined, color: Cores.branco, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'GeRelat',
            style: Tipografia.titleLarge.copyWith(
              color: Cores.azulDashNavAtivo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRodape() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Cores.cinzaNavBorda)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        children: const [
          _ItemNav(icone: Icons.settings_outlined, rotulo: 'Configurações', onPressed: null),
          _ItemNav(icone: Icons.logout, rotulo: 'Sair', onPressed: null),
        ],
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback? onPressed;

  const _ItemNav({
    required this.icone,
    required this.rotulo,
    this.ativo = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final corIcone = ativo ? Cores.azulDashNavAtivo : Cores.cinzaNavInativo;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: ativo
              ? BoxDecoration(
                  color: Cores.azulDashNavFundoAtivo,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icone, size: 18, color: corIcone),
              const SizedBox(width: 12),
              Text(
                rotulo,
                style: Tipografia.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: corIcone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

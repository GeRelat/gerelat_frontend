import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/cabecalho_dashboard.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/side_nav_bar.dart';

/// Shell compartilhado de todas as páginas do dashboard.
///
/// Uso:
///   return LayoutDashboard(
///     titulo: 'Programas',
///     corpo: SingleChildScrollView(child: ...),
///   );
///
/// O layout cuida automaticamente de:
///   - Sidebar fixa no desktop
///   - Drawer (menu hambúrguer) no mobile/tablet
///   - Cabeçalho com o título da página
///   - Fundo cinza da área de conteúdo
class LayoutDashboard extends StatelessWidget {
  final String titulo;
  final Widget corpo;

  const LayoutDashboard({
    super.key,
    required this.titulo,
    required this.corpo,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = Breakpoints.isSmallScreen(context);

    if (isSmall) {
      return Scaffold(
        backgroundColor: Colors.white,
        drawer: const Drawer(width: 256, child: SideNavBar()),
        body: _construirConteudo(context),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 256, child: SideNavBar()),
          Expanded(child: _construirConteudo(context)),
        ],
      ),
    );
  }

  Widget _construirConteudo(BuildContext context) {
    return Column(
      children: [
        CabecalhoDashboard(titulo: titulo),
        Expanded(
          child: ColoredBox(
            color: Cores.fundoPagina,
            child: corpo,
          ),
        ),
      ],
    );
  }
}

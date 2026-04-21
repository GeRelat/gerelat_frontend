import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Barra de navegação superior compartilhada entre as páginas.
/// Exibe o logo GeRelat centralizado com altura fixa de 64px.
class BarraTopo extends StatelessWidget implements PreferredSizeWidget {
  const BarraTopo({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Cores.branco,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: _construirLogo(),
    );
  }

  /// Logo "GeRelat" usando HeadlineSmall do design system (Poppins 24px)
  Widget _construirLogo() {
    return Text(
      'GeRelat',
      style: Tipografia.headlineSmall.copyWith(
        letterSpacing: -1.2,
        color: Cores.pretoProfundo,
      ),
    );
  }
}

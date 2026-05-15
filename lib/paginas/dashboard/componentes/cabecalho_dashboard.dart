import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/barra_pesquisa.dart';

/// Barra de navegação superior do dashboard.
/// Altura fixa de 64px com backdrop blur e sombra sutil.
class CabecalhoDashboard extends StatelessWidget {
  final String titulo;

  const CabecalhoDashboard({super.key, this.titulo = 'Dashboard'});

  @override
  Widget build(BuildContext context) {
    final isSmall = Breakpoints.isSmallScreen(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 32),
          decoration: BoxDecoration(
            color: Cores.branco.withValues(alpha: 0.85),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              if (isSmall) ...[
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF424655)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                titulo,
                style: Tipografia.headlineSmall.copyWith(
                  color: const Color(0xFF191C1E),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const Spacer(),
              if (!isSmall) ...[
                const BarraPesquisa(),
                const SizedBox(width: 24),
              ],
              _construirBotaoIcone(Icons.notifications_outlined, 'Notificações'),
              const SizedBox(width: 4),
              _construirBotaoIcone(Icons.help_outline, 'Ajuda'),
              const SizedBox(width: 16),
              _construirAvatar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBotaoIcone(IconData icone, String tooltip) {
    return IconButton(
      onPressed: () {},
      tooltip: tooltip,
      icon: Icon(icone, color: Cores.cinzaEscuro, size: 20),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 36),
      ),
    );
  }

  Widget _construirAvatar() {
    return Container(
      width: 32,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Cores.cinzaAvatar,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_outline, size: 18, color: Cores.cinzaEscuro),
    );
  }
}

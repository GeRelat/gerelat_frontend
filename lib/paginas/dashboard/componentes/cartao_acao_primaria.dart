import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';

/// Card hero azul — ação principal do dashboard.
/// Ocupa ~2/3 da largura da seção de ações.
class CartaoAcaoPrimaria extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String rotuloBotao;
  final VoidCallback? onPressed;

  const CartaoAcaoPrimaria({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.rotuloBotao,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final padding = Breakpoints.isMobile(context) ? 24.0 : 48.0;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Cores.azulDash,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Círculo decorativo de brilho — canto superior direito
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Cores.branco.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final isSmall = Breakpoints.isSmallScreen(context);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _construirConteudo()),
                  if (!isSmall) ...[
                    const SizedBox(width: 48),
                    _construirPreview(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirConteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          titulo,
          style: Tipografia.headlineMedium.copyWith(
            color: Cores.branco,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descricao,
          style: Tipografia.bodyLarge.copyWith(
            color: Cores.azulDecoratvo.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Cores.branco,
            foregroundColor: Cores.azulDashLink,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          icon: Icon(Icons.arrow_forward, size: 16, color: Cores.azulDashLink),
          iconAlignment: IconAlignment.end,
          label: Text(
            rotuloBotao,
            style: Tipografia.labelLarge.copyWith(color: Cores.azulDashLink),
          ),
        ),
      ],
    );
  }

  Widget _construirPreview() {
    return Transform.rotate(
      angle: 0.052, // 3 graus em radianos
      child: Container(
        width: 224,
        height: 224,
        decoration: BoxDecoration(
          color: Cores.branco.withValues(alpha: 0.1),
          border: Border.all(color: Cores.branco.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.bar_chart, size: 80, color: Cores.branco.withValues(alpha: 0.5)),
      ),
    );
  }
}

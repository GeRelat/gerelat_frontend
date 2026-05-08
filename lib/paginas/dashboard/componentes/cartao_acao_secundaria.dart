import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Card de ação secundária — complementa o CartaoAcaoPrimaria.
class CartaoAcaoSecundaria extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String rotuloLink;
  final IconData icone;
  final VoidCallback? onPressed;

  const CartaoAcaoSecundaria({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.rotuloLink,
    required this.icone,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: ShapeDecoration(
        color: Cores.branco,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Cores.cinzaAzulado.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Cores.azulDashIconeFundo,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 24, color: Cores.azulDashLink),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            style: Tipografia.titleLarge.copyWith(
              color: Cores.pretoProfundo,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rotuloLink,
                    style: Tipografia.labelLarge.copyWith(
                      color: Cores.azulDashLink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 14, color: Cores.azulDashLink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

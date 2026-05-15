import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Card informativo da seção inferior do dashboard.
class CartaoInfo extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;

  const CartaoInfo({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Cores.cinzaInfoFundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.pretoProfundo,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Icon(icone, size: 24, color: Cores.azulDecoratvo),
        ],
      ),
    );
  }
}

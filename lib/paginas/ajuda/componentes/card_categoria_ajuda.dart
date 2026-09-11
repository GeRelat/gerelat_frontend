import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class CardCategoriaAjuda extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final VoidCallback onTap;

  const CardCategoriaAjuda({super.key, required this.titulo, required this.descricao, required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.branco,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Cores.bordaSutil),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Cores.azulAcao.withValues(alpha: 0.08)),
                child: Icon(icone, size: 28, color: Cores.azulAcao),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Tipografia.titleMedium.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      descricao,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              const Icon(Icons.chevron_right, size: 24, color: Cores.azulAcao),
            ],
          ),
        ),
      ),
    );
  }
}

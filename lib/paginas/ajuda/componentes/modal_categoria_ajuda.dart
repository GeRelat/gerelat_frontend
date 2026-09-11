import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

Future<void> mostrarModalCategoriaAjuda({required BuildContext context, required String titulo, required String descricao, required IconData icone, required List<String> topicos}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Cores.branco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Cores.azulAcao.withValues(alpha: 0.08)),
                      child: Icon(icone, color: Cores.azulAcao, size: 24),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        titulo,
                        style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w700),
                      ),
                    ),

                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Cores.cinzaEscuro),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(descricao, style: Tipografia.bodyLarge.copyWith(color: Cores.cinzaEscuro, height: 1.5)),

                const SizedBox(height: 24),

                Text(
                  'Nesta seção você encontra:',
                  style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 14),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final topico in topicos)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Cores.azulAcao.withValues(alpha: 0.08)),
                                  child: const Icon(Icons.check, size: 14, color: Cores.azulAcao),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(topico, style: Tipografia.bodyMedium.copyWith(color: Cores.textoPrincipal, height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azulAcao,
                      foregroundColor: Cores.branco,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

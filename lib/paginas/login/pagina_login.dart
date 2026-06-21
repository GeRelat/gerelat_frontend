import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/paginas/login/componentes/painel_direito.dart';
import 'package:gerelat_frontend/paginas/login/componentes/painel_esquerdo.dart';

class PaginaLogin extends StatelessWidget {
  const PaginaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layoutCompacto =
                constraints.maxWidth < 900 || constraints.maxHeight < 720;
            final larguraMaxima = layoutCompacto ? 560.0 : 1100.0;
            final alturaCard = math.max(
              520.0,
              math.min(660.0, constraints.maxHeight - 48),
            );

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: larguraMaxima),
                  child: SizedBox(
                    height: alturaCard,
                    child: _construirCardLogin(layoutCompacto: layoutCompacto),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirCardLogin({required bool layoutCompacto}) {
    return Container(
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Cores.pretoProfundo.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: layoutCompacto
            ? const PainelDireito()
            : const Row(
                children: [
                  Flexible(flex: 45, child: PainelEsquerdo()),
                  Flexible(flex: 55, child: PainelDireito()),
                ],
              ),
      ),
    );
  }
}

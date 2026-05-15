import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';
import 'package:gerelat_frontend/paginas/login/componentes/painel_direito.dart';
import 'package:gerelat_frontend/paginas/login/componentes/painel_esquerdo.dart';

/// Página principal de login do GeRelat.
/// Desktop/tablet (≥700px): dois painéis lado a lado.
/// Mobile (<700px): apenas o painel de formulário.
class PaginaLogin extends StatelessWidget {
  const PaginaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < Breakpoints.thresholdLogin) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: const PainelDireito(),
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 660),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _construirCardLogin(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card central com sombra contendo os dois painéis lado a lado
  Widget _construirCardLogin() {
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
        child: const Row(
          children: [
            Flexible(flex: 45, child: PainelEsquerdo()),
            Flexible(flex: 55, child: PainelDireito()),
          ],
        ),
      ),
    );
  }
}

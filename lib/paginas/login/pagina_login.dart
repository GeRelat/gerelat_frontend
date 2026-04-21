import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/paginas/login/componentes/painel_direito.dart';
import 'package:gerelat_frontend/paginas/login/componentes/painel_esquerdo.dart';

/// Página principal de login do GeRelat.
/// Layout dividido em dois painéis: azul (esquerda) e branco (direita).
class PaginaLogin extends StatelessWidget {
  const PaginaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      body: Center(
        child: ConstrainedBox(
          // Limita a largura máxima do card de login
          constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 660),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _construirCardLogin(),
          ),
        ),
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
        child: Row(
          children: [
            // Painel esquerdo azul — ocupa 45% da largura
            const Flexible(
              flex: 45,
              child: PainelEsquerdo(),
            ),
            // Painel direito branco com formulário — ocupa 55% da largura
            const Flexible(
              flex: 55,
              child: PainelDireito(),
            ),
          ],
        ),
      ),
    );
  }
}

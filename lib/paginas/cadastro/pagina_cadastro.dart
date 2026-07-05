import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/componentes/barra_topo.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/cadastro/componentes/formulario_cadastro.dart';
import 'package:go_router/go_router.dart';

/// Página de cadastro de novo usuário.
/// Layout: barra superior + card centralizado + rodapé.
class PaginaCadastro extends StatelessWidget {
  const PaginaCadastro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.pretoProfundo,
      appBar: const BarraTopo(),
      body: Column(
        children: [
          // Área principal com o card de cadastro centralizado
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 65,
                ),
                child: FormularioCadastro(
                  // Volta para a página de login ao clicar em "Fazer login"
                  aoClicarEmLogin: () => context.go('/login'),
                ),
              ),
            ),
          ),
          _construirRodape(),
        ],
      ),
    );
  }

  /// Rodapé com copyright em letras maiúsculas e opacidade reduzida
  Widget _construirRodape() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Opacity(
        opacity: 0.6,
        child: Text(
          '© 2026 GERELAT • GESTÃO E RELATÓRIOS INTELIGENTES',
          style: Tipografia.labelMedium.copyWith(
            letterSpacing: 0.6,
            color: Cores.cinzaMedio,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

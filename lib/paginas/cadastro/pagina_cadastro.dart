import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/componentes/barra_topo.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/cadastro/componentes/formulario_cadastro.dart';
import 'package:go_router/go_router.dart';

/// Página de cadastro de novo usuário.
///
/// Estrutura:
/// - barra superior;
/// - fundo claro;
/// - formulário centralizado;
/// - rolagem vertical;
/// - rodapé.
class PaginaCadastro extends StatelessWidget {
  const PaginaCadastro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo semelhante ao utilizado nas demais páginas do sistema.
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: const BarraTopo(),

      // Toda a página pode rolar quando não houver altura suficiente.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              // Impede que o formulário fique largo demais em telas grandes.
              constraints: const BoxConstraints(maxWidth: 512),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormularioCadastro(
                    // Retorna para a tela de login.
                    aoClicarEmLogin: () => context.go('/login'),
                  ),

                  const SizedBox(height: 24),

                  _construirRodape(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Rodapé da página de cadastro.
  Widget _construirRodape() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Opacity(
        opacity: 0.7,
        child: Text(
          '© 2026 GERELAT • GESTÃO E RELATÓRIOS INTELIGENTES',
          style: Tipografia.labelMedium.copyWith(letterSpacing: 0.6, color: Cores.cinzaMedio),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

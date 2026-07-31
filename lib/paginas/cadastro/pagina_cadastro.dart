import 'package:flutter/material.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
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
  final RepositorioAutenticacao repositorioAutenticacao;

  const PaginaCadastro({super.key, required this.repositorioAutenticacao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo semelhante ao utilizado nas demais páginas do sistema.
      backgroundColor: Cores.fundoPagina,

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
                    repositorioAutenticacao: repositorioAutenticacao,
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
          style: Tipografia.eyebrow.copyWith(color: Cores.cinzaMedio),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaNaoEncontrada extends StatelessWidget {
  final String rotaDestino;

  const PaginaNaoEncontrada({super.key, required this.rotaDestino});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoCanvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Página não encontrada',
              style: Tipografia.headlineSmall.copyWith(
                color: Cores.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O endereço acessado não existe.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(rotaDestino),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}

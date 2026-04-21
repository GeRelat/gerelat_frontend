import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/login/pagina_login.dart';

/// Ponto de entrada da aplicação GeRelat.
void main() {
  runApp(const AplicativoGeRelat());
}

/// Widget raiz da aplicação — configura tema e rota inicial.
class AplicativoGeRelat extends StatelessWidget {
  const AplicativoGeRelat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeRelat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00488D),
        // Aplica a tipografia do design system (Poppins + Roboto)
        textTheme: Tipografia.textTheme,
      ),
      // Página inicial é sempre o login
      home: const PaginaLogin(),
    );
  }
}

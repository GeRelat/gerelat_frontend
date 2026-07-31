import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/nucleo/navegacao/app_router.dart';
import 'package:gerelat_frontend/nucleo/navegacao/estrategia_url.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configurarEstrategiaUrl();

  final dependencias = DependenciasApp.instancia;
  await dependencias.sessao.inicializar();

  dependencias.clienteHttp.onSessaoExpirada = () async {
    dependencias.sessao.notificarMudancaAutenticacao();
  };

  runApp(const AplicativoGeRelat());
}

class AplicativoGeRelat extends StatelessWidget {
  const AplicativoGeRelat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GeRelat',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Cores.azulPrimario,
        textTheme: Tipografia.textTheme,
      ),
    );
  }
}

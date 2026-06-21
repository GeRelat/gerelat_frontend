import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/dashboard/dashboard.dart';
import 'package:gerelat_frontend/paginas/login/pagina_login.dart';

final navegadorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencias = DependenciasApp.instancia;
  final sessao = SessaoViewModel(dependencias.repositorioAutenticacao);
  await sessao.inicializar();

  dependencias.clienteHttp.onSessaoExpirada = () async {
    navegadorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PaginaLogin()),
      (_) => false,
    );
  };

  runApp(AplicativoGeRelat(sessao: sessao));
}

class AplicativoGeRelat extends StatelessWidget {
  final SessaoViewModel? sessao;

  const AplicativoGeRelat({super.key, this.sessao});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeRelat',
      debugShowCheckedModeBanner: false,
      navigatorKey: navegadorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00488D),
        textTheme: Tipografia.textTheme,
      ),
      home: (sessao?.estaAutenticado ?? false)
          ? const DashboardPage()
          : const PaginaLogin(),
    );
  }
}

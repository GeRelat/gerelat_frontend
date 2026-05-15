import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/componentes/estilo_botao.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Botão de ação principal do GeRelat.
/// Suporta estado de carregamento, ícone opcional e variante com gradiente.
class BotaoPrimario extends StatelessWidget {
  final String rotulo;
  final VoidCallback? onPressed;
  final bool carregando;
  final EstiloBotao estilo;
  final IconData? icone;
  final IconAlignment alinhamentoIcone;

  const BotaoPrimario({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.carregando = false,
    this.estilo = EstiloBotao.padrao,
    this.icone,
    this.alinhamentoIcone = IconAlignment.end,
  });

  bool get _temIcone => carregando || icone != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: estilo.altura,
      child: estilo.gradiente ? _construirComGradiente() : _construirSolido(),
    );
  }

  Widget _construirSolido() {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Cores.azulPrimario,
      foregroundColor: Cores.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(estilo.raio),
      ),
      elevation: 0,
    );

    if (_temIcone) {
      return ElevatedButton.icon(
        onPressed: carregando ? null : onPressed,
        style: style,
        icon: _construirIcone(),
        iconAlignment: alinhamentoIcone,
        label: _construirRotulo(),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: _construirRotulo(),
    );
  }

  Widget _construirComGradiente() {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: Cores.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(estilo.raio),
      ),
    );

    final child = _temIcone
        ? ElevatedButton.icon(
            onPressed: carregando ? null : onPressed,
            style: style,
            icon: _construirIcone(),
            iconAlignment: alinhamentoIcone,
            label: _construirRotulo(),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: _construirRotulo(),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Cores.azulGradienteInicio, Cores.azulGradienteFim],
        ),
        borderRadius: BorderRadius.circular(estilo.raio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _construirRotulo() {
    return Text(
      rotulo,
      style: Tipografia.titleMedium.copyWith(color: Cores.branco),
    );
  }

  Widget _construirIcone() {
    if (carregando) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(color: Cores.branco, strokeWidth: 2),
      );
    }
    return Icon(icone!, size: 14, color: Cores.branco);
  }
}

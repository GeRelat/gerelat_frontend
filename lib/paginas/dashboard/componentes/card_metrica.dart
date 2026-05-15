import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Card de métrica reutilizável para o dashboard.
/// Exibe título, valor numérico e descrição opcional com prefixo colorido.
class CardMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color fundoIcone;
  final Color corIcone;

  // Prefixo colorido antes da descrição (ex: "Ativo" em verde)
  final String? prefixoDescricao;
  final Color? corPrefixo;

  final double opacidade;

  const CardMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    required this.descricao,
    required this.icone,
    this.fundoIcone = const Color(0xFFEFF6FF),
    this.corIcone = Cores.azulPrimario,
    this.prefixoDescricao,
    this.corPrefixo,
    this.opacidade = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacidade,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: ShapeDecoration(
          color: Cores.branco,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Cores.cinzaAzulado.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _construirCabecalho(),
            const SizedBox(height: 16),
            _construirValor(),
            const SizedBox(height: 8),
            _construirDescricao(),
          ],
        ),
      ),
    );
  }

  Widget _construirCabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: Tipografia.labelLarge.copyWith(
            color: Cores.cinzaEscuro,
            letterSpacing: 0.7,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: fundoIcone,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 16, color: corIcone),
        ),
      ],
    );
  }

  Widget _construirValor() {
    return Text(
      valor,
      style: Tipografia.headlineLarge.copyWith(
        fontSize: 36,
        color: Cores.pretoProfundo,
        height: 1.11,
      ),
    );
  }

  Widget _construirDescricao() {
    if (prefixoDescricao != null) {
      return Row(
        children: [
          Text(
            prefixoDescricao!,
            style: Tipografia.labelSmall.copyWith(
              color: corPrefixo ?? Cores.azulPrimario,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              descricao,
              style: Tipografia.labelSmall.copyWith(
                color: Cores.cinzaEscuro,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      descricao,
      style: Tipografia.labelSmall.copyWith(
        color: Cores.cinzaEscuro,
        fontSize: 12,
      ),
    );
  }
}

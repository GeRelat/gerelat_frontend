part of '../painel_ui.dart';

/// Cabeçalho padrão de página de listagem: título + subtítulo opcional à
/// esquerda e uma ação (normalmente um [BotaoPrimario]) à direita.
class CabecalhoPagina extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  const CabecalhoPagina({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitulo!,
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?acao,
      ],
    );
  }
}

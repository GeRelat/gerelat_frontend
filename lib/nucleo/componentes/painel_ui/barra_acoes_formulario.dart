part of '../painel_ui.dart';

class BarraAcoesFormulario extends StatelessWidget {
  final String textoPrimario;
  final VoidCallback? onCancelar;
  final VoidCallback? onSalvar;

  const BarraAcoesFormulario({
    super.key,
    required this.textoPrimario,
    this.onCancelar,
    this.onSalvar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancelar ?? () => context.pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        BotaoPrimario(
          texto: textoPrimario,
          icone: LucideIcons.save,
          // `BotaoPrimario.onPressed` já aceita null e desabilita o botão de
          // verdade (visual + toque bloqueado). O `?? () {}` anterior sempre
          // entregava um callback não-nulo ao ElevatedButton, então a tela
          // passando `null` pra "desabilitar durante o salvamento" não tinha
          // efeito nenhum — o botão continuava clicável, com risco de
          // duplo-clique/duplo-envio.
          onPressed: onSalvar,
        ),
      ],
    );
  }
}

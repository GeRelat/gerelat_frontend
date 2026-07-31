part of '../painel_ui.dart';

class BotaoPrimario extends StatelessWidget {
  final String texto;
  final IconData icone;
  final VoidCallback? onPressed;

  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.icone,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, size: 18),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: Cores.azulAcao,
        foregroundColor: Cores.branco,
        elevation: 0,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Tipografia.labelLarge,
      ),
    );
  }
}

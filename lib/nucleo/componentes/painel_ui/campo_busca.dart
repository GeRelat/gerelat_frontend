part of '../painel_ui.dart';

class CampoBusca extends StatelessWidget {
  final TextEditingController controlador;
  final String dica;
  final ValueChanged<String> aoAlterar;

  const CampoBusca({
    super.key,
    required this.controlador,
    required this.dica,
    required this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Cores.cinzaCampo,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 18, color: Cores.cinzaEscuro),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controlador,
                onChanged: aoAlterar,
                decoration: InputDecoration(
                  hintText: dica,
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintStyle: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaMedio,
                  ),
                ),
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

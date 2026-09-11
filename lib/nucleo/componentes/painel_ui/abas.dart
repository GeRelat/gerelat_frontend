part of '../painel_ui.dart';

/// Um item de [SeletorAbas].
typedef AbaItem = ({String rotulo, IconData icone});

/// Faixa de abas em formato de "pílula", extraída do padrão que já existia em
/// `pagina_membros.dart`. Puramente visual: o widget pai guarda o índice
/// selecionado e troca o conteúdo.
class SeletorAbas extends StatelessWidget {
  final List<AbaItem> itens;
  final int selecionado;
  final ValueChanged<int> aoSelecionar;

  const SeletorAbas({
    super.key,
    required this.itens,
    required this.selecionado,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < itens.length; i++)
          _Aba(
            item: itens[i],
            selecionado: selecionado == i,
            onTap: () => aoSelecionar(i),
          ),
      ],
    );
  }
}

class _Aba extends StatelessWidget {
  final AbaItem item;
  final bool selecionado;
  final VoidCallback onTap;

  const _Aba({
    required this.item,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? Cores.azulAcao : Cores.fundoSecao,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? Cores.azulAcao : Cores.bordaSutil,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icone,
              size: 16,
              color: selecionado ? Colors.white : Cores.cinzaEscuro,
            ),
            const SizedBox(width: 8),
            Text(
              item.rotulo,
              style: Tipografia.labelMedium.copyWith(
                color: selecionado ? Colors.white : Cores.cinzaEscuro,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

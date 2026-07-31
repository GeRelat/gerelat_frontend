part of '../painel_ui.dart';

/// Definição de uma coluna de [CabecalhoTabelaCrud]/[LinhaTabelaCrud].
///
/// Informe [flex] para uma coluna que ocupa o espaço restante (como
/// [Expanded]) ou [largura] para uma coluna de largura fixa — nunca os dois.
/// [gutterDireita] adiciona um espaçamento à direita da célula (dentro da
/// coluna); [alinhamento] só tem efeito em colunas de [largura] fixa.
class ColunaTabelaCrud {
  final String rotulo;
  final int? flex;
  final double? largura;
  final TextAlign alinhamento;
  final double gutterDireita;

  const ColunaTabelaCrud({
    required this.rotulo,
    this.flex,
    this.largura,
    this.alinhamento = TextAlign.left,
    this.gutterDireita = 0,
  }) : assert(
         (flex == null) != (largura == null),
         'Informe flex ou largura, nunca os dois nem nenhum.',
       );
}

/// Cabeçalho de uma tabela CRUD (lista com colunas + ações), no padrão
/// visual já usado pelas telas de listagem em linha (equipes, projetos,
/// classes de evento, campos de projeto, eventos).
class CabecalhoTabelaCrud extends StatelessWidget {
  final List<ColunaTabelaCrud> colunas;
  final double altura;

  const CabecalhoTabelaCrud({
    super.key,
    required this.colunas,
    this.altura = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Cores.fundoSecao,
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(children: [for (final coluna in colunas) _celula(coluna)]),
    );
  }

  Widget _celula(ColunaTabelaCrud coluna) {
    return _celulaTabelaCrud(
      coluna,
      Text(
        coluna.rotulo.toUpperCase(),
        textAlign: coluna.alinhamento,
        style: Tipografia.eyebrow.copyWith(color: Cores.cinzaMedio),
      ),
    );
  }
}

/// Linha de dados de uma tabela CRUD. [celulas] deve ter o mesmo tamanho e
/// ordem de [colunas] — normalmente as mesmas colunas passadas para o
/// [CabecalhoTabelaCrud] correspondente.
class LinhaTabelaCrud extends StatelessWidget {
  final List<ColunaTabelaCrud> colunas;
  final List<Widget> celulas;
  final EdgeInsetsGeometry padding;

  const LinhaTabelaCrud({
    super.key,
    required this.colunas,
    required this.celulas,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  }) : assert(
         colunas.length == celulas.length,
         'colunas e celulas devem ter o mesmo tamanho.',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < colunas.length; i++)
            _celulaTabelaCrud(colunas[i], celulas[i]),
        ],
      ),
    );
  }
}

/// Compartilhada por [CabecalhoTabelaCrud] e [LinhaTabelaCrud]: aplica o
/// gutter à direita (quando houver) e encaixa o conteúdo na coluna — via
/// [Expanded] (flex) ou [SizedBox]+[Align] (largura fixa, para que o
/// conteúdo não estique e respeite o alinhamento pedido).
Widget _celulaTabelaCrud(ColunaTabelaCrud coluna, Widget conteudo) {
  final comGutter = coluna.gutterDireita > 0
      ? Padding(
          padding: EdgeInsets.only(right: coluna.gutterDireita),
          child: conteudo,
        )
      : conteudo;

  if (coluna.largura != null) {
    return SizedBox(
      width: coluna.largura,
      child: Align(
        alignment: coluna.alinhamento == TextAlign.center
            ? Alignment.center
            : Alignment.centerLeft,
        child: comGutter,
      ),
    );
  }
  return Expanded(flex: coluna.flex!, child: comGutter);
}

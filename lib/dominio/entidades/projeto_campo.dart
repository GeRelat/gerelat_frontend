enum TipoCampoProjeto {
  texto('text', 'Texto'),
  textoRico('richtext', 'Texto Rico'),
  imagem('image', 'Imagem'),
  tabela('table', 'Tabela');

  final String valorApi;
  final String rotulo;

  const TipoCampoProjeto(this.valorApi, this.rotulo);

  static TipoCampoProjeto porValorApi(String valor) {
    return TipoCampoProjeto.values.firstWhere(
      (tipo) => tipo.valorApi == valor,
      orElse: () => TipoCampoProjeto.texto,
    );
  }
}

class ProjetoCampo {
  final int? id;
  final int projetoId;
  final String referencia;
  final String descricao;
  final TipoCampoProjeto tipo;
  final bool obrigatorio;
  final Map<String, dynamic> valor;

  const ProjetoCampo({
    this.id,
    required this.projetoId,
    required this.referencia,
    required this.descricao,
    required this.tipo,
    this.obrigatorio = false,
    this.valor = const {},
  });
}

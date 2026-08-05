/// Tipos possíveis de uma variável (`CampoDefinicao.tipo` / `CampoValor.valor`).
/// Espelha `CampoTipo` em `apps/gerelat/enums.py`.
enum TipoCampo {
  texto('text', 'Texto'),
  textoRico('richtext', 'Texto Rico'),
  imagem('image', 'Imagem'),
  tabela('table', 'Tabela');

  final String valorApi;
  final String rotulo;

  const TipoCampo(this.valorApi, this.rotulo);

  static TipoCampo porValorApi(String valor) {
    return TipoCampo.values.firstWhere(
      (tipo) => tipo.valorApi == valor,
      orElse: () => TipoCampo.texto,
    );
  }
}

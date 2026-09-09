// Níveis da hierarquia Cliente > Programa > Projeto > Evento.
//
// Espelha `apps/gerelat/enums.py` no gerelat-api: `NivelEscopo` corresponde a
// `NivelTemplate` (e ao escopo de uma `CampoDefinicao`), `NivelAplicacao` a
// `NivelAplicacao`. O campo `ordem` reproduz `NIVEL_ORDEM` e é o que permite
// comparar profundidade (um nível só pode aplicar-se a algo igual ou mais
// profundo que o escopo onde foi declarado).

/// Escopo onde uma variável (ou um template) é declarado.
enum NivelEscopo {
  cliente('cliente', 'Cliente', 0),
  programa('programa', 'Programa', 1),
  projeto('projeto', 'Projeto', 2);

  final String valorApi;
  final String rotulo;
  final int ordem;

  const NivelEscopo(this.valorApi, this.rotulo, this.ordem);

  /// Escopos que o usuário pode escolher na interface. O nível `cliente`
  /// continua existindo no enum (para ler dados legados e as variáveis nativas
  /// `sistema.cliente.*`), mas não é mais oferecido em nenhum formulário ou
  /// filtro — templates e variáveis são sempre de programa ou de projeto.
  static const List<NivelEscopo> selecionaveis = [
    NivelEscopo.programa,
    NivelEscopo.projeto,
  ];

  static NivelEscopo porValorApi(String valor) {
    return NivelEscopo.values.firstWhere(
      (nivel) => nivel.valorApi == valor,
      orElse: () => NivelEscopo.projeto,
    );
  }

  NivelAplicacao get comoAplicacao => switch (this) {
    NivelEscopo.cliente => NivelAplicacao.cliente,
    NivelEscopo.programa => NivelAplicacao.programa,
    NivelEscopo.projeto => NivelAplicacao.projeto,
  };

  static NivelEscopo? deAplicacao(NivelAplicacao aplicacao) {
    switch (aplicacao) {
      case NivelAplicacao.cliente:
        return NivelEscopo.cliente;
      case NivelAplicacao.programa:
        return NivelEscopo.programa;
      case NivelAplicacao.projeto:
        return NivelEscopo.projeto;
      case NivelAplicacao.evento:
        return null;
    }
  }
}

/// Nível da entidade à qual uma variável se aplica (o alvo de um `CampoValor`).
enum NivelAplicacao {
  cliente('cliente', 'Cliente', 0),
  programa('programa', 'Programa', 1),
  projeto('projeto', 'Projeto', 2),
  evento('evento', 'Evento', 3);

  final String valorApi;
  final String rotulo;
  final int ordem;

  const NivelAplicacao(this.valorApi, this.rotulo, this.ordem);

  /// Níveis de aplicação que o usuário pode escolher ao declarar uma variável.
  /// `cliente` fica de fora pelo mesmo motivo de [NivelEscopo.selecionaveis].
  static const List<NivelAplicacao> selecionaveis = [
    NivelAplicacao.programa,
    NivelAplicacao.projeto,
    NivelAplicacao.evento,
  ];

  static NivelAplicacao porValorApi(String valor) {
    return NivelAplicacao.values.firstWhere(
      (nivel) => nivel.valorApi == valor,
      orElse: () => NivelAplicacao.projeto,
    );
  }

  /// `null` quando o valor não corresponde a nenhum nível conhecido — usado
  /// pelo scanner de gaps, que precisa distinguir "nível desconhecido"
  /// (ignora) de "nível projeto" (exige um projeto).
  static NivelAplicacao? porValorApiOuNulo(String valor) {
    for (final nivel in NivelAplicacao.values) {
      if (nivel.valorApi == valor) return nivel;
    }
    return null;
  }

  /// Níveis iguais ou mais profundos que este. Espelha a constraint
  /// `campodef_nivel_geq_escopo` do backend — uma variável declarada num
  /// programa pode ter valor por programa, por projeto ou por evento.
  static List<NivelAplicacao> aPartirDe(NivelEscopo escopo) {
    return NivelAplicacao.values
        .where((nivel) => nivel.ordem >= escopo.ordem)
        .toList();
  }
}

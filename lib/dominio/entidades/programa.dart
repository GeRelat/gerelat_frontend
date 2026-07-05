class Programa {
  final int? id;
  final String nome;
  final String descricao;
  final int projetos;
  final int eventos;
  final String status;
  final String leiCriacao;
  final String convenioDados;
  final String rodape;
  final String logomarca;
  final int? clienteId;
  final String clienteNome;

  const Programa({
    this.id,
    required this.nome,
    required this.descricao,
    required this.projetos,
    required this.eventos,
    required this.status,
    this.leiCriacao = '',
    this.convenioDados = '',
    this.rodape = '',
    this.logomarca = '',
    this.clienteId,
    this.clienteNome = '',
  });
}

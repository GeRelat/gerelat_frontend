import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

/// Template de relatório. Desde a reestruturação de escopo no backend, um
/// template pertence a exatamente uma entidade — cliente, programa **ou**
/// projeto — indicada por [nivel] (constraint `template_owner_matches_nivel`).
class TemplateRelatorio {
  final int? id;
  final NivelEscopo nivel;
  final int? clienteId;
  final int? programaId;
  final int? projetoId;
  final String nome;
  final String descricao;
  final String tipo;
  final String status;
  final String arquivoBase;

  const TemplateRelatorio({
    this.id,
    this.nivel = NivelEscopo.projeto,
    this.clienteId,
    this.programaId,
    this.projetoId,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.status,
    this.arquivoBase = '',
  });

  /// Id da entidade dona do template, coerente com [nivel].
  int? get escopoId => switch (nivel) {
    NivelEscopo.cliente => clienteId,
    NivelEscopo.programa => programaId,
    NivelEscopo.projeto => projetoId,
  };
}

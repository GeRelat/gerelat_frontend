import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

class Asset {
  final int? id;
  final int? clienteId;
  final int? programaId;
  final int? projetoId;
  final String descricao;
  final String urlArquivo;

  const Asset({
    this.id,
    this.clienteId,
    this.programaId,
    this.projetoId,
    this.descricao = '',
    this.urlArquivo = '',
  });

  NivelEscopo? get escopo {
    if (projetoId != null) return NivelEscopo.projeto;
    if (programaId != null) return NivelEscopo.programa;
    if (clienteId != null) return NivelEscopo.cliente;
    return null;
  }

  int? get escopoId => projetoId ?? programaId ?? clienteId;
}

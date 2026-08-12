import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

class ClasseEvento {
  final int? id;
  final int? clienteId;
  final int? programaId;
  final int? projetoId;
  final String nomeClasse;

  const ClasseEvento({
    this.id,
    this.clienteId,
    this.programaId,
    this.projetoId,
    required this.nomeClasse,
  });

  NivelEscopo? get escopo {
    if (projetoId != null) return NivelEscopo.projeto;
    if (programaId != null) return NivelEscopo.programa;
    if (clienteId != null) return NivelEscopo.cliente;
    return null;
  }

  int? get escopoId => projetoId ?? programaId ?? clienteId;
}

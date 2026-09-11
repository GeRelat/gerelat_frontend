import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

class ClasseEvento {
  final int? id;
  final int? programaId;
  final String nomeClasse;

  const ClasseEvento({
    this.id,
    this.programaId,
    required this.nomeClasse,
  });

  NivelEscopo get escopo => NivelEscopo.programa;

  int? get escopoId => programaId;

  // Compatibilidade com código legado que consulta clienteId / projetoId
  int? get clienteId => null;
  int? get projetoId => null;
}

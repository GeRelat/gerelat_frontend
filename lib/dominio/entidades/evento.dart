import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

class Evento {
  final int? id;
  final int? projetoId;
  final int? classeEventoId;
  final String nome;
  final String programa;
  final DateTime? data;
  final String local;
  final String endereco;
  final String objetivo;
  final String classeEventoNome;

  const Evento({
    this.id,
    this.projetoId,
    this.classeEventoId,
    required this.nome,
    this.programa = '',
    required this.data,
    this.local = '',
    this.endereco = '',
    this.objetivo = '',
    this.classeEventoNome = '',
  });

  NivelEscopo get escopo => NivelEscopo.projeto;

  int? get escopoId => projetoId;

  // Compatibilidade com código legado que consulta clienteId / programaId
  int? get clienteId => null;
  int? get programaId => null;
}

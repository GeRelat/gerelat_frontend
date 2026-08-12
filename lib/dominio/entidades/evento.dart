import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

class Evento {
  final int? id;
  final int? clienteId;
  final int? programaId;
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
    this.clienteId,
    this.programaId,
    this.projetoId,
    this.classeEventoId,
    required this.nome,
    required this.programa,
    required this.data,
    this.local = '',
    this.endereco = '',
    this.objetivo = '',
    this.classeEventoNome = '',
  });

  NivelEscopo? get escopo {
    if (projetoId != null) return NivelEscopo.projeto;
    if (programaId != null) return NivelEscopo.programa;
    if (clienteId != null) return NivelEscopo.cliente;
    return null;
  }

  int? get escopoId => projetoId ?? programaId ?? clienteId;
}

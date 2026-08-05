import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

/// Valor concreto de uma [CampoDefinicao] para uma instância-alvo específica
/// (exatamente um de cliente/programa/projeto/evento), cujo nível é sempre
/// igual ao `nivelAplicacao` da definição.
class CampoValor {
  final int? id;
  final int definicaoId;
  final int? clienteId;
  final int? programaId;
  final int? projetoId;
  final int? eventoId;
  final Map<String, dynamic> valor;

  const CampoValor({
    this.id,
    required this.definicaoId,
    this.clienteId,
    this.programaId,
    this.projetoId,
    this.eventoId,
    this.valor = const {},
  });

  NivelAplicacao get nivelAlvo {
    if (clienteId != null) return NivelAplicacao.cliente;
    if (programaId != null) return NivelAplicacao.programa;
    if (projetoId != null) return NivelAplicacao.projeto;
    return NivelAplicacao.evento;
  }

  int? get alvoId => clienteId ?? programaId ?? projetoId ?? eventoId;
}

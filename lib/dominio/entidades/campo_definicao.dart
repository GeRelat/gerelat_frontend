import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

/// Schema de uma variável: referência, tipo e obrigatoriedade, declarados sob
/// um escopo (exatamente um de cliente/programa/projeto) e válidos para todas
/// as instâncias de [nivelAplicacao] dentro desse escopo.
///
/// Ex.: escopo = Programa X + `nivelAplicacao = evento` significa "todo evento
/// de qualquer projeto do Programa X tem esta variável", e cada evento guarda
/// seu próprio valor num `CampoValor`.
class CampoDefinicao {
  final int? id;
  final int? clienteId;
  final int? programaId;
  final int? projetoId;
  final NivelAplicacao nivelAplicacao;
  final String referencia;
  final String descricao;
  final TipoCampo tipo;
  final bool obrigatorio;

  const CampoDefinicao({
    this.id,
    this.clienteId,
    this.programaId,
    this.projetoId,
    required this.nivelAplicacao,
    required this.referencia,
    required this.descricao,
    required this.tipo,
    this.obrigatorio = false,
  });

  /// Nível do escopo onde a definição foi declarada. A precedência
  /// cliente > programa > projeto espelha `_nivel_of_scope` no backend; a
  /// constraint `campodef_exactly_one_escopo` garante que só uma FK vem
  /// preenchida, então na prática não há ambiguidade.
  NivelEscopo get nivelEscopo {
    if (clienteId != null) return NivelEscopo.cliente;
    if (programaId != null) return NivelEscopo.programa;
    return NivelEscopo.projeto;
  }

  int? get escopoId => clienteId ?? programaId ?? projetoId;
}

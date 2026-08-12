import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

/// Origem de uma variável oferecida na autoria de um template.
enum OrigemVariavel {
  /// Campo nativo da entidade, exposto automaticamente sob o prefixo
  /// reservado `sistema.<nivel>.<campo>` (ver `document_engine/system_fields.py`).
  sistema('sistema', 'Sistema'),

  /// Variável cadastrada manualmente como `CampoDefinicao`.
  customizado('customizado', 'Customizada');

  final String valorApi;
  final String rotulo;

  const OrigemVariavel(this.valorApi, this.rotulo);

  static OrigemVariavel porValorApi(String valor) {
    return OrigemVariavel.values.firstWhere(
      (origem) => origem.valorApi == valor,
      orElse: () => OrigemVariavel.customizado,
    );
  }
}

/// Item retornado por `GET /templates/variaveis-disponiveis/`: tudo que pode
/// ser inserido como variável num template do nível/instância consultados.
class VariavelDisponivel {
  final String referencia;
  final String descricao;
  final TipoCampo tipo;
  final NivelAplicacao nivelAplicacao;
  final OrigemVariavel origem;
  final bool obrigatorio;
  final String? escopoNome;

  const VariavelDisponivel({
    required this.referencia,
    required this.descricao,
    required this.tipo,
    required this.nivelAplicacao,
    required this.origem,
    this.obrigatorio = false,
    this.escopoNome,
  });
}

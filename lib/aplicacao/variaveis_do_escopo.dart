import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

/// Todas as variáveis que um template do escopo informado pode inserir:
/// campos nativos (`sistema.*`) e variáveis customizadas visíveis pela cadeia
/// de ancestrais.
///
/// A base vem de `GET /templates/variaveis-disponiveis/`, mas ela sozinha não
/// basta: a view descarta as `CampoDefinicao` cujo `nivel_aplicacao` é mais
/// profundo que o nível do template (`NIVEL_ORDEM[d.nivel_aplicacao] <=
/// max_ordem`), e como `nivel` só aceita cliente/programa/projeto, **nenhuma**
/// variável de nível evento é oferecida — embora a mesma view adicione os
/// `sistema.evento.*` logo abaixo, e o resto do backend (`build_variables_context`,
/// `scan_required_nivel`) as trate normalmente.
///
/// Por isso complementamos com `/campo-definicoes/`, que devolve as definições
/// sem esse corte. Quando o filtro do backend for corrigido, o merge continua
/// correto — só passa a não acrescentar nada.
Future<List<VariavelDisponivel>> carregarVariaveisDoEscopo(
  RepositorioCatalogo repositorio,
  HierarquiaEscopo hierarquia, {
  required NivelEscopo escopo,
  required int escopoId,
}) async {
  return repositorio.listarVariaveisDisponiveis(
    escopo: escopo,
    escopoId: escopoId,
  );
}

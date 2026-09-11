import 'dart:typed_data';

import 'package:gerelat_frontend/dominio/entidades/agendamento_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/assinatura_template.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_valor.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/programa.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/resumo_dashboard.dart';
import 'package:gerelat_frontend/dominio/entidades/solicitacao_cliente.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';

abstract interface class RepositorioClientes {
  Future<List<Cliente>> listarClientes();

  Future<List<OpcaoSelecao>> listarClientesSelecao({int? clienteId});

  Future<Cliente> obterCliente(int clienteId);

  Future<void> criarCliente({
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
    String logomarca = '',
  });

  Future<void> atualizarCliente({
    required int clienteId,
    required String nome,
    required String cnpj,
    required String nomeContato,
    required String emailContato,
    required String foneContato,
    required String numeroContrato,
    required DateTime dataTerminoContrato,
    String logomarca = '',
  });

  Future<void> excluirCliente(int clienteId);
}

abstract interface class RepositorioProgramas {
  Future<List<Programa>> listarProgramas();

  Future<List<OpcaoSelecao>> listarProgramasSelecao({int? clienteId});

  Future<Programa> obterPrograma(int programaId);

  Future<void> criarPrograma({
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  });

  Future<void> atualizarPrograma({
    required int programaId,
    required String nome,
    required String leiCriacao,
    required String convenioDados,
    String rodape = '',
    String logomarca = '',
    int? clienteId,
  });

  Future<void> excluirPrograma(int programaId);

  Future<void> criarProjeto({
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  });

  Future<List<Projeto>> listarProjetosDetalhados({int? programaId});

  Future<Projeto> obterProjeto(int projetoId);

  Future<void> atualizarProjeto({
    required int projetoId,
    required int programaId,
    required String nome,
    String parceira = '',
    String sigla = '',
    String logomarca = '',
  });

  Future<void> excluirProjeto(int projetoId);
}

abstract interface class RepositorioEventos {
  Future<List<Evento>> listarEventos();

  Future<Evento> obterEvento(int eventoId);

  Future<List<OpcaoSelecao>> listarProjetos();

  Future<List<OpcaoSelecao>> listarClassesEvento({
    int? programaId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
  });

  Future<int> criarClasseEvento({
    int? programaId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required String nomeClasse,
  });

  Future<List<ClasseEvento>> listarClassesEventoDetalhadas({
    int? programaId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
  });

  /// Classes de vários projetos numa única listagem — usado por templates de
  /// nível cliente/programa, que precisam agregar as classes de todos os
  /// projetos descendentes sem fazer uma requisição por projeto.
  Future<List<ClasseEvento>> listarClassesEventoDeProjetos(
    Set<int> projetoIds,
  );

  /// Classes de evento no alcance do escopo (cliente, programas ou projetos).
  Future<List<ClasseEvento>> listarClassesEventoDoAlcance({
    int? clienteId,
    Set<int> programaIds = const {},
    Set<int> projetoIds = const {},
  });

  Future<void> atualizarClasseEvento({
    required int classeId,
    required String nomeClasse,
  });

  Future<void> excluirClasseEvento(int classeId);

  Future<void> criarEvento({
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  });

  Future<void> atualizarEvento({
    required int eventoId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    required int classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  });

  Future<void> excluirEvento(int eventoId);
}

abstract interface class RepositorioTemplates {
  Future<List<TemplateRelatorio>> listarTemplates();

  Future<TemplateRelatorio> obterTemplate(int templateId);

  /// Cria um template a partir de um documento ProseMirror já pronto (ou de um
  /// documento vazio quando [modeloJson] é `null`). Usado pelo fluxo do editor,
  /// no qual o upload de `.docx` é opcional. Retorna o id do template criado.
  ///
  /// [escopo]/[escopoId] indicam a entidade dona do template — o backend exige
  /// exatamente um de cliente/programa/projeto, coerente com `nivel`.
  Future<int> criarTemplateComModelo({
    required NivelEscopo escopo,
    required int escopoId,
    required String nomeTemplate,
    Map<String, dynamic>? modeloJson,
  });

  /// Variáveis oferecidas na autoria de um template do escopo informado:
  /// campos nativos (`sistema.*`) + `CampoDefinicao` visíveis pela cadeia de
  /// ancestrais, via `GET /templates/variaveis-disponiveis/`.
  Future<List<VariavelDisponivel>> listarVariaveisDisponiveis({
    required NivelEscopo escopo,
    required int escopoId,
  });

  /// Converte um `.docx` em documento ProseMirror (`modelo_json`) via
  /// `/templates/convert-docx/`, sem criar nada. Serve para semear o editor.
  Future<Map<String, dynamic>> converterDocxParaModelo({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  });

  /// Lê o `modelo_json` (documento ProseMirror do template) para edição no
  /// editor. Retorna um documento vazio se o template ainda não tiver conteúdo.
  Future<Map<String, dynamic>> obterModeloTemplate(int templateId);

  /// Persiste o `modelo_json` editado no editor (PATCH `/templates/<id>/`).
  Future<void> salvarModeloTemplate({
    required int templateId,
    required Map<String, dynamic> modeloJson,
  });

  Future<void> atualizarTemplate({
    required int templateId,
    required NivelEscopo escopo,
    required int escopoId,
    required String nomeTemplate,
    Uint8List? arquivoBytes,
    String? nomeArquivo,
  });

  /// Mapa classeEventoId -> id do vínculo, para o template informado.
  Future<Map<int, int>> listarVinculosClasseTemplate(int templateId);

  Future<void> vincularTemplateClasse({
    required int templateId,
    required int classeEventoId,
  });

  Future<void> desvincularTemplateClasse(int vinculoId);

  Future<void> excluirTemplate(int templateId);

  Future<List<AssinaturaTemplate>> listarAssinaturasTemplate(int templateId);

  /// Cria uma assinatura vinculando o template a um membro de equipe.
  /// Informe exatamente um dos dois ids (regra espelhada do backend, ver
  /// `AssinaturaTemplateSerializer.validate`).
  Future<void> criarAssinaturaTemplate({
    required int templateId,
    int? equipeProgramaId,
    int? equipeProjetoId,
  });

  Future<void> excluirAssinaturaTemplate(int assinaturaId);

  /// Baixa o arquivo .docx original do template (via `/templates/<id>/download/`).
  /// Retorna vazio/erro se o template foi criado sem upload de arquivo base
  /// (ex.: fluxo `from-json`, que não armazena o .docx original).
  Future<Uint8List> baixarArquivoTemplate(int templateId);

  /// Listagem de eventos disponíveis para a geração de relatórios com o template
  /// informado (respeitando o escopo do template e vinculação com classe de evento).
  Future<List<Evento>> listarEventosDisponiveis(int templateId);

  /// Resolve as variáveis da cadeia de escopo informada sobre o `modelo_json`
  /// do template (via `/templates/<id>/preview/`) e retorna o documento
  /// ProseMirror resultante, para pré-visualização antes de gerar o relatório
  /// definitivo. Os ids omitidos caem no escopo do próprio template.
  Future<Map<String, dynamic>> previsualizarTemplate({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
  });

  /// Nível mais profundo (cliente/programa/projeto/evento) exigido para
  /// resolver todos os gaps do `modelo_json` do template dada a cadeia de
  /// escopo já conhecida — inclusive os usados apenas transitivamente, dentro
  /// do valor de variáveis de texto rico citadas pelo template (via
  /// `/templates/<id>/nivel-exigido/`). `null` se nenhum gap depender de uma
  /// variável ligada a nível.
  ///
  /// É o backend rodando `scan_required_nivel` — a mesma varredura que a
  /// criação do relatório aplica — para que a tela de gerar relatório saiba
  /// de antemão quais seletores exigir, sem reimplementar a varredura no
  /// cliente (que não tem acesso ao valor das variáveis de texto rico).
  Future<NivelAplicacao?> nivelExigidoTemplate({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
  });
}

abstract interface class RepositorioRelatorios {
  Future<List<Relatorio>> listarRelatorios();

  /// Gera o relatório definitivo a partir do documento ProseMirror já
  /// resolvido/editado no preview ([documentoJson]). Envia para
  /// `POST /relatorios/`, aguarda a task assíncrona concluir e retorna o id do
  /// relatório gerado.
  ///
  /// A cadeia cliente/programa/projeto/evento define quais variáveis o backend
  /// consegue resolver; ele rejeita com 400 se o documento referenciar uma
  /// variável de nível mais profundo do que o informado (`scan_required_nivel`).
  Future<int> gerarRelatorioComDocumento({
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    String? nome,
    List<Map<String, int>> assinaturas,
  });

  Future<Uint8List> baixarRelatorio(int relatorioId);

  Future<void> atualizarRelatorio({
    required int relatorioId,
    String? nome,
    Map<String, dynamic>? documentoJson,
  });

  Future<void> excluirRelatorio(int relatorioId);

  Future<void> agendarRelatorio({
    required String nome,
    required int templateId,
    int? clienteId,
    int? programaId,
    int? projetoId,
    int? eventoId,
    Map<String, dynamic>? documentoJson,
    required String tipoAgendamento,
    DateTime? dataHoraExecucao,
    String? recorrencia,
    String? horarioExecucao,
    int? diaSemana,
    int? diaMes,
    bool ativo = true,
  });

  Future<List<AgendamentoRelatorio>> listarAgendamentos({int? clienteId});

  Future<void> alterarStatusAgendamento({
    required int agendamentoId,
    required bool ativo,
  });

  Future<void> excluirAgendamento(int agendamentoId);
}

abstract interface class RepositorioDashboard {
  Future<ResumoDashboard> obterResumoDashboard({int? clienteId});
}

abstract interface class RepositorioEquipePrograma {
  Future<List<MembroEquipePrograma>> listarEquipePrograma({
    required int programaId,
  });

  /// Equipe de vários programas numa única listagem — ver
  /// [RepositorioEventos.listarClassesEventoDeProjetos].
  Future<List<MembroEquipePrograma>> listarEquipeDeProgramas(
    Set<int> programaIds,
  );

  Future<void> criarMembroEquipe({
    required int programaId,
    required String nome,
    required String cargo,
  });

  Future<void> atualizarMembroEquipe({
    required int membroId,
    required String nome,
    required String cargo,
  });

  Future<void> excluirMembroEquipe(int membroId);
}

abstract interface class RepositorioEquipeProjeto {
  Future<List<MembroEquipeProjeto>> listarEquipeProjeto({
    required int projetoId,
  });

  /// Equipe de vários projetos numa única listagem — ver
  /// [RepositorioEventos.listarClassesEventoDeProjetos].
  Future<List<MembroEquipeProjeto>> listarEquipeDeProjetos(Set<int> projetoIds);

  Future<void> criarMembroEquipeProjeto({
    required int projetoId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  });

  Future<void> atualizarMembroEquipeProjeto({
    required int membroId,
    required String nomeEquipe,
    required String nome,
    required String cargo,
  });

  Future<void> excluirMembroEquipeProjeto(int membroId);
}

/// Variáveis customizáveis: o schema (`CampoDefinicao`, declarado num escopo) e
/// os valores por instância (`CampoValor`). Substitui o antigo
/// `RepositorioProjetoCampo`, que conflava as duas coisas por projeto.
abstract interface class RepositorioCampos {
  /// Definições declaradas exatamente no escopo informado. Sem escopo,
  /// devolve todas.
  Future<List<CampoDefinicao>> listarDefinicoes({
    NivelEscopo? escopo,
    int? escopoId,
  });

  /// Definições visíveis a partir de uma cadeia de ancestrais — o equivalente
  /// no cliente ao filtro `Q(cliente_id=…) | Q(programa_id=…) | Q(projeto_id=…)`
  /// usado por `document_engine/variables.py` e pela view `variaveis-disponiveis`.
  Future<List<CampoDefinicao>> listarDefinicoesVisiveis({
    int? clienteId,
    int? programaId,
    int? projetoId,
  });

  Future<void> criarDefinicao({
    required NivelEscopo escopo,
    required int escopoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  });

  Future<void> atualizarDefinicao({
    required int definicaoId,
    required NivelAplicacao nivelAplicacao,
    required String referencia,
    required String descricao,
    required TipoCampo tipo,
    required bool obrigatorio,
  });

  Future<void> excluirDefinicao(int definicaoId);

  /// Valores já gravados para a instância-alvo informada.
  Future<List<CampoValor>> listarValores({
    required NivelAplicacao alvo,
    required int alvoId,
  });

  /// Cria (quando [valorId] é `null`) ou atualiza o valor de uma definição
  /// para a instância-alvo informada.
  Future<void> salvarValor({
    int? valorId,
    required int definicaoId,
    required NivelAplicacao alvo,
    required int alvoId,
    required Map<String, dynamic> valor,
  });

  Future<void> excluirValor(int valorId);
}

abstract interface class RepositorioAssets {
  /// Envia uma imagem e retorna o Asset criado.
  Future<Asset> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    NivelEscopo? escopo,
    int? escopoId,
    String descricao = '',
  });

  Future<List<Asset>> listarAssets();

  Future<Asset> obterAsset(int assetId);

  Future<void> atualizarAsset({
    required int assetId,
    required String descricao,
  });

  Future<void> excluirAsset(int assetId);
}

abstract interface class RepositorioSolicitacoes {
  Future<List<SolicitacaoClienteModel>> listarSolicitacoes({
    int? clienteId,
    String? status,
  });
  Future<bool> aprovarSolicitacao(
    int id, {
    bool eAdminCliente = false,
    List<Map<String, dynamic>> programas = const [],
    List<Map<String, dynamic>> projetos = const [],
  });
  Future<bool> recusarSolicitacao(int id);
}

abstract interface class RepositorioMembrosCliente {
  /// Retorna todos os usuários com qualquer acesso ao [clienteId] dado
  /// (Admin do Cliente + AcessoPrograma + AcessoProjeto), agregados por usuário.
  Future<List<UsuarioClienteModel>> listarUsuariosCliente(
      {required int clienteId});

  /// Remove TODOS os acessos do [userId] no [clienteId] (admin + programa + projeto).
  Future<void> removerUsuarioDoCliente({
    required int clienteId,
    required int userId,
  });

  /// Substitui completamente as permissões do [userId] no [clienteId].
  /// Se [eAdminCliente] for true, concede MembroCliente e remove os demais acessos.
  /// Caso contrário, sincroniza [programaIds] e [projetoIds] com o estado atual.
  Future<void> atualizarPermissoesUsuario({
    required int clienteId,
    required int userId,
    required bool eAdminCliente,
    required List<int> programaIds,
    required List<int> projetoIds,
  });

  // --- Admin do Cliente (MembroCliente) ---
  Future<List<MembroClienteModel>> listarMembrosCliente({int? clienteId});
  Future<void> criarMembroCliente({required int clienteId, required int userId});
  Future<void> excluirMembroCliente(int id);
}

abstract interface class RepositorioMembrosGeRelat {
  Future<List<MembroGeRelatModel>> listarMembrosGeRelat();
  Future<List<UsuarioDisponivelModel>> listarUsuariosDisponiveisGeRelat();
  Future<void> criarMembroGeRelat({required int userId});
  Future<void> excluirMembroGeRelat(int id);
}

abstract class RepositorioCatalogo
    implements
        RepositorioClientes,
        RepositorioProgramas,
        RepositorioEventos,
        RepositorioTemplates,
        RepositorioRelatorios,
        RepositorioDashboard,
        RepositorioEquipePrograma,
        RepositorioEquipeProjeto,
        RepositorioCampos,
        RepositorioAssets,
        RepositorioSolicitacoes,
        RepositorioMembrosCliente,
        RepositorioMembrosGeRelat {}

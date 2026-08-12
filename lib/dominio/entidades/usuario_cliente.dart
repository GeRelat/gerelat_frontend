/// Representa um usuário com qualquer tipo de acesso a um Cliente.
///
/// Agrega todas as fontes de acesso — Admin do Cliente ([isAdminCliente]),
/// acessos a Programas ([acessosPrograma]) e acessos a Projetos ([acessosProjeto]).
class AcessoProgramaResumido {
  final int id;
  final int programaId;
  final String programaNome;
  final String papel;

  const AcessoProgramaResumido({
    required this.id,
    required this.programaId,
    required this.programaNome,
    required this.papel,
  });

  factory AcessoProgramaResumido.fromJson(Map<String, dynamic> json) {
    return AcessoProgramaResumido(
      id: json['id'] as int,
      programaId: json['programa_id'] as int,
      programaNome: (json['programa_nome'] as String?) ?? '',
      papel: (json['papel'] as String?) ?? 'membro',
    );
  }
}

class AcessoProjetoResumido {
  final int id;
  final int projetoId;
  final String projetoNome;
  final String papel;

  const AcessoProjetoResumido({
    required this.id,
    required this.projetoId,
    required this.projetoNome,
    required this.papel,
  });

  factory AcessoProjetoResumido.fromJson(Map<String, dynamic> json) {
    return AcessoProjetoResumido(
      id: json['id'] as int,
      projetoId: json['projeto_id'] as int,
      projetoNome: (json['projeto_nome'] as String?) ?? '',
      papel: (json['papel'] as String?) ?? 'membro',
    );
  }
}

class UsuarioClienteModel {
  final int user;
  final String userEmail;
  final String userNome;
  final bool isAdminCliente;
  final int? membroClienteId;
  final List<AcessoProgramaResumido> acessosPrograma;
  final List<AcessoProjetoResumido> acessosProjeto;

  const UsuarioClienteModel({
    required this.user,
    required this.userEmail,
    required this.userNome,
    required this.isAdminCliente,
    this.membroClienteId,
    this.acessosPrograma = const [],
    this.acessosProjeto = const [],
  });

  factory UsuarioClienteModel.fromJson(Map<String, dynamic> json) {
    final progs = (json['membros_programa'] as List<dynamic>? ??
            json['acessos_programa'] as List<dynamic>? ??
            [])
        .map((e) => AcessoProgramaResumido.fromJson(e as Map<String, dynamic>))
        .toList();
    final projs = (json['membros_projeto'] as List<dynamic>? ??
            json['acessos_projeto'] as List<dynamic>? ??
            [])
        .map((e) => AcessoProjetoResumido.fromJson(e as Map<String, dynamic>))
        .toList();
    return UsuarioClienteModel(
      user: json['user'] as int,
      userEmail: (json['user_email'] as String?) ?? '',
      userNome: (json['user_nome'] as String?) ?? '',
      isAdminCliente: (json['is_admin_cliente'] as bool?) ?? false,
      membroClienteId: json['membro_cliente_id'] as int?,
      acessosPrograma: progs,
      acessosProjeto: projs,
    );
  }

  /// Rótulo resumido do papel mais alto deste usuário neste cliente.
  String get rotuloAcesso {
    if (isAdminCliente) return 'Administrador do Cliente';
    final labels = <String>[
      ...acessosPrograma.map(
        (a) => 'Programa: ${a.programaNome} (${_papelLabel(a.papel)})',
      ),
      ...acessosProjeto.map(
        (a) => 'Projeto: ${a.projetoNome} (${_papelLabel(a.papel)})',
      ),
    ];
    if (labels.isEmpty) return 'Sem acesso ativo';
    return labels.join(' • ');
  }

  static String _papelLabel(String papel) =>
      papel == 'moderador' ? 'Moderador' : 'Membro';
}

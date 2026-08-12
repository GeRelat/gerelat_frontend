class ItemContextoCliente {
  final int id;
  final String nome;
  final String papel; // "admin", "gestor", "membro"
  final String logomarca;

  const ItemContextoCliente({
    required this.id,
    required this.nome,
    required this.papel,
    this.logomarca = '',
  });
}

class ContextosAcesso {
  final bool adminGerelat;
  final List<ItemContextoCliente> clientesAdmin;
  final List<Map<String, dynamic>> programas;
  final List<Map<String, dynamic>> projetos;
  final List<Map<String, dynamic>> solicitacoesPendentes;

  const ContextosAcesso({
    this.adminGerelat = false,
    this.clientesAdmin = const [],
    this.programas = const [],
    this.projetos = const [],
    this.solicitacoesPendentes = const [],
  });

  factory ContextosAcesso.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ContextosAcesso();

    final clientesAdminList = (map['clientes_admin'] as List? ?? [])
        .whereType<Map>()
        .map((c) => ItemContextoCliente(
              id: int.tryParse('${c['id']}') ?? 0,
              nome: c['nome']?.toString() ?? '',
              papel: c['papel']?.toString() ?? 'admin',
              logomarca: c['logomarca']?.toString() ?? '',
            ))
        .toList();

    return ContextosAcesso(
      adminGerelat: map['admin_gerelat'] == true,
      clientesAdmin: clientesAdminList,
      programas: (map['programas'] as List? ?? []).cast<Map<String, dynamic>>(),
      projetos: (map['projetos'] as List? ?? []).cast<Map<String, dynamic>>(),
      solicitacoesPendentes:
          (map['solicitacoes_pendentes'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
  }
}

class Usuario {
  final int id;
  final String nomeCompleto;
  final String email;
  final DateTime? criadoEm;
  final bool possuiContextoAcesso;
  final ContextosAcesso contextosAcesso;

  const Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.criadoEm,
    this.possuiContextoAcesso = false,
    this.contextosAcesso = const ContextosAcesso(),
  });

  /// Verifica se o usuário é Administrador GeRelat (tem acesso total, inclusive Clientes e Aprovações)
  bool get isAdminGeRelat => contextosAcesso.adminGerelat;

  /// Verifica se o usuário é Admin de pelo menos um Cliente (pode ver Clientes e Aprovações/Membros)
  bool get isAdminCliente => contextosAcesso.clientesAdmin.isNotEmpty;

  /// Verifica se o usuário é Administrador do Cliente informado (ou Platform Admin)
  bool eAdminDoCliente(int? clienteId) {
    if (isAdminGeRelat) return true;
    if (clienteId == null) return false;
    return contextosAcesso.clientesAdmin.any((c) => c.id == clienteId);
  }

  /// Retorna lista combinada de clientes disponíveis para seleção no contexto do usuário
  List<ItemContextoCliente> get todosClientesDisponiveis {
    final mapa = <int, ItemContextoCliente>{};
    for (final c in contextosAcesso.clientesAdmin) {
      final nome = (c.nome.isNotEmpty && !c.nome.startsWith('Cliente #')) ? c.nome : '';
      mapa[c.id] = ItemContextoCliente(
        id: c.id,
        nome: nome,
        papel: c.papel,
        logomarca: c.logomarca,
      );
    }
    for (final p in contextosAcesso.programas) {
      final cId = int.tryParse('${p['cliente_id']}');
      final rawNome = p['cliente_nome']?.toString() ?? '';
      final cNome = (rawNome.isNotEmpty && !rawNome.startsWith('Cliente #')) ? rawNome : '';
      final cLogo = p['cliente_logomarca']?.toString() ?? '';
      final papel = p['papel']?.toString() ?? 'membro';
      if (cId != null) {
        if (!mapa.containsKey(cId)) {
          mapa[cId] = ItemContextoCliente(
            id: cId,
            nome: cNome,
            papel: papel,
            logomarca: cLogo,
          );
        } else {
          final existente = mapa[cId]!;
          mapa[cId] = ItemContextoCliente(
            id: cId,
            nome: existente.nome.isEmpty && cNome.isNotEmpty ? cNome : existente.nome,
            papel: existente.papel,
            logomarca: existente.logomarca.isEmpty ? cLogo : existente.logomarca,
          );
        }
      }
    }
    for (final p in contextosAcesso.projetos) {
      final cId = int.tryParse('${p['cliente_id']}');
      final rawNome = p['cliente_nome']?.toString() ?? '';
      final cNome = (rawNome.isNotEmpty && !rawNome.startsWith('Cliente #')) ? rawNome : '';
      final cLogo = p['cliente_logomarca']?.toString() ?? '';
      final papel = p['papel']?.toString() ?? 'membro';
      if (cId != null) {
        if (!mapa.containsKey(cId)) {
          mapa[cId] = ItemContextoCliente(
            id: cId,
            nome: cNome,
            papel: papel,
            logomarca: cLogo,
          );
        } else {
          final existente = mapa[cId]!;
          mapa[cId] = ItemContextoCliente(
            id: cId,
            nome: existente.nome.isEmpty && cNome.isNotEmpty ? cNome : existente.nome,
            papel: existente.papel,
            logomarca: existente.logomarca.isEmpty ? cLogo : existente.logomarca,
          );
        }
      }
    }
    return mapa.values.toList();
  }
}

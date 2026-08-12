import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class AssetsViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;
  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  NivelEscopo _escopo = NivelEscopo.projeto;
  int? _escopoId;
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<Asset> _assets = [];

  AssetsViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelEscopo get escopo => _escopo;
  int? get escopoId => _escopoId;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;

  List<OpcaoSelecao> get opcoesEscopo {
    final todas = _hierarquia.opcoesDe(_escopo.comoAplicacao, clienteId: _clienteAtivoId);
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return todas;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) return todas;

    return todas.where((op) => podeEditarEscopo(_escopo, op.id)).toList();
  }

  List<Asset> get assets => List.unmodifiable(_assets);

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final clienteMudou = _clienteAtivoId != clienteAtivoId;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;

    _ajustarSelecaoEscopo();

    if (clienteMudou) {
      notifyListeners();
      carregar();
    }
  }

  Future<void> inicializar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _repositorio,
        comEventos: false,
      );
      _ajustarSelecaoEscopo();
      await carregar(semInverterCarregamento: true);
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> carregarHierarquia() async {
    await inicializar();
  }

  void _ajustarSelecaoEscopo() {
    final opcoes = opcoesEscopo;
    if (_escopoId != null && !opcoes.any((o) => o.id == _escopoId)) {
      _escopoId = opcoes.isNotEmpty ? opcoes.first.id : null;
    } else if (_escopoId == null && opcoes.isNotEmpty) {
      _escopoId = opcoes.first.id;
    }
  }

  Future<void> selecionarEscopo(NivelEscopo escopo, int? escopoId) async {
    _escopo = escopo;
    if (escopoId != null) {
      _escopoId = escopoId;
    } else {
      final opcoes = opcoesEscopo;
      _escopoId = opcoes.isNotEmpty ? opcoes.first.id : null;
    }
    _assets = [];
    notifyListeners();

    await carregar();
  }

  Future<void> carregar({bool semInverterCarregamento = false}) async {
    if (!semInverterCarregamento) {
      iniciarCarregamento();
    }
    try {
      final todos = await _repositorio.listarAssets();

      final visiveis = todos.where((a) {
        if (!pertenhoAoClienteAtivo(a)) return false;
        return podeVisualizarAsset(a);
      }).toList();

      if (_escopoId != null) {
        _assets = visiveis.where((a) {
          switch (_escopo) {
            case NivelEscopo.cliente:
              return a.clienteId == _escopoId;
            case NivelEscopo.programa:
              return a.programaId == _escopoId;
            case NivelEscopo.projeto:
              return a.projetoId == _escopoId;
          }
        }).toList();
      } else {
        _assets = visiveis.where((a) => a.escopo == _escopo).toList();
      }
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  int? resolverClienteIdDoAsset(Asset a) {
    if (a.clienteId != null) return a.clienteId;
    if (a.programaId != null) {
      return _hierarquia.programaPorId(a.programaId)?.clienteId;
    }
    if (a.projetoId != null) {
      return _hierarquia
          .cadeiaDe(NivelAplicacao.projeto, a.projetoId)
          .clienteId;
    }
    return null;
  }

  bool pertenhoAoClienteAtivo(Asset a) {
    if (_clienteAtivoId == null) return true;
    final cId = resolverClienteIdDoAsset(a);
    return cId == _clienteAtivoId;
  }

  bool podeVisualizarAsset(Asset a) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }

    final cId = resolverClienteIdDoAsset(a);
    if (_clienteAtivoId != null && cId != _clienteAtivoId) return false;

    // Se o asset é de nível cliente, qualquer membro do cliente tem visualização
    if (a.clienteId != null) {
      return true;
    }

    // Se é de nível programa: membro do programa ou de algum projeto filho
    if (a.programaId != null) {
      final eMembroDoPrograma = usuario.contextosAcesso.programas
          .any((p) => int.tryParse('${p['id']}') == a.programaId);
      if (eMembroDoPrograma) return true;

      final eMembroDeProjetoDoPrograma = usuario.contextosAcesso.projetos.any(
        (p) => int.tryParse('${p['programa_id']}') == a.programaId,
      );
      if (eMembroDeProjetoDoPrograma) return true;

      return false;
    }

    // Se é de nível projeto: membro do próprio projeto ou do programa pai
    if (a.projetoId != null) {
      final eMembroDoProjeto = usuario.contextosAcesso.projetos
          .any((p) => int.tryParse('${p['id']}') == a.projetoId);
      if (eMembroDoProjeto) return true;

      final progPaiId = _hierarquia.projetoPorId(a.projetoId)?.programaId;
      final eMembroDoProgramaPai = progPaiId != null &&
          usuario.contextosAcesso.programas
              .any((p) => int.tryParse('${p['id']}') == progPaiId);
      if (eMembroDoProgramaPai) return true;

      return false;
    }

    return true;
  }

  bool podeEditarEscopo(NivelEscopo escopo, int? escopoId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (escopoId == null) return false;

    switch (escopo) {
      case NivelEscopo.cliente:
        return false;

      case NivelEscopo.programa:
        return usuario.contextosAcesso.programas
            .any((p) => int.tryParse('${p['id']}') == escopoId);

      case NivelEscopo.projeto:
        final eMembroDoProjeto = usuario.contextosAcesso.projetos
            .any((p) => int.tryParse('${p['id']}') == escopoId);
        if (eMembroDoProjeto) return true;

        final progPaiId = _hierarquia.projetoPorId(escopoId)?.programaId;
        final eMembroDoProgramaPai = progPaiId != null &&
            usuario.contextosAcesso.programas
                .any((p) => int.tryParse('${p['id']}') == progPaiId);
        return eMembroDoProgramaPai;
    }
  }

  bool podeEditarAsset(Asset asset) {
    final e = asset.escopo;
    final eId = asset.escopoId;
    if (e == null || eId == null) return false;
    return podeEditarEscopo(e, eId);
  }

  Future<bool> enviar({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    required NivelEscopo escopo,
    required int escopoId,
    String descricao = '',
  }) {
    return _executarAcao(
      () async {
        await _repositorio.criarAsset(
          arquivoBytes: arquivoBytes,
          nomeArquivo: nomeArquivo,
          escopo: escopo,
          escopoId: escopoId,
          descricao: descricao,
        );
      },
    );
  }

  Future<bool> atualizarDescricao({
    required int assetId,
    required String descricao,
  }) {
    return _executarAcao(
      () => _repositorio.atualizarAsset(assetId: assetId, descricao: descricao),
    );
  }

  Future<bool> excluir(int assetId) {
    return _executarAcao(() => _repositorio.excluirAsset(assetId));
  }

  Future<bool> _executarAcao(Future<void> Function() acao) async {
    iniciarCarregamento();
    try {
      await acao();
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

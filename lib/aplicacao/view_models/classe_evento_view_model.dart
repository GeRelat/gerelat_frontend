import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ClasseEventoViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;

  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  NivelEscopo _escopo = NivelEscopo.projeto;
  int? _escopoId;
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<ClasseEvento> _classes = [];

  int _tokenClasses = 0;

  ClasseEventoViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelEscopo get escopo => _escopo;
  int? get escopoId => _escopoId;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;

  List<NivelEscopo> get niveisPermitidos {
    final usuario = _usuarioAtual;
    if (usuario == null) return NivelEscopo.selecionaveis;
    if (usuario.isAdminGeRelat) return NivelEscopo.selecionaveis;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return NivelEscopo.selecionaveis;
    }

    final niveis = <NivelEscopo>[];
    final temPrograma = usuario.contextosAcesso.programas.any((p) {
      if (_clienteAtivoId == null) return true;
      final pId = int.tryParse('${p['id']}');
      return _hierarquia.programaPorId(pId)?.clienteId == _clienteAtivoId;
    });
    if (temPrograma) {
      niveis.add(NivelEscopo.programa);
      niveis.add(NivelEscopo.projeto);
    }

    final temProjeto = usuario.contextosAcesso.projetos.any((p) {
      if (_clienteAtivoId == null) return true;
      final projId = int.tryParse('${p['id']}');
      final cId = _hierarquia.cadeiaDe(NivelAplicacao.projeto, projId).clienteId;
      return cId == _clienteAtivoId;
    });
    if (temProjeto && !niveis.contains(NivelEscopo.projeto)) {
      niveis.add(NivelEscopo.projeto);
    }

    return niveis.isEmpty ? NivelEscopo.selecionaveis : niveis;
  }

  bool temPermissaoNoEscopo(NivelEscopo escopo, int? escopoId) {
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

  List<OpcaoSelecao> get opcoesEscopo {
    final todas = _hierarquia.opcoesDe(_escopo.comoAplicacao, clienteId: _clienteAtivoId);
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return todas;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) return todas;

    return todas.where((op) => temPermissaoNoEscopo(_escopo, op.id)).toList();
  }

  List<ClasseEvento> get classes => List.unmodifiable(_classes);

  // Backward compatibility getters
  List<OpcaoSelecao> get projetos => _hierarquia.opcoesDeEscopo(NivelEscopo.projeto, clienteId: _clienteAtivoId);
  int? get projetoSelecionadoId => _escopo == NivelEscopo.projeto ? _escopoId : null;

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final mudou = _clienteAtivoId != clienteAtivoId || _usuarioAtual != usuarioAtual;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;

    _ajustarSelecaoEscopo();

    if (mudou) {
      notifyListeners();
      if (_escopoId != null) {
        selecionarEscopo(_escopo, _escopoId);
      }
    }
  }

  void _ajustarSelecaoEscopo() {
    final permitidos = niveisPermitidos;
    if (!permitidos.contains(_escopo)) {
      _escopo = permitidos.first;
      _escopoId = null;
    }
    final opcoes = opcoesEscopo;
    if (_escopoId != null && !opcoes.any((o) => o.id == _escopoId)) {
      _escopoId = opcoes.isNotEmpty ? opcoes.first.id : null;
    }
  }

  Future<void> carregarHierarquia() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _repositorio,
        comEventos: false,
      );
      _ajustarSelecaoEscopo();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> carregarProjetos() async {
    await carregarHierarquia();
  }

  Future<void> selecionarEscopo(NivelEscopo escopo, int? escopoId) async {
    _escopo = escopo;
    _escopoId = escopoId;
    _classes = [];
    final token = ++_tokenClasses;
    notifyListeners();
    if (escopoId == null) return;

    iniciarCarregamento();
    try {
      final classes = await _repositorio.listarClassesEventoDetalhadas(
        escopo: escopo,
        escopoId: escopoId,
      );
      if (token != _tokenClasses) return;
      _classes = classes;
      finalizarCarregamento();
    } catch (erro) {
      if (token != _tokenClasses) return;
      definirErro(erro);
    }
  }

  Future<void> selecionarProjeto(int? projetoId) async {
    await selecionarEscopo(NivelEscopo.projeto, projetoId);
  }

  Future<bool> salvar({int? classeId, required String nomeClasse}) {
    return _executarAcaoClasse((escopo, escopoId) async {
      if (classeId == null) {
        await _repositorio.criarClasseEvento(
          escopo: escopo,
          escopoId: escopoId,
          nomeClasse: nomeClasse,
        );
      } else {
        await _repositorio.atualizarClasseEvento(
          classeId: classeId,
          nomeClasse: nomeClasse,
        );
      }
    });
  }

  Future<bool> excluir(int classeId) {
    return _executarAcaoClasse(
      (_, _) => _repositorio.excluirClasseEvento(classeId),
    );
  }

  Future<bool> _executarAcaoClasse(
    Future<void> Function(NivelEscopo escopo, int escopoId) acao,
  ) async {
    final escopoId = _escopoId;
    if (escopoId == null) return false;

    iniciarCarregamento();
    try {
      await acao(_escopo, escopoId);
      _classes = await _repositorio.listarClassesEventoDetalhadas(
        escopo: _escopo,
        escopoId: escopoId,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

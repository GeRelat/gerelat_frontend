import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EventoFormViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;
  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  NivelEscopo _escopo = NivelEscopo.projeto;
  int? _escopoId;
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<OpcaoSelecao> _classes = [];
  Evento? _evento;

  int _tokenClasses = 0;

  EventoFormViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelEscopo get escopo => _escopo;
  int? get escopoId => _escopoId;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;

  List<NivelEscopo> get niveisPermitidos {
    final usuario = _usuarioAtual;
    if (usuario == null) return NivelEscopo.values;
    if (usuario.isAdminGeRelat) return NivelEscopo.values;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return NivelEscopo.values;
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

    return niveis.isEmpty ? NivelEscopo.values : niveis;
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

  // Backward compatibility
  List<OpcaoSelecao> get projetos => _hierarquia.opcoesDeEscopo(NivelEscopo.projeto, clienteId: _clienteAtivoId);
  List<OpcaoSelecao> get classes => List.unmodifiable(_classes);
  Evento? get evento => _evento;

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

  Future<void> carregarOpcoes() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _repositorio,
        comEventos: false,
      );
      _classes = await _repositorio.listarClassesEvento();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> selecionarEscopo(NivelEscopo escopo, int? escopoId) async {
    _escopo = escopo;
    _escopoId = escopoId;
    _classes = [];
    notifyListeners();
    if (escopoId == null) return;
    await carregarClassesEscopo(escopo, escopoId);
  }

  Future<void> carregarClassesProjeto(int projetoId) async {
    await selecionarEscopo(NivelEscopo.projeto, projetoId);
  }

  Future<void> carregarClassesEscopo(NivelEscopo escopo, int escopoId) async {
    final token = ++_tokenClasses;
    iniciarCarregamento();
    try {
      final classes = await _repositorio.listarClassesEvento(
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

  Future<void> carregarEdicao(int eventoId) async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _repositorio,
        comEventos: false,
      );
      _evento = await _repositorio.obterEvento(eventoId);
      if (_evento != null) {
        if (_evento!.projetoId != null) {
          _escopo = NivelEscopo.projeto;
          _escopoId = _evento!.projetoId;
        } else if (_evento!.programaId != null) {
          _escopo = NivelEscopo.programa;
          _escopoId = _evento!.programaId;
        } else if (_evento!.clienteId != null) {
          _escopo = NivelEscopo.cliente;
          _escopoId = _evento!.clienteId;
        }
      }
      final escopoId = _escopoId;
      _classes = escopoId == null
          ? await _repositorio.listarClassesEvento()
          : await _repositorio.listarClassesEvento(
              escopo: _escopo,
              escopoId: escopoId,
            );
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? eventoId,
    int? projetoId,
    NivelEscopo? escopo,
    int? escopoId,
    int? classeEventoId,
    required String nome,
    required DateTime data,
    String local = '',
    String endereco = '',
    String objetivo = '',
  }) async {
    iniciarCarregamento();
    try {
      final targetEscopo = escopo ?? _escopo;
      final targetEscopoId = escopoId ?? _escopoId ?? projetoId;

      if (targetEscopoId == null) {
        throw Exception('Selecione um escopo (cliente, programa ou projeto).');
      }

      final classeId = classeEventoId;

      if (classeId == null || classeId <= 0) {
        throw Exception('Selecione uma classe de evento.');
      }

      if (eventoId == null) {
        await _repositorio.criarEvento(
          escopo: targetEscopo,
          escopoId: targetEscopoId,
          classeEventoId: classeId,
          nome: nome,
          data: data,
          local: local,
          endereco: endereco,
          objetivo: objetivo,
        );
      } else {
        await _repositorio.atualizarEvento(
          eventoId: eventoId,
          escopo: targetEscopo,
          escopoId: targetEscopoId,
          classeEventoId: classeId,
          nome: nome,
          data: data,
          local: local,
          endereco: endereco,
          objetivo: objetivo,
        );
      }
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

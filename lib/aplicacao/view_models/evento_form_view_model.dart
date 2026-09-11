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
  int? get projetoSelecionadoId => _escopoId;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;

  List<NivelEscopo> get niveisPermitidos => const [NivelEscopo.projeto];

  bool temPermissaoNoProjeto(int? projetoId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (projetoId == null) return false;

    final eMembroDoProjeto = usuario.contextosAcesso.projetos
        .any((p) => int.tryParse('${p['id']}') == projetoId);
    if (eMembroDoProjeto) return true;

    final progPaiId = _hierarquia.projetoPorId(projetoId)?.programaId;
    final eMembroDoProgramaPai = progPaiId != null &&
        usuario.contextosAcesso.programas
            .any((p) => int.tryParse('${p['id']}') == progPaiId);
    return eMembroDoProgramaPai;
  }

  List<OpcaoSelecao> get opcoesProjetos {
    final todas = _hierarquia.opcoesDe(NivelAplicacao.projeto, clienteId: _clienteAtivoId);
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return todas;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) return todas;

    return todas.where((op) => temPermissaoNoProjeto(op.id)).toList();
  }

  List<OpcaoSelecao> get opcoesEscopo => opcoesProjetos;
  List<OpcaoSelecao> get projetos => opcoesProjetos;
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
        selecionarProjeto(_escopoId);
      }
    }
  }

  void _ajustarSelecaoEscopo() {
    _escopo = NivelEscopo.projeto;
    final opcoes = opcoesProjetos;
    if (_escopoId == null || !opcoes.any((o) => o.id == _escopoId)) {
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
      _ajustarSelecaoEscopo();
      final projId = _escopoId;
      if (projId != null) {
        await _carregarClassesDoProgramaDoProjeto(projId);
      } else {
        _classes = [];
      }
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> selecionarProjeto(int? projetoId) async {
    _escopo = NivelEscopo.projeto;
    _escopoId = projetoId;
    _classes = [];
    notifyListeners();
    if (projetoId == null) return;
    await _carregarClassesDoProgramaDoProjeto(projetoId);
  }

  Future<void> selecionarEscopo(NivelEscopo escopo, int? escopoId) async {
    await selecionarProjeto(escopoId);
  }

  Future<void> carregarClassesProjeto(int projetoId) async {
    await selecionarProjeto(projetoId);
  }

  Future<void> _carregarClassesDoProgramaDoProjeto(int projetoId) async {
    final token = ++_tokenClasses;
    iniciarCarregamento();
    try {
      final progId = _hierarquia.projetoPorId(projetoId)?.programaId;
      final classes = await _repositorio.listarClassesEvento(
        programaId: progId,
        escopo: NivelEscopo.programa,
        escopoId: progId,
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
        _escopo = NivelEscopo.projeto;
        _escopoId = _evento!.projetoId;
      }
      final projId = _escopoId;
      if (projId != null) {
        final progId = _hierarquia.projetoPorId(projId)?.programaId;
        _classes = await _repositorio.listarClassesEvento(
          programaId: progId,
          escopo: NivelEscopo.programa,
          escopoId: progId,
        );
      } else {
        _classes = [];
      }
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
      final targetProjetoId = projetoId ?? _escopoId ?? escopoId;

      if (targetProjetoId == null) {
        throw Exception('Selecione um projeto.');
      }

      final classeId = classeEventoId;

      if (classeId == null || classeId <= 0) {
        throw Exception('Selecione uma classe de evento.');
      }

      if (eventoId == null) {
        await _repositorio.criarEvento(
          projetoId: targetProjetoId,
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
          projetoId: targetProjetoId,
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

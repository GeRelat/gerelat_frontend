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
  NivelEscopo _escopo = NivelEscopo.programa;
  int? _escopoId;
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<ClasseEvento> _classes = [];

  int _tokenClasses = 0;

  ClasseEventoViewModel(this._repositorio);

  HierarquiaEscopo get hierarquia => _hierarquia;
  NivelEscopo get escopo => _escopo;
  int? get escopoId => _escopoId;
  int? get programaSelecionadoId => _escopoId;
  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;

  List<NivelEscopo> get niveisPermitidos => const [NivelEscopo.programa];

  bool podeEditarPrograma(int? programaId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (programaId == null) return false;
    return usuario.contextosAcesso.programas
        .any((p) => int.tryParse('${p['id']}') == programaId);
  }

  bool get podeEditar => podeEditarPrograma(_escopoId);

  bool temAcessoAoPrograma(int? programaId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (programaId == null) return false;
    if (podeEditarPrograma(programaId)) return true;

    // Membros de projetos do programa têm acesso de leitura
    return usuario.contextosAcesso.projetos.any((p) {
      final projId = int.tryParse('${p['id']}');
      final progId = _hierarquia.projetoPorId(projId)?.programaId;
      return progId == programaId;
    });
  }

  List<OpcaoSelecao> get opcoesProgramas {
    final todas = _hierarquia.opcoesDe(NivelAplicacao.programa, clienteId: _clienteAtivoId);
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return todas;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) return todas;

    return todas.where((op) => temAcessoAoPrograma(op.id)).toList();
  }

  List<OpcaoSelecao> get opcoesEscopo => opcoesProgramas;

  List<ClasseEvento> get classes => List.unmodifiable(_classes);

  // Backward compatibility getters
  List<OpcaoSelecao> get projetos => _hierarquia.opcoesDeEscopo(NivelEscopo.projeto, clienteId: _clienteAtivoId);
  int? get projetoSelecionadoId => null;

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final mudou = _clienteAtivoId != clienteAtivoId || _usuarioAtual != usuarioAtual;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;

    _ajustarSelecaoEscopo();

    if (mudou) {
      notifyListeners();
      if (_escopoId != null) {
        selecionarPrograma(_escopoId);
      }
    }
  }

  void _ajustarSelecaoEscopo() {
    _escopo = NivelEscopo.programa;
    final opcoes = opcoesProgramas;
    if (_escopoId == null || !opcoes.any((o) => o.id == _escopoId)) {
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

  Future<void> selecionarPrograma(int? programaId) async {
    _escopo = NivelEscopo.programa;
    _escopoId = programaId;
    _classes = [];
    final token = ++_tokenClasses;
    notifyListeners();
    if (programaId == null) return;

    iniciarCarregamento();
    try {
      final classes = await _repositorio.listarClassesEventoDetalhadas(
        programaId: programaId,
      );
      if (token != _tokenClasses) return;
      _classes = classes;
      finalizarCarregamento();
    } catch (erro) {
      if (token != _tokenClasses) return;
      definirErro(erro);
    }
  }

  Future<void> selecionarEscopo(NivelEscopo escopo, int? escopoId) async {
    await selecionarPrograma(escopoId);
  }

  Future<void> selecionarProjeto(int? projetoId) async {
    await selecionarPrograma(projetoId);
  }

  Future<bool> salvar({int? classeId, required String nomeClasse}) {
    return _executarAcaoClasse((programaId) async {
      if (classeId == null) {
        await _repositorio.criarClasseEvento(
          programaId: programaId,
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
      (_) => _repositorio.excluirClasseEvento(classeId),
    );
  }

  Future<bool> _executarAcaoClasse(
    Future<void> Function(int programaId) acao,
  ) async {
    final programaId = _escopoId;
    if (programaId == null) return false;

    iniciarCarregamento();
    try {
      await acao(programaId);
      _classes = await _repositorio.listarClassesEventoDetalhadas(
        programaId: programaId,
      );
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

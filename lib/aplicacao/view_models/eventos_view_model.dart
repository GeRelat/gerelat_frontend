import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class EventosViewModel extends BaseViewModel {
  final RepositorioEventos _repositorio;
  final RepositorioCatalogo _catalogo;
  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<Evento> _eventos = [];
  List<ClasseEvento> _classes = [];
  String _termoBusca = '';
  String _filtroPeriodo = 'Todos';
  int? _filtroProgramaId;
  int? _filtroProjetoId;
  int? _filtroClasseId;

  // Compatibilidade com código/testes legados
  NivelEscopo? _filtroNivel;
  int? _filtroEscopoId;

  EventosViewModel(RepositorioCatalogo repositorio)
    : _repositorio = repositorio,
      _catalogo = repositorio;

  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;
  int? get filtroProgramaId => _filtroProgramaId;
  int? get filtroProjetoId => _filtroProjetoId;
  int? get filtroClasseId => _filtroClasseId;
  NivelEscopo? get filtroNivel => _filtroNivel;
  int? get filtroEscopoId => _filtroEscopoId;

  List<NivelEscopo> get niveisPermitidos =>
      const [NivelEscopo.programa, NivelEscopo.projeto];

  bool temAcessoAoPrograma(int? programaId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (programaId == null) return false;
    if (usuario.contextosAcesso.programas
        .any((p) => int.tryParse('${p['id']}') == programaId)) {
      return true;
    }
    return usuario.contextosAcesso.projetos.any((p) {
      final projId = int.tryParse('${p['id']}');
      return _hierarquia.projetoPorId(projId)?.programaId == programaId;
    });
  }

  bool temAcessoAoProjeto(int? projetoId) {
    final usuario = _usuarioAtual;
    if (usuario == null) return true;
    if (usuario.isAdminGeRelat) return true;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return true;
    }
    if (projetoId == null) return false;

    if (usuario.contextosAcesso.projetos
        .any((p) => int.tryParse('${p['id']}') == projetoId)) {
      return true;
    }
    final progPaiId = _hierarquia.projetoPorId(projetoId)?.programaId;
    return progPaiId != null &&
        usuario.contextosAcesso.programas
            .any((p) => int.tryParse('${p['id']}') == progPaiId);
  }

  List<OpcaoSelecao> get opcoesProgramas {
    final todas =
        _hierarquia.opcoesDe(NivelAplicacao.programa, clienteId: _clienteAtivoId);
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return todas;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return todas;
    }
    return todas.where((op) => temAcessoAoPrograma(op.id)).toList();
  }

  List<OpcaoSelecao> get opcoesProjetos {
    final todas =
        _hierarquia.opcoesDe(NivelAplicacao.projeto, clienteId: _clienteAtivoId);
    Iterable<OpcaoSelecao> filtradas = todas;
    if (_filtroProgramaId != null) {
      filtradas = filtradas.where((op) {
        return _hierarquia.projetoPorId(op.id)?.programaId == _filtroProgramaId;
      });
    }
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return filtradas.toList();
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return filtradas.toList();
    }
    return filtradas.where((op) => temAcessoAoProjeto(op.id)).toList();
  }

  List<OpcaoSelecao> get opcoesFiltroEscopo => opcoesProjetos;

  List<ClasseEvento> get classes {
    Iterable<ClasseEvento> resultado = _classes;
    if (_filtroProjetoId != null) {
      final progId = _hierarquia.projetoPorId(_filtroProjetoId)?.programaId;
      if (progId != null) {
        resultado = resultado.where((c) => c.programaId == progId);
      }
    } else if (_filtroProgramaId != null) {
      resultado = resultado.where((c) => c.programaId == _filtroProgramaId);
    }
    return List.unmodifiable(resultado);
  }

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final clienteMudou = _clienteAtivoId != clienteAtivoId;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;
    if (clienteMudou) {
      _filtroProgramaId = null;
      _filtroProjetoId = null;
      _filtroClasseId = null;
      _filtroNivel = null;
      _filtroEscopoId = null;
      notifyListeners();
      carregar();
    }
  }

  void definirClienteAtivoId(int? clienteId) {
    if (_clienteAtivoId == clienteId) return;
    _clienteAtivoId = clienteId;
    carregar();
  }

  void definirFiltroProgramaId(int? programaId) {
    _filtroProgramaId = programaId;
    if (_filtroProjetoId != null) {
      final progPai = _hierarquia.projetoPorId(_filtroProjetoId)?.programaId;
      if (programaId != null && progPai != programaId) {
        _filtroProjetoId = null;
      }
    }
    _filtroClasseId = null;
    notifyListeners();
  }

  void definirFiltroProjetoId(int? projetoId) {
    _filtroProjetoId = projetoId;
    if (projetoId != null) {
      final progPai = _hierarquia.projetoPorId(projetoId)?.programaId;
      if (progPai != null) {
        _filtroProgramaId = progPai;
      }
    }
    _filtroClasseId = null;
    notifyListeners();
  }

  void definirFiltroNivel(NivelEscopo? nivel) {
    _filtroNivel = nivel;
    _filtroEscopoId = null;
    _filtroClasseId = null;
    if (nivel == NivelEscopo.programa) {
      _filtroProjetoId = null;
    } else if (nivel == null) {
      _filtroProgramaId = null;
      _filtroProjetoId = null;
    }
    notifyListeners();
  }

  void definirFiltroEscopoId(int? escopoId) {
    _filtroEscopoId = escopoId;
    _filtroClasseId = null;
    if (_filtroNivel == NivelEscopo.programa) {
      _filtroProgramaId = escopoId;
      _filtroProjetoId = null;
    } else if (_filtroNivel == NivelEscopo.projeto) {
      definirFiltroProjetoId(escopoId);
    }
    notifyListeners();
  }

  void definirFiltroClasseId(int? classeId) {
    _filtroClasseId = classeId;
    notifyListeners();
  }

  List<Evento> get eventos {
    Iterable<Evento> resultado = _eventos;
    final termo = _termoBusca.trim().toLowerCase();

    if (_filtroProjetoId != null) {
      resultado = resultado.where((e) => e.projetoId == _filtroProjetoId);
    } else if (_filtroProgramaId != null) {
      resultado = resultado.where((e) {
        final progId = _hierarquia.projetoPorId(e.projetoId)?.programaId;
        return progId == _filtroProgramaId;
      });
    }

    if (_filtroClasseId != null) {
      resultado = resultado.where((e) => e.classeEventoId == _filtroClasseId);
    }

    if (termo.isNotEmpty) {
      resultado = resultado.where(
        (evento) =>
            evento.nome.toLowerCase().contains(termo) ||
            evento.programa.toLowerCase().contains(termo) ||
            evento.local.toLowerCase().contains(termo) ||
            evento.objetivo.toLowerCase().contains(termo),
      );
    }

    if (_filtroPeriodo == 'Este mês') {
      final agora = DateTime.now();
      resultado = resultado.where((evento) {
        final data = evento.data;
        return data != null &&
            data.month == agora.month &&
            data.year == agora.year;
      });
    } else if (_filtroPeriodo == 'Este ano') {
      final agora = DateTime.now();
      resultado = resultado.where((evento) {
        final data = evento.data;
        return data != null && data.year == agora.year;
      });
    }

    return resultado.toList(growable: false);
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(_catalogo, comEventos: true);
      final todos = await _repositorio.listarEventos();
      final todasClasses = await _repositorio.listarClassesEventoDoAlcance(
        clienteId: _clienteAtivoId,
      );

      if (_clienteAtivoId != null) {
        _eventos = todos.where((e) {
          final clienteId = e.projetoId != null
              ? _hierarquia.cadeiaDe(NivelAplicacao.projeto, e.projetoId).clienteId
              : _hierarquia.cadeiaDe(NivelAplicacao.evento, e.id).clienteId;
          return clienteId == _clienteAtivoId;
        }).toList();

        _classes = todasClasses.where((c) {
          if (c.programaId != null) {
            return _hierarquia.programaPorId(c.programaId)?.clienteId ==
                _clienteAtivoId;
          }
          return true;
        }).toList();
      } else {
        _eventos = todos;
        _classes = todasClasses;
      }
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  void definirBusca(String valor) {
    _termoBusca = valor;
    notifyListeners();
  }

  void definirFiltroPeriodo(String valor) {
    _filtroPeriodo = valor;
    notifyListeners();
  }

  String get filtroPeriodo => _filtroPeriodo;

  Future<bool> excluir(int eventoId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirEvento(eventoId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

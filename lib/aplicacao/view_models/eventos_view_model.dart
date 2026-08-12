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
  NivelEscopo? _filtroNivel;
  int? _filtroEscopoId;
  int? _filtroClasseId;

  EventosViewModel(RepositorioCatalogo repositorio)
    : _repositorio = repositorio,
      _catalogo = repositorio;

  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;
  NivelEscopo? get filtroNivel => _filtroNivel;
  int? get filtroEscopoId => _filtroEscopoId;
  int? get filtroClasseId => _filtroClasseId;
  List<ClasseEvento> get classes {
    Iterable<ClasseEvento> resultado = _classes;

    if (_filtroNivel != null) {
      resultado = resultado.where((c) {
        if (_filtroNivel == NivelEscopo.cliente) {
          return (c.clienteId == _clienteAtivoId || c.escopo == NivelEscopo.cliente) &&
              c.programaId == null &&
              c.projetoId == null;
        } else if (_filtroNivel == NivelEscopo.programa) {
          if (_filtroEscopoId != null) {
            return c.programaId == _filtroEscopoId && c.projetoId == null;
          }
          return c.programaId != null && c.projetoId == null;
        } else if (_filtroNivel == NivelEscopo.projeto) {
          if (_filtroEscopoId != null) {
            return c.projetoId == _filtroEscopoId;
          }
          return c.projetoId != null;
        }
        return true;
      });
    }

    return List.unmodifiable(resultado);
  }

  List<NivelEscopo> get niveisPermitidos {
    final usuario = _usuarioAtual;
    if (usuario == null) return NivelEscopo.values;
    if (usuario.isAdminGeRelat) return NivelEscopo.values;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) {
      return NivelEscopo.values;
    }
    final result = <NivelEscopo>[];
    final temPrograma = usuario.contextosAcesso.programas.any((p) {
      if (_clienteAtivoId == null) return true;
      final pId = int.tryParse('${p['id']}');
      return _hierarquia.programaPorId(pId)?.clienteId == _clienteAtivoId;
    });
    if (temPrograma) {
      result.add(NivelEscopo.programa);
      result.add(NivelEscopo.projeto);
    }
    final temProjeto = usuario.contextosAcesso.projetos.any((p) {
      if (_clienteAtivoId == null) return true;
      final projId = int.tryParse('${p['id']}');
      final cId = _hierarquia.cadeiaDe(NivelAplicacao.projeto, projId).clienteId;
      return cId == _clienteAtivoId;
    });
    if (temProjeto && !result.contains(NivelEscopo.projeto)) {
      result.add(NivelEscopo.projeto);
    }
    return result.isEmpty ? [NivelEscopo.projeto] : result;
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

  List<OpcaoSelecao> get opcoesFiltroEscopo {
    final nivel = _filtroNivel;
    if (nivel == null) return const [];
    final todas = _hierarquia.opcoesDeEscopo(nivel, clienteId: _clienteAtivoId);
    final usuario = _usuarioAtual;
    if (usuario == null || usuario.isAdminGeRelat) return todas;
    if (_clienteAtivoId != null && usuario.eAdminDoCliente(_clienteAtivoId)) return todas;

    return todas.where((op) => temPermissaoNoEscopo(nivel, op.id)).toList();
  }

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final clienteMudou = _clienteAtivoId != clienteAtivoId;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;
    if (clienteMudou) {
      _filtroNivel = null;
      _filtroEscopoId = null;
      _filtroClasseId = null;
      notifyListeners();
      carregar();
    }
  }

  void definirClienteAtivoId(int? clienteId) {
    if (_clienteAtivoId == clienteId) return;
    _clienteAtivoId = clienteId;
    carregar();
  }

  void definirFiltroNivel(NivelEscopo? nivel) {
    _filtroNivel = nivel;
    _filtroEscopoId = null;
    _filtroClasseId = null;
    notifyListeners();
  }

  void definirFiltroEscopoId(int? escopoId) {
    _filtroEscopoId = escopoId;
    _filtroClasseId = null;
    notifyListeners();
  }

  void definirFiltroClasseId(int? classeId) {
    _filtroClasseId = classeId;
    notifyListeners();
  }

  List<Evento> get eventos {
    Iterable<Evento> resultado = _eventos;
    final termo = _termoBusca.trim().toLowerCase();

    if (_filtroNivel != null) {
      resultado = resultado.where((e) {
        final escopoDoEvento = e.escopo;
        if (escopoDoEvento != null) {
          if (escopoDoEvento != _filtroNivel) return false;
          if (_filtroEscopoId != null && e.escopoId != _filtroEscopoId) {
            return false;
          }
          return true;
        }

        final cadeia = _hierarquia.cadeiaDe(NivelAplicacao.evento, e.id);
        if (_filtroNivel == NivelEscopo.cliente) {
          return cadeia.clienteId == _clienteAtivoId &&
              cadeia.programaId == null &&
              cadeia.projetoId == null;
        } else if (_filtroNivel == NivelEscopo.programa) {
          if (cadeia.projetoId != null || cadeia.programaId == null) {
            return false;
          }
          if (_filtroEscopoId != null) return cadeia.programaId == _filtroEscopoId;
          return true;
        } else if (_filtroNivel == NivelEscopo.projeto) {
          if (cadeia.projetoId == null) return false;
          if (_filtroEscopoId != null) return cadeia.projetoId == _filtroEscopoId;
          return true;
        }
        return false;
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
          final clienteId = e.escopo != null && e.escopoId != null
              ? _hierarquia.cadeiaDeEscopo(e.escopo!, e.escopoId).clienteId
              : _hierarquia.cadeiaDe(NivelAplicacao.evento, e.id).clienteId;
          return clienteId == _clienteAtivoId;
        }).toList();

        _classes = todasClasses.where((c) {
          if (c.clienteId != null) return c.clienteId == _clienteAtivoId;
          if (c.programaId != null) {
            return _hierarquia.programaPorId(c.programaId)?.clienteId ==
                _clienteAtivoId;
          }
          if (c.projetoId != null) {
            return _hierarquia
                    .cadeiaDe(NivelAplicacao.projeto, c.projetoId)
                    .clienteId ==
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

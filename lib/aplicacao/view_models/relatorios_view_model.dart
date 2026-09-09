import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RelatoriosViewModel extends BaseViewModel {
  final RepositorioRelatorios _repositorio;
  final RepositorioCatalogo _catalogo;
  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<Relatorio> _relatorios = [];
  Map<int, TemplateRelatorio> _templatesPorId = {};
  String _termoBusca = '';
  NivelEscopo? _filtroNivel;
  int? _filtroEscopoId;
  String? _mensagemErroAcao;

  RelatoriosViewModel(RepositorioCatalogo repositorio)
    : _repositorio = repositorio,
      _catalogo = repositorio;

  int? get clienteAtivoId => _clienteAtivoId;
  Usuario? get usuarioAtual => _usuarioAtual;
  NivelEscopo? get filtroNivel => _filtroNivel;
  int? get filtroEscopoId => _filtroEscopoId;

  List<NivelEscopo> get niveisPermitidos {
    final usuario = _usuarioAtual;
    if (usuario == null) return NivelEscopo.selecionaveis;
    if (usuario.isAdminGeRelat || usuario.eAdminDoCliente(_clienteAtivoId)) {
      return NivelEscopo.selecionaveis;
    }

    final eMembroPrograma = usuario.contextosAcesso.programas.any((p) {
      if (_clienteAtivoId == null) return true;
      final cId = int.tryParse('${p['cliente_id']}');
      return cId == _clienteAtivoId;
    });

    if (eMembroPrograma) {
      return const [NivelEscopo.programa, NivelEscopo.projeto];
    }

    final eMembroProjeto = usuario.contextosAcesso.projetos.any((p) {
      if (_clienteAtivoId == null) return true;
      final cId = int.tryParse('${p['cliente_id']}');
      return cId == _clienteAtivoId;
    });

    if (eMembroProjeto) {
      return const [NivelEscopo.projeto];
    }

    return const [NivelEscopo.projeto];
  }

  List<OpcaoSelecao> get opcoesFiltroEscopo {
    final nivel = _filtroNivel;
    if (nivel == null) return const [];
    return _hierarquia.opcoesDeEscopo(nivel, clienteId: _clienteAtivoId);
  }

  void definirFiltroNivel(NivelEscopo? nivel) {
    _filtroNivel = nivel;
    _filtroEscopoId = null;
    notifyListeners();
  }

  void definirFiltroEscopoId(int? escopoId) {
    _filtroEscopoId = escopoId;
    notifyListeners();
  }

  void definirContexto(int? clienteAtivoId, Usuario? usuarioAtual) {
    final clienteMudou = _clienteAtivoId != clienteAtivoId;
    _clienteAtivoId = clienteAtivoId;
    _usuarioAtual = usuarioAtual;

    final permitidos = niveisPermitidos;
    if (_filtroNivel != null && permitidos.isNotEmpty && !permitidos.contains(_filtroNivel)) {
      _filtroNivel = null;
      _filtroEscopoId = null;
    }

    if (clienteMudou) {
      carregar();
    } else {
      notifyListeners();
    }
  }

  void definirClienteAtivoId(int? clienteId) {
    definirContexto(clienteId, _usuarioAtual);
  }

  // Erro de uma ação pontual (baixar/renomear/excluir um item), separado de
  // `mensagemErro` — que é reservado para falha da carga da lista. Antes,
  // essas ações reaproveitavam `iniciarCarregamento`/`definirErro`, o que
  // trocava a lista inteira pela tela de erro a cada falha pontual, mesmo com
  // a lista já carregada.
  String? get mensagemErroAcao => _mensagemErroAcao;

  List<Relatorio> get relatorios {
    var lista = _relatorios;

    if (_filtroNivel != null) {
      lista = lista.where((r) {
        final t = _templatesPorId[r.templateId];
        if (t != null) {
          if (t.nivel != _filtroNivel) return false;
          if (_filtroEscopoId != null) {
            if (_filtroNivel == NivelEscopo.programa) {
              return t.programaId == _filtroEscopoId;
            } else if (_filtroNivel == NivelEscopo.projeto) {
              return t.projetoId == _filtroEscopoId;
            }
          }
          return true;
        }

        // Fallback por evento caso o template não esteja no mapa
        final cadeia = _hierarquia.cadeiaDe(NivelAplicacao.evento, r.eventoId);
        if (_filtroNivel == NivelEscopo.cliente) {
          return cadeia.clienteId == _clienteAtivoId &&
              cadeia.programaId == null &&
              cadeia.projetoId == null;
        } else if (_filtroNivel == NivelEscopo.programa) {
          if (cadeia.projetoId != null || cadeia.programaId == null) {
            return false;
          }
          if (_filtroEscopoId != null) {
            return cadeia.programaId == _filtroEscopoId;
          }
          return true;
        } else if (_filtroNivel == NivelEscopo.projeto) {
          if (cadeia.projetoId == null) return false;
          if (_filtroEscopoId != null) {
            return cadeia.projetoId == _filtroEscopoId;
          }
          return true;
        }
        return false;
      }).toList();
    }

    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isNotEmpty) {
      lista = lista
          .where((relatorio) {
            return relatorio.titulo.toLowerCase().contains(termo) ||
                relatorio.evento.toLowerCase().contains(termo) ||
                relatorio.template.toLowerCase().contains(termo) ||
                relatorio.status.toLowerCase().contains(termo);
          })
          .toList(growable: false);
    }

    return List.unmodifiable(lista);
  }

  bool get estaVazio => relatorios.isEmpty;

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(_catalogo, comEventos: true);
      final todosRelatorios = await _repositorio.listarRelatorios();
      final todosTemplates = await _catalogo.listarTemplates();
      _templatesPorId = {
        for (final t in todosTemplates)
          if (t.id != null) t.id!: t,
      };

      if (_clienteAtivoId != null) {
        _relatorios = todosRelatorios.where((r) {
          final t = _templatesPorId[r.templateId];
          if (t != null) {
            final clienteId =
                _hierarquia.cadeiaDeEscopo(t.nivel, t.escopoId).clienteId;
            return clienteId == _clienteAtivoId;
          }
          if (r.eventoId != null) {
            final clienteId =
                _hierarquia.cadeiaDe(NivelAplicacao.evento, r.eventoId).clienteId;
            return clienteId == _clienteAtivoId;
          }
          return true;
        }).toList();
      } else {
        _relatorios = todosRelatorios;
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

  Future<Uint8List?> baixar(int relatorioId) async {
    try {
      return await _repositorio.baixarRelatorio(relatorioId);
    } catch (erro) {
      _definirErroAcao(erro);
      return null;
    }
  }

  Future<bool> renomear({
    required int relatorioId,
    required String nome,
  }) async {
    try {
      await _repositorio.atualizarRelatorio(
        relatorioId: relatorioId,
        nome: nome,
      );
      await carregar();
      return true;
    } catch (erro) {
      _definirErroAcao(erro);
      return false;
    }
  }

  Future<bool> excluir(int relatorioId) async {
    try {
      await _repositorio.excluirRelatorio(relatorioId);
      await carregar();
      return true;
    } catch (erro) {
      _definirErroAcao(erro);
      return false;
    }
  }

  /// Registra o erro de uma ação pontual (ver comentário de
  /// [mensagemErroAcao]) e notifica os listeners — mesmo tratamento usado
  /// por [baixar], [renomear] e [excluir].
  void _definirErroAcao(Object erro) {
    _mensagemErroAcao = erro.toString();
    notifyListeners();
  }
}

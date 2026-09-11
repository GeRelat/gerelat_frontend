import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/usuario.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplatesViewModel extends BaseViewModel {
  final RepositorioTemplates _repositorio;
  final RepositorioCatalogo _catalogo;
  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  int? _clienteAtivoId;
  Usuario? _usuarioAtual;
  List<TemplateRelatorio> _templates = [];
  String _termoBusca = '';
  NivelEscopo? _filtroNivel;
  int? _filtroEscopoId;
  String? _mensagemErroAcao;

  TemplatesViewModel(RepositorioCatalogo repositorio)
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

    final eMembroProjeto = usuario.contextosAcesso.projetos.any((p) {
      if (_clienteAtivoId == null) return true;
      final cId = int.tryParse('${p['cliente_id']}');
      return cId == _clienteAtivoId;
    });

    if (eMembroPrograma || eMembroProjeto) {
      return const [NivelEscopo.programa, NivelEscopo.projeto];
    }

    return NivelEscopo.selecionaveis;
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

  /// Nome da entidade dona do template, para exibir junto do nível no cartão.
  String donoDoTemplate(TemplateRelatorio template) =>
      _hierarquia.nomeDeEscopo(template.nivel, template.escopoId);

  /// Verifica se o usuário autenticado tem permissão para editar metadados ou
  /// conteúdo ProseMirror do template. Membros de projetos podem visualizar e
  /// gerar relatórios a partir de templates de programa, mas não podem editá-los.
  bool podeEditarTemplate(TemplateRelatorio template) {
    final usuario = _usuarioAtual;
    if (usuario == null) return false;
    if (usuario.isAdminGeRelat) return true;
    if (usuario.eAdminDoCliente(_clienteAtivoId)) return true;

    if (template.nivel == NivelEscopo.programa) {
      return usuario.contextosAcesso.programas.any((p) {
        final progId = int.tryParse('${p['id']}');
        return progId == template.programaId;
      });
    }

    if (template.nivel == NivelEscopo.projeto) {
      final eMembroDoProgramaPai = usuario.contextosAcesso.programas.any((p) {
        final progId = int.tryParse('${p['id']}');
        final c = _hierarquia.cadeiaDe(NivelAplicacao.projeto, template.projetoId);
        return progId == c.programaId;
      });
      if (eMembroDoProgramaPai) return true;

      return usuario.contextosAcesso.projetos.any((p) {
        final projId = int.tryParse('${p['id']}');
        return projId == template.projetoId;
      });
    }

    return false;
  }

  /// Exclusão segue as mesmas permissões de edição.
  bool podeExcluirTemplate(TemplateRelatorio template) =>
      podeEditarTemplate(template);

  // Erro de uma ação pontual (excluir/baixar um item), separado de
  // `mensagemErro` — que é reservado para falha da carga da lista. Antes,
  // excluir/baixar reaproveitava `iniciarCarregamento`/`definirErro`, o que
  // trocava a grade inteira pela tela de erro (ou pelo spinner, derrubando o
  // card no meio da ação) a cada falha pontual, mesmo com a lista já
  // carregada.
  String? get mensagemErroAcao => _mensagemErroAcao;

  List<TemplateRelatorio> get templates {
    // Templates de nível cliente (legados) não são mais expostos na interface.
    var lista = _templates
        .where((t) => t.nivel != NivelEscopo.cliente)
        .toList();

    if (_filtroNivel != null) {
      lista = lista.where((t) => t.nivel == _filtroNivel).toList();
      if (_filtroEscopoId != null) {
        if (_filtroNivel == NivelEscopo.programa) {
          lista = lista.where((t) => t.programaId == _filtroEscopoId).toList();
        } else if (_filtroNivel == NivelEscopo.projeto) {
          lista = lista.where((t) => t.projetoId == _filtroEscopoId).toList();
        }
      }
    }

    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isNotEmpty) {
      lista = lista.where((template) => _correspondeABusca(template, termo)).toList();
    }

    return List.unmodifiable(lista);
  }

  /// Verifica se o termo buscado aparece em algum dos campos identificáveis
  /// do template (nome ou descrição).
  bool _correspondeABusca(TemplateRelatorio template, String termo) {
    return template.nome.toLowerCase().contains(termo) ||
        template.descricao.toLowerCase().contains(termo);
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _catalogo,
        comEventos: false,
      );
      final todos = await _repositorio.listarTemplates();
      if (_clienteAtivoId != null) {
        _templates = todos.where((t) {
          final clienteId =
              _hierarquia.cadeiaDeEscopo(t.nivel, t.escopoId).clienteId;
          return clienteId == _clienteAtivoId;
        }).toList();
      } else {
        _templates = todos;
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

  Future<bool> excluir(int templateId) async {
    try {
      await _repositorio.excluirTemplate(templateId);
      await carregar();
      return true;
    } catch (erro) {
      _definirErroAcao(erro);
      return false;
    }
  }

  Future<Uint8List?> baixarArquivo(int templateId) async {
    try {
      return await _repositorio.baixarArquivoTemplate(templateId);
    } catch (erro) {
      _definirErroAcao(erro);
      return null;
    }
  }

  /// Registra o erro de uma ação pontual (ver comentário de
  /// [mensagemErroAcao]) e notifica os listeners — mesmo tratamento usado
  /// por [excluir] e [baixarArquivo].
  void _definirErroAcao(Object erro) {
    _mensagemErroAcao = erro.toString();
    notifyListeners();
  }
}

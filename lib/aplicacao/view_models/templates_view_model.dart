import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplatesViewModel extends BaseViewModel {
  final RepositorioTemplates _repositorio;
  final RepositorioCatalogo _catalogo;
  HierarquiaEscopo _hierarquia = const HierarquiaEscopo();
  List<TemplateRelatorio> _templates = [];
  String _termoBusca = '';
  String? _mensagemErroAcao;

  TemplatesViewModel(RepositorioCatalogo repositorio)
    : _repositorio = repositorio,
      _catalogo = repositorio;

  /// Nome da entidade dona do template, para exibir junto do nível no cartão.
  String donoDoTemplate(TemplateRelatorio template) =>
      _hierarquia.nomeDeEscopo(template.nivel, template.escopoId);

  // Erro de uma ação pontual (excluir/baixar um item), separado de
  // `mensagemErro` — que é reservado para falha da carga da lista. Antes,
  // excluir/baixar reaproveitava `iniciarCarregamento`/`definirErro`, o que
  // trocava a grade inteira pela tela de erro (ou pelo spinner, derrubando o
  // card no meio da ação) a cada falha pontual, mesmo com a lista já
  // carregada.
  String? get mensagemErroAcao => _mensagemErroAcao;

  List<TemplateRelatorio> get templates {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return List.unmodifiable(_templates);
    return _templates
        .where((template) => _correspondeABusca(template, termo))
        .toList(growable: false);
  }

  /// Verifica se o termo buscado aparece em algum dos campos identificáveis
  /// do template (nome, descrição, arquivo base).
  bool _correspondeABusca(TemplateRelatorio template, String termo) {
    return template.nome.toLowerCase().contains(termo) ||
        template.descricao.toLowerCase().contains(termo) ||
        template.arquivoBase.toLowerCase().contains(termo);
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _hierarquia = await HierarquiaEscopo.carregar(
        _catalogo,
        comEventos: false,
      );
      _templates = await _repositorio.listarTemplates();
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

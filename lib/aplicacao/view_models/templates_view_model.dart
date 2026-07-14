import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplatesViewModel extends BaseViewModel {
  final RepositorioTemplates _repositorio;
  List<TemplateRelatorio> _templates = [];
  String _termoBusca = '';
  String? _mensagemErroAcao;

  TemplatesViewModel(this._repositorio);

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
        .where((template) {
          return template.nome.toLowerCase().contains(termo) ||
              template.descricao.toLowerCase().contains(termo) ||
              template.arquivoBase.toLowerCase().contains(termo);
        })
        .toList(growable: false);
  }

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
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
      _mensagemErroAcao = erro.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Uint8List?> baixarArquivo(int templateId) async {
    try {
      return await _repositorio.baixarArquivoTemplate(templateId);
    } catch (erro) {
      _mensagemErroAcao = erro.toString();
      notifyListeners();
      return null;
    }
  }
}

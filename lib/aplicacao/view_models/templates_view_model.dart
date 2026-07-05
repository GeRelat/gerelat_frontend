import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class TemplatesViewModel extends BaseViewModel {
  final RepositorioTemplates _repositorio;
  List<TemplateRelatorio> _templates = [];
  String _termoBusca = '';

  TemplatesViewModel(this._repositorio);

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
    iniciarCarregamento();
    try {
      await _repositorio.excluirTemplate(templateId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<Uint8List?> baixarArquivo(int templateId) async {
    iniciarCarregamento();
    try {
      final bytes = await _repositorio.baixarArquivoTemplate(templateId);
      finalizarCarregamento();
      return bytes;
    } catch (erro) {
      definirErro(erro);
      return null;
    }
  }
}

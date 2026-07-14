import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RelatoriosViewModel extends BaseViewModel {
  final RepositorioRelatorios _repositorio;
  List<Relatorio> _relatorios = [];
  String _termoBusca = '';
  String? _mensagemErroAcao;

  RelatoriosViewModel(this._repositorio);

  // Erro de uma ação pontual (baixar/renomear/excluir um item), separado de
  // `mensagemErro` — que é reservado para falha da carga da lista. Antes,
  // essas ações reaproveitavam `iniciarCarregamento`/`definirErro`, o que
  // trocava a lista inteira pela tela de erro a cada falha pontual, mesmo com
  // a lista já carregada.
  String? get mensagemErroAcao => _mensagemErroAcao;

  List<Relatorio> get relatorios {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return List.unmodifiable(_relatorios);
    return _relatorios
        .where((relatorio) {
          return relatorio.titulo.toLowerCase().contains(termo) ||
              relatorio.evento.toLowerCase().contains(termo) ||
              relatorio.template.toLowerCase().contains(termo) ||
              relatorio.status.toLowerCase().contains(termo);
        })
        .toList(growable: false);
  }

  bool get estaVazio => relatorios.isEmpty;

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _relatorios = await _repositorio.listarRelatorios();
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
      _mensagemErroAcao = erro.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> renomear({required int relatorioId, required String nome}) async {
    try {
      await _repositorio.atualizarRelatorio(relatorioId: relatorioId, nome: nome);
      await carregar();
      return true;
    } catch (erro) {
      _mensagemErroAcao = erro.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> excluir(int relatorioId) async {
    try {
      await _repositorio.excluirRelatorio(relatorioId);
      await carregar();
      return true;
    } catch (erro) {
      _mensagemErroAcao = erro.toString();
      notifyListeners();
      return false;
    }
  }
}

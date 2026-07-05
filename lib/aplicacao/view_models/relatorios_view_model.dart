import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class RelatoriosViewModel extends BaseViewModel {
  final RepositorioRelatorios _repositorio;
  List<Relatorio> _relatorios = [];
  String _termoBusca = '';

  RelatoriosViewModel(this._repositorio);

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
    iniciarCarregamento();
    try {
      final bytes = await _repositorio.baixarRelatorio(relatorioId);
      finalizarCarregamento();
      return bytes;
    } catch (erro) {
      definirErro(erro);
      return null;
    }
  }

  Future<bool> renomear({required int relatorioId, required String nome}) async {
    iniciarCarregamento();
    try {
      await _repositorio.atualizarRelatorio(relatorioId: relatorioId, nome: nome);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> excluir(int relatorioId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirRelatorio(relatorioId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

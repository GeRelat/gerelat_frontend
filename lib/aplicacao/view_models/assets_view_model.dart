import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class AssetsViewModel extends BaseViewModel {
  final RepositorioAssets _repositorio;
  List<Asset> _assets = [];

  AssetsViewModel(this._repositorio);

  List<Asset> get assets => List.unmodifiable(_assets);

  Future<void> carregar() async {
    iniciarCarregamento();
    try {
      _assets = await _repositorio.listarAssets();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> enviar({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    String descricao = '',
  }) async {
    iniciarCarregamento();
    try {
      await _repositorio.criarAsset(
        arquivoBytes: arquivoBytes,
        nomeArquivo: nomeArquivo,
        descricao: descricao,
      );
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> atualizarDescricao({
    required int assetId,
    required String descricao,
  }) async {
    iniciarCarregamento();
    try {
      await _repositorio.atualizarAsset(assetId: assetId, descricao: descricao);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> excluir(int assetId) async {
    iniciarCarregamento();
    try {
      await _repositorio.excluirAsset(assetId);
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

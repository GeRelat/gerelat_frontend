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
  }) {
    return _executarAcao(
      () => _repositorio.criarAsset(
        arquivoBytes: arquivoBytes,
        nomeArquivo: nomeArquivo,
        descricao: descricao,
      ),
    );
  }

  Future<bool> atualizarDescricao({
    required int assetId,
    required String descricao,
  }) {
    return _executarAcao(
      () => _repositorio.atualizarAsset(assetId: assetId, descricao: descricao),
    );
  }

  Future<bool> excluir(int assetId) {
    return _executarAcao(() => _repositorio.excluirAsset(assetId));
  }

  /// Executa uma ação de escrita (criar/atualizar/excluir), recarregando a
  /// lista em caso de sucesso — mesmo tratamento usado por [enviar],
  /// [atualizarDescricao] e [excluir].
  Future<bool> _executarAcao(Future<void> Function() acao) async {
    iniciarCarregamento();
    try {
      await acao();
      await carregar();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }
}

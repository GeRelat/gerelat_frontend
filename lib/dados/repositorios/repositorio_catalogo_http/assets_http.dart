import 'dart:typed_data';

import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioAssetsHttpMixin implements RepositorioAssets {
  ServicoApiGerelat get api;

  @override
  Future<int> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    String descricao = '',
  }) async {
    final resposta = await api.criarMultipart(
      caminho: '/assets/',
      campos: {'descricao': descricao},
      campoArquivo: 'arquivo',
      arquivoBytes: arquivoBytes,
      nomeArquivo: nomeArquivo,
      contentType: _mimeImagem(nomeArquivo),
    );
    return idCriado(resposta, 'id', 'asset');
  }

  @override
  Future<List<Asset>> listarAssets() async {
    final assets = await api.listar('/assets/');
    return assets.map(_assetDeMapa).toList();
  }

  @override
  Future<Asset> obterAsset(int assetId) async {
    final asset = await api.obter('/assets/$assetId/');
    return _assetDeMapa(asset);
  }

  @override
  Future<void> atualizarAsset({
    required int assetId,
    required String descricao,
  }) async {
    await api.atualizar('/assets/$assetId/', {'descricao': descricao});
  }

  @override
  Future<void> excluirAsset(int assetId) async {
    await api.excluir('/assets/$assetId/');
  }

  Asset _assetDeMapa(Map<String, dynamic> asset) {
    return Asset(
      id: paraInteiro(asset['id']),
      descricao: paraTexto(asset['descricao']),
      urlArquivo: paraTexto(asset['arquivo']),
    );
  }

  /// Deriva o content-type a partir da extensão do arquivo. O backend
  /// (`AssetCreateRequestSerializer.validate_arquivo`) rejeita uploads cujo
  /// content-type não comece com `image/`.
  String _mimeImagem(String nomeArquivo) {
    final extensao = nomeArquivo.split('.').last.toLowerCase();
    switch (extensao) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:gerelat_frontend/dados/servicos/servico_api_gerelat.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

import 'utilitarios_http.dart';

mixin RepositorioAssetsHttpMixin implements RepositorioAssets {
  ServicoApiGerelat get api;

  @override
  Future<Asset> criarAsset({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
    NivelEscopo? escopo,
    int? escopoId,
    String descricao = '',
  }) async {
    final contentType = _mimeImagem(nomeArquivo);

    // Upload de imagem é estritamente via URL preassinada (presigned PUT)
    final presignedDados = <String, dynamic>{
      'nome_arquivo': nomeArquivo,
      'content_type': contentType,
    };
    if (escopo != null && escopoId != null) {
      presignedDados[escopo.valorApi] = escopoId;
    }

    final info = await api.criar('/assets/presigned-url/', presignedDados);
    final uploadUrl = info['upload_url']?.toString();
    final caminhoArquivo = info['caminho_arquivo']?.toString();

    if (uploadUrl == null || caminhoArquivo == null || uploadUrl.isEmpty) {
      throw Exception('Falha ao obter URL preassinada para upload da imagem.');
    }

    final uploadResp = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: arquivoBytes,
    );

    if (uploadResp.statusCode < 200 || uploadResp.statusCode >= 300) {
      throw Exception(
        'Erro no envio da imagem para o storage (${uploadResp.statusCode}).',
      );
    }

    final bodyCriacao = <String, dynamic>{
      'caminho_arquivo': caminhoArquivo,
      'descricao': descricao,
    };
    if (escopo != null && escopoId != null) {
      bodyCriacao[escopo.valorApi] = escopoId;
    }

    final resposta = await api.criar('/assets/', bodyCriacao);
    return _assetDeMapa(resposta);
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
      clienteId: paraInteiro(asset['cliente']),
      programaId: paraInteiro(asset['programa']),
      projetoId: paraInteiro(asset['projeto']),
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

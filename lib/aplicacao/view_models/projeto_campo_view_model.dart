import 'dart:typed_data';

import 'package:gerelat_frontend/aplicacao/view_models/base_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';

class ColunaTabela {
  final String chave;
  final String rotulo;

  const ColunaTabela({required this.chave, required this.rotulo});
}

class ProjetoCampoViewModel extends BaseViewModel {
  final RepositorioCatalogo _repositorio;

  List<OpcaoSelecao> _projetos = [];
  int? _projetoSelecionadoId;
  List<ProjetoCampo> _campos = [];

  ProjetoCampoViewModel(this._repositorio);

  List<OpcaoSelecao> get projetos => List.unmodifiable(_projetos);
  int? get projetoSelecionadoId => _projetoSelecionadoId;
  List<ProjetoCampo> get campos => List.unmodifiable(_campos);

  Future<void> carregarProjetos() async {
    iniciarCarregamento();
    try {
      _projetos = await _repositorio.listarProjetos();
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<void> selecionarProjeto(int? projetoId) async {
    _projetoSelecionadoId = projetoId;
    _campos = [];
    notifyListeners();
    if (projetoId == null) return;

    iniciarCarregamento();
    try {
      _campos = await _repositorio.listarCamposProjeto(projetoId: projetoId);
      finalizarCarregamento();
    } catch (erro) {
      definirErro(erro);
    }
  }

  Future<bool> salvar({
    int? campoId,
    required String referencia,
    required String descricao,
    required TipoCampoProjeto tipo,
    required bool obrigatorio,
    required Map<String, dynamic> valor,
  }) async {
    final projetoId = _projetoSelecionadoId;
    if (projetoId == null) return false;

    iniciarCarregamento();
    try {
      if (campoId == null) {
        await _repositorio.criarCampoProjeto(
          projetoId: projetoId,
          referencia: referencia,
          descricao: descricao,
          tipo: tipo,
          obrigatorio: obrigatorio,
          valor: valor,
        );
      } else {
        await _repositorio.atualizarCampoProjeto(
          campoId: campoId,
          referencia: referencia,
          descricao: descricao,
          tipo: tipo,
          obrigatorio: obrigatorio,
          valor: valor,
        );
      }
      _campos = await _repositorio.listarCamposProjeto(projetoId: projetoId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<bool> excluir(int campoId) async {
    final projetoId = _projetoSelecionadoId;
    if (projetoId == null) return false;

    iniciarCarregamento();
    try {
      await _repositorio.excluirCampoProjeto(campoId);
      _campos = await _repositorio.listarCamposProjeto(projetoId: projetoId);
      finalizarCarregamento();
      return true;
    } catch (erro) {
      definirErro(erro);
      return false;
    }
  }

  Future<int?> enviarImagem({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async {
    try {
      return await _repositorio.criarAsset(
        arquivoBytes: arquivoBytes,
        nomeArquivo: nomeArquivo,
      );
    } catch (erro) {
      definirErro(erro);
      return null;
    }
  }

  // ── Conversão texto <-> valor (TEXT e RICHTEXT, tratados como texto simples) ──

  static Map<String, dynamic> construirValorTexto(String textoMultilinha) {
    final linhas = textoMultilinha
        .split('\n')
        .map((linha) => linha.trim())
        .where((linha) => linha.isNotEmpty)
        .toList();
    return {
      'type': 'doc',
      'content': linhas
          .map(
            (linha) => {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': linha},
              ],
            },
          )
          .toList(),
    };
  }

  static String extrairTextoDeValor(Map<String, dynamic> valor) {
    final content = valor['content'];
    if (content is! List) return '';
    final linhas = <String>[];
    for (final bloco in content) {
      if (bloco is! Map || bloco['content'] is! List) continue;
      for (final no in bloco['content'] as List) {
        if (no is Map && no['type'] == 'text' && no['text'] is String) {
          linhas.add(no['text'] as String);
        }
      }
    }
    return linhas.join('\n');
  }

  // ── Conversão colunas/linhas <-> valor (TABLE) ──

  static Map<String, dynamic> construirValorTabela({
    required List<ColunaTabela> colunas,
    required List<Map<String, String>> linhas,
  }) {
    return {
      'columns': colunas
          .map((c) => {'key': c.chave, 'label': c.rotulo})
          .toList(),
      'rows': linhas,
    };
  }

  static ({List<ColunaTabela> colunas, List<Map<String, String>> linhas})
  extrairTabelaDeValor(Map<String, dynamic> valor) {
    final colunasRaw = valor['columns'];
    final linhasRaw = valor['rows'];
    final colunas = <ColunaTabela>[];
    if (colunasRaw is List) {
      for (final coluna in colunasRaw) {
        if (coluna is Map) {
          colunas.add(
            ColunaTabela(
              chave: '${coluna['key'] ?? ''}',
              rotulo: '${coluna['label'] ?? ''}',
            ),
          );
        }
      }
    }
    final linhas = <Map<String, String>>[];
    if (linhasRaw is List) {
      for (final linha in linhasRaw) {
        if (linha is Map) {
          linhas.add(linha.map((k, v) => MapEntry('$k', '$v')));
        }
      }
    }
    return (colunas: colunas, linhas: linhas);
  }

  // ── Conversão dados de imagem <-> valor (IMAGE) ──

  static Map<String, dynamic> construirValorImagem({
    required int assetId,
    String? legenda,
    double? larguraMm,
    double? alturaMm,
  }) {
    return {
      'asset_id': assetId,
      if (legenda != null && legenda.isNotEmpty) 'caption': legenda,
      'width_mm': ?larguraMm,
      'height_mm': ?alturaMm,
    };
  }
}

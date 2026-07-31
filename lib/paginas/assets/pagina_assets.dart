import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/assets_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaAssets extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;

  const PaginaAssets({
    super.key,
    required this.repositorioCatalogo,
    required this.urlBase,
  });

  @override
  State<PaginaAssets> createState() => _PaginaAssetsState();
}

class _PaginaAssetsState extends State<PaginaAssets> {
  late final AssetsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AssetsViewModel(widget.repositorioCatalogo)..carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _enviarImagem() async {
    final arquivo = await selecionarImagem(context);
    if (arquivo == null) return;
    if (!mounted) return;

    final descricao = await _pedirDescricao(context, inicial: '');
    if (descricao == null) return;
    if (!mounted) return;

    final sucesso = await _viewModel.enviar(
      arquivoBytes: arquivo.bytes,
      nomeArquivo: arquivo.nome,
      descricao: descricao,
    );
    _mostrarErroSeFalhou(sucesso, 'Erro ao enviar imagem.');
  }

  /// Mostra o erro da última ação se ela tiver falhado — mesmo tratamento
  /// usado por [_enviarImagem], [_editarDescricao] e [_confirmarExclusao].
  void _mostrarErroSeFalhou(bool sucesso, String mensagemPadrao) {
    if (!mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? mensagemPadrao)),
    );
  }

  Future<String?> _pedirDescricao(
    BuildContext context, {
    required String inicial,
  }) async {
    final controlador = TextEditingController(text: inicial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descrição da imagem'),
          content: TextField(
            controller: controlador,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex: Logomarca do programa',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => context.pop(controlador.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    } finally {
      controlador.dispose();
    }
  }

  Future<void> _editarDescricao(Asset asset) async {
    final assetId = asset.id;
    if (assetId == null) return;

    final descricao = await _pedirDescricao(context, inicial: asset.descricao);
    if (descricao == null) return;
    if (!mounted) return;

    final sucesso = await _viewModel.atualizarDescricao(
      assetId: assetId,
      descricao: descricao,
    );
    _mostrarErroSeFalhou(sucesso, 'Erro ao salvar.');
  }

  Future<void> _confirmarExclusao(Asset asset) async {
    final assetId = asset.id;
    if (assetId == null) return;

    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir imagem',
      mensagem:
          'Tem certeza de que deseja excluir esta imagem? Textos de projeto '
          'que a utilizam ficarão com a referência quebrada. Esta ação não '
          'pode ser desfeita.',
    );
    if (!confirmou || !mounted) return;

    final sucesso = await _viewModel.excluir(assetId);
    _mostrarErroSeFalhou(sucesso, 'Erro ao excluir imagem.');
  }

  @override
  Widget build(BuildContext context) {
    // `_cabecalho()` não depende de `_viewModel` — só `_conteudo()` precisa
    // ser reconstruído a cada notificação.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [child!, const SizedBox(height: 24), _conteudo()],
          ),
        );
      },
      child: _cabecalho(),
    );
  }

  Widget _cabecalho() {
    return CabecalhoPagina(
      titulo: 'Galeria de imagens',
      subtitulo: 'Imagens enviadas para uso em textos de projeto e relatórios.',
      acao: BotaoPrimario(
        texto: 'Enviar Imagem',
        icone: LucideIcons.upload,
        onPressed: _enviarImagem,
      ),
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando && _viewModel.assets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null && _viewModel.assets.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possível carregar as imagens',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.assets.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.image,
        titulo: 'Nenhuma imagem enviada',
        descricao: 'Envie a primeira imagem para usar em textos de projeto.',
        acao: 'Enviar Imagem',
        onAcao: _enviarImagem,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = (constraints.maxWidth / 240).floor().clamp(1, 6);
        const espaco = 20.0;
        final largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: _viewModel.assets
              .map(
                (asset) => SizedBox(
                  width: largura,
                  child: _CartaoAsset(
                    asset,
                    urlBase: widget.urlBase,
                    onEditar: () => _editarDescricao(asset),
                    onExcluir: () => _confirmarExclusao(asset),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CartaoAsset extends StatelessWidget {
  final Asset asset;
  final String urlBase;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _CartaoAsset(
    this.asset, {
    required this.urlBase,
    required this.onEditar,
    required this.onExcluir,
  });

  String get _urlCompleta {
    if (asset.urlArquivo.startsWith('http')) return asset.urlArquivo;
    return '$urlBase${asset.urlArquivo}';
  }

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: asset.urlArquivo.isEmpty
                  ? _semImagem()
                  : Image.network(
                      _urlCompleta,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _semImagem(),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            asset.descricao.isEmpty ? 'Sem descrição' : asset.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.bodyMedium.copyWith(color: Cores.textoPrincipal),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Editar descrição',
                onPressed: onEditar,
                icon: const Icon(LucideIcons.pencil, size: 16),
              ),
              IconButton(
                tooltip: 'Excluir imagem',
                onPressed: onExcluir,
                icon: const Icon(
                  LucideIcons.trash_2,
                  size: 16,
                  color: Cores.vermelhoErro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _semImagem() {
    return Container(
      color: Cores.fundoSecao,
      child: const Center(
        child: Icon(LucideIcons.image_off, color: Cores.cinzaMedio, size: 28),
      ),
    );
  }
}

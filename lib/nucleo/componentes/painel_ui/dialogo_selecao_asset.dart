part of '../painel_ui.dart';

/// Diálogo para selecionar uma imagem existente da galeria de Assets,
/// com suporte a busca por texto e filtragem por escopo.
class DialogoSelecaoAsset extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final NivelEscopo? escopo;
  final int? escopoId;

  const DialogoSelecaoAsset({
    super.key,
    required this.repositorioCatalogo,
    required this.urlBase,
    this.escopo,
    this.escopoId,
  });

  @override
  State<DialogoSelecaoAsset> createState() => _DialogoSelecaoAssetState();
}

class _DialogoSelecaoAssetState extends State<DialogoSelecaoAsset> {
  bool _carregando = true;
  String? _erro;
  List<Asset> _assets = [];
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await widget.repositorioCatalogo.listarAssets();
      if (!mounted) return;
      setState(() {
        _assets = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar imagens.';
        _carregando = false;
      });
    }
  }

  bool _pertenceAoEscopo(Asset a) {
    final esc = widget.escopo;
    final id = widget.escopoId;
    if (esc == null || id == null) return true;

    switch (esc) {
      case NivelEscopo.cliente:
        return a.clienteId == id && a.programaId == null && a.projetoId == null;
      case NivelEscopo.programa:
        return a.programaId == id && a.projetoId == null;
      case NivelEscopo.projeto:
        return a.projetoId == id;
    }
  }

  List<Asset> get _assetsFiltrados {
    final filtradosPorEscopo = _assets.where(_pertenceAoEscopo).toList();
    if (_busca.trim().isEmpty) return filtradosPorEscopo;
    final termo = _busca.trim().toLowerCase();
    return filtradosPorEscopo.where((a) {
      final desc = a.descricao.toLowerCase();
      final idStr = '${a.id}';
      return desc.contains(termo) || idStr.contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.image, color: Cores.azulAcao, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Escolher imagem',
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CampoBusca(
              controlador: TextEditingController(text: _busca),
              dica: 'Pesquisar por descrição ou ID...',
              aoAlterar: (v) => setState(() => _busca = v),
            ),
            const SizedBox(height: 16),
            Expanded(child: _conteudoGrid()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoGrid() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Text(
          _erro!,
          style: Tipografia.bodyMedium.copyWith(color: Cores.vermelhoErro),
        ),
      );
    }
    final lista = _assetsFiltrados;
    if (lista.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma imagem disponível neste escopo.',
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final asset = lista[index];
        final url = asset.urlArquivo.startsWith('http')
            ? asset.urlArquivo
            : '${widget.urlBase}${asset.urlArquivo}';
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context).pop(asset),
          child: Container(
            decoration: BoxDecoration(
              color: Cores.fundoSecao,
              border: Border.all(color: Cores.bordaSutil),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: asset.urlArquivo.isEmpty
                      ? const Center(
                          child: Icon(
                            LucideIcons.image_off,
                            color: Cores.cinzaMedio,
                          ),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  LucideIcons.image_off,
                                  color: Cores.cinzaMedio,
                                ),
                              ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  color: Colors.white,
                  child: Text(
                    asset.descricao.isEmpty
                        ? 'Asset #${asset.id}'
                        : asset.descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.bodySmall.copyWith(
                      color: Cores.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

part of '../painel_ui.dart';

/// Abre o seletor de arquivo do sistema para uma imagem (PNG/JPG/WEBP, até
/// 5 MB) e retorna o arquivo escolhido, ou `null` se o usuário cancelou.
///
/// Em caso de arquivo inválido (tipo ou tamanho fora do permitido), mostra a
/// mensagem de erro num `SnackBar` e também retorna `null`. Usado por
/// [SeletorLogomarca] e por `PaginaAssets` — centraliza aqui os tipos e o
/// tamanho máximo aceitos para que as duas telas não corram o risco de
/// divergir.
Future<ArquivoSelecionadoWeb?> selecionarImagem(BuildContext context) async {
  try {
    return await selecionarArquivo(
      accept: '.png,.jpg,.jpeg,.webp',
      extensoesPermitidas: const ['.png', '.jpg', '.jpeg', '.webp'],
      tamanhoMaximoBytes: 5 * 1024 * 1024,
    );
  } on ArquivoInvalidoException catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.mensagem)));
    return null;
  }
}

/// Campo de logomarca: mostra uma prévia da imagem atual (se houver) e um
/// botão que abre o seletor de arquivo do sistema, sobe a imagem para
/// `/assets/` e devolve a URL resultante via [aoAlterar].
///
/// Diferente de [CampoFormulario], não recebe `controller` — quem usa este
/// widget guarda a URL num `String` de estado (não um `TextEditingController`).
class SeletorLogomarca extends StatefulWidget {
  final String label;
  final String urlAtual;
  final ValueChanged<String> aoAlterar;
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final NivelEscopo? escopo;
  final int? escopoId;

  const SeletorLogomarca({
    super.key,
    this.label = 'Logomarca',
    required this.urlAtual,
    required this.aoAlterar,
    required this.repositorioCatalogo,
    required this.urlBase,
    this.escopo,
    this.escopoId,
  });

  @override
  State<SeletorLogomarca> createState() => _SeletorLogomarcaState();
}

class _SeletorLogomarcaState extends State<SeletorLogomarca> {
  bool _enviando = false;

  String get _urlCompleta {
    final url = widget.urlAtual;
    if (url.isEmpty || url.startsWith('http')) return url;
    return '${widget.urlBase}$url';
  }

  Future<void> _selecionar() async {
    final arquivo = await selecionarImagem(context);
    if (arquivo == null || !mounted) return;

    setState(() => _enviando = true);
    try {
      final repositorio = widget.repositorioCatalogo;
      final asset = await repositorio.criarAsset(
        arquivoBytes: arquivo.bytes,
        nomeArquivo: arquivo.nome,
        escopo: widget.escopo,
        escopoId: widget.escopoId,
      );
      if (!mounted) return;
      widget.aoAlterar(asset.urlArquivo);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar imagem: $erro')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrirGaleria() async {
    final asset = await showDialog<Asset>(
      context: context,
      builder: (context) => DialogoSelecaoAsset(
        repositorioCatalogo: widget.repositorioCatalogo,
        urlBase: widget.urlBase,
        escopo: widget.escopo,
        escopoId: widget.escopoId,
      ),
    );
    if (asset != null && mounted) {
      widget.aoAlterar(asset.urlArquivo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exibirGaleria = widget.escopo != NivelEscopo.cliente;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RotuloCampo(widget.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Cores.cinzaClaro,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Cores.bordaSutil),
              ),
              child: widget.urlAtual.isEmpty
                  ? const Icon(
                      LucideIcons.image,
                      color: Cores.cinzaMedio,
                      size: 20,
                    )
                  : Image.network(
                      _urlCompleta,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        LucideIcons.image_off,
                        color: Cores.cinzaMedio,
                        size: 20,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _enviando ? null : _selecionar,
                icon: _enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.upload, size: 16),
                label: Text(_enviando ? 'Enviando...' : 'Upload'),
              ),
            ),
            if (exibirGaleria) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _enviando ? null : _abrirGaleria,
                icon: const Icon(LucideIcons.images, size: 16),
                label: const Text('Galeria'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/assets_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaAssets extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final SessaoViewModel sessaoViewModel;

  const PaginaAssets({
    super.key,
    required this.repositorioCatalogo,
    required this.urlBase,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaAssets> createState() => _PaginaAssetsState();
}

class _PaginaAssetsState extends State<PaginaAssets> {
  late final AssetsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AssetsViewModel(widget.repositorioCatalogo);
    widget.sessaoViewModel.addListener(_aoMudarSessao);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    _viewModel.inicializar();
  }

  void _aoMudarSessao() {
    if (!mounted) return;
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _enviarImagem() async {
    final escopoId = _viewModel.escopoId;
    if (escopoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione um escopo acima antes de enviar a imagem.',
          ),
        ),
      );
      return;
    }

    if (!_viewModel.podeEditarEscopo(_viewModel.escopo, escopoId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você não tem permissão para enviar imagens neste escopo.',
          ),
        ),
      );
      return;
    }

    final arquivo = await selecionarImagem(context);
    if (arquivo == null) return;
    if (!mounted) return;

    final descricao = await _pedirDescricao(context, inicial: '');
    if (descricao == null) return;
    if (!mounted) return;

    final sucesso = await _viewModel.enviar(
      arquivoBytes: arquivo.bytes,
      nomeArquivo: arquivo.nome,
      escopo: _viewModel.escopo,
      escopoId: escopoId,
      descricao: descricao,
    );
    _mostrarErroSeFalhou(sucesso, 'Erro ao enviar imagem.');
  }

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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(),
              const SizedBox(height: 24),
              _seletorEscopo(),
              const SizedBox(height: 24),
              _conteudo(),
            ],
          ),
        );
      },
    );
  }

  Widget _seletorEscopo() {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escopo das imagens',
            style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NivelEscopo.selecionaveis.map((escopo) {
              return ChoiceChip(
                label: Text(escopo.rotulo),
                selected: _viewModel.escopo == escopo,
                onSelected: (_) => _viewModel.selecionarEscopo(escopo, null),
                selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          CampoSelecao(
            label: _viewModel.escopo.rotulo,
            valor: _viewModel.escopoId,
            itens: _viewModel.opcoesEscopo
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.nome)),
                )
                .toList(),
            onChanged: (value) {
              _viewModel.selecionarEscopo(_viewModel.escopo, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    final podeEnviar = _viewModel.escopoId != null &&
        _viewModel.podeEditarEscopo(_viewModel.escopo, _viewModel.escopoId);

    return CabecalhoPagina(
      titulo: 'Imagens',
      subtitulo: 'Imagens enviadas para uso em textos de projeto e relatórios.',
      acao: BotaoPrimario(
        texto: 'Enviar Imagem',
        icone: LucideIcons.upload,
        onPressed: podeEnviar ? _enviarImagem : null,
      ),
    );
  }

  Future<void> _exibirDetalhesAsset(BuildContext context, Asset asset) async {
    final podeEditar = _viewModel.podeEditarAsset(asset);
    await showDialog(
      context: context,
      builder: (dialogContext) => _DialogoDetalhesAsset(
        asset: asset,
        urlBase: widget.urlBase,
        repositorioCatalogo: widget.repositorioCatalogo,
        podeEditar: podeEditar,
        onEditar: () async {
          Navigator.of(dialogContext).pop();
          await _editarDescricao(asset);
        },
        onExcluir: () async {
          Navigator.of(dialogContext).pop();
          await _confirmarExclusao(asset);
        },
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

    final podeEnviar = _viewModel.escopoId != null &&
        _viewModel.podeEditarEscopo(_viewModel.escopo, _viewModel.escopoId);

    if (_viewModel.assets.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.image,
        titulo: 'Nenhuma imagem enviada',
        descricao: 'Envie a primeira imagem para usar em textos de projeto.',
        acao: 'Enviar Imagem',
        onAcao: podeEnviar ? _enviarImagem : null,
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
                    key: ValueKey(asset.id ?? asset.urlArquivo),
                    urlBase: widget.urlBase,
                    podeEditar: _viewModel.podeEditarAsset(asset),
                    onEditar: () => _editarDescricao(asset),
                    onExcluir: () => _confirmarExclusao(asset),
                    onTapCard: () => _exibirDetalhesAsset(context, asset),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CartaoAsset extends StatefulWidget {
  final Asset asset;
  final String urlBase;
  final bool podeEditar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onTapCard;

  const _CartaoAsset(
    this.asset, {
    super.key,
    required this.urlBase,
    required this.podeEditar,
    required this.onEditar,
    required this.onExcluir,
    required this.onTapCard,
  });

  @override
  State<_CartaoAsset> createState() => _CartaoAssetState();
}

class _CartaoAssetState extends State<_CartaoAsset> {
  bool _carregado = false;
  bool _hover = false;

  String get _urlCompleta {
    if (widget.asset.urlArquivo.startsWith('http')) return widget.asset.urlArquivo;
    return '${widget.urlBase}${widget.asset.urlArquivo}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTapCard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hover ? Cores.azulAcao : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: CartaoConteudo(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.asset.urlArquivo.isEmpty
                        ? _semImagem()
                        : _carregado
                            ? Image.network(
                                _urlCompleta,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _semImagem(),
                              )
                            : _placeholderCarregar(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.asset.descricao.isEmpty
                      ? 'Sem descrição'
                      : widget.asset.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tipografia.bodyMedium.copyWith(color: Cores.textoPrincipal),
                ),
                if (widget.podeEditar) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Editar descrição',
                        onPressed: widget.onEditar,
                        icon: const Icon(LucideIcons.pencil, size: 16),
                      ),
                      IconButton(
                        tooltip: 'Excluir imagem',
                        onPressed: widget.onExcluir,
                        icon: const Icon(
                          LucideIcons.trash_2,
                          size: 16,
                          color: Cores.vermelhoErro,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderCarregar() {
    return Material(
      color: Cores.fundoSecao,
      child: InkWell(
        onTap: () {
          setState(() {
            _carregado = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Cores.cinzaClaro.withValues(alpha: 0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Cores.azulAcao.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.eye,
                  color: Cores.azulAcao,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clique para carregar',
                textAlign: TextAlign.center,
                style: Tipografia.bodySmall.copyWith(
                  color: Cores.cinzaMedio,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

class _UsoAsset {
  final String tipo;
  final String nome;
  final String detalhe;
  final IconData icone;

  _UsoAsset({
    required this.tipo,
    required this.nome,
    required this.detalhe,
    required this.icone,
  });
}

class _DialogoDetalhesAsset extends StatefulWidget {
  final Asset asset;
  final String urlBase;
  final RepositorioCatalogo repositorioCatalogo;
  final bool podeEditar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _DialogoDetalhesAsset({
    required this.asset,
    required this.urlBase,
    required this.repositorioCatalogo,
    required this.podeEditar,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  State<_DialogoDetalhesAsset> createState() => _DialogoDetalhesAssetState();
}

class _DialogoDetalhesAssetState extends State<_DialogoDetalhesAsset> {
  bool _carregandoUsos = true;
  List<_UsoAsset> _usos = [];
  String? _erroUsos;

  @override
  void initState() {
    super.initState();
    _buscarUsos();
  }

  Future<void> _buscarUsos() async {
    setState(() {
      _carregandoUsos = true;
      _erroUsos = null;
    });

    final asset = widget.asset;
    final repo = widget.repositorioCatalogo;
    final listaUsos = <_UsoAsset>[];

    try {
      String extrairNome(String s) =>
          s.split('?').first.split('#').first.split('/').last.trim();

      final nomeAsset = extrairNome(asset.urlArquivo);

      // 0. Usos registrados na API do backend
      try {
        final dynamic repoDyn = repo;
        final Map<String, dynamic> assetObj =
            await repoDyn.api.obter('/assets/${asset.id}/');
        final usosApi = assetObj['usos'] as List? ?? [];
        for (final u in usosApi) {
          if (u is Map) {
            final tipoUso = u['tipo_uso']?.toString() ?? '';
            final entidadeNome = u['entidade_nome']?.toString() ?? '';
            if (tipoUso == 'logomarca_cliente') {
              listaUsos.add(
                _UsoAsset(
                  tipo: 'Logomarca de Cliente',
                  nome: entidadeNome.isNotEmpty ? entidadeNome : 'Cliente',
                  detalhe: 'Organização / Cliente',
                  icone: LucideIcons.building_2,
                ),
              );
            } else if (tipoUso == 'logomarca_programa') {
              listaUsos.add(
                _UsoAsset(
                  tipo: 'Logomarca de Programa',
                  nome: entidadeNome.isNotEmpty ? entidadeNome : 'Programa',
                  detalhe: 'Programa institucional',
                  icone: LucideIcons.folder_kanban,
                ),
              );
            } else if (tipoUso == 'logomarca_projeto') {
              listaUsos.add(
                _UsoAsset(
                  tipo: 'Logomarca de Projeto',
                  nome: entidadeNome.isNotEmpty ? entidadeNome : 'Projeto',
                  detalhe: 'Projeto de extensão/pesquisa',
                  icone: LucideIcons.git_branch,
                ),
              );
            }
          }
        }
      } catch (_) {}

      // 1. Clientes
      try {
        final clientes = await repo.listarClientes();
        for (final c in clientes) {
          if (c.logomarca.isNotEmpty &&
              (c.logomarca == asset.urlArquivo ||
                  c.logomarca.endsWith(asset.urlArquivo) ||
                  (nomeAsset.isNotEmpty && extrairNome(c.logomarca) == nomeAsset))) {
            final jaExiste = listaUsos.any(
              (u) => u.tipo == 'Logomarca de Cliente' && u.nome.contains(c.nome),
            );
            if (!jaExiste) {
              listaUsos.add(
                _UsoAsset(
                  tipo: 'Logomarca de Cliente',
                  nome: c.nome,
                  detalhe: 'Organização / Cliente',
                  icone: LucideIcons.building_2,
                ),
              );
            }
          }
        }
      } catch (_) {}

      // 2. Programas
      final programas = await repo.listarProgramas();
      for (final p in programas) {
        if (p.logomarca.isNotEmpty &&
            (p.logomarca == asset.urlArquivo ||
                p.logomarca.endsWith(asset.urlArquivo) ||
                (nomeAsset.isNotEmpty && extrairNome(p.logomarca) == nomeAsset))) {
          final jaExiste = listaUsos.any(
            (u) => u.tipo == 'Logomarca de Programa' && u.nome.contains(p.nome),
          );
          if (!jaExiste) {
            listaUsos.add(
              _UsoAsset(
                tipo: 'Logomarca de Programa',
                nome: p.nome,
                detalhe: 'Programa institucional',
                icone: LucideIcons.folder_kanban,
              ),
            );
          }
        }
      }

      // 3. Projetos
      final projetos = await repo.listarProjetosDetalhados();
      for (final p in projetos) {
        if (p.logomarca.isNotEmpty &&
            (p.logomarca == asset.urlArquivo ||
                p.logomarca.endsWith(asset.urlArquivo) ||
                (nomeAsset.isNotEmpty && extrairNome(p.logomarca) == nomeAsset))) {
          final jaExiste = listaUsos.any(
            (u) => u.tipo == 'Logomarca de Projeto' && u.nome.contains(p.nome),
          );
          if (!jaExiste) {
            listaUsos.add(
              _UsoAsset(
                tipo: 'Logomarca de Projeto',
                nome: p.nome,
                detalhe: 'Projeto de extensão/pesquisa',
                icone: LucideIcons.git_branch,
              ),
            );
          }
        }
      }

      // 3. CampoValores (variaveis)
      try {
        final dynamic repoDyn = repo;
        final List valores = await repoDyn.api.listar('/campo-valores/');
        final definicoes = await repo.listarDefinicoes();
        final defMap = {for (final d in definicoes) d.id!: d};

        for (final v in valores) {
          if (v is Map) {
            final valObj = v['valor'];
            if (valObj is Map && valObj['asset_id'] == asset.id) {
              final defId = int.tryParse('${v['definicao']}');
              final def = defMap[defId];
              final ref = def?.referencia ?? 'Variável #$defId';

              String alvoStr = 'Instância';
              if (v['cliente'] != null) {
                alvoStr = 'Cliente #${v['cliente']}';
              } else if (v['programa'] != null) {
                alvoStr = 'Programa #${v['programa']}';
              } else if (v['projeto'] != null) {
                alvoStr = 'Projeto #${v['projeto']}';
              } else if (v['evento'] != null) {
                alvoStr = 'Evento #${v['evento']}';
              }

              listaUsos.add(_UsoAsset(
                tipo: 'Variável de Imagem',
                nome: '{$ref}',
                detalhe: 'Preenchida em: $alvoStr',
                icone: LucideIcons.variable,
              ));
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _usos = listaUsos;
          _carregandoUsos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroUsos = 'Erro ao verificar locais de uso.';
          _carregandoUsos = false;
        });
      }
    }
  }

  String get _urlCompleta {
    if (widget.asset.urlArquivo.startsWith('http')) return widget.asset.urlArquivo;
    return '${widget.urlBase}${widget.asset.urlArquivo}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.image, color: Cores.azulAcao, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.asset.descricao.isEmpty
                        ? 'Asset #${widget.asset.id}'
                        : widget.asset.descricao,
                    style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Cores.fundoSecao,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Cores.bordaSutil),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.asset.urlArquivo.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Icon(LucideIcons.image_off, size: 40, color: Cores.cinzaMedio),
                              )
                            : Image.network(
                                _urlCompleta,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Icon(LucideIcons.image_off, size: 40, color: Cores.cinzaMedio),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Escopo: ${widget.asset.escopo?.rotulo ?? 'Global'} (ID: ${widget.asset.escopoId ?? '-'})',
                      style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Onde esta imagem está sendo utilizada:',
                      style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
                    ),
                    const SizedBox(height: 12),
                    _secaoUsos(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _rodape(context),
          ],
        ),
      ),
    );
  }

  Widget _secaoUsos() {
    if (_carregandoUsos) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_erroUsos != null) {
      return Text(
        _erroUsos!,
        style: Tipografia.bodyMedium.copyWith(color: Cores.vermelhoErro),
      );
    }
    if (_usos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Cores.fundoSecao,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 18, color: Cores.cinzaMedio),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Esta imagem não está em uso em nenhuma logomarca ou variável no momento.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _usos.map((uso) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Cores.fundoSecao,
            border: Border.all(color: Cores.bordaSutil),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(uso.icone, size: 20, color: Cores.azulAcao),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uso.nome,
                      style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
                    ),
                    Text(
                      '${uso.tipo} · ${uso.detalhe}',
                      style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _rodape(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compac = constraints.maxWidth < 480;
        return Row(
          children: [
            if (widget.podeEditar)
              OutlinedButton.icon(
                onPressed: widget.onExcluir,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Cores.vermelhoErro,
                  side: const BorderSide(color: Cores.vermelhoErro),
                ),
                icon: const Icon(LucideIcons.trash_2, size: 16),
                label: compac ? const SizedBox.shrink() : const Text('Excluir'),
              ),
            const Spacer(),
            if (widget.podeEditar) ...[
              OutlinedButton.icon(
                onPressed: widget.onEditar,
                icon: const Icon(LucideIcons.pencil, size: 16),
                label: compac ? const SizedBox.shrink() : const Text('Editar Descrição'),
              ),
              const SizedBox(width: 8),
            ],
            BotaoPrimario(
              texto: compac ? '' : 'Fechar',
              icone: LucideIcons.check,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

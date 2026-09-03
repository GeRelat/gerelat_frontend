import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/conversores_valor_campo.dart';
import 'package:gerelat_frontend/dominio/entidades/asset.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/variaveis/componentes/dialogo_editor_texto_rico.dart';

/// Resultado da edição de um valor: o JSON pronto para `CampoValor.valor`, ou
/// uma mensagem explicando por que ainda não dá para salvar.
typedef ResultadoValor = ({Map<String, dynamic>? valor, String? erro});

/// Editor do valor de uma variável, com um formulário por tipo (texto/texto
/// rico, tabela e imagem).
///
/// Extraído da antiga tela "Variáveis do projeto", que conflava definição e
/// valor num só formulário. Agora o mesmo editor serve a qualquer alvo
/// (cliente, programa, projeto ou evento).
class EditorValorCampo extends StatefulWidget {
  final TipoCampo tipo;
  final Map<String, dynamic> valorInicial;
  final bool readOnly;
  final RepositorioCatalogo? repositorioCatalogo;
  final String urlBase;
  final NivelEscopo? escopo;
  final int? escopoId;

  /// Variáveis que podem ser inseridas dentro de um valor de texto rico.
  final List<VariavelDisponivel> variaveisDisponiveis;

  /// Referência da variável, usada só no título do diálogo de texto rico.
  final String referenciaVariavel;

  /// `'light'` ou `'dark'` — passado ao editor ProseMirror do diálogo.
  final String temaEditor;

  /// Envia a imagem selecionada e devolve o id do `Asset` criado.
  final Future<int?> Function({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  })
  aoEnviarImagem;

  const EditorValorCampo({
    super.key,
    required this.tipo,
    required this.valorInicial,
    required this.aoEnviarImagem,
    this.repositorioCatalogo,
    this.urlBase = '',
    this.readOnly = false,
    this.escopo,
    this.escopoId,
    this.variaveisDisponiveis = const [],
    this.temaEditor = 'light',
    this.referenciaVariavel = '',
  });

  @override
  State<EditorValorCampo> createState() => EditorValorCampoState();
}

class EditorValorCampoState extends State<EditorValorCampo> {
  final _textoValor = TextEditingController();
  final _legenda = TextEditingController();
  final _largura = TextEditingController();
  final _altura = TextEditingController();
  final _novaColunaChave = TextEditingController();
  final _novaColunaRotulo = TextEditingController();

  List<ColunaTabela> _colunasTabela = [];
  List<Map<String, String>> _linhasTabela = [];

  int? _assetIdExistente;
  Asset? _assetSelecionado;
  Uint8List? _imagemBytesNova;
  String? _imagemNomeNovo;

  Map<String, dynamic> _docRichtext = docRichtextVazio();

  @override
  void initState() {
    super.initState();
    _carregarValor(widget.valorInicial);
  }

  @override
  void didUpdateWidget(covariant EditorValorCampo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valorInicial != widget.valorInicial ||
        oldWidget.tipo != widget.tipo) {
      _carregarValor(widget.valorInicial);
    }
  }

  @override
  void dispose() {
    _textoValor.dispose();
    _legenda.dispose();
    _largura.dispose();
    _altura.dispose();
    _novaColunaChave.dispose();
    _novaColunaRotulo.dispose();
    super.dispose();
  }

  void _carregarValor(Map<String, dynamic> valor) {
    _textoValor.clear();
    _legenda.clear();
    _largura.clear();
    _altura.clear();
    _colunasTabela = [];
    _linhasTabela = [];
    _assetIdExistente = null;
    _assetSelecionado = null;
    _imagemBytesNova = null;
    _imagemNomeNovo = null;
    _docRichtext = docRichtextVazio();

    switch (widget.tipo) {
      case TipoCampo.texto:
        _textoValor.text = extrairTextoDeValor(valor);
      case TipoCampo.textoRico:
        _docRichtext = extrairDocDeValor(valor);
      case TipoCampo.tabela:
        final tabela = extrairTabelaDeValor(valor);
        _colunasTabela = tabela.colunas;
        _linhasTabela = tabela.linhas;
      case TipoCampo.imagem:
        final assetId = valor['asset_id'];
        _assetIdExistente = assetId is int ? assetId : null;
        _legenda.text = '${valor['caption'] ?? ''}';
        _largura.text = valor['width_mm'] != null ? '${valor['width_mm']}' : '';
        _altura.text = valor['height_mm'] != null ? '${valor['height_mm']}' : '';
    }
  }

  /// Monta o JSON do valor a partir do que está na tela. Envia a imagem
  /// selecionada, se houver — por isso é assíncrono.
  Future<ResultadoValor> montarValor() async {
    switch (widget.tipo) {
      case TipoCampo.texto:
        if (_textoValor.text.trim().isEmpty) {
          return (valor: null, erro: 'Preencha o texto da variável.');
        }
        return (valor: construirValorTexto(_textoValor.text), erro: null);

      case TipoCampo.textoRico:
        final content = _docRichtext['content'];
        if (content is! List ||
            content.isEmpty ||
            resumoDeDoc(_docRichtext).isEmpty) {
          return (valor: null, erro: 'Edite o texto rico da variável.');
        }
        return (valor: _docRichtext, erro: null);

      case TipoCampo.tabela:
        if (_colunasTabela.isEmpty || _linhasTabela.isEmpty) {
          return (
            valor: null,
            erro: 'Adicione ao menos uma coluna e uma linha.',
          );
        }
        final linhasNormalizadas = _linhasTabela
            .map(
              (linha) => {
                for (final coluna in _colunasTabela)
                  coluna.chave: linha[coluna.chave] ?? '',
              },
            )
            .toList();
        return (
          valor: construirValorTabela(
            colunas: _colunasTabela,
            linhas: linhasNormalizadas,
          ),
          erro: null,
        );

      case TipoCampo.imagem:
        final medidaInvalida =
            _erroMedida(_largura.text) ?? _erroMedida(_altura.text);
        if (medidaInvalida != null) {
          return (valor: null, erro: medidaInvalida);
        }
        var assetId = _assetIdExistente;
        if (_imagemBytesNova != null && _imagemNomeNovo != null) {
          assetId = await widget.aoEnviarImagem(
            arquivoBytes: _imagemBytesNova!,
            nomeArquivo: _imagemNomeNovo!,
          );
        }
        if (assetId == null) {
          return (valor: null, erro: 'Selecione uma imagem.');
        }
        return (
          valor: construirValorImagem(
            assetId: assetId,
            legenda: _legenda.text.trim(),
            larguraMm: double.tryParse(_largura.text.trim()),
            alturaMm: double.tryParse(_altura.text.trim()),
          ),
          erro: null,
        );
    }
  }

  // `keyboardType: TextInputType.number` é só dica de teclado, não valida
  // nada. Sem esta checagem, texto não numérico passava batido e
  // `double.tryParse` descartava o valor em silêncio — o campo virava vazio
  // no payload sem nenhum aviso ao usuário.
  String? _erroMedida(String texto) {
    final valor = texto.trim();
    if (valor.isEmpty) return null;
    final numero = double.tryParse(valor);
    if (numero == null || numero <= 0) {
      return 'Informe uma medida numérica maior que zero (ou deixe em branco).';
    }
    return null;
  }

  void _adicionarColuna() {
    final chave = _novaColunaChave.text.trim();
    final rotulo = _novaColunaRotulo.text.trim();
    if (chave.isEmpty || rotulo.isEmpty) return;
    setState(() {
      _colunasTabela = [
        ..._colunasTabela,
        ColunaTabela(chave: chave, rotulo: rotulo),
      ];
      _novaColunaChave.clear();
      _novaColunaRotulo.clear();
    });
  }

  void _removerColuna(String chave) {
    setState(() {
      _colunasTabela = _colunasTabela.where((c) => c.chave != chave).toList();
      _linhasTabela = _linhasTabela.map((linha) {
        final copia = Map<String, String>.from(linha);
        copia.remove(chave);
        return copia;
      }).toList();
    });
  }

  void _adicionarLinha() {
    setState(() => _linhasTabela = [..._linhasTabela, {}]);
  }

  void _removerLinha(int indice) {
    setState(() {
      _linhasTabela = [..._linhasTabela]..removeAt(indice);
    });
  }

  Future<void> _selecionarImagem() async {
    final arquivo = await selecionarImagem(context);
    if (arquivo == null || !mounted) return;
    setState(() {
      _imagemBytesNova = arquivo.bytes;
      _imagemNomeNovo = arquivo.nome;
      _assetSelecionado = null;
    });
  }

  Future<void> _abrirSeletorAssetGaleria() async {
    if (widget.repositorioCatalogo == null) return;
    final asset = await showDialog<Asset>(
      context: context,
      builder: (context) => DialogoSelecaoAsset(
        repositorioCatalogo: widget.repositorioCatalogo!,
        urlBase: widget.urlBase,
        escopo: widget.escopo,
        escopoId: widget.escopoId,
      ),
    );

    if (asset == null || !mounted) return;

    setState(() {
      _assetIdExistente = asset.id;
      _assetSelecionado = asset;
      _imagemBytesNova = null;
      _imagemNomeNovo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.tipo) {
      case TipoCampo.texto:
        return CampoFormulario(
          label: 'Texto (uma linha = um parágrafo)',
          hint: 'Digite o texto pré-cadastrado...',
          controller: _textoValor,
          maxLines: 5,
          enabled: !widget.readOnly,
        );
      case TipoCampo.textoRico:
        return _editorTextoRico();
      case TipoCampo.tabela:
        return _editorTabela();
      case TipoCampo.imagem:
        return _editorImagem();
    }
  }

  Widget _editorTextoRico() {
    final resumo = resumoDeDoc(_docRichtext);
    return _painelEditor(
      children: [
        Text(
          'Texto rico',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 6),
        Text(
          'Um mini-template: além de formatação, pode conter outras variáveis '
          '(texto, imagem, tabela e campos do sistema) que serão preenchidas '
          'onde este texto for usado.',
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Cores.branco,
            border: Border.all(color: Cores.bordaSutil),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            resumo.isEmpty ? 'Nenhum texto configurado.' : resumo,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.bodyMedium.copyWith(
              color: resumo.isEmpty ? Cores.cinzaMedio : Cores.textoPrincipal,
            ),
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _abrirEditorTextoRico,
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: Text(resumo.isEmpty ? 'Editar texto rico' : 'Editar'),
          ),
        ],
      ],
    );
  }

  Future<void> _abrirEditorTextoRico() async {
    final resultado = await mostrarDialogoEditorTextoRico(
      context,
      referencia: widget.referenciaVariavel,
      documentoInicial: _docRichtext,
      variaveis: widget.variaveisDisponiveis,
      tema: widget.temaEditor,
    );
    if (resultado == null || !mounted) return;
    setState(() => _docRichtext = resultado);
  }

  Widget _editorTabela() {
    return _painelEditor(
      children: [
        Text(
          'Colunas da tabela',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 10),
        if (_colunasTabela.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colunasTabela
                .map(
                  (coluna) => Chip(
                    label: Text('${coluna.rotulo} (${coluna.chave})'),
                    onDeleted: widget.readOnly ? null : () => _removerColuna(coluna.chave),
                  ),
                )
                .toList(),
          ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _novaColunaChave,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'chave (ex: nome)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _novaColunaRotulo,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'rótulo (ex: Nome)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _adicionarColuna,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Coluna'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'Linhas',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 10),
        if (_colunasTabela.isEmpty)
          Text(
            'Adicione ao menos uma coluna antes de criar linhas.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
          )
        else ...[
          for (var i = 0; i < _linhasTabela.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (final coluna in _colunasTabela)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          // Chave presa à identidade do mapa da linha (não
                          // ao índice `i`): ao excluir uma linha do meio,
                          // `_removerLinha` mantém os mesmos objetos `Map`
                          // das linhas restantes, só muda a posição delas
                          // na lista. Com chave por índice, o Flutter
                          // reaproveitava o TextFormField da posição e
                          // continuava mostrando o texto da linha excluída
                          // até o usuário digitar de novo.
                          key: ValueKey((_linhasTabela[i], coluna.chave)),
                          initialValue: _linhasTabela[i][coluna.chave] ?? '',
                          readOnly: widget.readOnly,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: coluna.rotulo,
                          ),
                          onChanged: (valor) =>
                              _linhasTabela[i][coluna.chave] = valor,
                        ),
                      ),
                    ),
                  if (!widget.readOnly)
                    IconButton(
                      tooltip: 'Remover linha',
                      onPressed: () => _removerLinha(i),
                      icon: const Icon(LucideIcons.trash_2, size: 18),
                    ),
                ],
              ),
            ),
          if (!widget.readOnly)
            TextButton.icon(
              onPressed: _adicionarLinha,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Adicionar linha'),
            ),
        ],
      ],
    );
  }

  Widget _editorImagem() {
    final temImagem = _imagemNomeNovo != null || _assetIdExistente != null;
    String? urlPreview;
    if (_assetSelecionado != null && _assetSelecionado!.urlArquivo.isNotEmpty) {
      urlPreview = _assetSelecionado!.urlArquivo.startsWith('http')
          ? _assetSelecionado!.urlArquivo
          : '${widget.urlBase}${_assetSelecionado!.urlArquivo}';
    }

    return _painelEditor(
      children: [
        Text(
          'Imagem',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 10),
        if (_imagemBytesNova != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imagemBytesNova!,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arquivo novo: $_imagemNomeNovo',
            style: Tipografia.bodyMedium.copyWith(color: Cores.textoPrincipal),
          ),
        ] else if (urlPreview != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              urlPreview,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                LucideIcons.image_off,
                size: 32,
                color: Cores.cinzaMedio,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _assetSelecionado!.descricao.isEmpty
                ? 'Asset #${_assetSelecionado!.id}'
                : 'Asset #${_assetSelecionado!.id} — ${_assetSelecionado!.descricao}',
            style: Tipografia.bodyMedium.copyWith(color: Cores.textoPrincipal),
          ),
        ] else ...[
          Text(
            _assetIdExistente != null
                ? 'Asset selecionado: #$_assetIdExistente'
                : 'Nenhuma imagem selecionada.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
        if (!widget.readOnly) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _selecionarImagem,
                icon: const Icon(LucideIcons.upload, size: 16),
                label: Text(temImagem ? 'Enviar Nova Imagem' : 'Upload Imagem'),
              ),
              if (widget.repositorioCatalogo != null)
                OutlinedButton.icon(
                  onPressed: _abrirSeletorAssetGaleria,
                  icon: const Icon(LucideIcons.image, size: 16),
                  label: const Text('Escolher da Galeria'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        CampoFormulario(
          label: 'Legenda (opcional)',
          hint: 'Ex: Foto do evento',
          controller: _legenda,
          enabled: !widget.readOnly,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: CampoFormulario(
                label: 'Largura em mm (opcional)',
                hint: 'Ex: 120',
                controller: _largura,
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: CampoFormulario(
                label: 'Altura em mm (opcional)',
                hint: 'Ex: 80',
                controller: _altura,
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Painel com fundo destacado usado pelos editores de tabela e imagem.
  Widget _painelEditor({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Cores.fundoSecao,
        border: Border.all(color: Cores.bordaSutil),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

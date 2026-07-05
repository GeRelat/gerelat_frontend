import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/projeto_campo_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaCamposProjeto extends StatefulWidget {
  const PaginaCamposProjeto({super.key});

  @override
  State<PaginaCamposProjeto> createState() => _PaginaCamposProjetoState();
}

class _PaginaCamposProjetoState extends State<PaginaCamposProjeto> {
  final _formKey = GlobalKey<FormState>();
  final _referencia = TextEditingController();
  final _descricao = TextEditingController();
  final _textoValor = TextEditingController();
  final _legenda = TextEditingController();
  final _largura = TextEditingController();
  final _altura = TextEditingController();
  final _novaColunaChave = TextEditingController();
  final _novaColunaRotulo = TextEditingController();
  final _focoReferencia = FocusNode();

  late final ProjetoCampoViewModel _viewModel;

  int? _campoEmEdicaoId;
  TipoCampoProjeto _tipo = TipoCampoProjeto.texto;
  bool _obrigatorio = false;

  List<ColunaTabela> _colunasTabela = [];
  List<Map<String, String>> _linhasTabela = [];

  int? _assetIdExistente;
  Uint8List? _imagemBytesNova;
  String? _imagemNomeNovo;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjetoCampoViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )..carregarProjetos();
  }

  @override
  void dispose() {
    _referencia.dispose();
    _descricao.dispose();
    _textoValor.dispose();
    _legenda.dispose();
    _largura.dispose();
    _altura.dispose();
    _novaColunaChave.dispose();
    _novaColunaRotulo.dispose();
    _focoReferencia.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _limparFormulario() {
    setState(() {
      _campoEmEdicaoId = null;
      _tipo = TipoCampoProjeto.texto;
      _obrigatorio = false;
      _referencia.clear();
      _descricao.clear();
      _textoValor.clear();
      _legenda.clear();
      _largura.clear();
      _altura.clear();
      _colunasTabela = [];
      _linhasTabela = [];
      _assetIdExistente = null;
      _imagemBytesNova = null;
      _imagemNomeNovo = null;
    });
  }

  void _iniciarEdicao(ProjetoCampo campo) {
    setState(() {
      _campoEmEdicaoId = campo.id;
      _tipo = campo.tipo;
      _obrigatorio = campo.obrigatorio;
      _referencia.text = campo.referencia;
      _descricao.text = campo.descricao;
      _textoValor.clear();
      _legenda.clear();
      _largura.clear();
      _altura.clear();
      _colunasTabela = [];
      _linhasTabela = [];
      _assetIdExistente = null;
      _imagemBytesNova = null;
      _imagemNomeNovo = null;

      switch (campo.tipo) {
        case TipoCampoProjeto.texto:
        case TipoCampoProjeto.textoRico:
          _textoValor.text = ProjetoCampoViewModel.extrairTextoDeValor(
            campo.valor,
          );
        case TipoCampoProjeto.tabela:
          final tabela = ProjetoCampoViewModel.extrairTabelaDeValor(
            campo.valor,
          );
          _colunasTabela = tabela.colunas;
          _linhasTabela = tabela.linhas;
        case TipoCampoProjeto.imagem:
          final assetId = campo.valor['asset_id'];
          _assetIdExistente = assetId is int ? assetId : null;
          _legenda.text = '${campo.valor['caption'] ?? ''}';
          _largura.text = campo.valor['width_mm'] != null
              ? '${campo.valor['width_mm']}'
              : '';
          _altura.text = campo.valor['height_mm'] != null
              ? '${campo.valor['height_mm']}'
              : '';
      }
    });
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
    final arquivo = await selecionarArquivo(accept: '.png,.jpg,.jpeg,.webp');
    if (arquivo == null) return;
    setState(() {
      _imagemBytesNova = arquivo.bytes;
      _imagemNomeNovo = arquivo.nome;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> valor;
    switch (_tipo) {
      case TipoCampoProjeto.texto:
      case TipoCampoProjeto.textoRico:
        valor = ProjetoCampoViewModel.construirValorTexto(_textoValor.text);
      case TipoCampoProjeto.tabela:
        if (_colunasTabela.isEmpty || _linhasTabela.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adicione ao menos uma coluna e uma linha.'),
            ),
          );
          return;
        }
        final linhasNormalizadas = _linhasTabela
            .map(
              (linha) => {
                for (final coluna in _colunasTabela)
                  coluna.chave: linha[coluna.chave] ?? '',
              },
            )
            .toList();
        valor = ProjetoCampoViewModel.construirValorTabela(
          colunas: _colunasTabela,
          linhas: linhasNormalizadas,
        );
      case TipoCampoProjeto.imagem:
        var assetId = _assetIdExistente;
        if (_imagemBytesNova != null && _imagemNomeNovo != null) {
          assetId = await _viewModel.enviarImagem(
            arquivoBytes: _imagemBytesNova!,
            nomeArquivo: _imagemNomeNovo!,
          );
        }
        if (assetId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecione uma imagem.')),
          );
          return;
        }
        valor = ProjetoCampoViewModel.construirValorImagem(
          assetId: assetId,
          legenda: _legenda.text.trim(),
          larguraMm: double.tryParse(_largura.text.trim()),
          alturaMm: double.tryParse(_altura.text.trim()),
        );
    }

    final sucesso = await _viewModel.salvar(
      campoId: _campoEmEdicaoId,
      referencia: _referencia.text.trim(),
      descricao: _descricao.text.trim(),
      tipo: _tipo,
      obrigatorio: _obrigatorio,
      valor: valor,
    );
    if (!mounted) return;
    if (sucesso) {
      _limparFormulario();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  Future<void> _confirmarExclusao(ProjetoCampo campo) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover campo'),
        content: Text(
          'Remover o campo "${campo.descricao}" (${campo.referencia})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    final campoId = campo.id;
    if (campoId == null) return;
    final sucesso = await _viewModel.excluir(campoId);
    if (!mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao remover.')),
      );
    }
    if (_campoEmEdicaoId == campoId) {
      _limparFormulario();
    }
  }

  String? _obrigatorioValidator(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.carregando && _viewModel.projetos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Textos do projeto',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Textos fixos, optativos e livres pré-cadastrados, usados na geração de relatórios.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
              const SizedBox(height: 24),
              CartaoConteudo(
                child: CampoSelecao(
                  label: 'Projeto',
                  valor: _viewModel.projetoSelecionadoId,
                  itens: _viewModel.projetos
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _limparFormulario();
                    _viewModel.selecionarProjeto(value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (_viewModel.projetoSelecionadoId == null)
                CartaoConteudo(
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.arrow_up,
                        color: Cores.cinzaMedio,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Escolha um projeto acima para ver e gerenciar seus textos.',
                          style: Tipografia.bodyMedium.copyWith(
                            color: Cores.cinzaEscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _formularioCampo(),
                const SizedBox(height: 32),
                _conteudoLista(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _formularioCampo() {
    return CartaoConteudo(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFormulario(
                    label: 'Referência',
                    hint: 'Ex: objetivo_evento',
                    icone: LucideIcons.tags,
                    controller: _referencia,
                    focusNode: _focoReferencia,
                    validator: _obrigatorioValidator,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: CampoFormulario(
                    label: 'Descrição',
                    hint: 'Ex: Objetivo do evento',
                    icone: LucideIcons.file_text,
                    controller: _descricao,
                    validator: _obrigatorioValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoSelecao(
                    label: 'Tipo',
                    valor: _tipo.index,
                    itens: TipoCampoProjeto.values
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo.index,
                            child: Text(tipo.rotulo),
                          ),
                        )
                        .toList(),
                    onChanged: _campoEmEdicaoId != null
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(
                              () => _tipo = TipoCampoProjeto.values[value],
                            );
                          },
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Obrigatório',
                        style: Tipografia.labelLarge.copyWith(
                          color: Cores.cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _obrigatorio,
                            onChanged: (value) =>
                                setState(() => _obrigatorio = value ?? false),
                          ),
                          Text(
                            'Este texto precisa ser preenchido',
                            style: Tipografia.bodyMedium.copyWith(
                              color: Cores.cinzaEscuro,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _editorValor(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_campoEmEdicaoId != null) ...[
                  TextButton(
                    onPressed: _viewModel.carregando ? null : _limparFormulario,
                    child: const Text('Cancelar edição'),
                  ),
                  const SizedBox(width: 12),
                ],
                BotaoPrimario(
                  texto: _viewModel.carregando
                      ? 'Salvando...'
                      : _campoEmEdicaoId != null
                      ? 'Salvar'
                      : 'Adicionar',
                  icone: _campoEmEdicaoId != null
                      ? LucideIcons.save
                      : LucideIcons.plus,
                  onPressed: _viewModel.carregando ? null : _salvar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _editorValor() {
    switch (_tipo) {
      case TipoCampoProjeto.texto:
      case TipoCampoProjeto.textoRico:
        return CampoFormulario(
          label: 'Texto (uma linha = um parágrafo)',
          hint: 'Digite o texto pré-cadastrado...',
          controller: _textoValor,
          maxLines: 5,
          validator: _obrigatorioValidator,
        );
      case TipoCampoProjeto.tabela:
        return _editorTabela();
      case TipoCampoProjeto.imagem:
        return _editorImagem();
    }
  }

  Widget _editorTabela() {
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
                      onDeleted: () => _removerColuna(coluna.chave),
                    ),
                  )
                  .toList(),
            ),
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
                            key: ValueKey('linha-$i-${coluna.chave}'),
                            initialValue: _linhasTabela[i][coluna.chave] ?? '',
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: coluna.rotulo,
                            ),
                            onChanged: (valor) =>
                                _linhasTabela[i][coluna.chave] = valor,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Remover linha',
                      onPressed: () => _removerLinha(i),
                      icon: const Icon(LucideIcons.trash_2, size: 18),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: _adicionarLinha,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Adicionar linha'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _editorImagem() {
    final temImagem = _imagemNomeNovo != null || _assetIdExistente != null;
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
        children: [
          Text(
            'Imagem',
            style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
          ),
          const SizedBox(height: 8),
          Text(
            _imagemNomeNovo ??
                (_assetIdExistente != null
                    ? 'Imagem atual: Asset #$_assetIdExistente (selecione um arquivo para substituir)'
                    : 'Nenhuma imagem selecionada.'),
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
          const SizedBox(height: 14),
          BotaoPrimario(
            texto: temImagem ? 'Substituir Imagem' : 'Selecionar Imagem',
            icone: temImagem ? LucideIcons.refresh_cw : LucideIcons.upload,
            onPressed: _selecionarImagem,
          ),
          const SizedBox(height: 18),
          CampoFormulario(
            label: 'Legenda (opcional)',
            hint: 'Ex: Foto do evento',
            controller: _legenda,
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
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: CampoFormulario(
                  label: 'Altura em mm (opcional)',
                  hint: 'Ex: 80',
                  controller: _altura,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conteudoLista() {
    if (_viewModel.carregando && _viewModel.campos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.campos.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.file_text,
        titulo: 'Nenhum texto cadastrado',
        descricao: 'Adicione o primeiro texto pré-cadastrado deste projeto.',
        acao: 'Adicionar texto',
        onAcao: () => _focoReferencia.requestFocus(),
      );
    }

    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _cabecalhoTabela(),
          for (final campo in _viewModel.campos) _linha(campo),
        ],
      ),
    );
  }

  Widget _cabecalhoTabela() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Cores.fundoSecao,
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          _celulaCabecalho('Referência', flex: 2),
          _celulaCabecalho('Descrição', flex: 3),
          _celulaCabecalho('Tipo'),
          _celulaCabecalho('Obrigatório'),
          _celulaCabecalho('Ações'),
        ],
      ),
    );
  }

  Widget _celulaCabecalho(String texto, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        texto.toUpperCase(),
        style: Tipografia.labelMedium.copyWith(
          color: Cores.cinzaMedio,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _linha(ProjetoCampo campo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              campo.referencia,
              style: Tipografia.labelLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              campo.descricao,
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Cores.fundoDestaqueSutil,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                campo.tipo.rotulo,
                style: Tipografia.labelMedium.copyWith(
                  color: Cores.cinzaEscuro,
                ),
              ),
            ),
          ),
          Expanded(
            child: Icon(
              campo.obrigatorio ? LucideIcons.circle_check : LucideIcons.circle,
              size: 18,
              color: campo.obrigatorio ? Cores.verdeSucesso : Cores.cinzaMedio,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _iniciarEdicao(campo),
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => _confirmarExclusao(campo),
                  icon: const Icon(
                    LucideIcons.trash_2,
                    size: 18,
                    color: Cores.vermelhoErro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

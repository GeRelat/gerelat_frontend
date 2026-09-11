import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/templates_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaginaTemplates extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaTemplates({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaTemplates> createState() => _PaginaTemplatesState();
}

class _PaginaTemplatesState extends State<PaginaTemplates> {
  late final TemplatesViewModel _viewModel;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = TemplatesViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    widget.sessaoViewModel.addListener(_aoMudarSessao);
  }

  void _aoMudarSessao() {
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _controladorBusca.dispose();
    _viewModel.dispose();
    super.dispose();
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
              _cabecalho(context),
              const SizedBox(height: 20),
              CampoBusca(
                controlador: _controladorBusca,
                dica: 'Pesquisar templates...',
                aoAlterar: _viewModel.definirBusca,
              ),
              const SizedBox(height: 16),
              _filtrosEscopo(),
              const SizedBox(height: 24),
              _conteudo(),
            ],
          ),
        );
      },
    );
  }

  Widget _cabecalho(BuildContext context) {
    return CabecalhoPagina(
      titulo: 'Templates prontos',
      subtitulo:
          'Gerencie modelos DOCX usados para gerar relatórios automaticamente.',
      acao: BotaoPrimario(
        texto: 'Novo Template',
        icone: LucideIcons.upload,
        onPressed: () async {
          final criado = await context.push<bool>('/templates/novo');
          if (criado == true) await _viewModel.carregar();
        },
      ),
    );
  }

  Widget _filtrosEscopo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nível:',
              style: Tipografia.bodyMedium.copyWith(
                color: Cores.cinzaEscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _viewModel.filtroNivel == null,
                    onSelected: (_) => _viewModel.definirFiltroNivel(null),
                    selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                  ),
                  for (final nivel in _viewModel.niveisPermitidos)
                    ChoiceChip(
                      label: Text(nivel.rotulo),
                      selected: _viewModel.filtroNivel == nivel,
                      onSelected: (_) => _viewModel.definirFiltroNivel(nivel),
                      selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_viewModel.filtroNivel != null &&
            _viewModel.filtroNivel != NivelEscopo.cliente &&
            _viewModel.opcoesFiltroEscopo.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 320,
            child: CampoSelecao(
              label: 'Filtrar por ${_viewModel.filtroNivel!.rotulo}',
              valor: _viewModel.filtroEscopoId ?? 0,
              itens: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text(
                    'Todos os ${_viewModel.filtroNivel!.rotulo.toLowerCase()}s',
                  ),
                ),
                ..._viewModel.opcoesFiltroEscopo.map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.nome),
                  ),
                ),
              ],
              onChanged: (value) =>
                  _viewModel.definirFiltroEscopoId(value == 0 ? null : value),
            ),
          ),
        ],
      ],
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null && _viewModel.templates.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possivel carregar os templates',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.templates.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.search_x,
        titulo: 'Nenhum template encontrado',
        descricao: 'Nenhum template corresponde à busca atual.',
        acao: 'Limpar busca',
        onAcao: () {
          _controladorBusca.clear();
          _viewModel.definirBusca('');
        },
      );
    }

    return _gradeTemplates(_viewModel.templates);
  }

  Widget _gradeTemplates(List<TemplateRelatorio> templates) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth < 900 ? 1 : 2;
        const espaco = 24.0;
        final largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: templates
              .map(
                (template) => SizedBox(
                  width: largura,
                  child: _CartaoTemplate(
                    template,
                    dono: _viewModel.donoDoTemplate(template),
                    podeEditar: _viewModel.podeEditarTemplate(template),
                    podeExcluir: _viewModel.podeExcluirTemplate(template),
                    onTap: () => _abrirModalDetalhesTemplate(context, template),
                    onEditado: _viewModel.carregar,
                    onExcluir: _viewModel.excluir,
                    onBaixar: _viewModel.baixarArquivo,
                    obterMensagemErro: () => _viewModel.mensagemErroAcao,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _abrirModalDetalhesTemplate(
    BuildContext context,
    TemplateRelatorio template,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _ModalDetalhesTemplate(
        template: template,
        dono: _viewModel.donoDoTemplate(template),
        podeEditar: _viewModel.podeEditarTemplate(template),
        podeExcluir: _viewModel.podeExcluirTemplate(template),
        onEditado: _viewModel.carregar,
        onExcluir: _viewModel.excluir,
        onBaixar: _viewModel.baixarArquivo,
        obterMensagemErro: () => _viewModel.mensagemErroAcao,
      ),
    );
  }
}

class _CartaoTemplate extends StatelessWidget {
  final TemplateRelatorio template;

  /// Nome da entidade dona do template (cliente, programa ou projeto).
  final String dono;
  final bool podeEditar;
  final bool podeExcluir;
  final VoidCallback onTap;
  final Future<void> Function() onEditado;
  final Future<bool> Function(int) onExcluir;
  final Future<Uint8List?> Function(int) onBaixar;
  final String? Function() obterMensagemErro;

  const _CartaoTemplate(
    this.template, {
    required this.dono,
    required this.podeEditar,
    required this.podeExcluir,
    required this.onTap,
    required this.onEditado,
    required this.onExcluir,
    required this.onBaixar,
    required this.obterMensagemErro,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CartaoConteudo(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconeComFundo(
                  cor: Cores.azulAcao,
                  tamanho: 48,
                  raio: 12,
                  icone: LucideIcons.file_text,
                  tamanhoIcone: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.nome,
                        style: Tipografia.titleLarge.copyWith(
                          color: Cores.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${template.nivel.rotulo} · $dono',
                        style: Tipografia.bodySmall.copyWith(
                          color: Cores.cinzaMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                _tag(template.tipo),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              template.descricao,
              style: Tipografia.bodyMedium.copyWith(
                color: Cores.cinzaEscuro,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _status(template.status),
                const Spacer(),
                IconButton(
                  tooltip: 'Baixar arquivo original (.docx)',
                  onPressed: () => _baixarArquivo(context),
                  icon: const Icon(LucideIcons.download, size: 18),
                ),
                if (podeEditar) ...[
                  TextButton.icon(
                    onPressed: () => _navegarEAtualizar(
                      context,
                      '/templates/${template.id}/editor',
                    ),
                    icon: const Icon(LucideIcons.pen_line, size: 16),
                    label: const Text('Conteúdo'),
                  ),
                  TextButton.icon(
                    onPressed: () => _navegarEAtualizar(
                      context,
                      '/templates/${template.id}/editar',
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    label: const Text('Editar'),
                  ),
                ],
                if (podeExcluir)
                  IconButton(
                    tooltip: 'Excluir template',
                    onPressed: () => _confirmarExclusao(context),
                    icon: const Icon(
                      LucideIcons.trash_2,
                      size: 18,
                      color: Cores.vermelhoErro,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Navega para [rota] e recarrega a lista se a tela retornar sucesso —
  /// mesmo tratamento usado pelos botões "Conteúdo" e "Editar".
  Future<void> _navegarEAtualizar(BuildContext context, String rota) async {
    final alterado = await context.push<bool>(rota);
    if (alterado == true) {
      await onEditado();
    }
  }

  Future<void> _baixarArquivo(BuildContext context) async {
    final templateId = template.id;
    if (templateId == null) return;

    final bytes = await onBaixar(templateId);
    if (!context.mounted) return;

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            obterMensagemErro() ??
                'Este template não possui arquivo .docx original armazenado.',
          ),
        ),
      );
      return;
    }

    baixarArquivo(
      bytes: bytes,
      nomeArquivo: '${template.nome}.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir template',
      mensagem:
          'Tem certeza de que deseja excluir "${template.nome}"? '
          'Os vínculos com classes de evento serão removidos junto. '
          'Se este template já foi usado para gerar algum relatório, '
          'a exclusão será recusada pelo servidor até que os relatórios '
          'relacionados sejam removidos. Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !context.mounted) return;

    final templateId = template.id;
    if (templateId == null) return;

    final sucesso = await onExcluir(templateId);
    if (!context.mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(obterMensagemErro() ?? 'Erro ao excluir o template.'),
      ),
    );
  }

  Widget _tag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Cores.fundoDestaqueSutil,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro),
      ),
    );
  }

  Widget _status(String texto) {
    return Text(
      texto,
      style: Tipografia.labelLarge.copyWith(
        color: texto == 'Ativo' ? Cores.verdeSucesso : Cores.azulAcao,
      ),
    );
  }
}

class _ModalDetalhesTemplate extends StatefulWidget {
  final TemplateRelatorio template;
  final String dono;
  final bool podeEditar;
  final bool podeExcluir;
  final Future<void> Function() onEditado;
  final Future<bool> Function(int) onExcluir;
  final Future<Uint8List?> Function(int) onBaixar;
  final String? Function() obterMensagemErro;

  const _ModalDetalhesTemplate({
    required this.template,
    required this.dono,
    required this.podeEditar,
    required this.podeExcluir,
    required this.onEditado,
    required this.onExcluir,
    required this.onBaixar,
    required this.obterMensagemErro,
  });

  @override
  State<_ModalDetalhesTemplate> createState() => __ModalDetalhesTemplateState();
}

class __ModalDetalhesTemplateState extends State<_ModalDetalhesTemplate> {
  final EditorProseMirrorController _controller = EditorProseMirrorController();
  String _temaEditor = 'light';

  @override
  void initState() {
    super.initState();
    _carregarTemaEditor();
  }

  Future<void> _carregarTemaEditor() async {
    final prefs = await SharedPreferences.getInstance();
    final escuro = prefs.getBool('editor_tema_escuro') ?? false;
    if (mounted) {
      setState(() {
        _temaEditor = escuro ? 'dark' : 'light';
      });
    }
  }

  Future<void> _salvarTemaEditor(String tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('editor_tema_escuro', tema == 'dark');
    if (mounted) {
      setState(() {
        _temaEditor = tema;
      });
    }
  }

  Future<void> _baixarArquivo(BuildContext context) async {
    final templateId = widget.template.id;
    if (templateId == null) return;

    final bytes = await widget.onBaixar(templateId);
    if (!context.mounted) return;

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.obterMensagemErro() ??
                'Este template não possui arquivo .docx original armazenado.',
          ),
        ),
      );
      return;
    }

    baixarArquivo(
      bytes: bytes,
      nomeArquivo: '${widget.template.nome}.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir template',
      mensagem:
          'Tem certeza de que deseja excluir "${widget.template.nome}"? '
          'Os vínculos com classes de evento serão removidos junto. '
          'Se este template já foi usado para gerar algum relatório, '
          'a exclusão será recusada pelo servidor até que os relatórios '
          'relacionados sejam removidos. Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !context.mounted) return;

    final templateId = widget.template.id;
    if (templateId == null) return;

    final sucesso = await widget.onExcluir(templateId);
    if (!context.mounted) return;
    if (sucesso) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.obterMensagemErro() ?? 'Erro ao excluir o template.'),
        ),
      );
    }
  }

  Future<void> _navegarEAtualizar(BuildContext context, String rota) async {
    Navigator.of(context).pop();
    final alterado = await context.push<bool>(rota);
    if (alterado == true) {
      await widget.onEditado();
    }
  }

  void _gerarRelatorio(BuildContext context) {
    Navigator.of(context).pop();
    context.push<bool>(
      '/relatorios/gerar',
      extra: {
        'templateId': widget.template.id,
        'programaId': widget.template.programaId,
        'projetoId': widget.template.projetoId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final dataCriacaoTexto = template.dataCriacao.isNotEmpty
        ? template.dataCriacao
        : 'Não informada';
    final ultimaAtualizacaoTexto = template.ultimaAtualizacao.isNotEmpty
        ? template.ultimaAtualizacao
        : dataCriacaoTexto;

    final temModelo =
        template.modeloJson != null && template.modeloJson!.isNotEmpty;

    return Dialog(
      backgroundColor: Cores.branco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
        child: Column(
          children: [
            // Cabecalho do Modal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Cores.cinzaClaro),
                ),
              ),
              child: Row(
                children: [
                  const IconeComFundo(
                    cor: Cores.azulAcao,
                    tamanho: 48,
                    raio: 12,
                    icone: LucideIcons.file_text,
                    tamanhoIcone: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.nome,
                          style: Tipografia.headlineSmall.copyWith(
                            color: Cores.textoPrincipal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _badgeStatus(template.status),
                            const SizedBox(width: 12),
                            Text(
                              'ID: #${template.id ?? "—"}',
                              style: Tipografia.bodySmall.copyWith(
                                color: Cores.cinzaMedio,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _tag(template.tipo),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
            ),

            // Conteudo Scrollavel: Metadados + Descricao + Preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid de Informações Básicas
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final duasColunas = constraints.maxWidth >= 600;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: duasColunas
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth,
                              child: _blocoInfo(
                                icone: LucideIcons.layers,
                                rotulo: 'Escopo / Dono',
                                valor:
                                    '${template.nivel.rotulo} · ${widget.dono}',
                              ),
                            ),
                            SizedBox(
                              width: duasColunas
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth,
                              child: _blocoInfo(
                                icone: LucideIcons.file_text,
                                rotulo: 'Formato / Motor',
                                valor: '${template.tipo} · ProseMirror',
                              ),
                            ),
                            SizedBox(
                              width: duasColunas
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth,
                              child: _blocoInfo(
                                icone: LucideIcons.clock,
                                rotulo: 'Data de Criação',
                                valor: dataCriacaoTexto,
                              ),
                            ),
                            SizedBox(
                              width: duasColunas
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth,
                              child: _blocoInfo(
                                icone: LucideIcons.refresh_cw,
                                rotulo: 'Última Atualização',
                                valor: ultimaAtualizacaoTexto,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    if (template.descricao.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        template.descricao,
                        style: Tipografia.bodyMedium.copyWith(
                          color: Cores.cinzaEscuro,
                          height: 1.45,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(color: Cores.cinzaClaro),
                    const SizedBox(height: 16),

                    // Titulo da secao de Preview
                    Row(
                      children: [
                        Text(
                          'Pré-visualização do Modelo',
                          style: Tipografia.titleMedium.copyWith(
                            color: Cores.textoPrincipal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: _temaEditor == 'dark'
                              ? 'Alternar para modo claro'
                              : 'Alternar para modo escuro',
                          child: IconButton(
                            onPressed: () {
                              final novoTema =
                                  _temaEditor == 'dark' ? 'light' : 'dark';
                              _salvarTemaEditor(novoTema);
                              _controller.definirTema(novoTema);
                            },
                            icon: Icon(
                              _temaEditor == 'dark'
                                  ? LucideIcons.sun
                                  : LucideIcons.moon,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Area do Editor / Preview
                    Container(
                      height: 420,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Cores.cinzaClaro),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: temModelo
                          ? IgnorePointer(
                              ignoring: true,
                              child: EditorProseMirror(
                                controller: _controller,
                                documentoInicial: template.modeloJson,
                                modo: 'report',
                                temaInicial: _temaEditor,
                                aoMudarTema: _salvarTemaEditor,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.file_x,
                                    size: 40,
                                    color: Cores.cinzaMedio,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nenhum modelo estruturado definido para este template.',
                                    style: Tipografia.bodyMedium.copyWith(
                                      color: Cores.cinzaEscuro,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Rodape de Acoes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Cores.cinzaClaro),
                ),
              ),
              child: Row(
                children: [
                  if (widget.podeExcluir) ...[
                    OutlinedButton.icon(
                      onPressed: () => _confirmarExclusao(context),
                      icon: const Icon(
                        LucideIcons.trash_2,
                        size: 18,
                        color: Cores.vermelhoErro,
                      ),
                      label: const Text(
                        'Excluir',
                        style: TextStyle(color: Cores.vermelhoErro),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.podeEditar) ...[
                    OutlinedButton.icon(
                      onPressed: () => _navegarEAtualizar(
                        context,
                        '/templates/${template.id}/editar',
                      ),
                      icon: const Icon(LucideIcons.pencil, size: 18),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _navegarEAtualizar(
                        context,
                        '/templates/${template.id}/editor',
                      ),
                      icon: const Icon(LucideIcons.pen_line, size: 16),
                      label: const Text('Editar Conteúdo'),
                    ),
                  ],
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _baixarArquivo(context),
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: const Text('Baixar .docx'),
                  ),
                  const SizedBox(width: 12),
                  BotaoPrimario(
                    texto: 'Gerar Relatório',
                    icone: LucideIcons.file_text,
                    onPressed: () => _gerarRelatorio(context),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoInfo({
    required IconData icone,
    required String rotulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.cinzaClaro.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icone, size: 20, color: Cores.azulAcao),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: Tipografia.bodySmall.copyWith(
                    color: Cores.cinzaMedio,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: Tipografia.labelMedium.copyWith(
                    color: Cores.textoPrincipal,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatus(String status) {
    final ativo = status.toLowerCase() == 'ativo' ||
        status.toLowerCase() == 'concluido' ||
        status.toLowerCase() == 'concluído';
    final cor = ativo ? Cores.verdeSucesso : Cores.azulAcao;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: Tipografia.labelSmall.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Cores.fundoDestaqueSutil,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro),
      ),
    );
  }
}

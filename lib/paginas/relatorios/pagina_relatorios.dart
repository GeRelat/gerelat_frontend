import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/relatorios_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/agendamento_relatorio.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/gaps_prosemirror.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaginaRelatorios extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaRelatorios({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaRelatorios> createState() => _PaginaRelatoriosState();
}

class _PaginaRelatoriosState extends State<PaginaRelatorios> {
  late final RelatoriosViewModel _viewModel;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = RelatoriosViewModel(widget.repositorioCatalogo);
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
                dica: 'Pesquisar relatórios...',
                aoAlterar: _viewModel.definirBusca,
              ),
              const SizedBox(height: 16),
              _filtrosEscopo(),
              const SizedBox(height: 24),
              _atalhoGeracao(context),
              const SizedBox(height: 24),
              _conteudo(context),
            ],
          ),
        );
      },
    );
  }

  Widget _cabecalho(BuildContext context) {
    return CabecalhoPagina(
      titulo: 'Relatórios gerados',
      subtitulo: 'Acompanhe documentos gerados e inicie novas gerações.',
      acao: BotaoPrimario(
        texto: 'Novo Relatório',
        icone: LucideIcons.plus,
        onPressed: () => _abrirGeracao(context),
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

  Widget _atalhoGeracao(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ehEstreito = constraints.maxWidth < 850;

        final botoes = Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: ehEstreito ? WrapAlignment.start : WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _abrirModalAgendamentos(context),
              icon: const Icon(LucideIcons.list_checks, size: 18),
              label: const Text('Ver Agendamentos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            BotaoPrimario(
              texto: 'Novo Agendamento',
              icone: LucideIcons.arrow_right,
              onPressed: () => context
                  .push<bool>('/relatorios/agendar')
                  .then((gerado) {
                if (gerado == true) _viewModel.carregar();
              }),
            ),
          ],
        );

        final info = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconeComFundo(
              cor: Cores.azulAcao,
              tamanho: 52,
              raio: 14,
              icone: LucideIcons.calendar_clock,
              tamanhoIcone: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geração agendada',
                    style: Tipografia.titleLarge.copyWith(
                      color: Cores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agende a geração de relatórios de forma única ou recorrente e acompanhe as automações executadas.',
                    style: Tipografia.bodyMedium.copyWith(
                      color: Cores.cinzaEscuro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (ehEstreito) {
          return CartaoConteudo(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 16),
                botoes,
              ],
            ),
          );
        }

        return CartaoConteudo(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: info),
              const SizedBox(width: 24),
              botoes,
            ],
          ),
        );
      },
    );
  }

  Widget _conteudo(BuildContext context) {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null && _viewModel.estaVazio) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Não foi possível carregar os relatórios',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    if (_viewModel.estaVazio) {
      return EstadoVazio(
        icone: LucideIcons.file_text,
        titulo: _controladorBusca.text.trim().isEmpty
            ? 'Nenhum relatório gerado ainda'
            : 'Nenhum relatório encontrado',
        descricao: _controladorBusca.text.trim().isEmpty
            ? 'Escolha um evento e um template para criar o primeiro relatório institucional.'
            : 'Nenhum relatório corresponde ao termo pesquisado.',
        acao: _controladorBusca.text.trim().isEmpty
            ? 'Gerar Relatório'
            : 'Limpar busca',
        onAcao: () {
          if (_controladorBusca.text.trim().isEmpty) {
            _abrirGeracao(context);
            return;
          }
          _controladorBusca.clear();
          _viewModel.definirBusca('');
        },
      );
    }

    return _listaRelatorios(_viewModel.relatorios);
  }

  Widget _listaRelatorios(List<Relatorio> relatorios) {
    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final relatorio in relatorios)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _abrirModalDetalhesRelatorio(context, relatorio),
                hoverColor: Cores.azulAcao.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const IconeComFundo(
                        cor: Cores.azulAcao,
                        tamanho: 40,
                        raio: 10,
                        icone: LucideIcons.file_text,
                        tamanhoIcone: 20,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              relatorio.titulo,
                              style: Tipografia.titleMedium.copyWith(
                                color: Cores.textoPrincipal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${relatorio.evento} • ${relatorio.template}',
                              style: Tipografia.bodyMedium.copyWith(
                                color: Cores.cinzaEscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _badgeStatus(relatorio.status),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Renomear relatório',
                            onPressed: relatorio.id == null
                                ? null
                                : () => _renomearRelatorio(relatorio),
                            icon: const Icon(LucideIcons.pencil, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Baixar relatório',
                            onPressed: relatorio.id == null
                                ? null
                                : () => _baixarRelatorio(relatorio),
                            icon: const Icon(LucideIcons.download, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Excluir relatório',
                            onPressed: relatorio.id == null
                                ? null
                                : () => _confirmarExclusao(relatorio),
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _badgeStatus(String texto) {
    final concluido = texto.toLowerCase().contains('conclu') ||
        texto.toLowerCase().contains('gerado') ||
        texto.toLowerCase().contains('pronto');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (concluido ? Cores.verdeSucesso : Cores.azulAcao).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: Tipografia.labelSmall.copyWith(
          color: concluido ? Cores.verdeSucesso : Cores.azulAcao,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _abrirModalDetalhesRelatorio(BuildContext context, Relatorio relatorio) {
    showDialog<void>(
      context: context,
      builder: (context) => _ModalDetalhesRelatorio(
        relatorio: relatorio,
        repositorioCatalogo: widget.repositorioCatalogo,
        onBaixar: () => _baixarRelatorio(relatorio),
        onRenomear: () => _renomearRelatorio(relatorio),
        onExcluir: () => _confirmarExclusao(relatorio),
        onSalvo: _viewModel.carregar,
      ),
    );
  }

  Future<void> _baixarRelatorio(Relatorio relatorio) async {
    final relatorioId = relatorio.id;
    if (relatorioId == null) return;

    final bytes = await _viewModel.baixar(relatorioId);
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      final mensagemErro = _viewModel.mensagemErroAcao;
      if (mensagemErro != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemErro)));
      }
      return;
    }

    baixarArquivo(
      bytes: bytes,
      nomeArquivo: '${relatorio.titulo}.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  Future<void> _renomearRelatorio(Relatorio relatorio) async {
    final relatorioId = relatorio.id;
    if (relatorioId == null) return;

    final controlador = TextEditingController(text: relatorio.titulo);
    final String? novoNome;
    try {
      novoNome = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Renomear relatório'),
          content: TextField(controller: controlador, autofocus: true),
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
    if (novoNome == null || novoNome.isEmpty || !mounted) return;

    final sucesso = await _viewModel.renomear(
      relatorioId: relatorioId,
      nome: novoNome,
    );
    _mostrarErroSeFalhou(sucesso, 'Erro ao renomear.');
  }

  Future<void> _confirmarExclusao(Relatorio relatorio) async {
    final relatorioId = relatorio.id;
    if (relatorioId == null) return;

    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir relatório',
      mensagem:
          'Tem certeza de que deseja excluir "${relatorio.titulo}"? '
          'Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !mounted) return;

    final sucesso = await _viewModel.excluir(relatorioId);
    _mostrarErroSeFalhou(sucesso, 'Erro ao excluir relatório.');
  }

  /// Mostra o erro da última ação pontual se ela tiver falhado — mesmo
  /// tratamento usado por [_renomearRelatorio] e [_confirmarExclusao].
  void _mostrarErroSeFalhou(bool sucesso, String mensagemPadrao) {
    if (!mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErroAcao ?? mensagemPadrao)),
    );
  }

  void _abrirGeracao(BuildContext context) {
    context.push<bool>('/relatorios/gerar').then((gerado) {
      if (gerado == true) _viewModel.carregar();
    });
  }

  void _abrirModalAgendamentos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ModalAgendamentos(
        repositorioCatalogo: widget.repositorioCatalogo,
        clienteId: widget.sessaoViewModel.clienteAtivoId,
      ),
    );
  }
}

class _ModalDetalhesRelatorio extends StatefulWidget {
  final Relatorio relatorio;
  final RepositorioCatalogo repositorioCatalogo;
  final VoidCallback onBaixar;
  final VoidCallback onRenomear;
  final VoidCallback onExcluir;
  final VoidCallback onSalvo;

  const _ModalDetalhesRelatorio({
    required this.relatorio,
    required this.repositorioCatalogo,
    required this.onBaixar,
    required this.onRenomear,
    required this.onExcluir,
    required this.onSalvo,
  });

  @override
  State<_ModalDetalhesRelatorio> createState() =>
      __ModalDetalhesRelatorioState();
}

class __ModalDetalhesRelatorioState extends State<_ModalDetalhesRelatorio> {
  final EditorProseMirrorController _controller =
      EditorProseMirrorController();
  String _temaEditor = 'light';
  Map<String, dynamic>? _documentoEditado;
  bool _editado = false;
  bool _salvando = false;
  late final bool _temBlocosManuais;

  @override
  void initState() {
    super.initState();
    _carregarTemaEditor();
    final doc = widget.relatorio.documentoJson;
    _temBlocosManuais =
        doc != null && extrairLabelsDeBlocosManuais(doc).isNotEmpty;
  }

  Future<void> _salvarRelatorio() async {
    final relatorioId = widget.relatorio.id;
    if (relatorioId == null || _documentoEditado == null) return;
    setState(() => _salvando = true);
    try {
      await widget.repositorioCatalogo.atualizarRelatorio(
        relatorioId: relatorioId,
        documentoJson: _documentoEditado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório salvo com sucesso!')),
      );
      setState(() {
        _editado = false;
        _salvando = false;
      });
      widget.onSalvo();
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar relatório: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final relatorio = widget.relatorio;
    final dataCriacaoTexto = relatorio.dataCriacao.isNotEmpty
        ? relatorio.dataCriacao
        : (relatorio.dataGeracao.isNotEmpty
            ? relatorio.dataGeracao
            : 'Não informada');
    final ultimaAtualizacaoTexto = relatorio.ultimaAtualizacao.isNotEmpty
        ? relatorio.ultimaAtualizacao
        : dataCriacaoTexto;

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
                          relatorio.titulo,
                          style: Tipografia.headlineSmall.copyWith(
                            color: Cores.textoPrincipal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _badgeStatus(relatorio.status),
                            const SizedBox(width: 12),
                            Text(
                              'ID: #${relatorio.id ?? "—"}',
                              style: Tipografia.bodySmall.copyWith(
                                color: Cores.cinzaMedio,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
            ),

            // Conteudo Scrollavel: Metadados + Preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid de Informações Básicas (Metadados)
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
                                icone: relatorio.eventoId != null
                                    ? LucideIcons.calendar
                                    : LucideIcons.briefcase,
                                rotulo: relatorio.eventoId != null
                                    ? 'Evento'
                                    : 'Projeto',
                                valor: relatorio.evento,
                              ),
                            ),
                            SizedBox(
                              width: duasColunas
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth,
                              child: _blocoInfo(
                                icone: LucideIcons.layout_template,
                                rotulo: 'Template Base',
                                valor: relatorio.template,
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

                    const SizedBox(height: 24),
                    const Divider(color: Cores.cinzaClaro),
                    const SizedBox(height: 16),

                    // Titulo da secao de Preview
                    Row(
                      children: [
                        Text(
                          'Pré-visualização do Relatório',
                          style: Tipografia.titleMedium.copyWith(
                            color: Cores.textoPrincipal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_temBlocosManuais) ...[
                          _botaoFormatacao(
                            tooltip: 'Negrito',
                            icone: LucideIcons.bold,
                            onPressed: _controller.negrito,
                          ),
                          const SizedBox(width: 4),
                          _botaoFormatacao(
                            tooltip: 'Itálico',
                            icone: LucideIcons.italic,
                            onPressed: _controller.italico,
                          ),
                          const SizedBox(width: 4),
                          _botaoFormatacao(
                            tooltip: 'Sublinhado',
                            icone: LucideIcons.underline,
                            onPressed: _controller.sublinhado,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 20,
                            color: Cores.cinzaClaro,
                          ),
                          const SizedBox(width: 8),
                          _botaoFormatacao(
                            tooltip: 'Título 1',
                            texto: 'H1',
                            onPressed: () => _controller.titulo(1),
                          ),
                          const SizedBox(width: 4),
                          _botaoFormatacao(
                            tooltip: 'Título 2',
                            texto: 'H2',
                            onPressed: () => _controller.titulo(2),
                          ),
                          const SizedBox(width: 4),
                          _botaoFormatacao(
                            tooltip: 'Título 3',
                            texto: 'H3',
                            onPressed: () => _controller.titulo(3),
                          ),
                          const SizedBox(width: 4),
                          _botaoFormatacao(
                            tooltip: 'Parágrafo',
                            texto: '¶',
                            onPressed: _controller.paragrafo,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 20,
                            color: Cores.cinzaClaro,
                          ),
                          const SizedBox(width: 8),
                          _botaoFormatacao(
                            tooltip: 'Desfazer',
                            icone: LucideIcons.undo,
                            onPressed: _controller.desfazer,
                          ),
                          const SizedBox(width: 4),
                          _botaoFormatacao(
                            tooltip: 'Refazer',
                            icone: LucideIcons.redo,
                            onPressed: _controller.refazer,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 20,
                            color: Cores.cinzaClaro,
                          ),
                          const SizedBox(width: 8),
                        ],
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
                      child: relatorio.documentoJson != null &&
                              relatorio.documentoJson!.isNotEmpty
                          ? IgnorePointer(
                              ignoring: !_temBlocosManuais,
                              child: EditorProseMirror(
                                controller: _controller,
                                documentoInicial: relatorio.documentoJson,
                                modo: 'report',
                                temaInicial: _temaEditor,
                                aoMudarTema: _salvarTemaEditor,
                                aoAlterarDocumento: _temBlocosManuais
                                    ? (doc) {
                                        setState(() {
                                          _documentoEditado = doc;
                                          _editado = true;
                                        });
                                      }
                                    : null,
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
                                    'Nenhum documento gerado para este relatório.',
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
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onExcluir();
                    },
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
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onRenomear();
                    },
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    label: const Text('Renomear'),
                  ),
                  const Spacer(),
                  if (_editado) ...[
                    BotaoPrimario(
                      texto: _salvando ? 'Salvando...' : 'Salvar',
                      icone: LucideIcons.save,
                      onPressed: _salvando ? null : _salvarRelatorio,
                    ),
                    const SizedBox(width: 12),
                  ],
                  BotaoPrimario(
                    texto: 'Baixar .docx',
                    icone: LucideIcons.download,
                    onPressed: () {
                      widget.onBaixar();
                    },
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

  Widget _botaoFormatacao({
    required String tooltip,
    IconData? icone,
    String? texto,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Cores.cinzaClaro),
            borderRadius: BorderRadius.circular(6),
          ),
          child: icone != null
              ? Icon(icone, size: 16, color: Cores.cinzaEscuro)
              : Text(
                  texto ?? '',
                  style: Tipografia.labelSmall.copyWith(
                    color: Cores.cinzaEscuro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  Widget _badgeStatus(String texto) {
    final concluido = texto.toLowerCase().contains('conclu') ||
        texto.toLowerCase().contains('gerado') ||
        texto.toLowerCase().contains('pronto');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (concluido ? Cores.verdeSucesso : Cores.azulAcao).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: Tipografia.labelSmall.copyWith(
          color: concluido ? Cores.verdeSucesso : Cores.azulAcao,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ModalAgendamentos extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final int? clienteId;

  const _ModalAgendamentos({
    required this.repositorioCatalogo,
    this.clienteId,
  });

  @override
  State<_ModalAgendamentos> createState() => _ModalAgendamentosState();
}

class _ModalAgendamentosState extends State<_ModalAgendamentos> {
  bool _carregando = true;
  String? _erro;
  List<AgendamentoRelatorio> _agendamentos = [];
  NivelEscopo? _filtroNivel;
  int? _filtroEscopoId;

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
      final lista = await widget.repositorioCatalogo.listarAgendamentos(
        clienteId: widget.clienteId,
      );
      if (mounted) {
        setState(() {
          _agendamentos = lista;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível carregar os agendamentos: $e';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _alternarStatusAgendamento(AgendamentoRelatorio agendamento) async {
    final pontualGerado = agendamento.tipoAgendamento == 'pontual' &&
        agendamento.ultimaExecucao != null &&
        agendamento.ultimaExecucao!.isNotEmpty;

    if (pontualGerado) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Agendamento já gerado'),
          content: const Text(
            'Este agendamento pontual já foi processado e concluído. '
            'Para executá-lo novamente, crie um novo agendamento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }

    // Se está inativo e tentando ativar agendamento pontual cuja data já passou
    if (!agendamento.ativo && agendamento.tipoAgendamento == 'pontual') {
      if (agendamento.dataHoraExecucao != null &&
          agendamento.dataHoraExecucao!.isNotEmpty) {
        final dataHora = DateTime.tryParse(agendamento.dataHoraExecucao!);
        if (dataHora != null && dataHora.isBefore(DateTime.now())) {
          final formatada = _formatarDataHora(agendamento.dataHoraExecucao);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Não é possível ativar'),
              content: Text(
                'Este agendamento pontual está configurado para $formatada, '
                'mas essa data e hora já passaram. Não é possível ativá-lo sem '
                'escolher uma nova data no futuro.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendi'),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    try {
      final novoAtivo = !agendamento.ativo;
      await widget.repositorioCatalogo.alterarStatusAgendamento(
        agendamentoId: agendamento.id,
        ativo: novoAtivo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              novoAtivo
                  ? 'Agendamento ativado com sucesso.'
                  : 'Agendamento desativado com sucesso.',
            ),
          ),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao alterar status do agendamento: $e')),
        );
      }
    }
  }

  Future<void> _excluirAgendamento(AgendamentoRelatorio agendamento) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Excluir agendamento',
      mensagem:
          'Tem certeza de que deseja excluir o agendamento "${agendamento.nome}"? Esta ação não pode ser desfeita.',
    );
    if (!confirmou || !mounted) return;

    try {
      await widget.repositorioCatalogo.excluirAgendamento(agendamento.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento excluído com sucesso.')),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir agendamento: $e')),
        );
      }
    }
  }

  String _formatarDataHora(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return isoString;
    final local = parsed.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year;
    final hora = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final dialogWidth = (largura - 32).clamp(280.0, 720.0);
    final isMobile = largura < 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight:
              (MediaQuery.of(context).size.height * 0.85).clamp(300.0, 620.0),
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconeComFundo(
                  cor: Cores.azulAcao,
                  tamanho: 44,
                  raio: 12,
                  icone: LucideIcons.calendar_clock,
                  tamanhoIcone: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Agendamentos de Relatório',
                            style: Tipografia.titleMedium.copyWith(
                              color: Cores.textoPrincipal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_carregando && _agendamentos.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Cores.azulAcao.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_agendamentos.length}',
                                style: Tipografia.labelSmall.copyWith(
                                  color: Cores.azulAcao,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gerações autônomas pontuais e recorrentes configuradas.',
                        style: Tipografia.bodySmall.copyWith(
                          color: Cores.cinzaEscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: _construirConteudo(),
            ),
          ],
        ),
      ),
    );
  }

  List<AgendamentoRelatorio> get _agendamentosFiltrados {
    return _agendamentos.where((item) {
      if (_filtroNivel != null && item.nivelEscopo != _filtroNivel) {
        return false;
      }
      if (_filtroNivel != null && _filtroEscopoId != null) {
        if (_filtroNivel == NivelEscopo.cliente &&
            item.clienteId != _filtroEscopoId) {
          return false;
        }
        if (_filtroNivel == NivelEscopo.programa &&
            item.programaId != _filtroEscopoId) {
          return false;
        }
        if (_filtroNivel == NivelEscopo.projeto &&
            item.projetoId != _filtroEscopoId) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<int, String> _obterOpcoesEscopoEspecifico() {
    if (_filtroNivel == null) return {};
    final map = <int, String>{};
    for (final a in _agendamentos) {
      if (_filtroNivel == NivelEscopo.cliente && a.clienteId != null) {
        final nome =
            a.clienteNome.isNotEmpty ? a.clienteNome : 'Cliente #${a.clienteId}';
        map[a.clienteId!] = nome;
      } else if (_filtroNivel == NivelEscopo.programa && a.programaId != null) {
        final nome = a.programaNome.isNotEmpty
            ? a.programaNome
            : 'Programa #${a.programaId}';
        map[a.programaId!] = nome;
      } else if (_filtroNivel == NivelEscopo.projeto && a.projetoId != null) {
        final nome =
            a.projetoNome.isNotEmpty ? a.projetoNome : 'Projeto #${a.projetoId}';
        map[a.projetoId!] = nome;
      }
    }
    return map;
  }

  Widget _secaoFiltros() {
    final opcoes = _obterOpcoesEscopoEspecifico();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _filtroNivel == null,
                onSelected: (_) {
                  setState(() {
                    _filtroNivel = null;
                    _filtroEscopoId = null;
                  });
                },
                selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
              ),
              const SizedBox(width: 8),
              for (final nivel in NivelEscopo.selecionaveis) ...[
                ChoiceChip(
                  label: Text(nivel.rotulo),
                  selected: _filtroNivel == nivel,
                  onSelected: (_) {
                    setState(() {
                      _filtroNivel = nivel;
                      _filtroEscopoId = null;
                    });
                  },
                  selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (_filtroNivel != null && opcoes.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: CampoSelecao(
              label: 'Filtrar por ${_filtroNivel!.rotulo}',
              valor: _filtroEscopoId ?? 0,
              itens: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text(
                    'Todos os ${_filtroNivel!.rotulo.toLowerCase()}s',
                  ),
                ),
                for (final entry in opcoes.entries)
                  DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (val) {
                setState(() {
                  _filtroEscopoId = (val == null || val == 0) ? null : val;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _construirEstadoVazioModal({
    required IconData icone,
    required String titulo,
    required String descricao,
    required String acao,
    required IconData iconeBotao,
    required VoidCallback onAcao,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconeComFundo(
              icone: icone,
              cor: Cores.azulAcao,
              tamanho: 52,
              raio: 999,
              tamanhoIcone: 24,
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Tipografia.titleMedium.copyWith(
                color: Cores.textoPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                descricao,
                textAlign: TextAlign.center,
                style: Tipografia.bodySmall.copyWith(
                  color: Cores.cinzaEscuro,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            BotaoPrimario(
              texto: acao,
              icone: iconeBotao,
              onPressed: onAcao,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return _construirEstadoVazioModal(
        icone: LucideIcons.circle_alert,
        titulo: 'Erro ao carregar',
        descricao: _erro!,
        acao: 'Tentar novamente',
        iconeBotao: LucideIcons.rotate_ccw,
        onAcao: _carregar,
      );
    }

    if (_agendamentos.isEmpty) {
      return _construirEstadoVazioModal(
        icone: LucideIcons.calendar_off,
        titulo: 'Nenhum agendamento ativo',
        descricao:
            'Você não possui relatórios com agendamento pontual ou recorrente configurados.',
        acao: 'Nova Geração Autônoma',
        iconeBotao: LucideIcons.plus,
        onAcao: () {
          Navigator.of(context).pop();
          context.push('/relatorios/agendar');
        },
      );
    }

    final filtrados = _agendamentosFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secaoFiltros(),
        const SizedBox(height: 16),
        Expanded(
          child: filtrados.isEmpty
              ? _construirEstadoVazioModal(
                  icone: LucideIcons.search_x,
                  titulo: 'Nenhum agendamento encontrado',
                  descricao:
                      'Não há agendamentos para o nível ou escopo selecionado.',
                  acao: 'Limpar filtros',
                  iconeBotao: LucideIcons.rotate_ccw,
                  onAcao: () {
                    setState(() {
                      _filtroNivel = null;
                      _filtroEscopoId = null;
                    });
                  },
                )
              : ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    return _cartaoAgendamento(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _cartaoAgendamento(AgendamentoRelatorio agendamento) {
    final proximaFormatada = _formatarDataHora(agendamento.proximaExecucao);
    final ultimaFormatada = _formatarDataHora(agendamento.ultimaExecucao);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.bordaSutil),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            agendamento.nome,
                            style: Tipografia.titleSmall.copyWith(
                              color: Cores.textoPrincipal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _badgeStatus(agendamento),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.file_text,
                          size: 14,
                          color: Cores.cinzaMedio,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Template: ${agendamento.templateNome.isEmpty ? "Padrão" : agendamento.templateNome}',
                            style: Tipografia.bodySmall.copyWith(
                              color: Cores.cinzaEscuro,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: agendamento.ativo
                        ? 'Deixar inativo'
                        : 'Ativar agendamento',
                    icon: Icon(
                      agendamento.ativo
                          ? LucideIcons.circle_check
                          : LucideIcons.circle_minus,
                      size: 20,
                      color: agendamento.ativo
                          ? Cores.verdeSucesso
                          : Cores.cinzaMedio,
                    ),
                    onPressed: () => _alternarStatusAgendamento(agendamento),
                  ),
                  IconButton(
                    tooltip: 'Excluir agendamento',
                    icon: const Icon(
                      LucideIcons.trash_2,
                      size: 18,
                      color: Cores.vermelhoErro,
                    ),
                    onPressed: () => _excluirAgendamento(agendamento),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _chipInfo(
                agendamento.nivelEscopo == NivelEscopo.projeto
                    ? LucideIcons.git_branch
                    : agendamento.nivelEscopo == NivelEscopo.programa
                        ? LucideIcons.folder_kanban
                        : LucideIcons.building_2,
                '${agendamento.nivelEscopo.rotulo}: ${agendamento.escopoRotulo}',
                corFundo: Cores.cinzaClaro.withValues(alpha: 0.5),
                corTexto: Cores.cinzaEscuro,
              ),
              _chipInfo(
                agendamento.tipoAgendamento == 'recorrente'
                    ? LucideIcons.repeat
                    : LucideIcons.calendar,
                agendamento.descricaoRecorrencia,
                corFundo: Cores.azulAcao.withValues(alpha: 0.08),
                corTexto: Cores.azulAcao,
              ),
              if (proximaFormatada.isNotEmpty)
                _chipInfo(
                  LucideIcons.clock,
                  'Próxima: $proximaFormatada',
                  corFundo: Cores.cinzaClaro.withValues(alpha: 0.5),
                  corTexto: Cores.textoPrincipal,
                ),
              if (ultimaFormatada.isNotEmpty)
                _chipInfo(
                  LucideIcons.history,
                  'Última: $ultimaFormatada',
                  corFundo: Cores.cinzaClaro.withValues(alpha: 0.5),
                  corTexto: Cores.cinzaEscuro,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeStatus(AgendamentoRelatorio agendamento) {
    final pontualGerado = agendamento.tipoAgendamento == 'pontual' &&
        agendamento.ultimaExecucao != null &&
        agendamento.ultimaExecucao!.isNotEmpty;

    if (pontualGerado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Cores.verdeSucesso.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Gerado',
          style: Tipografia.labelSmall.copyWith(
            color: Cores.verdeSucesso,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final ativo = agendamento.ativo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (ativo ? Cores.verdeSucesso : Cores.cinzaMedio).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: Tipografia.labelSmall.copyWith(
          color: ativo ? Cores.verdeSucesso : Cores.cinzaMedio,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _chipInfo(
    IconData icone,
    String texto, {
    Color? corFundo,
    Color? corTexto,
  }) {
    final bg = corFundo ?? Cores.cinzaClaro.withValues(alpha: 0.4);
    final fg = corTexto ?? Cores.cinzaEscuro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            texto,
            style: Tipografia.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

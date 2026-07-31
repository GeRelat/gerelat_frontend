import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/relatorios_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaRelatorios extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaRelatorios({super.key, required this.repositorioCatalogo});

  @override
  State<PaginaRelatorios> createState() => _PaginaRelatoriosState();
}

class _PaginaRelatoriosState extends State<PaginaRelatorios> {
  late final RelatoriosViewModel _viewModel;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = RelatoriosViewModel(widget.repositorioCatalogo)..carregar();
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cabeçalho, busca e o atalho de geração não leem `_viewModel` — só
    // `_conteudo` depende dele, então vão no `child`.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [child!, const SizedBox(height: 24), _conteudo(context)],
          ),
        );
      },
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
          const SizedBox(height: 24),
          _atalhoGeracao(context),
        ],
      ),
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

  Widget _atalhoGeracao(BuildContext context) {
    return CartaoConteudo(
      child: Row(
        children: [
          const IconeComFundo(
            cor: Cores.azulAcao,
            tamanho: 52,
            raio: 14,
            icone: LucideIcons.file_output,
            tamanhoIcone: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geração rápida',
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Abra o fluxo completo para selecionar evento, template e parâmetros do documento.',
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
              ],
            ),
          ),
          BotaoPrimario(
            texto: 'Abrir Gerador',
            icone: LucideIcons.arrow_right,
            onPressed: () => _abrirGeracao(context),
          ),
        ],
      ),
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
      child: Column(
        children: [
          for (final relatorio in relatorios)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.file_text),
              title: Text(relatorio.titulo),
              subtitle: Text('${relatorio.evento} - ${relatorio.template}'),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(relatorio.status),
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
            ),
        ],
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
}

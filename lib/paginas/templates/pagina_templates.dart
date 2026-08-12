import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/templates_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

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
}

class _CartaoTemplate extends StatelessWidget {
  final TemplateRelatorio template;

  /// Nome da entidade dona do template (cliente, programa ou projeto).
  final String dono;
  final Future<void> Function() onEditado;
  final Future<bool> Function(int) onExcluir;
  final Future<Uint8List?> Function(int) onBaixar;
  final String? Function() obterMensagemErro;

  const _CartaoTemplate(
    this.template, {
    required this.dono,
    required this.onEditado,
    required this.onExcluir,
    required this.onBaixar,
    required this.obterMensagemErro,
  });

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
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

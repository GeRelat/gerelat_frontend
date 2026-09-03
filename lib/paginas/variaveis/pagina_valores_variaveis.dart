import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/campo_valor_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/variaveis/componentes/editor_valor_campo.dart';
import 'package:go_router/go_router.dart';

/// Preenchimento dos valores das variáveis para uma instância concreta.
///
/// As variáveis listadas são as declaradas em qualquer ancestral do alvo (uma
/// variável do cliente aparece para todos os eventos daquele cliente) cujo
/// nível de aplicação é o do alvo escolhido.
class PaginaValoresVariaveis extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final SessaoViewModel sessaoViewModel;

  const PaginaValoresVariaveis({
    super.key,
    required this.repositorioCatalogo,
    required this.urlBase,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaValoresVariaveis> createState() => _PaginaValoresVariaveisState();
}

class _PaginaValoresVariaveisState extends State<PaginaValoresVariaveis> {
  late final CampoValorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CampoValorViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    _viewModel.carregarHierarquia();
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
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando && _viewModel.hierarquia.clientes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child!,
              const SizedBox(height: 24),
              _seletorAlvo(),
              const SizedBox(height: 24),
              if (_viewModel.alvoId == null)
                _avisoAlvoNaoSelecionado()
              else
                _listaVariaveis(),
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valores de variáveis',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha a entidade que vai ter os valores preenchidos. Aparecem aqui '
            'as variáveis declaradas nela e em qualquer escopo acima dela — é o '
            'que o backend resolve na geração do relatório.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }

  Widget _seletorAlvo() {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preencher valores de',
            style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NivelAplicacao.values
                .where((nivel) => nivel != NivelAplicacao.evento)
                .map((nivel) {
              return ChoiceChip(
                label: Text(nivel.rotulo),
                selected: _viewModel.alvo == nivel,
                onSelected: (_) => _viewModel.selecionarAlvo(nivel, null),
                selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          CampoSelecao(
            label: _viewModel.alvo.rotulo,
            valor: _viewModel.alvoId,
            itens: _viewModel.opcoesAlvo
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.nome)),
                )
                .toList(),
            onChanged: (value) =>
                _viewModel.selecionarAlvo(_viewModel.alvo, value),
          ),
        ],
      ),
    );
  }

  Widget _avisoAlvoNaoSelecionado() {
    return CartaoConteudo(
      child: Row(
        children: [
          const Icon(LucideIcons.arrow_up, color: Cores.cinzaMedio, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escolha ${_viewModel.alvo.rotulo.toLowerCase()} acima para preencher '
              'os valores das variáveis aplicáveis a ele.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaVariaveis() {
    if (_viewModel.carregando && _viewModel.variaveis.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final podeEditar = _viewModel.podeEditar;

    if (_viewModel.variaveis.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.tags,
        titulo: 'Nenhuma variável aplicável',
        descricao:
            'Nenhuma variável declarada para ${_viewModel.nomeAlvoSelecionado} '
            'ou para um escopo acima dele se aplica a este nível.',
        acao: 'Declarar variável',
        onAcao: podeEditar ? () => context.go('/variaveis/definicoes') : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (podeEditar && _viewModel.totalPendentes > 0) ...[
          _avisoPendentes(_viewModel.totalPendentes),
          const SizedBox(height: 16),
        ],
        for (final variavel in _viewModel.variaveis)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CartaoVariavel(
              // Sem chave por definição, trocar o alvo reaproveitaria o
              // `EditorValorCampo` da posição e manteria os controllers com o
              // valor da instância anterior.
              key: ValueKey(
                '${_viewModel.alvo.valorApi}:${_viewModel.alvoId}:${variavel.definicao.id}',
              ),
              variavel: variavel,
              viewModel: _viewModel,
              repositorioCatalogo: widget.repositorioCatalogo,
              urlBase: widget.urlBase,
            ),
          ),
      ],
    );
  }

  Widget _avisoPendentes(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.ambarAlerta.withValues(alpha: 0.12),
        border: Border.all(color: Cores.ambarAlerta.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangle_alert,
            size: 18,
            color: Cores.ambarAlerta,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              total == 1
                  ? '1 variável obrigatória ainda sem valor. Relatórios que a usarem sairão com o texto do placeholder.'
                  : '$total variáveis obrigatórias ainda sem valor. Relatórios que as usarem sairão com o texto do placeholder.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um cartão por variável: cabeçalho com referência/origem e o editor do tipo.
class _CartaoVariavel extends StatefulWidget {
  final VariavelDoAlvo variavel;
  final CampoValorViewModel viewModel;
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;

  const _CartaoVariavel({
    super.key,
    required this.variavel,
    required this.viewModel,
    required this.repositorioCatalogo,
    required this.urlBase,
  });

  @override
  State<_CartaoVariavel> createState() => _CartaoVariavelState();
}

class _CartaoVariavelState extends State<_CartaoVariavel> {
  final _editorKey = GlobalKey<EditorValorCampoState>();
  bool _salvando = false;

  Future<void> _salvar() async {
    final editor = _editorKey.currentState;
    if (editor == null) return;

    setState(() => _salvando = true);
    final resultado = await editor.montarValor();
    if (!mounted) return;

    final valor = resultado.valor;
    if (valor == null) {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.erro ?? 'Preencha o valor.')),
      );
      return;
    }

    final sucesso = await widget.viewModel.salvarValor(
      variavel: widget.variavel,
      valor: valor,
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Valor de "${widget.variavel.definicao.referencia}" salvo.'
              : widget.viewModel.mensagemErro ?? 'Erro ao salvar o valor.',
        ),
      ),
    );
  }

  Future<void> _limpar() async {
    final sucesso = await widget.viewModel.limparValor(widget.variavel);
    if (!mounted || sucesso) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.viewModel.mensagemErro ?? 'Erro ao limpar.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final definicao = widget.variavel.definicao;
    final podeEditar = widget.viewModel.podeEditar;
    return CartaoConteudo(
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
                            definicao.referencia,
                            style: Tipografia.labelLarge.copyWith(
                              color: Cores.textoPrincipal,
                            ),
                          ),
                        ),
                        if (definicao.obrigatorio) ...[
                          const SizedBox(width: 8),
                          _etiqueta(
                            'Obrigatória',
                            widget.variavel.pendente
                                ? Cores.ambarAlerta
                                : Cores.verdeSucesso,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definicao.descricao,
                      style: Tipografia.bodyMedium.copyWith(
                        color: Cores.cinzaEscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${definicao.tipo.rotulo} · definida em ${widget.variavel.origem}',
                      style: Tipografia.bodySmall.copyWith(
                        color: Cores.cinzaMedio,
                      ),
                    ),
                  ],
                ),
              ),
              if (podeEditar && widget.variavel.preenchida)
                TextButton.icon(
                  onPressed: widget.viewModel.carregando ? null : _limpar,
                  icon: const Icon(LucideIcons.eraser, size: 16),
                  label: const Text('Limpar valor'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          EditorValorCampo(
            key: _editorKey,
            tipo: definicao.tipo,
            valorInicial: widget.variavel.valor?.valor ?? const {},
            aoEnviarImagem: widget.viewModel.enviarImagem,
            repositorioCatalogo: widget.repositorioCatalogo,
            urlBase: widget.urlBase,
            escopo: widget.viewModel.alvoNivel,
            escopoId: widget.viewModel.alvoId,
            readOnly: !podeEditar,
            variaveisDisponiveis: widget.viewModel.variaveisDisponiveis,
            referenciaVariavel: definicao.referencia,
          ),
          if (podeEditar) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BotaoPrimario(
                  texto: _salvando ? 'Salvando...' : 'Salvar valor',
                  icone: LucideIcons.save,
                  onPressed: _salvando || widget.viewModel.carregando
                      ? null
                      : _salvar,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _etiqueta(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto, style: Tipografia.labelMedium.copyWith(color: cor)),
    );
  }
}

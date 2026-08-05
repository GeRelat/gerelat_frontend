import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/campo_definicao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Cadastro do *schema* das variáveis. Uma definição é declarada num escopo
/// (cliente, programa ou projeto) e diz a que nível de entidade ela se aplica;
/// os valores são preenchidos na tela "Valores de Variáveis".
class PaginaDefinicoesVariaveis extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaDefinicoesVariaveis({
    super.key,
    required this.repositorioCatalogo,
  });

  @override
  State<PaginaDefinicoesVariaveis> createState() =>
      _PaginaDefinicoesVariaveisState();
}

class _PaginaDefinicoesVariaveisState extends State<PaginaDefinicoesVariaveis> {
  final _formKey = GlobalKey<FormState>();
  final _referencia = TextEditingController();
  final _descricao = TextEditingController();
  final _focoReferencia = FocusNode();

  late final CampoDefinicaoViewModel _viewModel;

  int? _definicaoEmEdicaoId;
  TipoCampo _tipo = TipoCampo.texto;
  NivelAplicacao _nivelAplicacao = NivelAplicacao.projeto;
  bool _obrigatorio = false;

  @override
  void initState() {
    super.initState();
    _viewModel = CampoDefinicaoViewModel(widget.repositorioCatalogo)
      ..carregarHierarquia();
  }

  @override
  void dispose() {
    _referencia.dispose();
    _descricao.dispose();
    _focoReferencia.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _limparFormulario() {
    setState(() {
      _definicaoEmEdicaoId = null;
      _tipo = TipoCampo.texto;
      _nivelAplicacao = _nivelPadraoDoEscopo();
      _obrigatorio = false;
      _referencia.clear();
      _descricao.clear();
    });
  }

  /// O nível mais raso permitido para o escopo atual — o próprio escopo.
  NivelAplicacao _nivelPadraoDoEscopo() => _viewModel.escopo.comoAplicacao;

  void _iniciarEdicao(CampoDefinicao definicao) {
    setState(() {
      _definicaoEmEdicaoId = definicao.id;
      _tipo = definicao.tipo;
      _nivelAplicacao = definicao.nivelAplicacao;
      _obrigatorio = definicao.obrigatorio;
      _referencia.text = definicao.referencia;
      _descricao.text = definicao.descricao;
    });
  }

  Future<void> _trocarNivelEscopo(NivelEscopo escopo) async {
    _limparFormulario();
    await _viewModel.selecionarEscopo(escopo, null);
    if (!mounted) return;
    setState(() => _nivelAplicacao = _nivelPadraoDoEscopo());
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await _viewModel.salvar(
      definicaoId: _definicaoEmEdicaoId,
      nivelAplicacao: _nivelAplicacao,
      referencia: _referencia.text.trim(),
      descricao: _descricao.text.trim(),
      tipo: _tipo,
      obrigatorio: _obrigatorio,
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

  Future<void> _confirmarExclusao(CampoDefinicao definicao) async {
    final confirmou = await DialogoConfirmacaoExclusao.mostrar(
      context,
      titulo: 'Remover variável',
      mensagem:
          'Remover a variável "${definicao.descricao}" (${definicao.referencia})? '
          'Todos os valores já preenchidos para ela serão apagados junto.',
      textoConfirmar: 'Remover',
    );
    if (!confirmou) return;

    final definicaoId = definicao.id;
    if (definicaoId == null) return;
    final sucesso = await _viewModel.excluir(definicaoId);
    if (!mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao remover.')),
      );
    }
    if (_definicaoEmEdicaoId == definicaoId) {
      _limparFormulario();
    }
  }

  String? _obrigatorioValidator(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // O título é a única parte que não depende de `_viewModel`; é passado
    // como `child` para não ser reconstruído a cada notificação.
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
              _seletorEscopo(),
              const SizedBox(height: 24),
              if (_viewModel.escopoId == null)
                _avisoEscopoNaoSelecionado()
              else ...[
                _formularioDefinicao(),
                const SizedBox(height: 32),
                _conteudoLista(),
              ],
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Definições de variáveis',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cada variável tem uma referência (ex: objetivo_evento) usada nos nós '
            'do template. Declare-a no escopo mais amplo possível — uma variável '
            'do cliente vale para todos os programas, projetos e eventos dele — e '
            'escolha a que nível ela se aplica. Os valores são preenchidos na tela '
            '"Valores de variáveis".',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }

  Widget _seletorEscopo() {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escopo da declaração',
            style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NivelEscopo.values.map((escopo) {
              return ChoiceChip(
                label: Text(escopo.rotulo),
                selected: _viewModel.escopo == escopo,
                onSelected: (_) => _trocarNivelEscopo(escopo),
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
              _limparFormulario();
              _viewModel.selecionarEscopo(_viewModel.escopo, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _avisoEscopoNaoSelecionado() {
    return CartaoConteudo(
      child: Row(
        children: [
          const Icon(LucideIcons.arrow_up, color: Cores.cinzaMedio, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escolha ${_viewModel.escopo == NivelEscopo.cliente ? 'um cliente' : _viewModel.escopo == NivelEscopo.programa ? 'um programa' : 'um projeto'} '
              'acima para ver e gerenciar as variáveis declaradas nele.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formularioDefinicao() {
    final niveis = _viewModel.niveisAplicacaoPermitidos;
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
                    validator: (valor) => _viewModel.validarReferencia(
                      valor ?? '',
                      ignorandoDefinicaoId: _definicaoEmEdicaoId,
                    ),
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
                    itens: TipoCampo.values
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo.index,
                            child: Text(tipo.rotulo),
                          ),
                        )
                        .toList(),
                    onChanged: _definicaoEmEdicaoId != null
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _tipo = TipoCampo.values[value]);
                          },
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: CampoSelecao(
                    label: 'Aplica-se a cada',
                    valor: _nivelAplicacao.index,
                    itens: niveis
                        .map(
                          (nivel) => DropdownMenuItem(
                            value: nivel.index,
                            child: Text(nivel.rotulo),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(
                        () => _nivelAplicacao = NivelAplicacao.values[value],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _explicacaoNivel(),
              style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Checkbox(
                  value: _obrigatorio,
                  onChanged: (value) =>
                      setState(() => _obrigatorio = value ?? false),
                ),
                Expanded(
                  child: Text(
                    'Obrigatória — avisar quando um relatório usar esta variável sem valor preenchido',
                    style: Tipografia.bodyMedium.copyWith(
                      color: Cores.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_definicaoEmEdicaoId != null) ...[
                  TextButton(
                    onPressed: _viewModel.carregando ? null : _limparFormulario,
                    child: const Text('Cancelar edição'),
                  ),
                  const SizedBox(width: 12),
                ],
                BotaoPrimario(
                  texto: _viewModel.carregando
                      ? 'Salvando...'
                      : _definicaoEmEdicaoId != null
                      ? 'Salvar'
                      : 'Adicionar',
                  icone: _definicaoEmEdicaoId != null
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

  String _explicacaoNivel() {
    final escopo = _viewModel.nomeEscopoSelecionado;
    final nivel = _nivelAplicacao.rotulo.toLowerCase();
    if (_nivelAplicacao == _viewModel.escopo.comoAplicacao) {
      return 'A variável terá um único valor, preenchido para $escopo.';
    }
    return 'Cada $nivel de "$escopo" terá seu próprio valor para esta variável.';
  }

  Widget _conteudoLista() {
    if (_viewModel.carregando && _viewModel.definicoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.definicoes.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.tags,
        titulo: 'Nenhuma variável declarada',
        descricao:
            'Adicione a primeira variável de ${_viewModel.nomeEscopoSelecionado}.',
        acao: 'Adicionar variável',
        onAcao: () => _focoReferencia.requestFocus(),
      );
    }

    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const CabecalhoTabelaCrud(colunas: _colunas),
          for (final definicao in _viewModel.definicoes) _linha(definicao),
        ],
      ),
    );
  }

  static const _colunas = [
    ColunaTabelaCrud(rotulo: 'Referência', flex: 2),
    ColunaTabelaCrud(rotulo: 'Descrição', flex: 3),
    ColunaTabelaCrud(rotulo: 'Tipo', flex: 1),
    ColunaTabelaCrud(rotulo: 'Aplica-se a', flex: 1),
    ColunaTabelaCrud(rotulo: 'Obrigatória', flex: 1),
    ColunaTabelaCrud(rotulo: 'Ações', flex: 1),
  ];

  Widget _linha(CampoDefinicao definicao) {
    return LinhaTabelaCrud(
      colunas: _colunas,
      celulas: [
        Text(
          definicao.referencia,
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        Text(
          definicao.descricao,
          style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        _etiqueta(definicao.tipo.rotulo),
        _etiqueta(definicao.nivelAplicacao.rotulo),
        Icon(
          definicao.obrigatorio ? LucideIcons.circle_check : LucideIcons.circle,
          size: 18,
          color: definicao.obrigatorio ? Cores.verdeSucesso : Cores.cinzaMedio,
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _iniciarEdicao(definicao),
              icon: const Icon(LucideIcons.pencil, size: 18),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: () => _confirmarExclusao(definicao),
              icon: const Icon(
                LucideIcons.trash_2,
                size: 18,
                color: Cores.vermelhoErro,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _etiqueta(String texto) {
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

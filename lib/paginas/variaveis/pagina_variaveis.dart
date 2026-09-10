import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/hierarquia_escopo.dart';
import 'package:gerelat_frontend/aplicacao/variaveis_do_escopo.dart';
import 'package:gerelat_frontend/aplicacao/view_models/campo_definicao_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_definicao.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_valor.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/dialogo_confirmacao_exclusao.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/variaveis/componentes/editor_valor_campo.dart';

/// Tela única de variáveis: cada variável é declarada em um programa e, dentro
/// da própria linha, o usuário define/edita o valor — fixo do programa, um por
/// projeto ou um por evento.
class PaginaVariaveis extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final SessaoViewModel sessaoViewModel;

  const PaginaVariaveis({
    super.key,
    required this.repositorioCatalogo,
    required this.urlBase,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaVariaveis> createState() => _PaginaVariaveisState();
}

class _PaginaVariaveisState extends State<PaginaVariaveis> {
  final _formKey = GlobalKey<FormState>();
  final _referencia = TextEditingController();
  final _descricao = TextEditingController();

  late final CampoDefinicaoViewModel _viewModel;

  List<VariavelDisponivel> _variaveisDisponiveis = const [];
  bool _mostrandoForm = false;
  int? _editandoId;
  int? _expandidaId;
  NivelEscopo _escopoCriacao = NivelEscopo.programa;
  int? _projetoCriacaoId;
  TipoCampo _tipo = TipoCampo.texto;
  NivelAplicacao _aplicacao = NivelAplicacao.programa;
  bool _obrigatorio = false;

  @override
  void initState() {
    super.initState();
    _viewModel = CampoDefinicaoViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    widget.sessaoViewModel.addListener(_aoMudarSessao);
    _carregarInicial();
  }

  void _aoMudarSessao() {
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    _carregarVariaveisDisponiveis();
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _referencia.dispose();
    _descricao.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  List<OpcaoSelecao> get _opcoesPrograma => _viewModel.hierarquia
      .opcoesDeEscopo(NivelEscopo.programa, clienteId: _viewModel.clienteAtivoId);

  Future<void> _carregarInicial() async {
    await _viewModel.carregarHierarquia();
    if (!mounted) return;
    final programas = _opcoesPrograma;
    await _viewModel.selecionarEscopo(
      NivelEscopo.programa,
      programas.isNotEmpty ? programas.first.id : null,
    );
    if (!mounted) return;
    await _carregarVariaveisDisponiveis();
  }

  Future<void> _carregarVariaveisDisponiveis() async {
    final programaId = _viewModel.escopoId;
    if (programaId == null) {
      setState(() => _variaveisDisponiveis = const []);
      return;
    }
    final lista = await carregarVariaveisDoEscopo(
      widget.repositorioCatalogo,
      _viewModel.hierarquia,
      escopo: NivelEscopo.programa,
      escopoId: programaId,
    );
    if (!mounted) return;
    setState(() => _variaveisDisponiveis = lista);
  }

  Future<void> _trocarPrograma(int? id) async {
    setState(() {
      _expandidaId = null;
      _mostrandoForm = false;
    });
    await _viewModel.selecionarEscopo(NivelEscopo.programa, id);
    if (!mounted) return;
    await _carregarVariaveisDisponiveis();
  }

  String _nomeDoProjeto(int? projetoId) {
    if (projetoId == null) return '';
    final projeto = _viewModel.hierarquia.projetoPorId(projetoId);
    return projeto?.nome ?? 'Projeto #$projetoId';
  }

  void _limparForm() {
    _editandoId = null;
    _escopoCriacao = NivelEscopo.programa;
    _projetoCriacaoId = null;
    _tipo = TipoCampo.texto;
    _aplicacao = NivelAplicacao.programa;
    _obrigatorio = false;
    _referencia.clear();
    _descricao.clear();
  }

  void _iniciarNova() {
    final programaId = _viewModel.escopoId;
    final podeNoPrograma = _viewModel.podeCriarNoPrograma(programaId);
    final projetosPermitidos = _viewModel.projetosPermitidosParaCriar(programaId);

    setState(() {
      _limparForm();
      if (podeNoPrograma) {
        _escopoCriacao = NivelEscopo.programa;
        _aplicacao = NivelAplicacao.programa;
        _projetoCriacaoId =
            projetosPermitidos.isNotEmpty ? projetosPermitidos.first.id : null;
      } else if (projetosPermitidos.isNotEmpty) {
        _escopoCriacao = NivelEscopo.projeto;
        _aplicacao = NivelAplicacao.projeto;
        _projetoCriacaoId = projetosPermitidos.first.id;
      }
      _mostrandoForm = true;
    });
  }

  void _iniciarEdicao(CampoDefinicao definicao) {
    setState(() {
      _editandoId = definicao.id;
      _escopoCriacao = definicao.nivelEscopo;
      _projetoCriacaoId = definicao.projetoId;
      _tipo = definicao.tipo;
      _aplicacao = definicao.nivelAplicacao;
      _obrigatorio = definicao.obrigatorio;
      _referencia.text = definicao.referencia;
      _descricao.text = definicao.descricao;
      _mostrandoForm = true;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final programaId = _viewModel.escopoId;
    final escopoId = _escopoCriacao == NivelEscopo.programa
        ? programaId
        : _projetoCriacaoId;

    if (escopoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o projeto para criar a variável.'),
        ),
      );
      return;
    }

    final sucesso = await _viewModel.salvar(
      definicaoId: _editandoId,
      escopo: _escopoCriacao,
      escopoId: escopoId,
      nivelAplicacao: _aplicacao,
      referencia: _referencia.text.trim(),
      descricao: _descricao.text.trim(),
      tipo: _tipo,
      obrigatorio: _obrigatorio,
    );
    if (!mounted) return;
    if (sucesso) {
      setState(() => _mostrandoForm = false);
      await _carregarVariaveisDisponiveis();
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
    final id = definicao.id;
    if (id == null) return;
    final sucesso = await _viewModel.excluir(id);
    if (!mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao remover.')),
      );
      return;
    }
    if (_editandoId == id) setState(() => _mostrandoForm = false);
    if (_expandidaId == id) setState(() => _expandidaId = null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando && _viewModel.hierarquia.programas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child!,
              const SizedBox(height: 24),
              _seletorPrograma(),
              const SizedBox(height: 24),
              if (_viewModel.escopoId == null)
                _avisoSemPrograma()
              else ...[
                if (_viewModel.podeCriarVariavel(_viewModel.escopoId) &&
                    !_mostrandoForm) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BotaoPrimario(
                      texto: 'Nova variável',
                      icone: LucideIcons.plus,
                      onPressed: _iniciarNova,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_mostrandoForm) ...[
                  _formulario(),
                  const SizedBox(height: 24),
                ],
                _lista(),
              ],
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variáveis',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cada variável tem uma referência (ex: objetivo_projeto) usada nos '
            'templates. Escolha o programa, crie a variável e defina o valor '
            'dela aqui mesmo — um valor fixo para o programa inteiro ou um por '
            'projeto.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }

  Widget _seletorPrograma() {
    return CartaoConteudo(
      child: CampoSelecao(
        label: 'Programa',
        valor: _viewModel.escopoId,
        itens: _opcoesPrograma
            .map(
              (item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.nome)),
            )
            .toList(),
        onChanged: _trocarPrograma,
      ),
    );
  }

  Widget _avisoSemPrograma() {
    return CartaoConteudo(
      child: Row(
        children: [
          const Icon(LucideIcons.arrow_up, color: Cores.cinzaMedio, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escolha um programa acima para ver e gerenciar suas variáveis.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    final programaId = _viewModel.escopoId;
    final podeNoPrograma = _viewModel.podeCriarNoPrograma(programaId);
    final projetosPermitidos =
        _viewModel.projetosPermitidosParaCriar(programaId);
    final todosProjetos = _viewModel.projetosDoPrograma(programaId);
    final projetosDropdown =
        _editandoId != null ? todosProjetos : projetosPermitidos;

    return CartaoConteudo(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editandoId != null ? 'Editar variável' : 'Nova variável',
              style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFormulario(
                    label: 'Referência',
                    hint: 'Ex: objetivo_projeto',
                    icone: LucideIcons.tags,
                    controller: _referencia,
                    validator: (valor) => _viewModel.validarReferencia(
                      valor ?? '',
                      escopo: _escopoCriacao,
                      escopoId: _escopoCriacao == NivelEscopo.programa
                          ? _viewModel.escopoId
                          : _projetoCriacaoId,
                      ignorandoDefinicaoId: _editandoId,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: CampoFormulario(
                    label: 'Descrição',
                    hint: 'Ex: Objetivo do projeto',
                    icone: LucideIcons.file_text,
                    controller: _descricao,
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 260,
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
                onChanged: _editandoId != null
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _tipo = TipoCampo.values[value]);
                      },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Esta variável tem:',
              style: Tipografia.labelLarge.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (podeNoPrograma ||
                    (_editandoId != null &&
                        _escopoCriacao == NivelEscopo.programa &&
                        _aplicacao == NivelAplicacao.programa))
                  ChoiceChip(
                    label: const Text('Um valor fixo para todo o programa'),
                    selected: _escopoCriacao == NivelEscopo.programa &&
                        _aplicacao == NivelAplicacao.programa,
                    onSelected: _editandoId != null
                        ? null
                        : (_) {
                            setState(() {
                              _escopoCriacao = NivelEscopo.programa;
                              _aplicacao = NivelAplicacao.programa;
                            });
                          },
                    selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                  ),
                if (podeNoPrograma ||
                    (_editandoId != null &&
                        _escopoCriacao == NivelEscopo.programa &&
                        _aplicacao == NivelAplicacao.projeto))
                  ChoiceChip(
                    label: const Text('Um valor para cada projeto'),
                    selected: _escopoCriacao == NivelEscopo.programa &&
                        _aplicacao == NivelAplicacao.projeto,
                    onSelected: _editandoId != null
                        ? null
                        : (_) {
                            setState(() {
                              _escopoCriacao = NivelEscopo.programa;
                              _aplicacao = NivelAplicacao.projeto;
                            });
                          },
                    selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                  ),
                if (projetosPermitidos.isNotEmpty ||
                    (_editandoId != null &&
                        _escopoCriacao == NivelEscopo.projeto))
                  ChoiceChip(
                    label: const Text('Um valor para um projeto específico'),
                    selected: _escopoCriacao == NivelEscopo.projeto,
                    onSelected: _editandoId != null
                        ? null
                        : (_) {
                            setState(() {
                              _escopoCriacao = NivelEscopo.projeto;
                              _aplicacao = NivelAplicacao.projeto;
                              if (_projetoCriacaoId == null &&
                                  projetosDropdown.isNotEmpty) {
                                _projetoCriacaoId = projetosDropdown.first.id;
                              }
                            });
                          },
                    selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                  ),
              ],
            ),
            if (_escopoCriacao == NivelEscopo.projeto) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: 320,
                child: CampoSelecao(
                  label: 'Projeto',
                  valor: _projetoCriacaoId,
                  itens: projetosDropdown
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.nome),
                        ),
                      )
                      .toList(),
                  onChanged: _editandoId != null
                      ? null
                      : (id) => setState(() => _projetoCriacaoId = id),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _explicacaoAplicacao(),
              style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Checkbox(
                  value: _obrigatorio,
                  onChanged: (value) =>
                      setState(() => _obrigatorio = value ?? false),
                ),
                Expanded(
                  child: Text(
                    'Obrigatória — avisar quando um relatório usar esta '
                    'variável sem valor preenchido',
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
                TextButton(
                  onPressed: _viewModel.carregando
                      ? null
                      : () => setState(() => _mostrandoForm = false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                BotaoPrimario(
                  texto: _viewModel.carregando
                      ? 'Salvando...'
                      : _editandoId != null
                      ? 'Salvar'
                      : 'Adicionar',
                  icone: _editandoId != null
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


  String _explicacaoAplicacao() {
    if (_escopoCriacao == NivelEscopo.projeto) {
      final nomeProj = _nomeDoProjeto(_projetoCriacaoId);
      return 'Esta variável existirá e terá valor exclusivo no projeto "$nomeProj".';
    }
    final programa = _viewModel.nomeEscopoSelecionado;
    return switch (_aplicacao) {
      NivelAplicacao.programa =>
        'Um único valor, usado em qualquer projeto de "$programa".',
      NivelAplicacao.projeto =>
        'Cada projeto de "$programa" terá seu próprio valor.',
      _ => '',
    };
  }

  Widget _lista() {
    if (_viewModel.carregando && _viewModel.definicoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.definicoes.isEmpty) {
      return EstadoVazio(
        icone: LucideIcons.tags,
        titulo: 'Nenhuma variável neste programa',
        descricao:
            'Crie a primeira variável de "${_viewModel.nomeEscopoSelecionado}".',
        acao: 'Nova variável',
        onAcao: _viewModel.podeCriarVariavel(_viewModel.escopoId)
            ? _iniciarNova
            : null,
      );
    }
    return Column(
      children: [
        for (final definicao in _viewModel.definicoes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _linhaVariavel(definicao),
          ),
      ],
    );
  }

  Widget _linhaVariavel(CampoDefinicao definicao) {
    final expandida = _expandidaId == definicao.id;
    final podeEditar = _viewModel.podeEditarDefinicao(definicao);
    return CartaoConteudo(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _expandidaId = expandida ? null : definicao.id,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    expandida
                        ? LucideIcons.chevron_down
                        : LucideIcons.chevron_right,
                    size: 18,
                    color: Cores.cinzaMedio,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          definicao.referencia,
                          style: Tipografia.labelLarge.copyWith(
                            color: Cores.textoPrincipal,
                          ),
                        ),
                        Text(
                          definicao.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tipografia.bodySmall.copyWith(
                            color: Cores.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _etiqueta(definicao.tipo.rotulo),
                  const SizedBox(width: 8),
                  if (definicao.nivelEscopo == NivelEscopo.projeto)
                    _etiqueta('Projeto: ${_nomeDoProjeto(definicao.projetoId)}')
                  else
                    _etiqueta(_rotuloAplicacao(definicao.nivelAplicacao)),
                  if (definicao.obrigatorio) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.circle_check,
                      size: 16,
                      color: Cores.verdeSucesso,
                    ),
                  ],
                  if (podeEditar) ...[
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => _iniciarEdicao(definicao),
                      icon: const Icon(LucideIcons.pencil, size: 16),
                    ),
                    IconButton(
                      tooltip: 'Remover',
                      onPressed: () => _confirmarExclusao(definicao),
                      icon: const Icon(
                        LucideIcons.trash_2,
                        size: 16,
                        color: Cores.vermelhoErro,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expandida)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _ValorVariavelInline(
                key: ValueKey('valor-${definicao.id}-${_viewModel.escopoId}'),
                repositorioCatalogo: widget.repositorioCatalogo,
                urlBase: widget.urlBase,
                definicao: definicao,
                programaId: _viewModel.escopoId!,
                hierarquia: _viewModel.hierarquia,
                variaveisDisponiveis: _variaveisDisponiveis,
                podeEditarEscopo: _viewModel.podeEditarEscopo,
              ),
            ),
        ],
      ),
    );
  }

  String _rotuloAplicacao(NivelAplicacao nivel) => switch (nivel) {
    NivelAplicacao.programa => 'Valor do programa',
    NivelAplicacao.projeto => 'Por projeto',
    NivelAplicacao.evento => 'Por evento',
    NivelAplicacao.cliente => 'Cliente',
  };

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

/// Editor do valor de uma variável dentro da própria linha. Resolve o alvo
/// (o programa ou um projeto) e chama `CampoValor` direto no repositório.
class _ValorVariavelInline extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final String urlBase;
  final CampoDefinicao definicao;
  final int programaId;
  final HierarquiaEscopo hierarquia;
  final List<VariavelDisponivel> variaveisDisponiveis;
  final bool Function(NivelEscopo escopo, int? escopoId) podeEditarEscopo;

  const _ValorVariavelInline({
    super.key,
    required this.repositorioCatalogo,
    required this.urlBase,
    required this.definicao,
    required this.programaId,
    required this.hierarquia,
    required this.variaveisDisponiveis,
    required this.podeEditarEscopo,
  });

  @override
  State<_ValorVariavelInline> createState() => _ValorVariavelInlineState();
}

class _ValorVariavelInlineState extends State<_ValorVariavelInline> {
  final _editorKey = GlobalKey<EditorValorCampoState>();
  int? _alvoId;
  CampoValor? _valorAtual;
  bool _carregando = false;
  bool _salvando = false;

  NivelAplicacao get _nivel => widget.definicao.nivelAplicacao;

  bool get _podeEditarValor {
    if (widget.definicao.projetoId != null) {
      return widget.podeEditarEscopo(
        NivelEscopo.projeto,
        widget.definicao.projetoId,
      );
    }
    if (_nivel == NivelAplicacao.programa) {
      return widget.podeEditarEscopo(
        NivelEscopo.programa,
        widget.programaId,
      );
    }
    if (_nivel == NivelAplicacao.projeto) {
      return _alvoId != null &&
          widget.podeEditarEscopo(NivelEscopo.projeto, _alvoId);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.definicao.projetoId != null) {
      _alvoId = widget.definicao.projetoId;
      _carregarValor();
    } else if (_nivel == NivelAplicacao.programa) {
      _alvoId = widget.programaId;
      _carregarValor();
    }
  }

  List<OpcaoSelecao> get _opcoesAlvo => widget.hierarquia.opcoesDe(
    _nivel,
    programaId: widget.programaId,
  );

  Future<void> _selecionarAlvo(int? id) async {
    setState(() {
      _alvoId = id;
      _valorAtual = null;
    });
    await _carregarValor();
  }

  Future<void> _carregarValor() async {
    final alvoId = _alvoId;
    if (alvoId == null) return;
    setState(() => _carregando = true);
    try {
      final valores = await widget.repositorioCatalogo.listarValores(
        alvo: _nivel,
        alvoId: alvoId,
      );
      CampoValor? achado;
      for (final v in valores) {
        if (v.definicaoId == widget.definicao.id) {
          achado = v;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _valorAtual = achado;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar valor: $erro')),
      );
    }
  }

  ({NivelEscopo escopo, int? escopoId}) get _escopoAsset {
    if (widget.definicao.projetoId != null) {
      return (
        escopo: NivelEscopo.projeto,
        escopoId: widget.definicao.projetoId,
      );
    }
    switch (_nivel) {
      case NivelAplicacao.programa:
        return (escopo: NivelEscopo.programa, escopoId: widget.programaId);
      case NivelAplicacao.projeto:
        return (escopo: NivelEscopo.projeto, escopoId: _alvoId);
      default:
        return (escopo: NivelEscopo.programa, escopoId: widget.programaId);
    }
  }

  Future<int?> _enviarImagem({
    required Uint8List arquivoBytes,
    required String nomeArquivo,
  }) async {
    final alvo = _escopoAsset;
    final escopoId = alvo.escopoId;
    if (escopoId == null) return null;
    try {
      final asset = await widget.repositorioCatalogo.criarAsset(
        arquivoBytes: arquivoBytes,
        nomeArquivo: nomeArquivo,
        escopo: alvo.escopo,
        escopoId: escopoId,
      );
      return asset.id;
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar imagem: $erro')),
        );
      }
      return null;
    }
  }

  Future<void> _salvarValor() async {
    final editor = _editorKey.currentState;
    final alvoId = _alvoId;
    if (editor == null || alvoId == null) return;
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
    try {
      await widget.repositorioCatalogo.salvarValor(
        valorId: _valorAtual?.id,
        definicaoId: widget.definicao.id!,
        alvo: _nivel,
        alvoId: alvoId,
        valor: valor,
      );
      if (!mounted) return;
      setState(() => _salvando = false);
      await _carregarValor();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Valor de "${widget.definicao.referencia}" salvo.'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $erro')),
      );
    }
  }

  Future<void> _limparValor() async {
    final valorId = _valorAtual?.id;
    if (valorId == null) return;
    try {
      await widget.repositorioCatalogo.excluirValor(valorId);
      if (!mounted) return;
      await _carregarValor();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao limpar: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final precisaAlvo =
        widget.definicao.projetoId == null &&
        _nivel != NivelAplicacao.programa;
    final podeEditar = _podeEditarValor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.fundoSecao,
        border: Border.all(color: Cores.bordaSutil),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (precisaAlvo) ...[
            CampoSelecao(
              label: 'Projeto',
              valor: _alvoId,
              itens: _opcoesAlvo
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.nome),
                    ),
                  )
                  .toList(),
              onChanged: _selecionarAlvo,
            ),
            const SizedBox(height: 16),
          ],
          if (_alvoId == null)
            Text(
              'Escolha um projeto para ver e editar o valor.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            )
          else if (_carregando)
            const Center(child: CircularProgressIndicator())
          else ...[
            EditorValorCampo(
              key: _editorKey,
              tipo: widget.definicao.tipo,
              valorInicial: _valorAtual?.valor ?? const {},
              aoEnviarImagem: _enviarImagem,
              repositorioCatalogo: widget.repositorioCatalogo,
              urlBase: widget.urlBase,
              escopo: _escopoAsset.escopo,
              escopoId: _escopoAsset.escopoId,
              readOnly: !podeEditar,
              variaveisDisponiveis: widget.variaveisDisponiveis,
              referenciaVariavel: widget.definicao.referencia,
            ),
            if (podeEditar) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_valorAtual != null)
                    TextButton.icon(
                      onPressed: _salvando ? null : _limparValor,
                      icon: const Icon(LucideIcons.eraser, size: 16),
                      label: const Text('Limpar valor'),
                    ),
                  const SizedBox(width: 8),
                  BotaoPrimario(
                    texto: _salvando ? 'Salvando...' : 'Salvar valor',
                    icone: LucideIcons.save,
                    onPressed: _salvando ? null : _salvarValor,
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

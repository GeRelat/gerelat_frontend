import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/template_form_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/classe_evento.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioTemplate extends StatefulWidget {
  final bool edicao;
  final int? templateId;
  final RepositorioCatalogo repositorioCatalogo;

  const PaginaFormularioTemplate({
    super.key,
    this.edicao = false,
    this.templateId,
    required this.repositorioCatalogo,
  });

  @override
  State<PaginaFormularioTemplate> createState() =>
      _PaginaFormularioTemplateState();
}

class _PaginaFormularioTemplateState extends State<PaginaFormularioTemplate> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  late final TemplateFormViewModel _viewModel;
  String? _nomeArquivo;
  Uint8List? _arquivoBytes;

  @override
  void initState() {
    super.initState();
    _viewModel = TemplateFormViewModel(widget.repositorioCatalogo);
    final templateId = widget.templateId;
    if (widget.edicao && templateId != null) {
      _viewModel.carregarEdicao(templateId).then((_) {
        final template = _viewModel.template;
        if (!mounted || template == null) return;
        _nome.text = template.nome;
        _nomeArquivo = template.arquivoBase.isEmpty
            ? null
            : template.arquivoBase;
        setState(() {});
      });
    } else {
      _viewModel.carregarOpcoes();
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    try {
      final arquivo = await selecionarArquivo(
        accept: '.docx',
        extensoesPermitidas: const ['.docx'],
        tamanhoMaximoBytes: 10 * 1024 * 1024,
      );
      if (arquivo == null) return;
      setState(() {
        _nomeArquivo = arquivo.nome;
        _arquivoBytes = arquivo.bytes;
      });
    } on ArquivoInvalidoException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final escopoId = _viewModel.escopoId;
    if (escopoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecione ${_viewModel.nivel.rotulo.toLowerCase()} ao qual o template pertence.',
          ),
        ),
      );
      return;
    }

    final idTemplate = await _viewModel.salvar(
      templateId: widget.templateId,
      escopo: _viewModel.nivel,
      escopoId: escopoId,
      nomeTemplate: _nome.text.trim(),
      arquivoBytes: _arquivoBytes,
      nomeArquivo: _nomeArquivo,
    );
    if (!mounted) return;
    if (idTemplate != null) {
      if (widget.edicao) {
        // Edição de metadados: volta para a lista.
        context.pop(true);
      } else {
        // Template recém-criado: segue direto para o editor de conteúdo.
        context.pushReplacement('/templates/$idTemplate/editor');
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar template.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O título não depende de `_viewModel` — é passado como `child`.
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando &&
            _viewModel.hierarquia.projetos.isEmpty &&
            _viewModel.hierarquia.clientes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child!,
                const SizedBox(height: 24),
                CartaoConteudo(
                  child: Column(
                    children: [
                      _campoEscopo(),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Nome do Template',
                        hint: 'Ex: Relatório padrão de visita técnica',
                        icone: LucideIcons.file_text,
                        controller: _nome,
                        validator: _obrigatorio,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 18),
                      _campoClassesEvento(),
                      const SizedBox(height: 18),
                      _campoAssinaturas(),
                      const SizedBox(height: 18),
                      _painelSecao(
                        children: [
                          Text(
                            'Arquivo base (.docx) — opcional',
                            style: Tipografia.labelLarge.copyWith(
                              color: Cores.textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Se enviado, o conteúdo do .docx é carregado no '
                            'editor como ponto de partida. Você também pode '
                            'criar o template do zero e montá-lo no editor.',
                            style: Tipografia.bodySmall.copyWith(
                              color: Cores.cinzaMedio,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _nomeArquivo ?? 'Nenhum arquivo selecionado.',
                            style: Tipografia.bodyMedium.copyWith(
                              color: Cores.cinzaEscuro,
                            ),
                          ),
                          const SizedBox(height: 14),
                          BotaoPrimario(
                            texto: widget.edicao
                                ? 'Substituir Arquivo'
                                : 'Selecionar Arquivo',
                            icone: widget.edicao
                                ? LucideIcons.refresh_cw
                                : LucideIcons.upload,
                            onPressed: _selecionarArquivo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      BarraAcoesFormulario(
                        textoPrimario: _viewModel.carregando
                            ? 'Salvando...'
                            : widget.edicao
                            ? 'Salvar Template'
                            : 'Criar Template',
                        onSalvar: _viewModel.carregando ? null : _salvar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Text(
        widget.edicao ? 'Editar template' : 'Cadastrar template',
        style: Tipografia.headlineMedium.copyWith(color: Cores.textoPrincipal),
      ),
    );
  }

  /// Nível do template + a instância dona. Em nível cliente ou programa, o
  /// template vale para todos os projetos descendentes — é o que as seções de
  /// classes e assinaturas abaixo refletem.
  Widget _campoEscopo() {
    return _painelSecao(
      children: [
        Text(
          'Nível do template',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 4),
        Text(
          'Define a quem o template pertence e quais variáveis ele enxerga: um '
          'template de cliente pode usar variáveis do cliente e de tudo abaixo '
          'dele; um de projeto, só as do próprio projeto e seus eventos.',
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NivelEscopo.values.map((nivel) {
            return ChoiceChip(
              label: Text(nivel.rotulo),
              selected: _viewModel.nivel == nivel,
              onSelected: (_) => _viewModel.selecionarEscopo(nivel, null),
              selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        CampoSelecao(
          label: _viewModel.nivel.rotulo,
          valor: _viewModel.escopoId,
          itens: _viewModel.opcoesEscopo
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.nome)),
              )
              .toList(),
          onChanged: (value) =>
              _viewModel.selecionarEscopo(_viewModel.nivel, value),
        ),
      ],
    );
  }

  /// Mensagem de "escolha o escopo primeiro", adaptada ao nível selecionado.
  Widget _avisoSemEscopo(String complemento) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Selecione ${_viewModel.nivel.rotulo.toLowerCase()} acima para ver $complemento.',
        style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
      ),
    );
  }

  Widget _campoClassesEvento() {
    // Em nível cliente/programa as classes vêm de vários projetos; agrupá-las
    // por projeto é o que torna a lista legível quando ela cresce.
    final porProjeto = <int?, List<ClasseEvento>>{};
    for (final classe in _viewModel.classesDisponiveis) {
      porProjeto.putIfAbsent(classe.projetoId, () => []).add(classe);
    }
    final agrupar = _viewModel.nivel != NivelEscopo.projeto;

    return _painelSecao(
      children: [
        Text(
          'Classes de Evento',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 4),
        Text(
          'Indique a quais classes de evento este template se relaciona.',
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
        const SizedBox(height: 8),
        if (_viewModel.escopoId == null)
          _avisoSemEscopo('as classes disponíveis')
        else if (_viewModel.classesDisponiveis.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma classe de evento cadastrada nos projetos deste escopo.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            ),
          )
        else
          for (final entrada in porProjeto.entries) ...[
            if (agrupar) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  _viewModel.nomeProjeto(entrada.key),
                  style: Tipografia.labelMedium.copyWith(
                    color: Cores.cinzaEscuro,
                  ),
                ),
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entrada.value.map((classe) {
                final id = classe.id;
                return FilterChip(
                  label: Text(classe.nomeClasse),
                  selected: _viewModel.classesSelecionadas.contains(id),
                  onSelected: id == null
                      ? null
                      : (_) => _viewModel.alternarClasse(id),
                  selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                  checkmarkColor: Cores.azulAcao,
                );
              }).toList(),
            ),
          ],
      ],
    );
  }

  Widget _campoAssinaturas() {
    return _painelSecao(
      children: [
        Text(
          'Assinaturas do documento',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecione quem deve assinar os relatórios gerados a partir deste template.',
          style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        ),
        const SizedBox(height: 8),
        if (_viewModel.escopoId == null)
          _avisoSemEscopo('os possíveis signatários')
        else ...[
          _grupoSignatarios(
            titulo: 'Equipes fixas de programa',
            vazio: 'Nenhum membro cadastrado nas equipes fixas deste escopo.',
            // Em nível cliente há vários programas; o nome do programa/projeto
            // desambigua homônimos entre equipes diferentes.
            itens: [
              for (final membro in _viewModel.membrosPrograma)
                if (membro.id != null)
                  (
                    id: membro.id!,
                    rotulo: '${membro.nome} (${membro.cargo})',
                    origem: _viewModel.nomePrograma(membro.programaId),
                    marcado: _viewModel.equipeProgramaSelecionada.contains(
                      membro.id,
                    ),
                    aoAlternar: () =>
                        _viewModel.alternarSignatarioPrograma(membro.id!),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          _grupoSignatarios(
            titulo: 'Equipes de projeto',
            vazio: 'Nenhum membro cadastrado nas equipes de projeto deste escopo.',
            itens: [
              for (final membro in _viewModel.membrosProjeto)
                if (membro.id != null)
                  (
                    id: membro.id!,
                    rotulo: '${membro.nome} (${membro.cargo})',
                    origem: _viewModel.nomeProjeto(membro.projetoId),
                    marcado: _viewModel.equipeProjetoSelecionada.contains(
                      membro.id,
                    ),
                    aoAlternar: () =>
                        _viewModel.alternarSignatarioProjeto(membro.id!),
                  ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _grupoSignatarios({
    required String titulo,
    required String vazio,
    required List<
      ({
        int id,
        String rotulo,
        String origem,
        bool marcado,
        VoidCallback aoAlternar,
      })
    >
    itens,
  }) {
    final mostrarOrigem = _viewModel.nivel != NivelEscopo.projeto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro),
        ),
        const SizedBox(height: 8),
        if (itens.isEmpty)
          Text(
            vazio,
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: itens.map((item) {
              return FilterChip(
                label: Text(
                  mostrarOrigem
                      ? '${item.rotulo} — ${item.origem}'
                      : item.rotulo,
                ),
                selected: item.marcado,
                onSelected: (_) => item.aoAlternar(),
                selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                checkmarkColor: Cores.azulAcao,
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Painel com fundo destacado usado pelas seções do formulário — mesmo
  /// tratamento usado pelo painel "Arquivo base", [_campoClassesEvento] e
  /// [_campoAssinaturas].
  Widget _painelSecao({required List<Widget> children}) {
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

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

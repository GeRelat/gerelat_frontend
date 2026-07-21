import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/template_form_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/servicos/arquivo_web.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioTemplate extends StatefulWidget {
  final bool edicao;
  final int? templateId;

  const PaginaFormularioTemplate({super.key, this.edicao = false, this.templateId});

  @override
  State<PaginaFormularioTemplate> createState() => _PaginaFormularioTemplateState();
}

class _PaginaFormularioTemplateState extends State<PaginaFormularioTemplate> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  late final TemplateFormViewModel _viewModel;
  int? _projetoId;
  String? _nomeArquivo;
  Uint8List? _arquivoBytes;

  @override
  void initState() {
    super.initState();
    _viewModel = TemplateFormViewModel(DependenciasApp.instancia.repositorioCatalogo);
    final templateId = widget.templateId;
    if (widget.edicao && templateId != null) {
      _viewModel.carregarEdicao(templateId).then((_) {
        final template = _viewModel.template;
        if (!mounted || template == null) return;
        _nome.text = template.nome;
        _projetoId = template.projetoId;
        _nomeArquivo = template.arquivoBase;
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
      final arquivo = await selecionarArquivo(accept: '.docx', extensoesPermitidas: const ['.docx'], tamanhoMaximoBytes: 10 * 1024 * 1024);
      if (arquivo == null) return;
      setState(() {
        _nomeArquivo = arquivo.nome;
        _arquivoBytes = arquivo.bytes;
      });
    } on ArquivoInvalidoException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_projetoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um projeto.')));
      return;
    }

    final idTemplate = await _viewModel.salvar(templateId: widget.templateId, projetoId: _projetoId!, nomeTemplate: _nome.text.trim(), arquivoBytes: _arquivoBytes, nomeArquivo: _nomeArquivo);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar template.')));
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.edicao ? 'Editar template' : 'Cadastrar template', style: Tipografia.headlineMedium.copyWith(color: Cores.textoPrincipal)),
                const SizedBox(height: 24),
                CartaoConteudo(
                  child: Column(
                    children: [
                      CampoSelecao(
                        label: 'Projeto',
                        valor: _projetoId,
                        itens: _viewModel.projetos.map((item) => DropdownMenuItem(value: item.id, child: Text(item.nome))).toList(),
                        onChanged: (value) {
                          setState(() => _projetoId = value);
                          _viewModel.carregarClasses(value);
                        },
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(label: 'Nome do Template', hint: 'Ex: Relatório padrão de visita técnica', icone: LucideIcons.file_text, controller: _nome, validator: _obrigatorio),
                      const SizedBox(height: 18),
                      _campoClassesEvento(),
                      const SizedBox(height: 18),
                      _campoAssinaturas(),
                      const SizedBox(height: 18),
                      Container(
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
                            Text('Arquivo base (.docx) — opcional', style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal)),
                            const SizedBox(height: 4),
                            Text(
                              'Se enviado, o conteúdo do .docx é carregado no '
                              'editor como ponto de partida. Você também pode '
                              'criar o template do zero e montá-lo no editor.',
                              style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
                            ),
                            const SizedBox(height: 8),
                            Text(_nomeArquivo ?? 'Nenhum arquivo selecionado.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),
                            const SizedBox(height: 14),
                            BotaoPrimario(texto: widget.edicao ? 'Substituir Arquivo' : 'Selecionar Arquivo', icone: widget.edicao ? LucideIcons.refresh_cw : LucideIcons.upload, onPressed: _selecionarArquivo),
                          ],
                        ),
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
    );
  }

  Widget _campoClassesEvento() {
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
          Text('Classes de Evento', style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal)),
          const SizedBox(height: 4),
          Text('Indique a quais classes de evento este template se relaciona.', style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio)),
          const SizedBox(height: 8),
          if (_projetoId == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Selecione um projeto para ver as classes disponíveis.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio)),
            )
          else if (_viewModel.classesDisponiveis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhuma classe cadastrada para este projeto.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _viewModel.classesDisponiveis.map((classe) {
                final marcada = _viewModel.classesSelecionadas.contains(classe.id);
                return FilterChip(label: Text(classe.nome), selected: marcada, onSelected: (_) => _viewModel.alternarClasse(classe.id), selectedColor: Cores.azulAcao.withValues(alpha: 0.16), checkmarkColor: Cores.azulAcao);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _campoAssinaturas() {
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
          Text('Assinaturas do documento', style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal)),
          const SizedBox(height: 4),
          Text('Selecione quem deve assinar os relatórios gerados a partir deste template.', style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio)),
          const SizedBox(height: 8),
          if (_projetoId == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Selecione um projeto para ver os possíveis signatários.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio)),
            )
          else ...[
            Text('Equipe fixa do programa', style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro)),
            const SizedBox(height: 8),
            if (_viewModel.membrosPrograma.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Nenhum membro cadastrado na equipe fixa do programa.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _viewModel.membrosPrograma.map((membro) {
                    final marcado = _viewModel.equipeProgramaSelecionada.contains(membro.id);
                    return FilterChip(
                      label: Text('${membro.nome} (${membro.cargo})'),
                      selected: marcado,
                      onSelected: (_) => _viewModel.alternarSignatarioPrograma(membro.id!),
                      selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                      checkmarkColor: Cores.azulAcao,
                    );
                  }).toList(),
                ),
              ),
            Text('Equipe do projeto', style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro)),
            const SizedBox(height: 8),
            if (_viewModel.membrosProjeto.isEmpty)
              Text('Nenhum membro cadastrado na equipe deste projeto.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _viewModel.membrosProjeto.map((membro) {
                  final marcado = _viewModel.equipeProjetoSelecionada.contains(membro.id);
                  return FilterChip(
                    label: Text('${membro.nome} (${membro.cargo})'),
                    selected: marcado,
                    onSelected: (_) => _viewModel.alternarSignatarioProjeto(membro.id!),
                    selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
                    checkmarkColor: Cores.azulAcao,
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/editor_template_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/projeto_campo.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

/// Editor de conteúdo do template: painel lateral com as variáveis do projeto
/// (inseríveis como nós) + blocos manuais, e o editor ProseMirror embarcado.
class PaginaEditorTemplate extends StatefulWidget {
  final int templateId;

  const PaginaEditorTemplate({super.key, required this.templateId});

  @override
  State<PaginaEditorTemplate> createState() => _PaginaEditorTemplateState();
}

class _PaginaEditorTemplateState extends State<PaginaEditorTemplate> {
  late final EditorTemplateViewModel _viewModel;
  final EditorProseMirrorController _controller = EditorProseMirrorController();
  bool _salvouAlgumaVez = false;

  @override
  void initState() {
    super.initState();
    _viewModel = EditorTemplateViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )..carregar(widget.templateId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _colunasDoCampo(ProjetoCampo campo) {
    final colunas = campo.valor['columns'];
    if (colunas is List) {
      return colunas
          .whereType<Map>()
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
    }
    return const [];
  }

  void _inserirCampo(ProjetoCampo campo) {
    switch (campo.tipo) {
      case TipoCampoProjeto.texto:
        _controller.inserirVarTexto(campo.referencia);
      case TipoCampoProjeto.textoRico:
        _controller.inserirVarRichtext(campo.referencia);
      case TipoCampoProjeto.imagem:
        _controller.inserirVarImagem(campo.referencia);
      case TipoCampoProjeto.tabela:
        _controller.inserirVarTabela(
          campo.referencia,
          colunas: _colunasDoCampo(campo),
        );
    }
  }

  Future<void> _inserirBlocoManual() async {
    final label = await _pedirTexto(
      titulo: 'Novo bloco manual',
      hint: 'Ex: Observações da equipe',
    );
    if (label == null) return;
    _controller.inserirBloco(label.trim().isEmpty ? 'bloco' : label.trim());
  }

  Future<String?> _pedirTexto({
    required String titulo,
    required String hint,
  }) async {
    final controlador = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      // Usa `Navigator.of(dialogContext).pop` (não `context.pop` do go_router):
      // dentro de um `showDialog`, `context.pop` fecharia a rota da página do
      // editor inteira em vez do diálogo, desmontando este widget e disparando
      // "_dependents.isEmpty is not true".
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controlador,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controlador.text),
            child: const Text('Inserir'),
          ),
        ],
      ),
    );
    controlador.dispose();
    return resultado;
  }

  Future<void> _salvar() async {
    final documento = await _controller.obterDocumento();
    if (!mounted) return;
    if (documento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O editor ainda está carregando.')),
      );
      return;
    }
    final ok = await _viewModel.salvar(widget.templateId, documento);
    if (!mounted) return;
    if (ok) {
      _salvouAlgumaVez = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template salvo.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar o template.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final template = _viewModel.template;
        return Scaffold(
          backgroundColor: Cores.fundoSecao,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.arrow_left),
              tooltip: 'Voltar',
              onPressed: () => context.pop(_salvouAlgumaVez),
            ),
            title: Text(
              template == null
                  ? 'Editor de template'
                  : 'Editor — ${template.nome}',
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _viewModel.salvando ? null : _salvar,
                  icon: const Icon(LucideIcons.save, size: 18),
                  label: Text(_viewModel.salvando ? 'Salvando...' : 'Salvar'),
                ),
              ),
            ],
          ),
          body: _corpo(),
        );
      },
    );
  }

  Widget _corpo() {
    if (_viewModel.carregando && _viewModel.documentoInicial == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.mensagemErro != null && _viewModel.documentoInicial == null) {
      return Center(
        child: Text(
          _viewModel.mensagemErro!,
          style: Tipografia.bodyMedium.copyWith(color: Cores.vermelhoErro),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 300, child: _painelLateral()),
        const VerticalDivider(width: 1, color: Cores.bordaSutil),
        Expanded(
          child: Container(
            color: Cores.branco,
            child: EditorProseMirror(
              controller: _controller,
              documentoInicial: _viewModel.documentoInicial,
              modo: 'template',
            ),
          ),
        ),
      ],
    );
  }

  Widget _painelLateral() {
    return Container(
      color: Cores.branco,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tituloSecao('Formatação'),
          const SizedBox(height: 8),
          _barraFormatacao(),
          const SizedBox(height: 20),
          _tituloSecao('Variáveis do projeto'),
          const SizedBox(height: 4),
          Text(
            'Insira uma variável para que ela seja preenchida automaticamente '
            'com os dados do banco na geração do relatório.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
          const SizedBox(height: 10),
          if (_viewModel.campos.isEmpty)
            Text(
              'Nenhuma variável cadastrada para este projeto.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            )
          else
            ..._viewModel.campos.map(_itemCampo),
          const SizedBox(height: 20),
          _tituloSecao('Blocos manuais'),
          const SizedBox(height: 4),
          Text(
            'Um bloco de texto livre, sem variável de banco, para ser '
            'preenchido/editado manualmente na geração do relatório.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _inserirBlocoManual,
            icon: const Icon(LucideIcons.square_pen, size: 18),
            label: const Text('Inserir bloco manual'),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Text(
      texto.toUpperCase(),
      style: Tipografia.labelLarge.copyWith(
        color: Cores.cinzaEscuro,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _barraFormatacao() {
    Widget botao(String rotulo, VoidCallback onTap, {String? tooltip}) {
      return Tooltip(
        message: tooltip ?? rotulo,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
          child: Text(rotulo),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        botao('B', _controller.negrito, tooltip: 'Negrito'),
        botao('I', _controller.italico, tooltip: 'Itálico'),
        botao('U', _controller.sublinhado, tooltip: 'Sublinhado'),
        botao('H1', () => _controller.titulo(1)),
        botao('H2', () => _controller.titulo(2)),
        botao('H3', () => _controller.titulo(3)),
        botao('¶', _controller.paragrafo, tooltip: 'Parágrafo'),
        botao('↩', _controller.desfazer, tooltip: 'Desfazer'),
        botao('↪', _controller.refazer, tooltip: 'Refazer'),
      ],
    );
  }

  Widget _itemCampo(ProjetoCampo campo) {
    final (icone, cor) = switch (campo.tipo) {
      TipoCampoProjeto.texto => (LucideIcons.type, Cores.azulAcao),
      TipoCampoProjeto.textoRico => (LucideIcons.text_quote, Cores.verdeSucesso),
      TipoCampoProjeto.imagem => (LucideIcons.image, Cores.azulAcao),
      TipoCampoProjeto.tabela => (LucideIcons.table, Cores.verdeSucesso),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _inserirCampo(campo),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Cores.fundoSecao,
            border: Border.all(color: Cores.bordaSutil),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icone, size: 18, color: cor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campo.referencia,
                      style: Tipografia.labelLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                    Text(
                      campo.tipo.rotulo,
                      style: Tipografia.bodySmall.copyWith(
                        color: Cores.cinzaMedio,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.plus, size: 16, color: Cores.cinzaMedio),
            ],
          ),
        ),
      ),
    );
  }
}

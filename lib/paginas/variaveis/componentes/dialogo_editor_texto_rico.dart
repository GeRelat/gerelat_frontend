import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/nucleo/componentes/editor_prosemirror.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_variaveis.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';

/// Abre o editor de texto rico em tela cheia e devolve o documento ProseMirror
/// editado, ou `null` se o usuário cancelou.
///
/// O valor de uma variável de texto rico é um mini-template: além de
/// formatação, pode conter outras variáveis (`var_text`, `var_image`,
/// `var_table`, `sistema.*`) que o backend resolve na geração do relatório.
/// Não oferece variáveis de texto rico (aninhamento é proibido) nem blocos
/// manuais (só existem em templates).
Future<Map<String, dynamic>?> mostrarDialogoEditorTextoRico(
  BuildContext context, {
  required String referencia,
  required Map<String, dynamic> documentoInicial,
  required List<VariavelDisponivel> variaveis,
  String tema = 'light',
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoEditorTextoRico(
      referencia: referencia,
      documentoInicial: documentoInicial,
      variaveis: variaveis,
      tema: tema,
    ),
  );
}

class _DialogoEditorTextoRico extends StatefulWidget {
  const _DialogoEditorTextoRico({
    required this.referencia,
    required this.documentoInicial,
    required this.variaveis,
    required this.tema,
  });

  final String referencia;
  final Map<String, dynamic> documentoInicial;
  final List<VariavelDisponivel> variaveis;
  final String tema;

  @override
  State<_DialogoEditorTextoRico> createState() =>
      _DialogoEditorTextoRicoState();
}

class _DialogoEditorTextoRicoState extends State<_DialogoEditorTextoRico> {
  final EditorProseMirrorController _controller = EditorProseMirrorController();

  // O editor roda num `<iframe>`. Sair da rota/diálogo com ele ainda montado
  // faz o Flutter tentar compor a transição com o platform view vivo e quebrar
  // com "Cannot get renderObject of inactive element". Desmontamos antes de
  // fechar (ver `pagina_editor_template.dart:_voltar`).
  bool _saindo = false;
  bool _salvando = false;

  void _inserirVariavel(VariavelDisponivel variavel) {
    switch (variavel.tipo) {
      case TipoCampo.texto:
        _controller.inserirVarTexto(variavel.referencia);
      case TipoCampo.imagem:
        _controller.inserirVarImagem(variavel.referencia);
      case TipoCampo.tabela:
        _controller.inserirVarTabela(variavel.referencia, colunas: const []);
      case TipoCampo.textoRico:
        // Filtrado no painel; aninhamento de texto rico é proibido.
        break;
    }
  }

  Future<void> _fechar([Map<String, dynamic>? resultado]) async {
    setState(() => _saindo = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.of(context).pop(resultado);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final doc = await _controller.obterDocumento();
    if (!mounted) return;

    final content = doc['content'];
    // `obterDocumento` devolve `{}` no timeout de 5s — indistinguível de doc
    // vazio. Nos dois casos, avisa e não fecha, em vez de gravar um valor vazio.
    if (doc.isEmpty || content is! List || content.isEmpty) {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O editor ainda está carregando ou o texto está vazio.',
          ),
        ),
      );
      return;
    }

    await _fechar(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Cores.fundoSecao,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: 'Cancelar',
            onPressed: _salvando ? null : () => _fechar(),
          ),
          title: Text('Texto rico — ${widget.referencia}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: const Icon(LucideIcons.save, size: 18),
                label: Text(_salvando ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
        body: _saindo
            ? const SizedBox.shrink()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: PainelVariaveis(
                      variaveis: widget.variaveis,
                      aoInserir: _inserirVariavel,
                      tiposPermitidos: const {
                        TipoCampo.texto,
                        TipoCampo.imagem,
                        TipoCampo.tabela,
                      },
                      barraFormatacao: _barraFormatacao(),
                      textoIntroducao:
                          'Insira uma variável para que ela apareça já '
                          'preenchida onde este texto for usado. Uma variável '
                          'de nível mais profundo (evento, por exemplo) fará o '
                          'template que usar este texto exigir esse nível.',
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Cores.bordaSutil),
                  Expanded(
                    child: Container(
                      color: Cores.branco,
                      child: EditorProseMirror(
                        controller: _controller,
                        documentoInicial: widget.documentoInicial,
                        modo: 'template',
                        temaInicial: widget.tema,
                      ),
                    ),
                  ),
                ],
              ),
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
}

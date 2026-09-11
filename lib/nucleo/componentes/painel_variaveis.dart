import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/dominio/entidades/campo_tipo.dart';
import 'package:gerelat_frontend/dominio/entidades/variavel_disponivel.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Painel lateral do editor ProseMirror: barra de formatação (opcional),
/// variáveis inseríveis agrupadas por origem e, opcionalmente, o botão de
/// bloco manual.
///
/// Usado pelo editor de template (`PaginaEditorTemplate`) e pelo diálogo de
/// edição do valor de uma variável de texto rico (`DialogoEditorTextoRico`).
class PainelVariaveis extends StatelessWidget {
  const PainelVariaveis({
    super.key,
    required this.variaveis,
    required this.aoInserir,
    this.tiposPermitidos,
    this.barraFormatacao,
    this.aoInserirBlocoManual,
    this.aoInserirBlocoInline,
    this.modoPrevisualizacao = false,
    this.carregandoPrevisualizacao = false,
    this.aoAlternarPrevisualizacao,
    this.textoIntroducao,
  });

  final List<VariavelDisponivel> variaveis;
  final void Function(VariavelDisponivel) aoInserir;

  /// Quando informado, só variáveis desses tipos aparecem (ex.: o diálogo de
  /// texto rico esconde `textoRico` para evitar aninhamento).
  final Set<TipoCampo>? tiposPermitidos;

  /// Barra de formatação (B/I/U/H1...). O chamador a constrói com seu próprio
  /// `EditorProseMirrorController`.
  final Widget? barraFormatacao;

  /// `null` esconde a ação de bloco manual de parágrafo.
  final VoidCallback? aoInserirBlocoManual;

  /// `null` esconde a ação de bloco manual em linha.
  final VoidCallback? aoInserirBlocoInline;

  /// Indica se a visualização com variáveis resolvidas está ativa.
  final bool modoPrevisualizacao;

  /// Indica se a resolução de pré-visualização está em andamento.
  final bool carregandoPrevisualizacao;

  /// Callback para alternar entre modo de autoria (chips) e pré-visualização resolvida.
  final VoidCallback? aoAlternarPrevisualizacao;

  final String? textoIntroducao;

  List<VariavelDisponivel> get _visiveis {
    final tipos = tiposPermitidos;
    if (tipos == null) return variaveis;
    return variaveis.where((v) => tipos.contains(v.tipo)).toList();
  }

  List<VariavelDisponivel> get _customizadas =>
      _visiveis.where((v) => v.origem == OrigemVariavel.customizado).toList();

  List<VariavelDisponivel> get _sistema =>
      _visiveis.where((v) => v.origem == OrigemVariavel.sistema).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cores.branco,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (barraFormatacao != null) ...[
            _tituloSecao('Formatação'),
            const SizedBox(height: 8),
            barraFormatacao!,
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(child: _tituloSecao('Variáveis disponíveis')),
              if (aoAlternarPrevisualizacao != null)
                Tooltip(
                  message: modoPrevisualizacao
                      ? 'Voltar para o modo de edição'
                      : 'Pré-visualizar variáveis resolvidas no texto',
                  child: InkWell(
                    onTap: carregandoPrevisualizacao
                        ? null
                        : aoAlternarPrevisualizacao,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: modoPrevisualizacao
                            ? Cores.azulAcao.withValues(alpha: 0.12)
                            : Cores.fundoSecao,
                        border: Border.all(
                          color: modoPrevisualizacao
                              ? Cores.azulAcao
                              : Cores.bordaSutil,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (carregandoPrevisualizacao)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Cores.azulAcao,
                              ),
                            )
                          else
                            Icon(
                              modoPrevisualizacao
                                  ? LucideIcons.eye_off
                                  : LucideIcons.eye,
                              size: 15,
                              color: modoPrevisualizacao
                                  ? Cores.azulAcao
                                  : Cores.cinzaEscuro,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            modoPrevisualizacao ? 'Editar' : 'Pré-visualizar',
                            style: Tipografia.labelSmall.copyWith(
                              color: modoPrevisualizacao
                                  ? Cores.azulAcao
                                  : Cores.cinzaEscuro,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            textoIntroducao ??
                'Insira uma variável para que ela seja preenchida automaticamente '
                    'com os dados do banco na geração do relatório. A etiqueta indica '
                    'de qual nível vem o valor — usar uma variável de evento, por '
                    'exemplo, obrigará a escolher um evento ao gerar o relatório.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
          const SizedBox(height: 12),
          if (_visiveis.isEmpty)
            Text(
              'Nenhuma variável disponível para este escopo.',
              style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            )
          else ...[
            ..._grupo(
              'Customizadas',
              _customizadas,
              vazio: 'Nenhuma variável cadastrada para este escopo.',
            ),
            ..._grupo('Campos do sistema', _sistema, vazio: ''),
          ],
          if (aoInserirBlocoManual != null || aoInserirBlocoInline != null) ...[
            const SizedBox(height: 20),
            _tituloSecao('Blocos manuais'),
            const SizedBox(height: 4),
            Text(
              'Trechos de texto livre, sem variável de banco, para serem '
              'preenchidos/editados manualmente na geração do relatório.',
              style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
            ),
            const SizedBox(height: 10),
            if (aoInserirBlocoInline != null) ...[
              OutlinedButton.icon(
                onPressed: aoInserirBlocoInline,
                icon: const Icon(LucideIcons.text_cursor_input, size: 18),
                label: const Text('Inserir bloco em linha'),
              ),
              const SizedBox(height: 8),
            ],
            if (aoInserirBlocoManual != null)
              OutlinedButton.icon(
                onPressed: aoInserirBlocoManual,
                icon: const Icon(LucideIcons.square_pen, size: 18),
                label: const Text('Inserir bloco (parágrafo)'),
              ),
          ],
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

  List<Widget> _grupo(
    String titulo,
    List<VariavelDisponivel> variaveis, {
    required String vazio,
  }) {
    if (variaveis.isEmpty && vazio.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Text(
          titulo,
          style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro),
        ),
      ),
      if (variaveis.isEmpty)
        Text(vazio, style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio))
      else
        ...variaveis.map(_item),
    ];
  }

  Widget _item(VariavelDisponivel variavel) {
    final (icone, cor) = switch (variavel.tipo) {
      TipoCampo.texto => (LucideIcons.type, Cores.azulAcao),
      TipoCampo.textoRico => (LucideIcons.text_quote, Cores.verdeSucesso),
      TipoCampo.imagem => (LucideIcons.image, Cores.azulAcao),
      TipoCampo.tabela => (LucideIcons.table, Cores.verdeSucesso),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => aoInserir(variavel),
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
                      variavel.referencia,
                      style: Tipografia.labelLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                    Text(
                      '${variavel.tipo.rotulo} · ${variavel.nivelAplicacao.rotulo}'
                      '${variavel.escopoNome != null && variavel.escopoNome!.isNotEmpty ? ' (${variavel.escopoNome})' : ''}',
                      style: Tipografia.bodySmall.copyWith(
                        color: Cores.cinzaMedio,
                      ),
                    ),
                    if (variavel.descricao.isNotEmpty &&
                        variavel.descricao != variavel.referencia)
                      Text(
                        variavel.descricao,
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

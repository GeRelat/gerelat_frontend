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

  /// `null` esconde a seção "Blocos manuais" (não faz sentido no valor de uma
  /// variável).
  final VoidCallback? aoInserirBlocoManual;

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
          _tituloSecao('Variáveis disponíveis'),
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
          if (aoInserirBlocoManual != null) ...[
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
              onPressed: aoInserirBlocoManual,
              icon: const Icon(LucideIcons.square_pen, size: 18),
              label: const Text('Inserir bloco manual'),
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

import 'package:flutter/material.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_programa.dart';
import 'package:gerelat_frontend/dominio/entidades/membro_equipe_projeto.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Seleção de signatários (membros das equipes fixas de programa e das equipes
/// de projeto do escopo) como grupos de `FilterChip`.
///
/// Usado pelo formulário de template (`PaginaFormularioTemplate`) e pela tela de
/// gerar relatório (`PaginaGerarRelatorio`).
class SeletorSignatarios extends StatelessWidget {
  const SeletorSignatarios({
    super.key,
    required this.membrosPrograma,
    required this.membrosProjeto,
    required this.programaSelecionada,
    required this.projetoSelecionada,
    required this.aoAlternarPrograma,
    required this.aoAlternarProjeto,
    required this.nomePrograma,
    required this.nomeProjeto,
    this.mostrarOrigem = true,
  });

  final List<MembroEquipePrograma> membrosPrograma;
  final List<MembroEquipeProjeto> membrosProjeto;
  final Set<int> programaSelecionada;
  final Set<int> projetoSelecionada;
  final ValueChanged<int> aoAlternarPrograma;
  final ValueChanged<int> aoAlternarProjeto;
  final String Function(int?) nomePrograma;
  final String Function(int?) nomeProjeto;

  /// Mostra de qual programa/projeto o membro vem — útil quando o escopo
  /// abrange vários (template de nível cliente/programa). No nível projeto o
  /// signatário é único, então some.
  final bool mostrarOrigem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grupo(
          titulo: 'Equipes fixas de programa',
          vazio: 'Nenhum membro cadastrado nas equipes fixas deste escopo.',
          itens: [
            for (final membro in membrosPrograma)
              if (membro.id != null)
                (
                  rotulo: '${membro.nome} (${membro.cargo})',
                  origem: nomePrograma(membro.programaId),
                  marcado: programaSelecionada.contains(membro.id),
                  aoAlternar: () => aoAlternarPrograma(membro.id!),
                ),
          ],
        ),
        const SizedBox(height: 12),
        _grupo(
          titulo: 'Equipes de projeto',
          vazio: 'Nenhum membro cadastrado nas equipes de projeto deste escopo.',
          itens: [
            for (final membro in membrosProjeto)
              if (membro.id != null)
                (
                  rotulo: '${membro.nome} (${membro.cargo})',
                  origem: nomeProjeto(membro.projetoId),
                  marcado: projetoSelecionada.contains(membro.id),
                  aoAlternar: () => aoAlternarProjeto(membro.id!),
                ),
          ],
        ),
      ],
    );
  }

  Widget _grupo({
    required String titulo,
    required String vazio,
    required List<
      ({String rotulo, String origem, bool marcado, VoidCallback aoAlternar})
    >
    itens,
  }) {
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
                  mostrarOrigem && item.origem.isNotEmpty
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
}

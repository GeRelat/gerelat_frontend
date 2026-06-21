import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaFormularioTemplate extends StatelessWidget {
  final bool edicao;

  const PaginaFormularioTemplate({super.key, this.edicao = false});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      secaoAtual: SecaoApp.templates,
      titulo: edicao ? 'Editar Template' : 'Novo Template',
      dicaPesquisa: 'Pesquisar templates...',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editor de templates',
              style: Tipografia.headlineMedium.copyWith(
                color: Cores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 24),
            CartaoConteudo(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.file_cog,
                    size: 42,
                    color: Cores.azulAcao,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Criação disponível no editor de documentos',
                    style: Tipografia.titleLarge.copyWith(
                      color: Cores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Templates ProseMirror e arquivos DOCX devem ser criados no módulo prosemirror-doc-editor. Esta tela não simula mais um salvamento que a interface Flutter não executa.',
                    style: Tipografia.bodyMedium.copyWith(
                      color: Cores.cinzaEscuro,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.arrow_left),
                    label: const Text('Voltar para templates'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

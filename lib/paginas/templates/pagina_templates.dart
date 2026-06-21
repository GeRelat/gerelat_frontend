import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/templates_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/template_relatorio.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/paginas/templates/pagina_formulario_template.dart';

class PaginaTemplates extends StatefulWidget {
  const PaginaTemplates({super.key});

  @override
  State<PaginaTemplates> createState() => _PaginaTemplatesState();
}

class _PaginaTemplatesState extends State<PaginaTemplates> {
  late final TemplatesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TemplatesViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )
      ..carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      secaoAtual: SecaoApp.templates,
      titulo: 'Templates',
      dicaPesquisa: 'Pesquisar templates...',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalho(context),
                const SizedBox(height: 24),
                _conteudo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Templates prontos',
                style: Tipografia.headlineMedium.copyWith(
                  color: Cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie modelos DOCX usados para gerar relatorios automaticamente.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ],
          ),
        ),
        BotaoPrimario(
          texto: 'Novo Template',
          icone: LucideIcons.upload,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaginaFormularioTemplate()),
          ),
        ),
      ],
    );
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.mensagemErro != null) {
      return EstadoVazio(
        icone: LucideIcons.circle_alert,
        titulo: 'Nao foi possivel carregar os templates',
        descricao: _viewModel.mensagemErro!,
        acao: 'Tentar novamente',
        onAcao: _viewModel.carregar,
      );
    }

    return _gradeTemplates(_viewModel.templates);
  }

  Widget _gradeTemplates(List<TemplateRelatorio> templates) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth < 900 ? 1 : 2;
        const espaco = 24.0;
        final largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: templates
              .map(
                (template) =>
                    SizedBox(width: largura, child: _CartaoTemplate(template)),
              )
              .toList(),
        );
      },
    );
  }
}

class _CartaoTemplate extends StatelessWidget {
  final TemplateRelatorio template;

  const _CartaoTemplate(this.template);

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Cores.azulAcao.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.file_text, color: Cores.azulAcao),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  template.nome,
                  style: Tipografia.titleLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
              ),
              _tag(template.tipo),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            template.descricao,
            style: Tipografia.bodyMedium.copyWith(
              color: Cores.cinzaEscuro,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _status(template.status),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const PaginaFormularioTemplate(edicao: true),
                  ),
                ),
                icon: const Icon(LucideIcons.pencil, size: 16),
                label: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: Tipografia.labelMedium.copyWith(color: Cores.cinzaEscuro),
      ),
    );
  }

  Widget _status(String texto) {
    return Text(
      texto,
      style: Tipografia.labelLarge.copyWith(
        color: texto == 'Ativo' ? Cores.verdeSucesso : Cores.azulAcao,
      ),
    );
  }
}

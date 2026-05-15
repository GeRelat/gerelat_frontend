import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/utils/breakpoints.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/card_metrica.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/cartao_acao_primaria.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/cartao_acao_secundaria.dart';
import 'package:gerelat_frontend/paginas/dashboard/componentes/cartao_info.dart';
import 'package:gerelat_frontend/paginas/dashboard/layout_dashboard.dart';

class PaginaDashboard extends StatelessWidget {
  const PaginaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return LayoutDashboard(
      titulo: 'Dashboard',
      corpo: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirCardsMetrica(context),
              const SizedBox(height: 32),
              _construirSecaoAcoes(context),
              const SizedBox(height: 32),
              _construirSecaoInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCardsMetrica(BuildContext context) {
    final cards = [
      CardMetrica(
        titulo: 'PROGRAMAS',
        valor: '1',
        descricao: 'sistema centralizado',
        prefixoDescricao: 'Ativo',
        corPrefixo: Cores.verde,
        icone: Icons.folder_open_outlined,
      ),
      CardMetrica(
        titulo: 'TEMPLATES',
        valor: '1',
        descricao: 'Padrão corporativo disponível',
        icone: Icons.description_outlined,
      ),
      CardMetrica(
        titulo: 'RELATÓRIOS',
        valor: '0',
        descricao: 'Nenhum gerado este mês',
        icone: Icons.bar_chart_outlined,
        fundoIcone: Cores.cinzaNavFundo,
        corIcone: Cores.cinzaEscuro,
        opacidade: 0.8,
      ),
    ];

    if (Breakpoints.isMobile(context)) {
      return Column(
        children: cards
            .map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c))
            .toList(),
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _construirSecaoAcoes(BuildContext context) {
    final primaria = CartaoAcaoPrimaria(
      titulo: 'Criar Novo\nRelatório',
      descricao:
          'Automatize a geração de relatórios corporativos com templates inteligentes e dados sincronizados.',
      rotuloBotao: 'Criar Relatório',
      onPressed: () {},
    );

    final secundaria = CartaoAcaoSecundaria(
      titulo: 'Novo Programa',
      descricao: 'Configure um novo programa e centralize seus projetos e relatórios.',
      rotuloLink: 'Criar Programa',
      icone: Icons.folder_open_outlined,
      onPressed: () {},
    );

    if (Breakpoints.isDesktop(context)) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: primaria),
            const SizedBox(width: 32),
            Expanded(child: secundaria),
          ],
        ),
      );
    }

    return Column(
      children: [
        primaria,
        const SizedBox(height: 16),
        secundaria,
      ],
    );
  }

  Widget _construirSecaoInfo(BuildContext context) {
    final info1 = CartaoInfo(
      titulo: 'Última atualização',
      descricao:
          'Seu dashboard foi sincronizado há 5 minutos com a base de dados corporativa.',
      icone: Icons.sync_outlined,
    );

    return info1;
  }
}

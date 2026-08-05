import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

enum SecaoApp {
  dashboard,
  clientes,
  programas,
  variaveis,
  variaveisValores,
  eventos,
  relatorios,
  templates,
  assets,
  configuracoes,
}

class AppShell extends StatelessWidget {
  final SecaoApp secaoAtual;
  final String titulo;
  final Widget child;
  final SessaoViewModel sessao;

  const AppShell({
    super.key,
    required this.secaoAtual,
    required this.titulo,
    required this.child,
    required this.sessao,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Abaixo de 800 px, o sistema utiliza o layout móvel.
        final telaPequena = constraints.maxWidth < 800;

        if (telaPequena) {
          return _construirLayoutCelular();
        }

        return _construirLayoutDesktop();
      },
    );
  }

  /// Layout utilizado em celulares e tablets menores.
  ///
  /// O menu lateral deixa de ocupar espaço fixo e passa a ser um Drawer.
  Widget _construirLayoutCelular() {
    return Scaffold(
      backgroundColor: Cores.fundoCanvas,
      drawer: Drawer(
        width: 280,
        backgroundColor: Cores.fundoDestaqueSutil,
        child: SafeArea(
          child: _SideNav(
            secaoAtual: secaoAtual,
            sessao: sessao,
            fecharAoNavegar: true,
          ),
        ),
      ),
      body: Column(
        children: [
          _TopAppBar(titulo: titulo, exibirBotaoMenu: true),
          Expanded(
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }

  /// Layout utilizado em computadores e telas maiores.
  Widget _construirLayoutDesktop() {
    return Scaffold(
      backgroundColor: Cores.fundoCanvas,
      body: Row(
        children: [
          _SideNav(secaoAtual: secaoAtual, sessao: sessao),
          Expanded(
            child: Column(
              children: [
                _TopAppBar(titulo: titulo),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  final String titulo;
  final bool exibirBotaoMenu;

  const _TopAppBar({required this.titulo, this.exibirBotaoMenu = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: exibirBotaoMenu ? 12 : 32),
      decoration: BoxDecoration(
        color: Cores.branco.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: Cores.bordaSutil)),
      ),
      child: Row(
        children: [
          if (exibirBotaoMenu)
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'Abrir menu',
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(LucideIcons.menu, size: 22),
                  color: Cores.textoPrincipal,
                  style: IconButton.styleFrom(
                    backgroundColor: Cores.fundoSecao,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),

          if (exibirBotaoMenu) const SizedBox(width: 8),

          // Fundo transparente e estados de hover/focus/pressed padrão do
          // Material — igual aos demais IconButton do app (ex.: editar/
          // excluir nos cartões de lista), sem o `style` "quadrado" usado
          // pelo botão de menu acima.
          if (context.canPop())
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Voltar',
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(LucideIcons.arrow_left, size: 20),
                color: Cores.textoPrincipal,
              ),
            ),

          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: exibirBotaoMenu
                  ? Tipografia.titleLargeDestaque.copyWith(
                      color: Cores.textoPrincipal,
                    )
                  : Tipografia.headlineSmall.copyWith(
                      color: Cores.textoPrincipal,
                      fontWeight: FontWeight.w800,
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // No celular, alguns ícones são ocultados para evitar overflow.
          if (!exibirBotaoMenu) ...[
            const Icon(LucideIcons.bell, size: 20, color: Cores.cinzaEscuro),
            const SizedBox(width: 16),
            const Icon(Icons.help_outline, size: 20, color: Cores.cinzaEscuro),
            const SizedBox(width: 16),
          ],

          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Cores.cinzaCampo,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_brisa.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um item de navegação da sidebar: ícone, rótulo, [SecaoApp] que ele
/// representa (para destacar como ativo) e rota para onde navega.
///
/// Mantido como dado (não widget) para que os itens do menu principal
/// possam ser declarados numa lista só, em vez de repetir a construção de
/// `_NavItem` uma vez por item.
typedef _ItemMenu = ({
  IconData icone,
  String rotulo,
  SecaoApp secao,
  String rota,
});

const _itensMenuPrincipal = <_ItemMenu>[
  (
    icone: LucideIcons.house,
    rotulo: 'Dashboard',
    secao: SecaoApp.dashboard,
    rota: '/dashboard',
  ),
  (
    icone: LucideIcons.building_2,
    rotulo: 'Clientes',
    secao: SecaoApp.clientes,
    rota: '/clientes',
  ),
  (
    icone: LucideIcons.folder_kanban,
    rotulo: 'Programas',
    secao: SecaoApp.programas,
    rota: '/programas',
  ),
  // Variáveis têm duas telas por causa da separação entre schema
  // (`CampoDefinicao`) e valor (`CampoValor`) feita no backend.
  (
    icone: LucideIcons.variable,
    rotulo: 'Variáveis',
    secao: SecaoApp.variaveis,
    rota: '/variaveis/definicoes',
  ),
  (
    icone: LucideIcons.pencil_ruler,
    rotulo: 'Valores das variáveis',
    secao: SecaoApp.variaveisValores,
    rota: '/variaveis/valores',
  ),
  (
    icone: LucideIcons.calendar,
    rotulo: 'Eventos',
    secao: SecaoApp.eventos,
    rota: '/eventos',
  ),
  (
    icone: LucideIcons.file_text,
    rotulo: 'Relatórios',
    secao: SecaoApp.relatorios,
    rota: '/relatorios',
  ),
  (
    icone: LucideIcons.copy,
    rotulo: 'Templates',
    secao: SecaoApp.templates,
    rota: '/templates',
  ),
  (
    icone: LucideIcons.image,
    rotulo: 'Imagens',
    secao: SecaoApp.assets,
    rota: '/assets',
  ),
];

class _SideNav extends StatelessWidget {
  final SecaoApp secaoAtual;
  final SessaoViewModel sessao;

  /// Quando verdadeiro, fecha o Drawer antes de navegar.
  final bool fecharAoNavegar;

  const _SideNav({
    required this.secaoAtual,
    required this.sessao,
    this.fecharAoNavegar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: Cores.fundoDestaqueSutil,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Image(
                    image: AssetImage(
                      'assets/images/logo_gerelat_icone_azul.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'GeRelat',
                  style: Tipografia.titleLargeDestaque.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final item in _itensMenuPrincipal)
                  _NavItem(
                    icon: item.icone,
                    label: item.rotulo,
                    ativo: secaoAtual == item.secao,
                    onTap: () {
                      _navegar(context, item.rota);
                    },
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Cores.bordaSutil),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              children: [
                _NavItem(
                  icon: LucideIcons.settings,
                  label: 'Configurações',
                  ativo: secaoAtual == SecaoApp.configuracoes,
                  onTap: () {
                    _navegar(context, '/configuracoes');
                  },
                ),
                _NavItem(
                  icon: LucideIcons.log_out,
                  label: 'Sair',
                  ativo: false,
                  onTap: () {
                    _sair(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fecha o Drawer, quando necessário, e depois realiza a navegação.
  void _navegar(BuildContext context, String rota) {
    if (fecharAoNavegar) {
      Navigator.of(context).pop();
    }

    context.go(rota);
  }

  Future<void> _sair(BuildContext context) async {
    if (fecharAoNavegar) {
      Navigator.of(context).pop();
    }

    final saiu = await sessao.sair();

    if (!saiu || !context.mounted) {
      return;
    }

    context.go('/login');
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: ativo ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: ativo ? Cores.azulAcao : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.bodyMedium.copyWith(
                      color: ativo ? Cores.azulAcao : const Color(0xFF475569),
                      fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

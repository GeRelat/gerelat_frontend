import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color azul = Color(0xff0057D9);
  static const Color azulClaro = Color(0xff0A6CFF);
  static const Color azulEscuro = Color(0xff004A98);

  static const Color fundo = Color(0xffF5F7FA);
  static const Color borda = Color(0xffE5E7EB);
  static const Color texto = Color(0xff111827);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: Row(
        children: [
          _buildSidebar(),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Visão geral da sua gestão de relatórios",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Color(0xff1F2937)),
                        ),

                        const SizedBox(height: 36),

                        _buildStatusCards(),

                        const SizedBox(height: 40),

                        _buildActionCards(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SIDEBAR
  // =========================================================

  Widget _buildSidebar() {
    return Container(
      width: 223,

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(right: BorderSide(color: borda, width: 1)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            height: 72,

            alignment: Alignment.centerLeft,

            padding: const EdgeInsets.only(left: 22),

            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borda, width: 1)),
            ),

            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Ge",
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -1.0, color: Color(0xff003E91), height: 1),
                  ),

                  TextSpan(
                    text: "Relat",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w100, letterSpacing: -1.0, color: Color(0xff0054C7), height: 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          _sideItem(LucideIcons.house, "Dashboard", true),

          _sideItem(LucideIcons.folder_kanban, "Programas", false),

          _sideItem(LucideIcons.calendar, "Eventos", false),

          _sideItem(LucideIcons.file_text, "Relatórios", false),

          _sideItem(LucideIcons.copy, "Templates", false),

          const Spacer(),

          Container(height: 1, color: borda),

          const SizedBox(height: 14),

          _sideItem(LucideIcons.settings, "Configurações", false),

          _sideItem(LucideIcons.log_out, "Sair", false),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sideItem(IconData icon, String label, bool active) {
    return Container(
      height: 52,

      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: active ? const Color(0xffEEF5FF) : Colors.transparent,

        borderRadius: BorderRadius.circular(30),

        boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))] : [],
      ),

      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 16),

        child: Row(
          children: [
            Icon(icon, size: 23, color: active ? azul : texto),

            const SizedBox(width: 16),

            Text(
              label,

              style: TextStyle(fontSize: 18, height: 1, fontWeight: FontWeight.w500, color: active ? azul : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TOP BAR
  // =========================================================

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 780;

        return Container(
          height: 92,

          padding: const EdgeInsets.symmetric(horizontal: 40),

          decoration: const BoxDecoration(
            color: Colors.white,

            border: Border(bottom: BorderSide(color: borda, width: 1)),
          ),

          child: Row(
            children: [
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, minWidth: 220),

                  height: 54,

                  decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(10)),

                  padding: const EdgeInsets.symmetric(horizontal: 18),

                  child: const Row(
                    children: [
                      Icon(LucideIcons.search, size: 24, color: Color(0xff4B5563)),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          "Pesquisar programas...",

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(fontSize: 18, color: Color(0xff6B7280)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              if (!isNarrow) ...[
                const Icon(LucideIcons.bell, size: 28, color: Color(0xff374151)),

                const SizedBox(width: 24),

                const Icon(Icons.help_outline, size: 28, color: Color(0xff374151)),

                const SizedBox(width: 24),

                Container(width: 1, height: 38, color: borda),

                const SizedBox(width: 28),

                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.end,

                  children: [
                    Text(
                      "Admin User",

                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: texto),
                    ),

                    Text("Administrador", style: TextStyle(fontSize: 14, color: Color(0xff4B5563))),
                  ],
                ),

                const SizedBox(width: 14),
              ],

              Container(
                width: 54,
                height: 54,

                padding: const EdgeInsets.all(7),

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,

                  border: Border.all(color: const Color(0xffA7C8FF), width: 2),
                ),

                child: ClipOval(child: Image.asset("assets/images/logo_brisa.png", fit: BoxFit.contain)),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // STATUS CARDS
  // =========================================================

  Widget _buildStatusCards() {
    final items = [
      ("PROGRAMAS", "1", "Ativos no sistema", LucideIcons.folder_kanban, azul),

      ("TEMPLATES", "1", "Disponíveis", LucideIcons.copy, azul),

      ("RELATÓRIOS", "0", "Gerados este mês", LucideIcons.file_text, const Color(0xff10B981)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns = 3;

        if (width < 700) {
          columns = 1;
        } else if (width < 1050) {
          columns = 2;
        }

        const spacing = 30.0;

        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 24,

          children: items.map((item) {
            return SizedBox(width: cardWidth, child: _statusCard(item.$1, item.$2, item.$3, item.$4, item.$5));
          }).toList(),
        );
      },
    );
  }

  Widget _statusCard(String title, String number, String subtitle, IconData icon, Color iconColor) {
    return Container(
      height: 205,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: texto),
                ),
              ),

              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),

                child: Icon(icon, size: 21, color: iconColor),
              ),
            ],
          ),

          const SizedBox(height: 26),

          Text(
            number,

            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.black, height: 1),
          ),

          const SizedBox(height: 12),

          Text(
            subtitle,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontSize: 16, color: Color(0xff6B7280), height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 950;

        if (isSmall) {
          return Column(children: [_buildCriarRelatorioCard(), const SizedBox(height: 24), _buildNovoProgramaCard()]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Expanded(child: _buildCriarRelatorioCard()),

            const SizedBox(width: 30),

            Expanded(child: _buildNovoProgramaCard()),
          ],
        );
      },
    );
  }

  Widget _buildCriarRelatorioCard() {
    return Container(
      height: 260,

      padding: const EdgeInsets.fromLTRB(40, 36, 40, 32),

      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff0054C8), Color(0xff004A98)], begin: Alignment.topLeft, end: Alignment.bottomRight),

        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        children: [
          Expanded(child: _buildRelatorioTexto()),

          const SizedBox(width: 18),

          Container(
            width: 72,
            height: 72,

            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(24)),

            child: const Icon(LucideIcons.plus, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatorioTexto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Criar Novo Relatório",

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 14),

        const Text(
          "Gere relatórios completos a partir dos\n"
          "seus eventos cadastrados",

          style: TextStyle(fontSize: 20, color: Colors.white, height: 1.4),
        ),

        const Spacer(),

        Container(
          height: 52,

          padding: const EdgeInsets.symmetric(horizontal: 26),

          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),

          child: const Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                "Começar agora",

                style: TextStyle(color: azul, fontSize: 17, fontWeight: FontWeight.w800),
              ),

              SizedBox(width: 12),

              Icon(LucideIcons.arrow_right, color: azul, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNovoProgramaCard() {
    return Container(
      height: 260,

      padding: const EdgeInsets.fromLTRB(40, 36, 40, 32),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Novo Programa",

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(fontSize: 30, color: Colors.black, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Configure um novo programa\n"
                  "institucional no sistema",

                  style: TextStyle(fontSize: 20, color: texto, height: 1.4),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () {},

                  child: const Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Text(
                        "Cadastrar programa",

                        style: TextStyle(color: azul, fontSize: 17, fontWeight: FontWeight.w800),
                      ),

                      SizedBox(width: 12),

                      Icon(LucideIcons.arrow_right, color: azul, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Container(
            width: 72,
            height: 72,

            decoration: BoxDecoration(color: const Color(0xffEEF5FF), borderRadius: BorderRadius.circular(24)),

            child: const Icon(LucideIcons.plus, size: 40, color: azul),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class RelatoriosPage extends StatelessWidget {
  const RelatoriosPage({super.key});

  static const Color azul = Color(0xff0057D9);
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
                    padding: const EdgeInsets.fromLTRB(40, 30, 40, 36),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(), const SizedBox(height: 30), _buildEmptyCard(), const SizedBox(height: 40), _buildInfoCards()]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Relatórios",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.black, height: 1),
              ),
              SizedBox(height: 12),
              Text("Gerencie e gere relatórios institucionais automaticamente", style: TextStyle(fontSize: 17, color: Color(0xff1F2937))),
            ],
          ),
        ),
        _blueButton("Gerar Relatório", width: 196, height: 56),
      ],
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borda),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(color: const Color(0xffDFEBFF), borderRadius: BorderRadius.circular(13)),
            child: const Icon(LucideIcons.file_text, color: azul, size: 42),
          ),
          const SizedBox(height: 26),
          const Text(
            "Nenhum relatório gerado ainda",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 14),
          const Text(
            "Comece criando seu primeiro relatório a partir de um evento\n"
            "cadastrado e um template disponível",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xff1F2937)),
          ),
          const SizedBox(height: 28),
          _blueButton("Gerar Relatório", width: 192, height: 52),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 24.0;
        final isSmall = constraints.maxWidth < 900;
        final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 22,
          children: [
            SizedBox(
              width: cardWidth,
              child: _infoCard(
                icon: LucideIcons.file_text,
                iconColor: azul,
                iconBg: const Color(0xffDFEBFF),
                title: "Templates Prontos",
                description: "Utilize templates pré-configurados para acelerar a geração de relatórios institucionais",
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _infoCard(icon: LucideIcons.zap, iconColor: azul, iconBg: const Color(0xffDFEBFF), title: "Geração Rápida", description: "Crie relatórios completos em segundos com dados dos eventos cadastrados no sistema"),
            ),
            SizedBox(
              width: cardWidth,
              child: _infoCard(icon: LucideIcons.download, iconColor: const Color(0xff00A66A), iconBg: const Color(0xffDFF8EF), title: "Exportação", description: "Exporte seus relatórios em múltiplos formatos: PDF, DOCX e muito mais"),
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard({required IconData icon, required Color iconColor, required Color iconBg, required String title, required String description}) {
    return Container(
      height: 176,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borda),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 25, color: iconColor),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xff1F2937))),
        ],
      ),
    );
  }

  Widget _blueButton(String label, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: azul,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [BoxShadow(color: azul.withValues(alpha: 0.32), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.plus, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

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
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -1, color: Color(0xff003E91)),
                  ),
                  TextSpan(
                    text: "Relat",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w100, letterSpacing: -1, color: Color(0xff0054C7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sideItem(LucideIcons.house, "Dashboard", false),
          _sideItem(LucideIcons.folder_kanban, "Programas", false),
          _sideItem(LucideIcons.calendar, "Eventos", false),
          _sideItem(LucideIcons.file_text, "Relatórios", true),
          _sideItem(LucideIcons.copy, "Templates", false),
          const Spacer(),
          Container(height: 1, color: borda),
          const SizedBox(height: 12),
          _sideItem(LucideIcons.settings, "Configurações", false),
          _sideItem(LucideIcons.log_out, "Sair", false),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sideItem(IconData icon, String label, bool active) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xffEEF5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? azul : texto),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? azul : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borda, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 232,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: const Row(
              children: [
                Icon(LucideIcons.search, size: 17, color: Color(0xff4B5563)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pesquisar programas...",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Color(0xff6B7280)),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(LucideIcons.bell, size: 19, color: Color(0xff374151)),
          const SizedBox(width: 18),
          const Icon(Icons.help_outline, size: 20, color: Color(0xff374151)),
          const SizedBox(width: 18),
          Container(width: 1, height: 28, color: borda),
          const SizedBox(width: 20),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Admin User", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              Text("Administrador", style: TextStyle(fontSize: 10, color: Color(0xff4B5563))),
            ],
          ),
          const SizedBox(width: 12),
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
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class NovoRelatorioPage extends StatelessWidget {
  const NovoRelatorioPage({super.key});

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
                    padding: const EdgeInsets.fromLTRB(32, 32, 40, 40),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _backLink(),
                            const SizedBox(height: 28),
                            const Text(
                              "Novo Relatório",
                              style: TextStyle(fontSize: 33, fontWeight: FontWeight.w800, color: Colors.black, height: 1),
                            ),
                            const SizedBox(height: 30),
                            _detailsCard(),
                            const SizedBox(height: 22),
                            _selectedEventCard(),
                            const SizedBox(height: 28),
                            _actions(),
                          ],
                        ),
                      ),
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

  Widget _backLink() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.chevron_left, size: 17, color: Color(0xff1F2937)),
        SizedBox(width: 8),
        Text(
          "Voltar para Relatórios",
          style: TextStyle(fontSize: 15, color: Color(0xff1F2937), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _detailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borda),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Detalhes do Relatório",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 26),
          _label("Evento"),
          const SizedBox(height: 9),
          _selectField("Selecione um evento"),
          const SizedBox(height: 20),
          _label("Template"),
          const SizedBox(height: 9),
          _selectField("Selecione um template"),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
    );
  }

  Widget _selectField(String hint) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: const Color(0xffDDE1E4), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.black)),
          ),
          const Icon(LucideIcons.chevron_down, size: 19, color: Colors.black),
        ],
      ),
    );
  }

  Widget _selectedEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 28),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff9CC3FF)),
        boxShadow: [BoxShadow(color: azul.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: azul, borderRadius: BorderRadius.circular(13)),
            child: const Icon(LucideIcons.file_text, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Workshop de React Avançado",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 15, color: Color(0xff1F2937)),
                    SizedBox(width: 7),
                    Text("15 de Maio de 2024", style: TextStyle(fontSize: 13, color: Color(0xff1F2937))),
                    SizedBox(width: 150),
                    Icon(LucideIcons.map_pin, size: 15, color: Color(0xff1F2937)),
                    SizedBox(width: 7),
                    Text("São Paulo, SP", style: TextStyle(fontSize: 13, color: Color(0xff1F2937))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.86), borderRadius: BorderRadius.circular(12)),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Programa: ",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: "Programa de Capacitação Profissional"),
                      ],
                    ),
                    style: TextStyle(fontSize: 13, color: Color(0xff1F2937)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: const Text(
            "Cancelar",
            style: TextStyle(fontSize: 14, color: Color(0xff111827), fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 25),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: azul,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: azul.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: const Text(
            "Gerar Relatório",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
          _sideItem(LucideIcons.file_text, "Relatórios", false),
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
      decoration: BoxDecoration(color: active ? const Color(0xffEEF5FF) : Colors.transparent, borderRadius: BorderRadius.circular(24)),
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borda, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 235,
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
          const Icon(LucideIcons.bell, size: 20, color: Color(0xff374151)),
          const SizedBox(width: 18),
          const Icon(Icons.help_outline, size: 21, color: Color(0xff374151)),
          const SizedBox(width: 18),
          Container(width: 1, height: 28, color: borda),
          const SizedBox(width: 20),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Admin User",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: texto),
              ),
              Text("Administrador", style: TextStyle(fontSize: 10, color: Color(0xff4B5563))),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xffA7C8FF), width: 1.5),
            ),
            child: ClipOval(child: Image.asset("assets/images/logo_brisa.png", fit: BoxFit.contain)),
          ),
        ],
      ),
    );
  }
}

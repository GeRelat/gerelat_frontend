import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class EventosPage extends StatelessWidget {
  const EventosPage({super.key});

  static const Color azul = Color(0xff0057D9);
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(), const SizedBox(height: 28), _buildContent()]),
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
                "Gestão de Eventos",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.black, height: 1),
              ),
              SizedBox(height: 10),
              Text("Cadastre novos eventos e acompanhe o cronograma dos projetos.", style: TextStyle(fontSize: 17, color: Color(0xff374151))),
            ],
          ),
        ),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: azul,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: azul.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.plus, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "Novo Evento",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 1000;

        if (isSmall) {
          return Column(children: [_buildEventForm(), const SizedBox(height: 24), _buildUpcomingEvents()]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _buildEventForm()),
            const SizedBox(width: 30),
            Expanded(flex: 3, child: _buildUpcomingEvents()),
          ],
        );
      },
    );
  }

  Widget _buildEventForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.list_plus, color: azul, size: 22),
              SizedBox(width: 10),
              Text(
                "Detalhes do Evento",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _selectField(label: "PROJETO VINCULADO *", hint: "Selecione o projeto"),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _selectField(label: "CLASSE DE EVENTO *", hint: "Selecione a classe"),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _inputField(label: "NOME DO EVENTO *", hint: "Ex: Residência TIC"),

          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _inputField(label: "LOCAL", hint: "Ex: Sala de Conferências A"),
              ),
              const SizedBox(width: 22),
              Expanded(child: _dateField()),
            ],
          ),

          const SizedBox(height: 22),
          _inputField(label: "ENDEREÇO COMPLETO", hint: "Rua, Número, Bairro, Cidade - UF"),

          const SizedBox(height: 22),
          _textArea(),

          const SizedBox(height: 28),
          Container(height: 1, color: borda),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Descartar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              const SizedBox(width: 28),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: azul,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: azul.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.circle_check, color: Colors.white, size: 19),
                    SizedBox(width: 8),
                    Text(
                      "Salvar Evento",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 9),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                child: Text(hint, style: const TextStyle(fontSize: 16, color: Color(0xff8190A5))),
              ),
              const Icon(LucideIcons.chevron_down, size: 20, color: Color(0xff6B7280)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 9),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(8)),
          child: Text(hint, style: const TextStyle(fontSize: 16, color: Color(0xff9AABC1))),
        ),
      ],
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("DATA DO EVENTO"),
        const SizedBox(height: 9),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Expanded(
                child: Text("mm/dd/yyyy", style: TextStyle(fontSize: 16, color: Color(0xff9AABC1))),
              ),
              Icon(LucideIcons.calendar_days, size: 19, color: Color(0xff6B7280)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("OBJETIVO DO EVENTO"),
        const SizedBox(height: 9),
        Container(
          height: 118,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(8)),
          child: const Text("Descreva os principais objetivos e resultados esperados para este evento...", style: TextStyle(fontSize: 16, color: Color(0xff9AABC1))),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: Color(0xff374151)),
    );
  }

  Widget _buildUpcomingEvents() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Próximos Eventos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(18)),
                child: const Text(
                  "GERAL",
                  style: TextStyle(color: azul, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _eventCard(azul),
          const SizedBox(height: 16),
          _eventCard(const Color(0xff10B981)),
          const SizedBox(height: 16),
          _eventCard(const Color(0xffF59E0B)),
          const SizedBox(height: 22),
          Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff9CC3FF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Ver Calendário Completo",
              style: TextStyle(color: azul, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Color color) {
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(color: const Color(0xffF0F2F5), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "••••",
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  "•••••",
                  style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(LucideIcons.map_pin, size: 13, color: Colors.black.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    const Text(
                      "••••",
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
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
          _sideItem(LucideIcons.house, "Dashboard", false),
          _sideItem(LucideIcons.folder_kanban, "Programas", false),
          _sideItem(LucideIcons.calendar, "Eventos", true),
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

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borda, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 400, minWidth: 220),
            height: 44,
            decoration: BoxDecoration(color: const Color(0xffE1E5EA), borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              children: [
                Icon(LucideIcons.search, size: 20, color: Color(0xff4B5563)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Pesquisar programas...",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, color: Color(0xff6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

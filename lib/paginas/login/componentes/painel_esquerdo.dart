import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';

/// Painel azul da esquerda na tela de login.
/// Exibe o logo GeRelat, slogan, ilustração e rodapé de segurança.
class PainelEsquerdo extends StatelessWidget {
  const PainelEsquerdo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Fundo azul principal do painel
        color: Cores.azulPrimario,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirLogo(),
          const SizedBox(height: 16),
          _construirSlogan(),
          const SizedBox(height: 40),
          _construirIlustracao(),
          const Spacer(),
          _construirRodapeSeguranca(),
        ],
      ),
    );
  }

  /// Exibe o nome "GeRelat" como logo em texto branco e negrito
  Widget _construirLogo() {
    return const Text(
      'GeRelat',
      style: TextStyle(
        color: Cores.branco,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  /// Exibe o slogan institucional abaixo do logo
  Widget _construirSlogan() {
    return const Text(
      'A inteligência por trás dos seus dados.\nRelatórios precisos para decisões estratégicas.',
      style: TextStyle(
        color: Cores.branco,
        fontSize: 15,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Área de ilustração — placeholder com ícone de documento
  Widget _construirIlustracao() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Cores.brancoSutil,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone principal de documento
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Cores.brancoSutil,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Cores.branco,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          // Ícone menor abaixo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Cores.brancoSutil,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bar_chart_outlined,
              color: Cores.branco,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          // Terceiro ícone ainda menor
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Cores.brancoSutil,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.data_usage_outlined,
              color: Cores.branco,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Rodapé com ícone de escudo e texto de segurança
  Widget _construirRodapeSeguranca() {
    return Row(
      children: [
        // Ícone de escudo em círculo azul mais escuro
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Cores.brancoSutil,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Cores.branco,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Expanded garante que o texto ocupe o espaço restante sem transbordar
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Segurança Total',
                style: TextStyle(
                  color: Cores.branco,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Seus dados protegidos por criptografia de ponta.',
                style: TextStyle(
                  color: Cores.branco,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

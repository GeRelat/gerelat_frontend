import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

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
          const SizedBox(height: 88),
          _construirIlustracao(),
          const SizedBox(height: 40),
          _construirSlogan(),
          const Spacer(),
          _construirRodapeSeguranca(),
        ],
      ),
    );
  }

  /// Exibe o slogan institucional, centralizado abaixo da ilustração
  Widget _construirSlogan() {
    return SizedBox(
      width: double.infinity,
      child: Text(
        'A inteligência por trás dos seus dados.\nRelatórios precisos para decisões estratégicas.',
        textAlign: TextAlign.center,
        style: Tipografia.bodyLarge.copyWith(
          color: Cores.branco,
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  /// Área de ilustração — logo completo (ícone + "GeRelat" + tagline) em
  /// versão branca, direto sobre o azul do painel, sem cartão/caixa por
  /// trás. Único lugar do painel onde o nome "GeRelat" aparece — já vem
  /// escrito na própria imagem.
  Widget _construirIlustracao() {
    return SizedBox(
      width: double.infinity,
      height: 260,
      child: Center(
        child: Image.asset(
          'assets/images/logo_gerelat_completo_branco.png',
          height: 220,
        ),
      ),
    );
  }

  /// Rodapé com ícone de escudo e texto de segurança
  Widget _construirRodapeSeguranca() {
    return Row(
      children: [
        // Ícone de escudo em círculo azul mais escuro
        const IconeComFundo(
          cor: Cores.branco,
          tamanho: 40,
          raio: 20,
          icone: Icons.shield_outlined,
          tamanhoIcone: 20,
        ),
        const SizedBox(width: 12),
        // Expanded garante que o texto ocupe o espaço restante sem transbordar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Segurança Total',
                style: Tipografia.titleSmall.copyWith(
                  color: Cores.branco,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Seus dados protegidos por criptografia de ponta.',
                style: Tipografia.bodySmall.copyWith(color: Cores.branco),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

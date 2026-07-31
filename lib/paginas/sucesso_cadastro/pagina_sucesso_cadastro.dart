import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/sombras.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

/// Página exibida após o cadastro ser concluído com sucesso.
/// Confirma a criação da conta e redireciona o usuário para o login.
class PaginaSucessoCadastro extends StatelessWidget {
  const PaginaSucessoCadastro({super.key});

  /// Navega para o login e limpa todo o histórico de navegação.
  /// Assim o usuário não consegue voltar para o cadastro com o botão "voltar".
  void _irParaLogin(BuildContext context) {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoPagina,
      body: Column(
        children: [
          Expanded(child: Center(child: _construirCard(context))),
          _construirRodape(),
        ],
      ),
    );
  }

  /// Card principal branco com todos os elementos de sucesso
  Widget _construirCard(BuildContext context) {
    return Container(
      width: 448,
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Sombras.cartaoAutenticacao,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _construirBarraTopo(),
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _construirIconeSucesso(),
                  const SizedBox(height: 32),
                  _construirTextos(),
                  const SizedBox(height: 32),
                  _construirAcoes(context),
                  const SizedBox(height: 32),
                  _construirIdentidadeMarca(),
                ],
              ),
            ),
            _construirIndicadorProgresso(),
          ],
        ),
      ),
    );
  }

  /// Barra de 4px no topo com gradiente azul — elemento decorativo do card
  Widget _construirBarraTopo() {
    return Container(
      height: 4,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Cores.azulPrimario, Cores.azulGradienteFim],
        ),
      ),
    );
  }

  /// Ícone de check verde com efeito de brilho ambiente
  Widget _construirIconeSucesso() {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Efeito de luz ambiente — círculo verde desfocado atrás
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Cores.verdeClaro.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
            // Círculo verde principal com ícone de check
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Cores.verdeClaro,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Cores.verdeTextoEscuro,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Título e subtítulo da confirmação usando o design system
  Widget _construirTextos() {
    return Column(
      children: [
        // Título → HeadlineMedium (Poppins Regular 28px)
        Text(
          'Conta criada com\nsucesso!',
          style: Tipografia.headlineMediumDestaque.copyWith(
            height: 1.2,
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Subtítulo → BodyLarge (Roboto Regular 16px) com "GeRelat" em azul
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Tipografia.bodyLarge.copyWith(
              height: 1.625,
              color: Cores.cinzaEscuro,
            ),
            children: [
              const TextSpan(
                text:
                    'Sua conta foi configurada e está pronta para uso. Explore todas as ferramentas do ',
              ),
              // "GeRelat" destacado em azul → LabelLarge (Roboto SemiBold 14px)
              TextSpan(
                text: 'GeRelat',
                style: Tipografia.labelLargeDestaque.copyWith(
                  color: Cores.azulPrimario,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }

  /// Botão principal e link secundário de suporte
  Widget _construirAcoes(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _irParaLogin(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Cores.azulAcao,
              foregroundColor: Cores.branco,
              elevation: 1,
              shadowColor: Sombras.botaoPrimario,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Texto do botão → TitleMedium (Poppins Medium 16px)
            child: Text(
              'Ir para o Login',
              style: Tipografia.titleMedium.copyWith(color: Cores.branco),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Texto secundário → TitleSmall (Poppins Medium 14px)
        Text(
          'Dúvidas? Fale com o suporte',
          style: Tipografia.titleSmall.copyWith(color: Cores.cinzaEscuro),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Linha divisória com o logo GeRelat — ancora visual de marca
  Widget _construirIdentidadeMarca() {
    return Column(
      children: [
        Divider(
          color: Cores.cinzaAzulado.withValues(alpha: 0.15),
          thickness: 1,
        ),
        const SizedBox(height: 16),
        // Logo → HeadlineSmall (Poppins Regular 24px) em tamanho reduzido
        Text(
          'GeRelat',
          style: Tipografia.titleSmall.copyWith(
            letterSpacing: -0.5,
            color: Cores.pretoProfundo,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Indicador de progresso de 3 barras — a segunda (azul) representa a etapa atual
  Widget _construirIndicadorProgresso() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _construirBarra(ativa: false),
            const SizedBox(width: 16),
            _construirBarra(ativa: true),
            const SizedBox(width: 16),
            _construirBarra(ativa: false),
          ],
        ),
      ),
    );
  }

  /// Barra individual do indicador de progresso
  Widget _construirBarra({required bool ativa}) {
    return Container(
      width: 80,
      height: 4,
      decoration: BoxDecoration(
        color: ativa ? Cores.azulPrimario : Cores.cinzaInativo,
        borderRadius: BorderRadius.circular(9999),
      ),
    );
  }

  /// Rodapé com copyright → BodySmall (Roboto Regular 12px)
  Widget _construirRodape() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        '© 2026 GeRelat • Segurança e transparência em seus relatórios.',
        style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
        textAlign: TextAlign.center,
      ),
    );
  }
}

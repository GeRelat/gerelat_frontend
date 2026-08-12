part of '../painel_ui.dart';

/// Ícone dentro de um contêiner com fundo tingido na cor do próprio ícone
/// (10% de opacidade). Usado pelo ícone de destaque de [CartaoInfo] e pelo
/// ícone grande de [EstadoVazio] — cada um com tamanho e raio próprios.
class IconeComFundo extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final double tamanho;
  final double raio;
  final double tamanhoIcone;

  const IconeComFundo({
    super.key,
    required this.icone,
    required this.cor,
    required this.tamanho,
    required this.raio,
    required this.tamanhoIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(raio),
      ),
      child: Icon(icone, color: cor, size: tamanhoIcone),
    );
  }
}

class CartaoInfo extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color cor;

  const CartaoInfo({
    super.key,
    required this.titulo,
    required this.valor,
    required this.descricao,
    required this.icone,
    this.cor = Cores.azulAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Cores.branco,
        border: Border.all(color: Cores.bordaSutil),
        borderRadius: BorderRadius.circular(12),
        boxShadow: Sombras.cartaoEstatistica,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: Tipografia.labelLarge.copyWith(
                    color: Cores.cinzaEscuro,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              IconeComFundo(
                icone: icone,
                cor: cor,
                tamanho: 32,
                raio: 8,
                tamanhoIcone: 18,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            valor,
            style: Tipografia.headlineLarge.copyWith(
              color: Cores.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }
}

class CartaoConteudo extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CartaoConteudo({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Cores.branco,
        border: Border.all(color: Cores.bordaSutil),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final String acao;
  final VoidCallback? onAcao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.acao,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    return CartaoConteudo(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconeComFundo(
            icone: icone,
            cor: Cores.azulAcao,
            tamanho: 64,
            raio: 999,
            tamanhoIcone: 30,
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Tipografia.titleLargeDestaque.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              descricao,
              textAlign: TextAlign.center,
              style: Tipografia.bodyMedium.copyWith(
                color: Cores.cinzaEscuro,
                height: 1.5,
              ),
            ),
          ),
          if (onAcao != null) ...[
            const SizedBox(height: 24),
            BotaoPrimario(
              texto: acao,
              icone: LucideIcons.plus,
              onPressed: onAcao,
            ),
          ],
        ],
      ),
    );
  }
}

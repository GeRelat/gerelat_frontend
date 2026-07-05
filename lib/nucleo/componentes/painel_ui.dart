import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class CampoBusca extends StatelessWidget {
  final TextEditingController controlador;
  final String dica;
  final ValueChanged<String> aoAlterar;

  const CampoBusca({
    super.key,
    required this.controlador,
    required this.dica,
    required this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Cores.cinzaCampo,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 18, color: Cores.cinzaEscuro),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controlador,
                onChanged: aoAlterar,
                decoration: InputDecoration(
                  hintText: dica,
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintStyle: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaMedio,
                  ),
                ),
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BotaoPrimario extends StatelessWidget {
  final String texto;
  final IconData icone;
  final VoidCallback? onPressed;

  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.icone,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, size: 18),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: Cores.azulAcao,
        foregroundColor: Cores.branco,
        elevation: 0,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Tipografia.labelLarge,
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor, size: 18),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Cores.azulAcao.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icone, color: Cores.azulAcao, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Tipografia.titleLarge.copyWith(
              color: Cores.textoPrincipal,
              fontWeight: FontWeight.w800,
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
          const SizedBox(height: 24),
          BotaoPrimario(
            texto: acao,
            icone: LucideIcons.plus,
            onPressed: onAcao,
          ),
        ],
      ),
    );
  }
}

class CampoFormulario extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icone;
  final int maxLines;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool obscureText;
  final Widget? sufixo;

  const CampoFormulario({
    super.key,
    required this.label,
    required this.hint,
    this.icone,
    this.maxLines = 1,
    this.controller,
    this.focusNode,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.obscureText = false,
    this.sufixo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
            prefixIcon: icone == null
                ? null
                : Icon(icone, color: Cores.cinzaMedio, size: 18),
            suffixIcon: sufixo,
            filled: true,
            fillColor: Cores.cinzaClaro,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Cores.azulAcao),
            ),
          ),
        ),
      ],
    );
  }
}

class CampoSelecao extends StatelessWidget {
  final String label;
  final int? valor;
  final List<DropdownMenuItem<int>> itens;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;

  const CampoSelecao({
    super.key,
    required this.label,
    required this.valor,
    required this.itens,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: valor,
          items: itens,
          onChanged: onChanged,
          validator:
              validator ??
              (value) => value == null ? 'Selecione uma opção' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Cores.cinzaClaro,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class BarraAcoesFormulario extends StatelessWidget {
  final String textoPrimario;
  final VoidCallback? onCancelar;
  final VoidCallback? onSalvar;

  const BarraAcoesFormulario({
    super.key,
    required this.textoPrimario,
    this.onCancelar,
    this.onSalvar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancelar ?? () => context.pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        BotaoPrimario(
          texto: textoPrimario,
          icone: LucideIcons.save,
          onPressed: onSalvar ?? () {},
        ),
      ],
    );
  }
}

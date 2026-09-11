part of '../painel_ui.dart';

/// Rótulo padrão exibido acima de campos de formulário. Usado por
/// [CampoFormulario], [CampoSelecao] e [SeletorLogomarca].
class _RotuloCampo extends StatelessWidget {
  final String texto;

  const _RotuloCampo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro),
    );
  }
}

/// Decoração base dos campos de formulário: fundo preenchido e borda
/// arredondada sem contorno. Compartilhada por [CampoFormulario] e
/// [CampoSelecao] — cada um adiciona por cima (`copyWith`) o que for
/// específico daquele campo (ícone, contador, borda de foco etc.).
InputDecoration _decoracaoCampoBase({
  required EdgeInsetsGeometry contentPadding,
}) {
  return InputDecoration(
    filled: true,
    fillColor: Cores.cinzaClaro,
    contentPadding: contentPadding,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
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
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

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
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RotuloCampo(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          obscureText: obscureText,
          decoration:
              _decoracaoCampoBase(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ).copyWith(
                hintText: hint,
                hintStyle: Tipografia.bodyMedium.copyWith(
                  color: Cores.cinzaMedio,
                ),
                prefixIcon: icone == null
                    ? null
                    : Icon(icone, color: Cores.cinzaMedio, size: 18),
                suffixIcon: sufixo,
                counterText: maxLength == null ? null : '',
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
  final Widget? acaoRotulo;

  const CampoSelecao({
    super.key,
    required this.label,
    required this.valor,
    required this.itens,
    this.onChanged,
    this.validator,
    this.acaoRotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty || acaoRotulo != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label.isNotEmpty) _RotuloCampo(label),
              ?acaoRotulo,
            ],
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<int>(
          initialValue: valor,
          items: itens,
          onChanged: onChanged,
          validator:
              validator ??
              (value) => value == null ? 'Selecione uma opção' : null,
          decoration: _decoracaoCampoBase(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ],
    );
  }
}

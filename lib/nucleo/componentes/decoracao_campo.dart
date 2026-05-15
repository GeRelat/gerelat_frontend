import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Decoração padrão reutilizável para campos de formulário do GeRelat.
///
/// Parâmetros opcionais permitem customizar o preenchimento, raio, ícone e
/// estilo de borda sem duplicar o código de borda em cada tela.
InputDecoration decoracaoCampo({
  required String dica,
  required IconData icone,
  Widget? sufixo,
  Color fillColor = Cores.cinzaClaro,
  double borderRadius = 8,
  double iconSize = 18,
  EdgeInsetsGeometry contentPadding =
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  Color hintColor = Cores.cinzaMedio,
  bool bordaVisivel = false,
}) {
  OutlineInputBorder borda(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: side,
      );

  final bordaNormal =
      bordaVisivel ? const BorderSide(color: Cores.cinzaClaro) : BorderSide.none;

  return InputDecoration(
    hintText: dica,
    hintStyle: Tipografia.bodyMedium.copyWith(color: hintColor),
    prefixIcon: Icon(icone, color: Cores.cinzaMedio, size: iconSize),
    suffixIcon: sufixo,
    filled: true,
    fillColor: fillColor,
    contentPadding: contentPadding,
    border: borda(bordaNormal),
    enabledBorder: borda(bordaNormal),
    focusedBorder: borda(const BorderSide(color: Cores.azulPrimario, width: 1.5)),
    errorBorder: borda(const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder:
        borda(const BorderSide(color: Colors.redAccent, width: 1.5)),
  );
}

import 'package:flutter/services.dart';

/// Formatadores de digitação: reescrevem o texto a cada tecla, a partir só
/// dos dígitos já informados — o usuário digita apenas números e o campo
/// já entrega "12/05/2026" ou "(53) 9 92.05.11.45" em vez de "12052026"
/// ou "53992051145".
class FormatadorData extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = _formatarData(_apenasDigitos(newValue.text, maximo: 8));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class FormatadorTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = _formatarTelefone(_apenasDigitos(newValue.text, maximo: 11));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

final RegExp _naoDigito = RegExp(r'\D');

String _apenasDigitos(String valor, {required int maximo}) {
  final digitos = valor.replaceAll(_naoDigito, '');
  return digitos.length > maximo ? digitos.substring(0, maximo) : digitos;
}

String _formatarData(String digitos) {
  if (digitos.length <= 2) return digitos;
  if (digitos.length <= 4) {
    return '${digitos.substring(0, 2)}/${digitos.substring(2)}';
  }
  return '${digitos.substring(0, 2)}/${digitos.substring(2, 4)}/${digitos.substring(4)}';
}

// Celular (11 dígitos): (DD) D DD.DD.DD.DD — o dígito 9 isolado, depois
// pares. Fixo (10 dígitos ou menos, ainda sendo digitado): (DD) DD.DD.DD.DD.
String _formatarTelefone(String digitos) {
  if (digitos.isEmpty) return '';
  if (digitos.length <= 2) return '($digitos';

  final ddd = digitos.substring(0, 2);
  final resto = digitos.substring(2);
  final buffer = StringBuffer('($ddd) ');

  if (digitos.length == 11) {
    buffer.write(resto[0]);
    final pares = resto.substring(1);
    if (pares.isNotEmpty) buffer.write(' ');
    buffer.write(_agruparEmPares(pares));
  } else {
    buffer.write(_agruparEmPares(resto));
  }
  return buffer.toString();
}

String _agruparEmPares(String digitos) {
  final grupos = <String>[];
  for (var i = 0; i < digitos.length; i += 2) {
    final fim = i + 2 > digitos.length ? digitos.length : i + 2;
    grupos.add(digitos.substring(i, fim));
  }
  return grupos.join('.');
}

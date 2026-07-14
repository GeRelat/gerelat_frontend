final RegExp _regexEmail = RegExp(
  r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
);

bool emailValido(String valor) => _regexEmail.hasMatch(valor);

final RegExp _naoDigito = RegExp(r'\D');

// Só confere a quantidade de dígitos (14), sem checar o dígito verificador —
// mais permissivo de propósito para não travar cadastro em ambiente de teste
// com CNPJs fictícios/gerados à mão.
bool cnpjValido(String valor) {
  final digitos = valor.replaceAll(_naoDigito, '');
  return digitos.length == 14;
}

bool telefoneValido(String valor) {
  final digitos = valor.replaceAll(_naoDigito, '');
  return digitos.length == 10 || digitos.length == 11;
}

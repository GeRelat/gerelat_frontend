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

final RegExp _somenteDigitos = RegExp(r'^\d+$');

// Aproximação client-side do CommonPasswordValidator do Django, que usa uma
// lista de ~20 mil senhas vazadas (common-passwords.txt.gz). Reproduzir a
// lista inteira aqui não é prático — esta é uma amostra das entradas mais
// óbvias, só para dar feedback imediato; a validação definitiva depende do
// backend aplicar `validate_password()` (ver pendencias-backend.md, item 5).
const Set<String> _senhasComuns = {
  'password',
  'password1',
  'password123',
  '12345678',
  '123456789',
  '1234567890',
  'qwerty123',
  'qwertyuiop',
  'letmein',
  'welcome1',
  'admin123',
  'senha123',
  'abc12345',
  '11111111',
  'iloveyou',
  'monkey123',
  'football',
  'dragon123',
  'sunshine1',
  'princess1',
};

bool senhaSomenteNumerica(String senha) => _somenteDigitos.hasMatch(senha);

bool senhaComum(String senha) => _senhasComuns.contains(senha.toLowerCase());

// Aproxima o UserAttributeSimilarityValidator do Django: rejeita senha muito
// parecida com algum atributo do próprio usuário (nome, e-mail).
bool senhaSemelhanteAAtributo(String senha, List<String> atributosUsuario) {
  final senhaNormalizada = senha.trim().toLowerCase();
  if (senhaNormalizada.isEmpty) return false;

  for (final atributo in atributosUsuario) {
    final valor = atributo.trim().toLowerCase();
    // Atributos muito curtos (ex.: iniciais) geram falso positivo demais.
    if (valor.length < 4) continue;
    if (senhaNormalizada.contains(valor) || valor.contains(senhaNormalizada)) {
      return true;
    }
  }
  return false;
}

/// Valida a força de uma nova senha, espelhando no cliente as regras
/// declaradas em `AUTH_PASSWORD_VALIDATORS` no backend (mínimo 8
/// caracteres, não inteiramente numérica, não muito parecida com dados do
/// usuário, não estar entre as senhas mais comuns).
///
/// É uma aproximação: o backend ainda não chama `validate_password()` nos
/// serializers de cadastro/troca de senha (ver pendencias-backend.md, item
/// 5), então esta é a única validação de força de senha realmente aplicada
/// hoje — nem o backend nem esta função cobrem a lista completa de ~20 mil
/// senhas comuns do Django.
String? validarForcaSenha(
  String? valor, {
  List<String> atributosUsuario = const [],
}) {
  if (valor == null || valor.isEmpty) return 'Informe a senha';
  if (valor.length < 8) return 'Mínimo de 8 caracteres';
  if (senhaSomenteNumerica(valor)) {
    return 'A senha não pode ser inteiramente numérica';
  }
  if (senhaComum(valor)) return 'Essa senha é muito comum. Escolha outra.';
  if (senhaSemelhanteAAtributo(valor, atributosUsuario)) {
    return 'A senha não pode ser parecida com seu nome ou e-mail';
  }
  return null;
}

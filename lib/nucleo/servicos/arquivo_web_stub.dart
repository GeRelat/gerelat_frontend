import 'dart:typed_data';

class ArquivoSelecionadoWeb {
  final String nome;
  final Uint8List bytes;

  const ArquivoSelecionadoWeb({required this.nome, required this.bytes});
}

/// Lançada quando o arquivo escolhido pelo usuário não passa na validação
/// client-side de extensão ou tamanho.
class ArquivoInvalidoException implements Exception {
  final String mensagem;

  const ArquivoInvalidoException(this.mensagem);

  @override
  String toString() => mensagem;
}

Future<ArquivoSelecionadoWeb?> selecionarArquivo({
  String accept = '*/*',
  List<String> extensoesPermitidas = const [],
  int? tamanhoMaximoBytes,
}) {
  throw UnsupportedError(
    'selecionarArquivo só está disponível na plataforma web.',
  );
}

void baixarArquivo({
  required Uint8List bytes,
  required String nomeArquivo,
  required String mimeType,
}) {
  throw UnsupportedError(
    'baixarArquivo só está disponível na plataforma web.',
  );
}

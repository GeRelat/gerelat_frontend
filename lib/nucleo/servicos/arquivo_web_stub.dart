import 'dart:typed_data';

class ArquivoSelecionadoWeb {
  final String nome;
  final Uint8List bytes;

  const ArquivoSelecionadoWeb({required this.nome, required this.bytes});
}

Future<ArquivoSelecionadoWeb?> selecionarArquivo({
  String accept = '*/*',
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

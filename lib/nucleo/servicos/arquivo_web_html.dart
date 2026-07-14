import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'arquivo_web_stub.dart'
    show ArquivoSelecionadoWeb, ArquivoInvalidoException;

export 'arquivo_web_stub.dart'
    show ArquivoSelecionadoWeb, ArquivoInvalidoException;

Future<ArquivoSelecionadoWeb?> selecionarArquivo({
  String accept = '*/*',
  List<String> extensoesPermitidas = const [],
  int? tamanhoMaximoBytes,
}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..style.display = 'none';
  html.document.body?.append(input);

  final completer = Completer<ArquivoSelecionadoWeb?>();

  void finalizar(ArquivoSelecionadoWeb? resultado) {
    input.remove();
    if (!completer.isCompleted) completer.complete(resultado);
  }

  void finalizarComErro(Object erro) {
    input.remove();
    if (!completer.isCompleted) completer.completeError(erro);
  }

  input.onChange.listen((_) {
    final arquivo = input.files?.first;
    if (arquivo == null) {
      finalizar(null);
      return;
    }

    if (extensoesPermitidas.isNotEmpty) {
      final nomeMinusculo = arquivo.name.toLowerCase();
      final extensaoValida = extensoesPermitidas.any(
        (extensao) => nomeMinusculo.endsWith(extensao.toLowerCase()),
      );
      if (!extensaoValida) {
        finalizarComErro(
          ArquivoInvalidoException(
            'Tipo de arquivo não permitido. Extensões aceitas: '
            '${extensoesPermitidas.join(', ')}.',
          ),
        );
        return;
      }
    }

    if (tamanhoMaximoBytes != null && arquivo.size > tamanhoMaximoBytes) {
      final limiteMb = (tamanhoMaximoBytes / (1024 * 1024)).toStringAsFixed(1);
      finalizarComErro(
        ArquivoInvalidoException(
          'Arquivo muito grande. Tamanho máximo permitido: ${limiteMb}MB.',
        ),
      );
      return;
    }

    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      // O tipo runtime de FileReader.result após readAsArrayBuffer varia
      // conforme o compilador (dart2js/dartdevc): pode vir como ByteBuffer
      // ou já como Uint8List/TypedData. Aceita qualquer um dos formatos.
      final resultado = reader.result;
      Uint8List? bytes;
      if (resultado is Uint8List) {
        bytes = resultado;
      } else if (resultado is ByteBuffer) {
        bytes = resultado.asUint8List();
      } else if (resultado is TypedData) {
        bytes = resultado.buffer.asUint8List();
      } else if (resultado is List<int>) {
        bytes = Uint8List.fromList(resultado);
      }

      if (bytes == null) {
        finalizar(null);
        return;
      }

      finalizar(ArquivoSelecionadoWeb(nome: arquivo.name, bytes: bytes));
    });
    reader.readAsArrayBuffer(arquivo);
  });

  input.click();
  return completer.future;
}

void baixarArquivo({
  required Uint8List bytes,
  required String nomeArquivo,
  required String mimeType,
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = nomeArquivo
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

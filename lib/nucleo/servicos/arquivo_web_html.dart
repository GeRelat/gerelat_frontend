import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'arquivo_web_stub.dart' show ArquivoSelecionadoWeb;

Future<ArquivoSelecionadoWeb?> selecionarArquivo({
  String accept = '*/*',
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

  input.onChange.listen((_) {
    final arquivo = input.files?.first;
    if (arquivo == null) {
      finalizar(null);
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

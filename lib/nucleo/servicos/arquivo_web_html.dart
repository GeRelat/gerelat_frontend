import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

import 'arquivo_web_stub.dart'
    show ArquivoSelecionadoWeb, ArquivoInvalidoException;

export 'arquivo_web_stub.dart'
    show ArquivoSelecionadoWeb, ArquivoInvalidoException;

Future<ArquivoSelecionadoWeb?> selecionarArquivo({
  String accept = '*/*',
  List<String> extensoesPermitidas = const [],
  int? tamanhoMaximoBytes,
}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..style.display = 'none';
  web.document.body?.append(input);

  final completer = Completer<ArquivoSelecionadoWeb?>();

  void finalizar(ArquivoSelecionadoWeb? resultado) {
    input.remove();
    if (!completer.isCompleted) completer.complete(resultado);
  }

  void finalizarComErro(Object erro) {
    input.remove();
    if (!completer.isCompleted) completer.completeError(erro);
  }

  input.addEventListener(
    'change',
    (web.Event _) {
      final arquivo = input.files?.item(0);
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
        final limiteMb = (tamanhoMaximoBytes / (1024 * 1024)).toStringAsFixed(
          1,
        );
        finalizarComErro(
          ArquivoInvalidoException(
            'Arquivo muito grande. Tamanho máximo permitido: ${limiteMb}MB.',
          ),
        );
        return;
      }

      final reader = web.FileReader();
      reader.addEventListener(
        'loadend',
        (web.Event _) {
          final resultado = reader.result;
          final bytes = resultado.isA<JSArrayBuffer>()
              ? (resultado as JSArrayBuffer).toDart.asUint8List()
              : null;

          if (bytes == null) {
            finalizar(null);
            return;
          }

          finalizar(ArquivoSelecionadoWeb(nome: arquivo.name, bytes: bytes));
        }.toJS,
      );
      reader.readAsArrayBuffer(arquivo);
    }.toJS,
  );

  input.click();
  return completer.future;
}

void baixarArquivo({
  required Uint8List bytes,
  required String nomeArquivo,
  required String mimeType,
}) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = nomeArquivo
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

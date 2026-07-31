import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Diálogo de confirmação para ações destrutivas (excluir/remover).
///
/// Uso:
/// ```dart
/// final confirmou = await DialogoConfirmacaoExclusao.mostrar(
///   context,
///   titulo: 'Excluir programa',
///   mensagem: 'Tem certeza de que deseja excluir "${programa.nome}"?',
/// );
/// if (!confirmou || !context.mounted) return;
/// ```
class DialogoConfirmacaoExclusao extends StatelessWidget {
  final String titulo;
  final String mensagem;
  final String textoConfirmar;

  const DialogoConfirmacaoExclusao({
    super.key,
    required this.titulo,
    required this.mensagem,
    this.textoConfirmar = 'Excluir',
  });

  /// Mostra o diálogo e retorna `true` somente se o usuário confirmou.
  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    String textoConfirmar = 'Excluir',
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => DialogoConfirmacaoExclusao(
        titulo: titulo,
        mensagem: mensagem,
        textoConfirmar: textoConfirmar,
      ),
    );
    return confirmou ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            textoConfirmar,
            style: Tipografia.labelLarge.copyWith(color: Cores.vermelhoErro),
          ),
        ),
      ],
    );
  }
}

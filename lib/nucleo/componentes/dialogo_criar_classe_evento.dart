import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Diálogo modal para criação rápida de Classe de Evento em um Programa.
class DialogoCriarClasseEvento extends StatefulWidget {
  final String nomePrograma;
  final Future<bool> Function(String nomeClasse) onSalvar;

  const DialogoCriarClasseEvento({
    super.key,
    required this.nomePrograma,
    required this.onSalvar,
  });

  /// Abre o diálogo e retorna `true` se a classe foi criada com sucesso.
  static Future<bool> mostrar(
    BuildContext context, {
    required String nomePrograma,
    required Future<bool> Function(String nomeClasse) onSalvar,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => DialogoCriarClasseEvento(
        nomePrograma: nomePrograma,
        onSalvar: onSalvar,
      ),
    );
    return resultado ?? false;
  }

  @override
  State<DialogoCriarClasseEvento> createState() =>
      _DialogoCriarClasseEventoState();
}

class _DialogoCriarClasseEventoState extends State<DialogoCriarClasseEvento> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final sucesso = await widget.onSalvar(_controller.text.trim());
      if (!mounted) return;
      if (sucesso) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _salvando = false;
          _erro = 'Não foi possível criar a classe de evento.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Cores.branco,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nova classe de evento',
                    style: Tipografia.headlineSmall.copyWith(
                      color: Cores.textoPrincipal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _salvando
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(LucideIcons.x, size: 20),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A classe será criada no programa "${widget.nomePrograma}" e ficará disponível para todos os seus projetos e templates.',
                style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
              ),
              const SizedBox(height: 20),
              CampoFormulario(
                label: 'Nome da Classe',
                hint: 'Ex: Oficina, Reunião, Palestra',
                icone: LucideIcons.tags,
                controller: _controller,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o nome da classe';
                  }
                  return null;
                },
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  style:
                      Tipografia.bodySmall.copyWith(color: Cores.vermelhoErro),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  BotaoPrimario(
                    texto: _salvando ? 'Criando...' : 'Criar Classe',
                    icone: LucideIcons.plus,
                    onPressed: _salvando ? null : _submeter,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

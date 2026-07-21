import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/evento_form_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/formatadores.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioEvento extends StatefulWidget {
  final bool edicao;
  final int? eventoId;

  const PaginaFormularioEvento({super.key, this.edicao = false, this.eventoId});

  @override
  State<PaginaFormularioEvento> createState() => _PaginaFormularioEventoState();
}

class _PaginaFormularioEventoState extends State<PaginaFormularioEvento> {
  final _formKey = GlobalKey<FormState>();

  final _nome = TextEditingController();
  final _data = TextEditingController();
  final _local = TextEditingController();
  final _endereco = TextEditingController();
  final _objetivo = TextEditingController();
  final _novaClasse = TextEditingController();

  late final EventoFormViewModel _viewModel;

  int? _projetoId;
  int? _classeId;

  @override
  void initState() {
    super.initState();

    _viewModel = EventoFormViewModel(DependenciasApp.instancia.repositorioCatalogo);

    // Classe existente e nova classe são opções mutuamente exclusivas.
    _novaClasse.addListener(_aoDigitarNovaClasse);

    final eventoId = widget.eventoId;

    if (widget.edicao && eventoId != null) {
      _viewModel.carregarEdicao(eventoId).then((_) {
        final evento = _viewModel.evento;

        if (!mounted || evento == null) {
          return;
        }

        _projetoId = evento.projetoId;
        _classeId = evento.classeEventoId;
        _nome.text = evento.nome;
        _data.text = evento.data == null ? '' : _formatarData(evento.data!);
        _local.text = evento.local;
        _endereco.text = evento.endereco;
        _objetivo.text = evento.objetivo;

        setState(() {});
      });
    } else {
      _viewModel.carregarOpcoes();
    }
  }

  @override
  void dispose() {
    _novaClasse.removeListener(_aoDigitarNovaClasse);

    _nome.dispose();
    _data.dispose();
    _local.dispose();
    _endereco.dispose();
    _objetivo.dispose();
    _novaClasse.dispose();
    _viewModel.dispose();

    super.dispose();
  }

  void _aoDigitarNovaClasse() {
    if (_classeId != null && _novaClasse.text.trim().isNotEmpty) {
      setState(() {
        _classeId = null;
      });
    }
  }

  Future<void> _salvar() async {
    final formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final data = _parseData(_data.text);

    if (data == null || _projetoId == null) {
      return;
    }

    final sucesso = await _viewModel.salvar(
      eventoId: widget.eventoId,
      projetoId: _projetoId!,
      classeEventoId: _classeId,
      nomeNovaClasse: _novaClasse.text.trim(),
      nome: _nome.text.trim(),
      data: data,
      local: _local.text.trim(),
      endereco: _endereco.text.trim(),
      objetivo: _objetivo.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      context.pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.carregando && _viewModel.projetos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.edicao ? 'Editar evento institucional' : 'Cadastrar evento institucional', style: Tipografia.headlineMedium.copyWith(color: Cores.textoPrincipal)),
                const SizedBox(height: 24),
                CartaoConteudo(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final telaPequena = constraints.maxWidth < 700;

                          if (telaPequena) {
                            return Column(
                              children: [
                                CampoSelecao(
                                  label: 'Projeto',
                                  valor: _projetoId,
                                  itens: _viewModel.projetos.map((item) => DropdownMenuItem<int>(value: item.id, child: Text(item.nome))).toList(),
                                  onChanged: _aoSelecionarProjeto,
                                ),
                                const SizedBox(height: 18),
                                CampoSelecao(
                                  label: 'Classe do Evento',
                                  valor: _classeId,
                                  itens: _viewModel.classes.map((item) => DropdownMenuItem<int>(value: item.id, child: Text(item.nome))).toList(),
                                  onChanged: _aoSelecionarClasse,
                                  validator: _validarClasseEvento,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CampoSelecao(
                                  label: 'Projeto',
                                  valor: _projetoId,
                                  itens: _viewModel.projetos.map((item) => DropdownMenuItem<int>(value: item.id, child: Text(item.nome))).toList(),
                                  onChanged: _aoSelecionarProjeto,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: CampoSelecao(
                                  label: 'Classe do Evento',
                                  valor: _classeId,
                                  itens: _viewModel.classes.map((item) => DropdownMenuItem<int>(value: item.id, child: Text(item.nome))).toList(),
                                  onChanged: _aoSelecionarClasse,
                                  validator: _validarClasseEvento,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(label: 'Nova classe de evento', hint: 'Preencha quando a classe ainda não existir', icone: LucideIcons.tags, controller: _novaClasse),
                      const SizedBox(height: 18),
                      CampoFormulario(label: 'Nome do Evento', hint: 'Ex.: Oficina de Dados Abertos', icone: LucideIcons.calendar, controller: _nome, validator: _obrigatorio),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Data',
                        hint: 'DD/MM/AAAA',
                        icone: LucideIcons.calendar_days,
                        controller: _data,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FormatadorData()],
                        validator: (valor) {
                          return _parseData(valor ?? '') == null ? 'Informe uma data válida' : null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(label: 'Local', hint: 'Local do evento', icone: LucideIcons.map_pin, controller: _local),
                      const SizedBox(height: 18),
                      CampoFormulario(label: 'Endereço', hint: 'Endereço completo', icone: LucideIcons.map, controller: _endereco),
                      const SizedBox(height: 18),

                      // Campo próprio para manter o ícone alinhado ao topo.
                      _construirCampoObjetivo(),

                      const SizedBox(height: 28),
                      BarraAcoesFormulario(
                        textoPrimario: _viewModel.carregando
                            ? 'Salvando...'
                            : widget.edicao
                            ? 'Salvar Evento'
                            : 'Criar Evento',
                        onSalvar: _viewModel.carregando ? null : _salvar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _aoSelecionarProjeto(int? value) async {
    setState(() {
      _projetoId = value;
      _classeId = null;
    });

    if (value != null) {
      await _viewModel.carregarClassesProjeto(value);
    }
  }

  void _aoSelecionarClasse(int? value) {
    setState(() {
      _classeId = value;

      if (value != null) {
        _novaClasse.clear();
      }
    });
  }

  String? _validarClasseEvento(int? value) {
    if (value == null && _novaClasse.text.trim().isEmpty) {
      return 'Selecione ou informe uma nova classe';
    }

    return null;
  }

  /// Campo de objetivo com ícone alinhado ao início do texto.
  Widget _construirCampoObjetivo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Objetivo', style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Cores.cinzaClaro, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(LucideIcons.target, size: 20, color: Cores.cinzaMedio),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _objetivo,
                  minLines: 4,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.top,
                  style: Tipografia.bodyLarge.copyWith(color: Cores.textoPrincipal),
                  decoration: InputDecoration(
                    hintText: 'Descreva o objetivo do evento',
                    hintStyle: Tipografia.bodyLarge.copyWith(color: Cores.cinzaMedio),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  DateTime? _parseData(String valor) {
    final partes = valor.trim().split('/');

    if (partes.length != 3) {
      return null;
    }

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);

    if (dia == null || mes == null || ano == null) {
      return null;
    }

    final data = DateTime(ano, mes, dia);

    if (data.day != dia || data.month != mes || data.year != ano) {
      return null;
    }

    return data;
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }
}

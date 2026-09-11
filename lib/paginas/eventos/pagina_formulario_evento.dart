import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/evento_form_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/formatadores.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioEvento extends StatefulWidget {
  final bool edicao;
  final int? eventoId;
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaFormularioEvento({
    super.key,
    this.edicao = false,
    this.eventoId,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

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

  late final EventoFormViewModel _viewModel;

  int? _projetoId;
  int? _classeId;

  @override
  void initState() {
    super.initState();

    _viewModel = EventoFormViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    widget.sessaoViewModel.addListener(_aoMudarSessao);

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

  void _aoMudarSessao() {
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);

    _nome.dispose();
    _data.dispose();
    _local.dispose();
    _endereco.dispose();
    _objetivo.dispose();
    _viewModel.dispose();

    super.dispose();
  }

  Future<void> _salvar() async {
    final formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final data = _parseData(_data.text);
    final projetoId = _viewModel.projetoSelecionadoId ?? _projetoId;

    if (data == null || projetoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um projeto e informe uma data válida.'),
        ),
      );
      return;
    }

    final sucesso = await _viewModel.salvar(
      eventoId: widget.eventoId,
      projetoId: projetoId,
      classeEventoId: _classeId,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
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
                child!,
                const SizedBox(height: 24),
                CartaoConteudo(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _seletorProjeto(),
                      const SizedBox(height: 18),
                      _campoClasse(),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Nome do Evento',
                        hint: 'Ex.: Oficina de Dados Abertos',
                        icone: LucideIcons.calendar,
                        controller: _nome,
                        validator: _obrigatorio,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Data',
                        hint: 'DD/MM/AAAA',
                        icone: LucideIcons.calendar_days,
                        controller: _data,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FormatadorData()],
                        validator: (valor) {
                          return _parseData(valor ?? '') == null
                              ? 'Informe uma data válida'
                              : null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Local',
                        hint: 'Local do evento',
                        icone: LucideIcons.map_pin,
                        controller: _local,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Endereço',
                        hint: 'Endereço completo',
                        icone: LucideIcons.map,
                        controller: _endereco,
                        maxLength: 255,
                      ),
                      const SizedBox(height: 18),
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
      child: Text(
        widget.edicao
            ? 'Editar evento institucional'
            : 'Cadastrar evento institucional',
        style: Tipografia.headlineMedium.copyWith(color: Cores.textoPrincipal),
      ),
    );
  }

  Widget _seletorProjeto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projeto',
          style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
        ),
        const SizedBox(height: 8),
        CampoSelecao(
          label: 'Selecione o Projeto',
          valor: _viewModel.projetoSelecionadoId ?? _projetoId,
          itens: _viewModel.opcoesProjetos
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.nome),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _projetoId = value;
              _classeId = null;
            });
            _viewModel.selecionarProjeto(value);
          },
        ),
      ],
    );
  }

  Widget _campoClasse() {
    return CampoSelecao(
      label: 'Classe do Evento',
      valor: _classeId,
      itens: _viewModel.classes
          .map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(item.nome),
            ),
          )
          .toList(),
      onChanged: _aoSelecionarClasse,
      validator: _validarClasseEvento,
    );
  }

  void _aoSelecionarClasse(int? value) {
    setState(() {
      _classeId = value;
    });
  }

  String? _validarClasseEvento(int? value) {
    if (value == null) {
      return 'Selecione uma classe de evento';
    }

    return null;
  }

  Widget _construirCampoObjetivo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objetivo',
          style: Tipografia.labelLarge.copyWith(color: Cores.cinzaEscuro),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Cores.cinzaClaro,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  LucideIcons.target,
                  size: 20,
                  color: Cores.cinzaMedio,
                ),
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
                  style: Tipografia.bodyLarge.copyWith(
                    color: Cores.textoPrincipal,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Descreva o objetivo do evento',
                    hintStyle: Tipografia.bodyLarge.copyWith(
                      color: Cores.cinzaMedio,
                    ),
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

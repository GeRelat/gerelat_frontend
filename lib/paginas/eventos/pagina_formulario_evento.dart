import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/evento_form_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/app_shell.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

class PaginaFormularioEvento extends StatefulWidget {
  final bool edicao;

  const PaginaFormularioEvento({super.key, this.edicao = false});

  @override
  State<PaginaFormularioEvento> createState() =>
      _PaginaFormularioEventoState();
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
    _viewModel = EventoFormViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    )..carregarOpcoes();
  }

  @override
  void dispose() {
    _nome.dispose();
    _data.dispose();
    _local.dispose();
    _endereco.dispose();
    _objetivo.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _parseData(_data.text);
    if (data == null || _projetoId == null || _classeId == null) return;

    final sucesso = await _viewModel.salvar(
      projetoId: _projetoId!,
      classeEventoId: _classeId!,
      nome: _nome.text.trim(),
      data: data,
      local: _local.text.trim(),
      endereco: _endereco.text.trim(),
      objetivo: _objetivo.text.trim(),
    );
    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      secaoAtual: SecaoApp.eventos,
      titulo: widget.edicao ? 'Editar Evento' : 'Novo Evento',
      dicaPesquisa: 'Pesquisar eventos...',
      child: AnimatedBuilder(
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
                  Text(
                    'Cadastrar evento institucional',
                    style: Tipografia.headlineMedium.copyWith(
                      color: Cores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CartaoConteudo(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CampoSelecao(
                                label: 'Projeto',
                                valor: _projetoId,
                                itens: _viewModel.projetos
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item.id,
                                        child: Text(item.nome),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _projetoId = value),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: CampoSelecao(
                                label: 'Classe do Evento',
                                valor: _classeId,
                                itens: _viewModel.classes
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item.id,
                                        child: Text(item.nome),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _classeId = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        CampoFormulario(
                          label: 'Nome do Evento',
                          hint: 'Ex: Oficina de Dados Abertos',
                          icone: LucideIcons.calendar,
                          controller: _nome,
                          validator: _obrigatorio,
                        ),
                        const SizedBox(height: 18),
                        CampoFormulario(
                          label: 'Data',
                          hint: 'DD/MM/AAAA',
                          icone: LucideIcons.calendar_days,
                          controller: _data,
                          validator: (valor) => _parseData(valor ?? '') == null
                              ? 'Informe uma data válida'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        CampoFormulario(
                          label: 'Local',
                          hint: 'Local do evento',
                          icone: LucideIcons.map_pin,
                          controller: _local,
                        ),
                        const SizedBox(height: 18),
                        CampoFormulario(
                          label: 'Endereço',
                          hint: 'Endereço completo',
                          icone: LucideIcons.map,
                          controller: _endereco,
                        ),
                        const SizedBox(height: 18),
                        CampoFormulario(
                          label: 'Objetivo',
                          hint: 'Descreva o objetivo do evento',
                          icone: LucideIcons.target,
                          controller: _objetivo,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 28),
                        BarraAcoesFormulario(
                          textoPrimario: _viewModel.carregando
                              ? 'Salvando...'
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
      ),
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  DateTime? _parseData(String valor) {
    final partes = valor.trim().split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    final data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || data.year != ano) return null;
    return data;
  }
}

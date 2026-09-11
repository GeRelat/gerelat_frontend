import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/view_models/gerar_relatorio_view_model.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/nivel.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_catalogo.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaAgendarRelatorio extends StatefulWidget {
  final RepositorioCatalogo repositorioCatalogo;
  final SessaoViewModel sessaoViewModel;

  const PaginaAgendarRelatorio({
    super.key,
    required this.repositorioCatalogo,
    required this.sessaoViewModel,
  });

  @override
  State<PaginaAgendarRelatorio> createState() => _PaginaAgendarRelatorioState();
}

class _PaginaAgendarRelatorioState extends State<PaginaAgendarRelatorio> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  late final GerarRelatorioViewModel _viewModel;
  int? _templateId;

  // Parâmetros de Agendamento
  String _tipoAgendamento = 'pontual'; // 'pontual' ou 'recorrente'
  DateTime? _dataHoraExecucao;
  String _recorrencia = 'diario'; // 'diario', 'semanal', 'mensal'
  TimeOfDay _horarioExecucao = const TimeOfDay(hour: 8, minute: 0);
  int _diaSemana = 1; // 1 = Segunda, 7 = Domingo
  int _diaMes = 1; // 1 a 31
  bool _ativo = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _viewModel = GerarRelatorioViewModel(widget.repositorioCatalogo);
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    widget.sessaoViewModel.addListener(_aoMudarSessao);
    _viewModel.carregar();

    // Data hora default para amanhã às 08:00
    final amanha = DateTime.now().add(const Duration(days: 1));
    _dataHoraExecucao = DateTime(amanha.year, amanha.month, amanha.day, 8, 0);
  }

  void _aoMudarSessao() {
    _viewModel.definirContexto(
      widget.sessaoViewModel.clienteAtivoId,
      widget.sessaoViewModel.usuarioAtual,
    );
    if (_viewModel.template == null) {
      setState(() => _templateId = null);
    }
  }

  @override
  void dispose() {
    widget.sessaoViewModel.removeListener(_aoMudarSessao);
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataHoraExecucao() async {
    final agora = DateTime.now();
    final dataInicial = _dataHoraExecucao ?? agora.add(const Duration(days: 1));
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 365 * 5)),
    );
    if (data == null || !mounted) return;

    final horaInicial = TimeOfDay.fromDateTime(dataInicial);
    final hora = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );
    if (hora == null || !mounted) return;

    setState(() {
      _dataHoraExecucao = DateTime(
        data.year,
        data.month,
        data.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _selecionarHorarioExecucao() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horarioExecucao,
    );
    if (hora != null && mounted) {
      setState(() => _horarioExecucao = hora);
    }
  }

  Future<void> _salvarAgendamento() async {
    if (!_formKey.currentState!.validate() || _templateId == null) return;
    if (_tipoAgendamento == 'pontual' && _dataHoraExecucao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data e hora de execução.'),
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final horarioStr =
          '${_horarioExecucao.hour.toString().padLeft(2, '0')}:${_horarioExecucao.minute.toString().padLeft(2, '0')}:00';

      final documento = await _viewModel.obterDocumentoPreview();

      await widget.repositorioCatalogo.agendarRelatorio(
        nome: _nome.text.trim().isEmpty
            ? (_viewModel.template?.nome ?? 'Relatório Agendado')
            : _nome.text.trim(),
        templateId: _templateId!,
        clienteId: _viewModel.clienteId,
        programaId: _viewModel.programaId,
        projetoId: _viewModel.projetoId,
        eventoId: _viewModel.eventoId,
        documentoJson: documento,
        tipoAgendamento: _tipoAgendamento,
        dataHoraExecucao: _tipoAgendamento == 'pontual' ? _dataHoraExecucao : null,
        recorrencia: _tipoAgendamento == 'recorrente' ? _recorrencia : null,
        horarioExecucao: _tipoAgendamento == 'recorrente' ? horarioStr : null,
        diaSemana: (_tipoAgendamento == 'recorrente' && _recorrencia == 'semanal')
            ? _diaSemana
            : null,
        diaMes: (_tipoAgendamento == 'recorrente' && _recorrencia == 'mensal')
            ? _diaMes
            : null,
        ativo: _ativo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento de relatório criado com sucesso!'),
          backgroundColor: Cores.verdeSucesso,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao agendar relatório: $e'),
          backgroundColor: Cores.vermelhoErro,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando && _viewModel.templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final podeSalvar =
            _templateId != null &&
            _viewModel.escopoCompleto &&
            !_viewModel.carregando &&
            !_salvando;

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
                      CampoSelecao(
                        label: 'Programa',
                        valor: _viewModel.programaSelecionadoId,
                        itens: _viewModel.opcoesPrograma
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _templateId = null);
                          _viewModel.selecionarPrograma(value);
                        },
                      ),
                      const SizedBox(height: 18),
                      CampoSelecao(
                        label: 'Projeto',
                        valor: _viewModel.projetoSelecionadoId,
                        itens: _viewModel.opcoesProjeto
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _templateId = null);
                          _viewModel.selecionarProjeto(value);
                        },
                      ),
                      const SizedBox(height: 18),
                      if (_viewModel.projetoSelecionadoId == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Selecione o programa e o projeto para ver os '
                            'templates disponíveis.',
                            style: Tipografia.bodyMedium.copyWith(
                              color: Cores.cinzaMedio,
                            ),
                          ),
                        )
                      else if (_viewModel.templatesFiltrados.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Nenhum template disponível para este projeto.',
                            style: Tipografia.bodyMedium.copyWith(
                              color: Cores.cinzaMedio,
                            ),
                          ),
                        )
                      else
                        CampoSelecao(
                          label: 'Template',
                          valor: _templateId,
                          itens: _viewModel.templatesFiltrados
                              .where((template) => template.id != null)
                              .map(
                                (template) => DropdownMenuItem(
                                  value: template.id,
                                  child: Text(
                                    '${template.nome} (${_viewModel.nomeOrigemTemplate(template)})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _templateId = value);
                            _viewModel.selecionarTemplate(value);
                          },
                        ),
                      if (_templateId != null) ...[
                        const SizedBox(height: 18),
                        ..._seletorEvento(),
                        _painelAvisos(),
                      ],
                      const SizedBox(height: 18),
                      CampoFormulario(
                        label: 'Nome do relatório agendado',
                        hint: 'Ex: Relatório Mensal Recorrente',
                        icone: LucideIcons.file_text,
                        controller: _nome,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Configurações de Agendamento',
                        style: Tipografia.titleLarge.copyWith(
                          color: Cores.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _secaoAgendamento(),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          BotaoPrimario(
                            texto: _salvando ? 'Agendando...' : 'Agendar Relatório',
                            icone: LucideIcons.calendar_plus,
                            onPressed: podeSalvar ? _salvarAgendamento : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geração Autônoma de Relatório',
            style: Tipografia.headlineMedium.copyWith(
              color: Cores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure a geração automática de relatórios de forma pontual '
            'ou com frequência recorrente. O sistema irá gerar o documento no '
            'horário programado.',
            style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro),
          ),
        ],
      ),
    );
  }

  Widget _secaoAgendamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text('Execução Pontual'),
              selected: _tipoAgendamento == 'pontual',
              onSelected: (_) => setState(() => _tipoAgendamento = 'pontual'),
              selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Execução Recorrente'),
              selected: _tipoAgendamento == 'recorrente',
              onSelected: (_) => setState(() => _tipoAgendamento = 'recorrente'),
              selectedColor: Cores.azulAcao.withValues(alpha: 0.16),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_tipoAgendamento == 'pontual') ...[
          Text(
            'Data e Hora da Execução',
            style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _selecionarDataHoraExecucao,
            icon: const Icon(LucideIcons.calendar, size: 18),
            label: Text(
              _dataHoraExecucao == null
                  ? 'Selecionar Data e Hora'
                  : '${_dataHoraExecucao!.day.toString().padLeft(2, '0')}/${_dataHoraExecucao!.month.toString().padLeft(2, '0')}/${_dataHoraExecucao!.year} às ${_dataHoraExecucao!.hour.toString().padLeft(2, '0')}:${_dataHoraExecucao!.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequência',
                      style: Tipografia.labelLarge.copyWith(
                        color: Cores.cinzaEscuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _recorrencia,
                      items: const [
                        DropdownMenuItem(value: 'diario', child: Text('Diário')),
                        DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                        DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _recorrencia = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Cores.cinzaClaro,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horário de Execução',
                      style: Tipografia.labelLarge.copyWith(
                        color: Cores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selecionarHorarioExecucao,
                      icon: const Icon(LucideIcons.clock, size: 18),
                      label: Text(
                        '${_horarioExecucao.hour.toString().padLeft(2, '0')}:${_horarioExecucao.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_recorrencia == 'semanal') ...[
            const SizedBox(height: 18),
            CampoSelecao(
              label: 'Dia da Semana',
              valor: _diaSemana,
              itens: const [
                DropdownMenuItem(value: 1, child: Text('Segunda-feira')),
                DropdownMenuItem(value: 2, child: Text('Terça-feira')),
                DropdownMenuItem(value: 3, child: Text('Quarta-feira')),
                DropdownMenuItem(value: 4, child: Text('Quinta-feira')),
                DropdownMenuItem(value: 5, child: Text('Sexta-feira')),
                DropdownMenuItem(value: 6, child: Text('Sábado')),
                DropdownMenuItem(value: 7, child: Text('Domingo')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _diaSemana = val);
              },
            ),
          ],
          if (_recorrencia == 'mensal') ...[
            const SizedBox(height: 18),
            CampoSelecao(
              label: 'Dia do Mês',
              valor: _diaMes,
              itens: List.generate(
                31,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Dia ${i + 1}'),
                ),
              ),
              onChanged: (val) {
                if (val != null) setState(() => _diaMes = val);
              },
            ),
          ],
        ],
        const SizedBox(height: 18),
        SwitchListTile(
          title: Text(
            'Agendamento Ativo',
            style: Tipografia.labelLarge.copyWith(color: Cores.textoPrincipal),
          ),
          subtitle: Text(
            'Desative caso queira pausar temporariamente a execução automática.',
            style: Tipografia.bodySmall.copyWith(color: Cores.cinzaMedio),
          ),
          value: _ativo,
          activeTrackColor: Cores.azulAcao,
          onChanged: (val) => setState(() => _ativo = val),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  List<Widget> _seletorEvento() {
    if (!_viewModel.niveisASelecionar.contains(NivelAplicacao.evento)) {
      return const [];
    }
    return [
      CampoSelecao(
        label: 'Evento',
        valor: _viewModel.eventoId,
        itens: _viewModel
            .opcoesDe(NivelAplicacao.evento)
            .map(
              (item) => DropdownMenuItem(
                value: item.id,
                child: Text(item.nome),
              ),
            )
            .toList(),
        onChanged: (value) =>
            _viewModel.definirEscopo(NivelAplicacao.evento, value),
        validator: (_) => null,
      ),
      const SizedBox(height: 18),
    ];
  }

  Widget _painelAvisos() {
    final avisos = <Widget>[];

    final escopoIncompleto = _viewModel.mensagemEscopoIncompleto;
    if (escopoIncompleto != null) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.triangle_alert,
          cor: Cores.ambarAlerta,
          texto: escopoIncompleto,
        ),
      );
    }

    if (_viewModel.refsNaoContempladas.isNotEmpty) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.circle_alert,
          cor: Cores.ambarAlerta,
          titulo: 'Variáveis não contempladas',
          texto:
              'O template referencia variáveis que não existem neste escopo. '
              'Elas sairão no documento como o próprio nome entre colchetes:\n'
              '${_viewModel.refsNaoContempladas.map((ref) => '• $ref').join('\n')}',
        ),
      );
    }

    final obrigatorias = _viewModel.obrigatoriasUsadas;
    if (obrigatorias.isNotEmpty) {
      avisos.add(
        _painelInformativo(
          icone: LucideIcons.list_checks,
          cor: Cores.azulAcao,
          titulo: 'Variáveis obrigatórias em uso',
          texto:
              'Confira em "Valores de variáveis" se estas estarão preenchidas '
              'no momento da execução do agendamento:\n'
              '${obrigatorias.map((v) => '• ${v.referencia} (${v.nivelAplicacao.rotulo})').join('\n')}',
        ),
      );
    }

    if (avisos.isEmpty) {
      return _painelInformativo(
        icone: LucideIcons.circle_check,
        cor: Cores.verdeSucesso,
        texto: 'Todas as variáveis do template serão resolvidas.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final aviso in avisos)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: aviso),
      ],
    );
  }

  Widget _painelInformativo({
    required IconData icone,
    required Color cor,
    String? titulo,
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) ...[
                  Text(
                    titulo,
                    style: Tipografia.labelLarge.copyWith(color: cor),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  texto,
                  style: Tipografia.bodyMedium.copyWith(
                    color: Cores.cinzaEscuro,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

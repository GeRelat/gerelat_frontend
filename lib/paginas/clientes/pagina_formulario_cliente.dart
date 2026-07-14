import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gerelat_frontend/aplicacao/dependencias.dart';
import 'package:gerelat_frontend/aplicacao/view_models/cliente_form_view_model.dart';
import 'package:gerelat_frontend/nucleo/componentes/painel_ui.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:gerelat_frontend/nucleo/utils/formatadores.dart';
import 'package:gerelat_frontend/nucleo/utils/validadores.dart';
import 'package:go_router/go_router.dart';

class PaginaFormularioCliente extends StatefulWidget {
  final bool edicao;
  final int? clienteId;

  const PaginaFormularioCliente({
    super.key,
    this.edicao = false,
    this.clienteId,
  });

  @override
  State<PaginaFormularioCliente> createState() =>
      _PaginaFormularioClienteState();
}

class _PaginaFormularioClienteState extends State<PaginaFormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cnpj = TextEditingController();
  final _nomeContato = TextEditingController();
  final _emailContato = TextEditingController();
  final _foneContato = TextEditingController();
  final _numeroContrato = TextEditingController();
  final _dataTerminoContrato = TextEditingController();
  late final ClienteFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ClienteFormViewModel(
      DependenciasApp.instancia.repositorioCatalogo,
    );
    final clienteId = widget.clienteId;
    if (widget.edicao && clienteId != null) {
      _viewModel.carregar(clienteId).then((_) {
        final cliente = _viewModel.cliente;
        if (!mounted || cliente == null) return;
        _nome.text = cliente.nome;
        _cnpj.text = cliente.cnpj;
        _nomeContato.text = cliente.nomeContato;
        _emailContato.text = cliente.emailContato;
        _foneContato.text = cliente.foneContato;
        _numeroContrato.text = cliente.numeroContrato;
        _dataTerminoContrato.text = cliente.dataTerminoContrato == null
            ? ''
            : _formatarData(cliente.dataTerminoContrato!);
      });
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _cnpj.dispose();
    _nomeContato.dispose();
    _emailContato.dispose();
    _foneContato.dispose();
    _numeroContrato.dispose();
    _dataTerminoContrato.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _parseData(_dataTerminoContrato.text);
    if (data == null) return;

    final sucesso = await _viewModel.salvar(
      clienteId: widget.clienteId,
      nome: _nome.text.trim(),
      cnpj: _cnpj.text.trim(),
      nomeContato: _nomeContato.text.trim(),
      emailContato: _emailContato.text.trim(),
      foneContato: _foneContato.text.trim(),
      numeroContrato: _numeroContrato.text.trim(),
      dataTerminoContrato: data,
    );
    if (!mounted) return;
    if (sucesso) {
      context.pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.mensagemErro ?? 'Erro ao salvar.')),
    );
  }

  Future<void> _excluir() async {
    final clienteId = widget.clienteId;
    if (clienteId == null) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: const Text(
          'Tem certeza de que deseja excluir este cliente? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Cores.vermelhoErro),
            ),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final sucesso = await _viewModel.excluir(clienteId);
    if (!mounted) return;
    if (sucesso) {
      context.pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.mensagemErro ?? 'Erro ao excluir cliente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        // Só se aplica ao carregamento inicial em modo edição: sem essas
        // duas checagens, uma falha no GET do cliente deixava o formulário
        // em branco e mudo — indistinguível de um cadastro novo — porque
        // `build()` nunca lia `mensagemErro`/`carregando` do ViewModel.
        if (widget.edicao &&
            _viewModel.carregando &&
            _viewModel.cliente == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.edicao &&
            _viewModel.mensagemErro != null &&
            _viewModel.cliente == null) {
          final clienteId = widget.clienteId;
          return EstadoVazio(
            icone: LucideIcons.circle_alert,
            titulo: 'Não foi possível carregar o cliente',
            descricao: _viewModel.mensagemErro!,
            acao: 'Tentar novamente',
            onAcao: clienteId == null
                ? null
                : () => _viewModel.carregar(clienteId),
          );
        }
        return _conteudoFormulario(context);
      },
    );
  }

  Widget _conteudoFormulario(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.edicao ? 'Editar cliente' : 'Cadastrar cliente',
                    style: Tipografia.headlineMedium.copyWith(
                      color: Cores.textoPrincipal,
                    ),
                  ),
                ),
                if (widget.edicao)
                  TextButton.icon(
                    onPressed: _viewModel.carregando ? null : _excluir,
                    icon: const Icon(
                      LucideIcons.trash_2,
                      size: 18,
                      color: Cores.vermelhoErro,
                    ),
                    label: const Text(
                      'Excluir',
                      style: TextStyle(color: Cores.vermelhoErro),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            CartaoConteudo(
              child: Column(
                children: [
                  CampoFormulario(
                    label: 'Nome do Cliente',
                    hint: 'Ex: Secretaria de Inovação',
                    icone: LucideIcons.building_2,
                    controller: _nome,
                    validator: _obrigatorio,
                  ),
                  const SizedBox(height: 18),
                  CampoFormulario(
                    label: 'CNPJ',
                    hint: '00.000.000/0000-00',
                    icone: LucideIcons.hash,
                    controller: _cnpj,
                    validator: _validarCnpj,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoFormulario(
                          label: 'Nome do Contato',
                          hint: 'Nome do responsável',
                          icone: LucideIcons.user,
                          controller: _nomeContato,
                          validator: _obrigatorio,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: CampoFormulario(
                          label: 'E-mail do Contato',
                          hint: 'contato@cliente.com',
                          icone: LucideIcons.mail,
                          controller: _emailContato,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validarEmail,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoFormulario(
                          label: 'Telefone do Contato',
                          hint: '(00) 0 00.00.00.00',
                          icone: LucideIcons.phone,
                          controller: _foneContato,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FormatadorTelefone()],
                          validator: _validarTelefone,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: CampoFormulario(
                          label: 'Número do Contrato',
                          hint: 'Ex: 123/2026',
                          icone: LucideIcons.signature,
                          controller: _numeroContrato,
                          validator: _obrigatorio,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CampoFormulario(
                    label: 'Término do Contrato',
                    hint: 'DD/MM/AAAA',
                    icone: LucideIcons.calendar_days,
                    controller: _dataTerminoContrato,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FormatadorData()],
                    validator: (valor) => _parseData(valor ?? '') == null
                        ? 'Informe uma data válida'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  BarraAcoesFormulario(
                    textoPrimario: _viewModel.carregando
                        ? 'Salvando...'
                        : widget.edicao
                        ? 'Salvar Cliente'
                        : 'Criar Cliente',
                    onSalvar: _viewModel.carregando ? null : _salvar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _validarCnpj(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (!cnpjValido(valor!)) return 'CNPJ inválido';
    return null;
  }

  String? _validarEmail(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (!emailValido(valor!)) return 'E-mail inválido';
    return null;
  }

  String? _validarTelefone(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (!telefoneValido(valor!)) return 'Telefone inválido';
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

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}

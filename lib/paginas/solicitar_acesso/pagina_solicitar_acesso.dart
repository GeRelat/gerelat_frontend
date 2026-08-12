import 'package:flutter/material.dart';
import 'package:gerelat_frontend/aplicacao/view_models/sessao_view_model.dart';
import 'package:gerelat_frontend/dominio/entidades/opcao_selecao.dart';
import 'package:gerelat_frontend/dominio/repositorios/repositorio_autenticacao.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';
import 'package:go_router/go_router.dart';

class PaginaSolicitarAcesso extends StatefulWidget {
  final RepositorioAutenticacao repositorioAutenticacao;
  final SessaoViewModel sessao;

  const PaginaSolicitarAcesso({
    super.key,
    required this.repositorioAutenticacao,
    required this.sessao,
  });

  @override
  State<PaginaSolicitarAcesso> createState() => _PaginaSolicitarAcessoState();
}

class _PaginaSolicitarAcessoState extends State<PaginaSolicitarAcesso> {
  final _chaveFormulario = GlobalKey<FormState>();
  List<OpcaoSelecao> _clientes = const [];
  int? _clienteSelecionadoId;
  bool _carregando = true;
  bool _enviando = false;
  String? _erro;
  String? _mensagemSucesso;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final clientes = await widget.repositorioAutenticacao.listarClientesPublicos();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _solicitarAcesso() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _erro = null;
      _mensagemSucesso = null;
    });

    final resultado = await widget.repositorioAutenticacao.solicitarAcessoCliente(
      clienteId: _clienteSelecionadoId!,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.sucesso) {
      setState(() {
        _mensagemSucesso =
            'Solicitação enviada. Aguarde a aprovação de um responsável pelo cliente.';
      });
      return;
    }

    setState(() {
      _erro = _formatarMensagem(
        resultado.mensagemErro ?? 'Não foi possível enviar a solicitação.',
      );
    });
  }

  String _formatarMensagem(String texto) {
    var limpo = texto.trim();
    if (limpo.contains('ao receber')) {
      final idx = limpo.indexOf('ao receber');
      limpo = limpo.substring(idx + 'ao receber'.length).trim();
    }
    while ((limpo.startsWith('[') && limpo.endsWith(']')) ||
        (limpo.startsWith('"') && limpo.endsWith('"')) ||
        (limpo.startsWith("'") && limpo.endsWith("'"))) {
      limpo = limpo.substring(1, limpo.length - 1).trim();
    }
    return limpo.isEmpty ? 'Não foi possível enviar a solicitação.' : limpo;
  }

  void _voltar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _sair() async {
    await widget.sessao.sair();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final possuiAcesso =
        widget.sessao.usuarioAtual?.possuiContextoAcesso ?? false;

    return PopScope(
      canPop: possuiAcesso,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !possuiAcesso) {
          _sair();
        }
      },
      child: Scaffold(
        backgroundColor: Cores.fundoPagina,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Cores.branco,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Cores.pretoProfundo.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: _carregando
                  ? _construirCarregando()
                  : _construirConteudo(possuiAcesso),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCarregando() {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _construirConteudo(bool possuiAcesso) {
    return Form(
      key: _chaveFormulario,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (possuiAcesso) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _voltar,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar'),
                style: TextButton.styleFrom(
                  foregroundColor: Cores.cinzaEscuro,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Solicite acesso a um cliente',
            style: Tipografia.headlineMediumDestaque.copyWith(
              color: Cores.pretoProfundo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            possuiAcesso
                ? 'Selecione o cliente ao qual você deseja solicitar acesso para ser aprovado pelos responsáveis.'
                : 'Sua conta está ativa, mas não possui vínculo com nenhum cliente, programa ou projeto. Selecione o cliente ao qual você pertence para pedir aprovação.',
            style: Tipografia.bodyMedium.copyWith(
              color: Cores.cinzaEscuro,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<int>(
            initialValue: _clienteSelecionadoId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Cliente',
              hintText: _clientes.isEmpty
                  ? 'Nenhum cliente disponível'
                  : 'Selecione o cliente',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            items: [
              for (final cliente in _clientes)
                DropdownMenuItem(value: cliente.id, child: Text(cliente.nome)),
            ],
            onChanged: _clientes.isEmpty
                ? null
                : (valor) => setState(() => _clienteSelecionadoId = valor),
            validator: (valor) => valor == null ? 'Selecione o cliente' : null,
          ),
          if (_erro != null) ...[
            const SizedBox(height: 16),
            Text(
              _erro!,
              style: Tipografia.bodyMedium.copyWith(color: Cores.vermelhoErro),
              textAlign: TextAlign.center,
            ),
          ],
          if (_mensagemSucesso != null) ...[
            const SizedBox(height: 16),
            Text(
              _mensagemSucesso!,
              style: Tipografia.bodyMedium.copyWith(color: Cores.verdeTextoEscuro),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _enviando || _clientes.isEmpty ? null : _solicitarAcesso,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Solicitar acesso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Cores.azulAcao,
              foregroundColor: Cores.branco,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _sair, child: const Text('Sair da conta')),
        ],
      ),
    );
  }
}

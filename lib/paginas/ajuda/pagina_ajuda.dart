import 'package:flutter/material.dart';

import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

import 'package:gerelat_frontend/paginas/ajuda/componentes/card_categoria_ajuda.dart';
import 'package:gerelat_frontend/paginas/ajuda/componentes/modal_categoria_ajuda.dart';

class PaginaAjuda extends StatefulWidget {
  const PaginaAjuda({super.key});

  @override
  State<PaginaAjuda> createState() => _PaginaAjudaState();
}

class _PaginaAjudaState extends State<PaginaAjuda> {
  final TextEditingController _buscaController = TextEditingController();

  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        int quantidadeColunas;

        if (largura < 700) {
          quantidadeColunas = 1;
        } else if (largura < 1100) {
          quantidadeColunas = 2;
        } else {
          quantidadeColunas = 3;
        }

        final categorias = _categoriasFiltradas();

        return SingleChildScrollView(
          padding: EdgeInsets.all(largura < 700 ? 20 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Central de Ajuda',
                    style: Tipografia.headlineMedium.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  Text('Encontre respostas para suas dúvidas e aprenda a utilizar o GeRelat.', style: Tipografia.bodyLarge.copyWith(color: Cores.cinzaEscuro)),

                  const SizedBox(height: 28),

                  _campoBusca(),

                  const SizedBox(height: 32),

                  _cardPrimeiroRelatorio(),

                  const SizedBox(height: 36),

                  Text(
                    'Categorias',
                    style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 6),

                  Text('Escolha um tema para encontrar orientações sobre o sistema.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),

                  const SizedBox(height: 20),

                  if (categorias.isEmpty)
                    _semResultados()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categorias.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: quantidadeColunas, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: quantidadeColunas == 1 ? 2.5 : 2.2),
                      itemBuilder: (context, index) {
                        final categoria = categorias[index];

                        return CardCategoriaAjuda(
                          titulo: categoria.titulo,
                          descricao: categoria.descricao,
                          icone: categoria.icone,
                          onTap: () {
                            mostrarModalCategoriaAjuda(context: context, titulo: categoria.titulo, descricao: categoria.descricaoModal, icone: categoria.icone, topicos: categoria.topicos);
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  _blocoSuporte(),

                  const SizedBox(height: 20),

                  _dica(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardPrimeiroRelatorio() {
    return Material(
      color: Cores.branco,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          mostrarModalCategoriaAjuda(
            context: context,
            titulo: 'Como gerar meu primeiro relatório?',
            descricao: 'Antes de criar novos registros, verifique o que já existe no GeRelat. A geração utiliza informações cadastradas na organização, no programa, no projeto, nas variáveis, nos eventos e nos templates.',
            icone: Icons.description_outlined,
            topicos: const [
              '1. Confira a organização ativa. Exemplo: BRISA.',
              '2. Acesse Programas e verifique se o programa relacionado ao relatório já existe. Exemplo: TIC55.',
              '3. Dentro do contexto do programa, confirme se o projeto correspondente já está cadastrado. Exemplo: FURG2025.1 – TIC55.',
              '4. Acesse Variáveis e confira se as informações necessárias ao documento já estão definidas.',
              '5. Em Valores das Variáveis, preencha ou revise os conteúdos necessários no nível Cliente, Programa ou Projeto.',
              '6. Quando o relatório estiver relacionado a uma atividade, confirme se o evento correspondente está cadastrado.',
              '7. Verifique se já existe um template adequado. Não é necessário criar um novo template para cada relatório.',
              '8. Volte ao Dashboard e utilize “Criar Novo Relatório” > “Começar agora”.',
              '9. Selecione o contexto e o modelo apresentados pelo sistema.',
              '10. Revise os dados inseridos automaticamente antes de finalizar ou baixar o documento.',
            ],
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Cores.azulAcao.withValues(alpha: 0.35)),
            color: Cores.azulAcao.withValues(alpha: 0.04),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final celular = constraints.maxWidth < 700;

              final icone = Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(color: Cores.azulAcao.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.description_outlined, size: 30, color: Cores.azulAcao),
              );

              final texto = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Cores.azulAcao.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      'COMECE POR AQUI',
                      style: Tipografia.labelMedium.copyWith(color: Cores.azulAcao, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Como gerar meu primeiro relatório?',
                    style: Tipografia.titleLarge.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  Text('Veja o passo a passo desde a escolha da organização até a revisão do documento.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro, height: 1.4)),
                ],
              );

              final botao = ElevatedButton.icon(
                onPressed: () {
                  mostrarModalCategoriaAjuda(
                    context: context,
                    titulo: 'Como gerar meu primeiro relatório?',
                    descricao: 'Antes de criar novos registros, verifique o que já existe no GeRelat. A geração utiliza informações cadastradas na organização, no programa, no projeto, nas variáveis, nos eventos e nos templates.',
                    icone: Icons.description_outlined,
                    topicos: const [
                      '1. Confira a organização ativa. Exemplo: BRISA.',
                      '2. Acesse Programas e verifique se o programa relacionado ao relatório já existe. Exemplo: TIC55.',
                      '3. Dentro do contexto do programa, confirme se o projeto correspondente já está cadastrado. Exemplo: FURG2025.1 – TIC55.',
                      '4. Acesse Variáveis e confira se as informações necessárias ao documento já estão definidas.',
                      '5. Em Valores das Variáveis, preencha ou revise os conteúdos necessários no nível Cliente, Programa ou Projeto.',
                      '6. Quando o relatório estiver relacionado a uma atividade, confirme se o evento correspondente está cadastrado.',
                      '7. Verifique se já existe um template adequado. Não é necessário criar um novo template para cada relatório.',
                      '8. Volte ao Dashboard e utilize “Criar Novo Relatório” > “Começar agora”.',
                      '9. Selecione o contexto e o modelo apresentados pelo sistema.',
                      '10. Revise os dados inseridos automaticamente antes de finalizar ou baixar o documento.',
                    ],
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver passo a passo'),
              );

              if (celular) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [icone, const SizedBox(height: 18), texto, const SizedBox(height: 18), botao]);
              }

              return Row(
                children: [
                  icone,
                  const SizedBox(width: 20),
                  Expanded(child: texto),
                  const SizedBox(width: 24),
                  botao,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _campoBusca() {
    return TextField(
      controller: _buscaController,
      onChanged: (valor) {
        setState(() {
          _busca = valor;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar por um tema, palavra-chave ou funcionalidade...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _busca.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _buscaController.clear();

                  setState(() {
                    _busca = '';
                  });
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Cores.branco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.bordaSutil),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.bordaSutil),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.azulAcao, width: 1.5),
        ),
      ),
    );
  }

  Widget _semResultados() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.bordaSutil),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 42, color: Cores.cinzaMedio),

          const SizedBox(height: 12),

          Text(
            'Nenhum conteúdo encontrado',
            style: Tipografia.titleMedium.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          Text('Tente pesquisar por outro termo.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),
        ],
      ),
    );
  }

  Widget _blocoSuporte() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Cores.branco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.bordaSutil),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final celular = constraints.maxWidth < 700;

          final textoSuporte = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precisa de mais ajuda?',
                style: Tipografia.titleMedium.copyWith(color: Cores.textoPrincipal, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 8),

              Text('Se você não encontrou o que precisava, entre em contato com o suporte GeRelat.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),

              const SizedBox(height: 18),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _mostrarMensagem('Entre em contato pelo e-mail contato@gerelat.tech');
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Chamar suporte'),
                  ),

                  OutlinedButton.icon(
                    onPressed: () {
                      _mostrarMensagem('E-mail: contato@gerelat.tech');
                    },
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Enviar e-mail'),
                  ),
                ],
              ),
            ],
          );

          final informacoes = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Cores.azulAcao.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atendimento',
                  style: Tipografia.labelLarge.copyWith(color: Cores.azulAcao, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Cores.azulAcao),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Segunda a sexta, das 8h às 18h', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 18, color: Cores.azulAcao),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('contato@gerelat.tech', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (celular) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [textoSuporte, const SizedBox(height: 24), informacoes]);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: textoSuporte),

              const SizedBox(width: 32),

              Container(width: 1, height: 120, color: Cores.bordaSutil),

              const SizedBox(width: 32),

              Expanded(flex: 2, child: informacoes),
            ],
          );
        },
      ),
    );
  }

  Widget _dica() {
    return Row(
      children: [
        const Icon(Icons.lightbulb_outline, size: 20, color: Cores.azulAcao),

        const SizedBox(width: 10),

        Expanded(
          child: Text('Dica: antes de criar um novo cadastro, verifique se a informação já existe no GeRelat.', style: Tipografia.bodyMedium.copyWith(color: Cores.cinzaEscuro)),
        ),
      ],
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<_CategoriaAjuda> _categoriasFiltradas() {
    final categorias = _categorias;

    if (_busca.trim().isEmpty) {
      return categorias;
    }

    final termo = _busca.toLowerCase().trim();

    return categorias.where((categoria) {
      final titulo = categoria.titulo.toLowerCase();
      final descricao = categoria.descricao.toLowerCase();
      final descricaoModal = categoria.descricaoModal.toLowerCase();

      final topicoEncontrado = categoria.topicos.any((topico) => topico.toLowerCase().contains(termo));

      return titulo.contains(termo) || descricao.contains(termo) || descricaoModal.contains(termo) || topicoEncontrado;
    }).toList();
  }
}

class _CategoriaAjuda {
  final String titulo;
  final String descricao;
  final String descricaoModal;
  final IconData icone;
  final List<String> topicos;

  const _CategoriaAjuda({required this.titulo, required this.descricao, required this.descricaoModal, required this.icone, required this.topicos});
}

const List<_CategoriaAjuda> _categorias = [
  _CategoriaAjuda(
    titulo: 'Clientes',
    descricao: 'Entenda o contexto da organização e o acesso aos dados.',
    descricaoModal: 'O Cliente, também chamado de Organização, define o contexto principal em que o usuário trabalha no GeRelat. Programas, projetos, variáveis, eventos e relatórios são organizados a partir desse contexto.',
    icone: Icons.business_outlined,
    topicos: [
      'Antes de iniciar qualquer atividade, confira no menu lateral qual organização está selecionada.',
      'Exemplo: se a organização ativa for BRISA, o sistema apresentará os dados vinculados ao contexto da BRISA.',
      'A área Clientes reúne o cadastro e as informações das organizações atendidas pelo GeRelat.',
      'Usuários que ainda não possuem acesso a uma organização podem utilizar a opção “Solicitar outro cliente”.',
      'Não é necessário cadastrar novamente um cliente para cada relatório. Os dados existentes devem ser reutilizados.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Programas e Projetos',
    descricao: 'Entenda como programas e projetos organizam as informações.',
    descricaoModal: 'Programas e Projetos organizam as iniciativas desenvolvidas dentro de uma organização. O Programa representa um nível mais amplo e pode reunir diferentes projetos.',
    icone: Icons.folder_outlined,
    topicos: [
      'Exemplo de Programa: TIC55.',
      'Exemplo de Projeto vinculado ao programa: FURG2025.1 – TIC55.',
      'Antes de cadastrar um novo programa ou projeto, verifique se ele já existe no sistema.',
      'Informações cadastradas no nível do Programa podem ser reutilizadas pelos projetos relacionados.',
      'Na versão atual do GeRelat, a criação de um projeto é iniciada pela área Programas, utilizando o botão “Novo Projeto”.',
      'A área Programas também apresenta indicadores relacionados aos projetos e eventos existentes.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Variáveis',
    descricao: 'Defina quais informações poderão ser utilizadas nos documentos.',
    descricaoModal: 'As variáveis são campos de informação que o GeRelat utiliza para estruturar dados que poderão ser inseridos automaticamente nos templates e relatórios.',
    icone: Icons.data_object_outlined,
    topicos: [
      'Uma variável representa qual informação o sistema precisa conhecer.',
      'Exemplo: a variável “numero_participantes” representa a informação número de participantes.',
      'A criação da variável não significa que seu conteúdo já foi preenchido.',
      'As variáveis podem ser definidas nos níveis Cliente, Programa ou Projeto.',
      'Use o nível Cliente para informações institucionais da organização.',
      'Use o nível Programa para informações comuns aos projetos daquele programa.',
      'Use o nível Projeto para informações específicas de uma iniciativa.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Valores das Variáveis',
    descricao: 'Preencha os conteúdos das variáveis de Cliente, Programa ou Projeto.',
    descricaoModal: 'Valores das Variáveis é a área utilizada para informar o conteúdo concreto das variáveis previamente definidas.',
    icone: Icons.edit_note_outlined,
    topicos: [
      'Primeiro escolha o nível em que deseja preencher as informações: Cliente, Programa ou Projeto.',
      'Depois selecione a entidade correspondente.',
      'Exemplo: variável “numero_participantes” → valor “35”.',
      'Uma informação institucional da BRISA pode ser preenchida no nível Cliente.',
      'Uma informação comum ao TIC55 pode ser preenchida no nível Programa.',
      'Um resultado específico de FURG2025.1 – TIC55 pode ser preenchido no nível Projeto.',
      'Variáveis de níveis superiores podem aparecer em níveis inferiores, permitindo reutilizar informações sem preencher o mesmo dado várias vezes.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Eventos',
    descricao: 'Entenda como as atividades são registradas e utilizadas nos relatórios.',
    descricaoModal: 'Eventos representam atividades realizadas dentro do contexto dos programas e projetos e podem ser utilizados como parte da geração de relatórios.',
    icone: Icons.calendar_month_outlined,
    topicos: [
      'Um evento deve estar relacionado ao contexto correto do programa ou projeto.',
      'Exemplo: Programa TIC55 → Projeto FURG2025.1 – TIC55 → Evento “Workshop de apresentação dos projetos”.',
      'O evento pode reunir informações como nome, data, local, objetivo e demais dados da atividade.',
      'Quando o relatório estiver relacionado a uma atividade específica, confira se o evento correspondente já está cadastrado.',
      'Não é necessário cadastrar novamente um evento que já esteja disponível no sistema.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Templates',
    descricao: 'Entenda os modelos utilizados para gerar os documentos.',
    descricaoModal: 'O Template é o modelo estruturado utilizado pelo GeRelat para compor um relatório. Ele define a organização do documento e pode utilizar informações cadastradas no sistema.',
    icone: Icons.content_copy_outlined,
    topicos: [
      'O template não é o relatório final. Ele funciona como o modelo utilizado para gerar o documento.',
      'Um template pode utilizar informações do Cliente, Programa, Projeto, Eventos e Variáveis.',
      'Durante a geração, o GeRelat utiliza os valores cadastrados para preencher as informações previstas no template.',
      'Antes de criar um novo template, verifique se já existe um modelo adequado.',
      'Um template não precisa ser criado para cada relatório.',
      'Quando já existir um padrão que atenda ao documento desejado, reutilize o template existente.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Relatórios',
    descricao: 'Veja o que conferir antes de iniciar a geração de um relatório.',
    descricaoModal: 'A geração de relatórios utiliza informações previamente cadastradas no GeRelat. Antes de iniciar, confira se o contexto e os dados necessários estão disponíveis.',
    icone: Icons.description_outlined,
    topicos: [
      'Confira se está trabalhando na organização correta. Exemplo: BRISA.',
      'Verifique se o programa já existe. Exemplo: TIC55.',
      'Verifique se o projeto correspondente já está cadastrado. Exemplo: FURG2025.1 – TIC55.',
      'Confira se as variáveis necessárias ao documento estão definidas.',
      'Acesse Valores das Variáveis e revise se os dados necessários estão preenchidos.',
      'Quando o relatório estiver relacionado a uma atividade, confirme se o evento correspondente está cadastrado.',
      'Verifique se já existe um template adequado ao documento.',
      'No Dashboard, utilize “Criar Novo Relatório” e selecione “Começar agora”.',
      'Selecione o contexto e o modelo disponíveis.',
      'Revise as informações preenchidas automaticamente antes de finalizar ou baixar o relatório.',
    ],
  ),

  _CategoriaAjuda(
    titulo: 'Imagens',
    descricao: 'Gerencie imagens e logomarcas utilizadas pelo sistema.',
    descricaoModal: 'A área de Imagens reúne arquivos visuais que podem ser utilizados em diferentes partes do GeRelat, inclusive em programas, projetos, templates e documentos.',
    icone: Icons.image_outlined,
    topicos: [
      'Utilize a galeria para consultar imagens já cadastradas antes de enviar um novo arquivo.',
      'Imagens podem representar logomarcas de organizações, programas, projetos ou outros elementos visuais.',
      'Quando houver uma imagem disponível na galeria, ela poderá ser reutilizada.',
      'Evite cadastrar várias vezes o mesmo arquivo quando ele já estiver disponível no sistema.',
    ],
  ),
];

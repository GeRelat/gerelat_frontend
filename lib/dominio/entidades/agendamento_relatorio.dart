import 'package:gerelat_frontend/dominio/entidades/nivel.dart';

class AgendamentoRelatorio {
  final int id;
  final String nome;
  final int templateId;
  final String templateNome;
  final int? clienteId;
  final String clienteNome;
  final int? programaId;
  final String programaNome;
  final int? projetoId;
  final String projetoNome;
  final int? eventoId;
  final int? criadoPorId;
  final String criadoPorNome;
  final Map<String, dynamic>? documentoJson;
  final String tipoAgendamento; // 'pontual' ou 'recorrente'
  final String? dataHoraExecucao;
  final String? recorrencia; // 'diario', 'semanal', 'mensal'
  final String? horarioExecucao;
  final int? diaSemana; // 0=Seg, 6=Dom
  final int? diaMes;
  final bool ativo;
  final String dataCriacao;
  final String ultimaAtualizacao;
  final String? ultimaExecucao;
  final String? proximaExecucao;

  const AgendamentoRelatorio({
    required this.id,
    required this.nome,
    required this.templateId,
    required this.templateNome,
    this.clienteId,
    this.clienteNome = '',
    this.programaId,
    this.programaNome = '',
    this.projetoId,
    this.projetoNome = '',
    this.eventoId,
    this.criadoPorId,
    this.criadoPorNome = '',
    this.documentoJson,
    required this.tipoAgendamento,
    this.dataHoraExecucao,
    this.recorrencia,
    this.horarioExecucao,
    this.diaSemana,
    this.diaMes,
    this.ativo = true,
    this.dataCriacao = '',
    this.ultimaAtualizacao = '',
    this.ultimaExecucao,
    this.proximaExecucao,
  });

  String get tipoRotulo =>
      tipoAgendamento == 'recorrente' ? 'Recorrente' : 'Pontual';

  NivelEscopo get nivelEscopo {
    if (projetoId != null) return NivelEscopo.projeto;
    if (programaId != null) return NivelEscopo.programa;
    return NivelEscopo.cliente;
  }

  String get escopoRotulo {
    if (projetoId != null) {
      return projetoNome.isNotEmpty ? projetoNome : 'Projeto #$projetoId';
    }
    if (programaId != null) {
      return programaNome.isNotEmpty ? programaNome : 'Programa #$programaId';
    }
    return clienteNome.isNotEmpty ? clienteNome : 'Cliente #$clienteId';
  }

  String get descricaoRecorrencia {
    if (tipoAgendamento == 'pontual') {
      return dataHoraExecucao != null && dataHoraExecucao!.isNotEmpty
          ? 'Execução pontual'
          : 'Pontual';
    }

    final horaBruta = horarioExecucao != null && horarioExecucao!.isNotEmpty
        ? horarioExecucao!
        : '08:00';
    final hora = horaBruta.length >= 5 ? horaBruta.substring(0, 5) : horaBruta;

    switch (recorrencia) {
      case 'diario':
        return 'Diário às $hora';
      case 'semanal':
        const dias = [
          'Segunda',
          'Terça',
          'Quarta',
          'Quinta',
          'Sexta',
          'Sábado',
          'Domingo',
        ];
        final diaStr = (diaSemana != null && diaSemana! >= 0 && diaSemana! < 7)
            ? dias[diaSemana!]
            : 'Segunda';
        return 'Toda $diaStr às $hora';
      case 'mensal':
        final diaStr = diaMes ?? 1;
        return 'Todo dia $diaStr às $hora';
      default:
        return 'Recorrente às $hora';
    }
  }
}

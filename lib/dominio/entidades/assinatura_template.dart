class AssinaturaTemplate {
  final int? id;
  final int? templateId;
  final int? equipeProgramaId;
  final int? equipeProjetoId;
  final String nomeSignatario;
  final String cargoSignatario;

  const AssinaturaTemplate({
    this.id,
    this.templateId,
    this.equipeProgramaId,
    this.equipeProjetoId,
    this.nomeSignatario = '',
    this.cargoSignatario = '',
  });
}

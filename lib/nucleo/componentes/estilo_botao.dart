import 'package:equatable/equatable.dart';

class EstiloBotao extends Equatable {
  final double altura;
  final double raio;
  final bool gradiente;

  const EstiloBotao({
    this.altura = 52,
    this.raio = 8,
    this.gradiente = false,
  });

  // Botão sólido padrão — altura 52, raio 8
  static const EstiloBotao padrao = EstiloBotao();

  // Botão sólido maior — altura 56, raio 8
  static const EstiloBotao grande = EstiloBotao(altura: 56);

  // Botão com gradiente — altura 56, raio 16
  static const EstiloBotao comGradiente = EstiloBotao(
    altura: 56,
    raio: 16,
    gradiente: true,
  );

  @override
  List<Object?> get props => [altura, raio, gradiente];
}

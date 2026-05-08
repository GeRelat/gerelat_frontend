import 'package:gerelat_frontend/nucleo/utils/type_def.dart';

/// Contrato que a camada de dados deve implementar.
/// A UI e os casos de uso dependem apenas desta interface.
abstract class IRepositorioAuth {
  ResultFuture<void> login({
    required String email,
    required String senha,
  });

  ResultFuture<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  });
}

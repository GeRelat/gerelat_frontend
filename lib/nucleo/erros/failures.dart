import 'package:equatable/equatable.dart';
import 'package:gerelat_frontend/nucleo/erros/exceptions.dart';

abstract class Failure extends Equatable {
  Failure({required this.message, required this.statusCode})
    : assert(
        statusCode is String || statusCode is int,
        'StatusCode cannot be a ${statusCode.runtimeType}',
      );

  final String message;
  final dynamic statusCode;

  String get errorMessages => 'Error ${statusCode ?? 'desconhecido'}: $message';

  @override
  List<dynamic> get props => <dynamic>[message, statusCode];
}

class ApiFailure extends Failure {
  ApiFailure({required super.message, required super.statusCode});

  ApiFailure.fromException(ApiException exception)
    : this(message: exception.message, statusCode: exception.statusCode);
}

import 'package:dio/dio.dart';
import 'package:gerelat_frontend/nucleo/erros/exceptions.dart';

abstract class BaseDatasource {
  const BaseDatasource();

  Future<T> request<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        message: _dioMessage(e),
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}

// Extrai mensagem legível de um DioException, compatível com respostas Django REST Framework.
String _dioMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail != null) return detail.toString();
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String) return value;
    }
  }
  return e.message ?? 'Erro de conexão com o servidor.';
}

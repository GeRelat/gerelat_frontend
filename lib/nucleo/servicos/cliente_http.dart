import 'package:dio/dio.dart';

class ClienteHttp {
  ClienteHttp._();

  static final Dio instancia = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

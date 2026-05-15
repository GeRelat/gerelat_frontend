import 'package:gerelat_frontend/nucleo/erros/exceptions.dart';
import 'package:gerelat_frontend/nucleo/erros/failures.dart';
import 'package:gerelat_frontend/nucleo/utils/result.dart';
import 'package:gerelat_frontend/nucleo/utils/type_def.dart';

abstract class BaseRepository {
  const BaseRepository();

  ResultFuture<T> request<T>(Future<T> Function() request) async {
    try {
      final result = await request();
      return Right(result);
    } on ApiException catch (e) {
      return Left(ApiFailure.fromException(e));
    }
  }
}

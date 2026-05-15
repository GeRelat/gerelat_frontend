import 'package:gerelat_frontend/nucleo/erros/failures.dart';
import 'package:gerelat_frontend/nucleo/utils/result.dart';

typedef ResultFuture<T> = Future<Result<Failure, T>>;
typedef ResultVoid = ResultFuture<void>;

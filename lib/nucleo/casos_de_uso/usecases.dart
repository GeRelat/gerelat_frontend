import 'package:gerelat_frontend/nucleo/utils/type_def.dart';

abstract class UsecaseWithParams<ValType, Params> {
  const UsecaseWithParams();

  ResultFuture<ValType> call(Params params);
}

abstract class UsecaseWithoutParams<ValType> {
  const UsecaseWithoutParams();

  ResultFuture<ValType> call();
}

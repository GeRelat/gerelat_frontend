sealed class Result<L, R> {}

class Right<L, R> extends Result<L, R> {
  final R data;
  Right(this.data);
}

class Left<L, R> extends Result<L, R> {
  final L error;
  Left(this.error);
}

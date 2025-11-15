import 'package:movi/src/core/shared/failure.dart';

sealed class Result<T, F extends Failure> {
  const Result();

  R fold<R>({required R Function(T) ok, required R Function(F) err});

  bool isOk() => this is Ok<T, F>;
  bool isErr() => this is Err<T, F>;

  Result<R, F> map<R>(R Function(T value) mapper) {
    return fold(
      ok: (value) => Ok<R, F>(mapper(value)),
      err: (failure) => Err<R, F>(failure),
    );
  }

  Result<T, F2> mapError<F2 extends Failure>(F2 Function(F failure) mapper) {
    return fold(
      ok: (value) => Ok<T, F2>(value),
      err: (failure) => Err<T, F2>(mapper(failure)),
    );
  }

  Result<R, F> flatMap<R>(Result<R, F> Function(T value) mapper) {
    return fold(ok: mapper, err: (failure) => Err<R, F>(failure));
  }
}

class Ok<T, F extends Failure> extends Result<T, F> {
  const Ok(this.value);
  final T value;

  @override
  R fold<R>({required R Function(T p1) ok, required R Function(F p1) err}) {
    return ok(value);
  }
}

class Err<T, F extends Failure> extends Result<T, F> {
  const Err(this.failure);
  final F failure;

  @override
  R fold<R>({required R Function(T p1) ok, required R Function(F p1) err}) {
    return err(failure);
  }
}

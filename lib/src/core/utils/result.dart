import 'package:movi/src/core/shared/failure.dart';

sealed class Result<T, F extends Failure> {
  const Result();

  R fold<R>({required R Function(T) ok, required R Function(F) err});

  bool isOk() => this is Ok<T, F>;
  bool isErr() => this is Err<T, F>;
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

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(
    this.message, {
    this.code,
    this.stackTrace,
    this.cause,
    this.context,
  });

  final String message;
  final String? code;
  final StackTrace? stackTrace;
  final Object? cause;
  final Map<String, Object?>? context;

  factory Failure.fromException(
    Object error, {
    StackTrace? stackTrace,
    String? code,
    Map<String, Object?>? context,
  }) {
    if (error is Failure) return error;
    final message = error is Exception
        ? error.toString()
        : 'Unexpected error: ${error.toString()}';
    return _GenericFailure(
      message,
      code: code,
      stackTrace: stackTrace,
      cause: error,
      context: context,
    );
  }

  @override
  List<Object?> get props => [message, code, stackTrace, cause, context];
}

class _GenericFailure extends Failure {
  const _GenericFailure(
    super.message, {
    super.code,
    super.stackTrace,
    super.cause,
    super.context,
  });
}

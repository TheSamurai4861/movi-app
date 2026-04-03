import 'package:equatable/equatable.dart';

enum StorageFailureCode { read, write, corruptedPayload, unknown }

abstract class StorageFailure extends Equatable {
  const StorageFailure(this.code, this.message);

  final StorageFailureCode code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}

class StorageReadFailure extends StorageFailure {
  const StorageReadFailure([String message = 'Storage read error'])
    : super(StorageFailureCode.read, message);
}

class StorageWriteFailure extends StorageFailure {
  const StorageWriteFailure([String message = 'Storage write error'])
    : super(StorageFailureCode.write, message);
}

class StorageCorruptedPayloadFailure extends StorageFailure {
  const StorageCorruptedPayloadFailure([
    String message = 'Storage payload corrupted',
  ]) : super(StorageFailureCode.corruptedPayload, message);
}

class UnknownStorageFailure extends StorageFailure {
  const UnknownStorageFailure([String message = 'Unknown storage error'])
    : super(StorageFailureCode.unknown, message);
}

class StorageException implements Exception {
  const StorageException(this.failure, [this.cause]);

  final StorageFailure failure;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'StorageException: ${failure.message}';
    }
    return 'StorageException: ${failure.message} (${cause.runtimeType})';
  }
}

import 'package:equatable/equatable.dart';

abstract class StorageFailure extends Equatable {
  const StorageFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class StorageReadFailure extends StorageFailure {
  const StorageReadFailure([super.message = 'Storage read error']);
}

class StorageWriteFailure extends StorageFailure {
  const StorageWriteFailure([super.message = 'Storage write error']);
}

class UnknownStorageFailure extends StorageFailure {
  const UnknownStorageFailure([super.message = 'Unknown storage error']);
}

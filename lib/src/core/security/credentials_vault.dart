abstract class CredentialsVault {
  Future<void> storePassword(String accountId, String password);
  Future<String?> readPassword(String accountId);
  Future<void> removePassword(String accountId);
}

class CredentialsVaultException implements Exception {
  CredentialsVaultException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() =>
      'CredentialsVaultException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Simple in-memory vault useful for tests or platforms without secure storage.
class MemoryCredentialsVault implements CredentialsVault {
  MemoryCredentialsVault([Map<String, String>? seed])
    : _store = Map<String, String>.from(seed ?? const {});

  final Map<String, String> _store;

  @override
  Future<void> storePassword(String accountId, String password) async {
    _store[accountId] = password;
  }

  @override
  Future<String?> readPassword(String accountId) async {
    return _store[accountId];
  }

  @override
  Future<void> removePassword(String accountId) async {
    _store.remove(accountId);
  }
}

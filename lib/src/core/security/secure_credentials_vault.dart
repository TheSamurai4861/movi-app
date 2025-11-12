import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movi/src/core/security/credentials_vault.dart';

class SecureCredentialsVault implements CredentialsVault {
  SecureCredentialsVault({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _prefix = 'secret_pw_';

  @override
  Future<void> storePassword(String accountId, String password) async {
    await _storage.write(key: '$_prefix$accountId', value: password);
  }

  @override
  Future<String?> readPassword(String accountId) async {
    return _storage.read(key: '$_prefix$accountId');
  }

  @override
  Future<void> removePassword(String accountId) async {
    await _storage.delete(key: '$_prefix$accountId');
  }
}

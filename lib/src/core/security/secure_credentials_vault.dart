import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:movi/src/core/security/credentials_vault.dart';

class SecureCredentialsVault implements CredentialsVault {
  SecureCredentialsVault({
    FlutterSecureStorage? storage,
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
    WindowsOptions? windowsOptions,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _androidOptions =
           androidOptions ??
           const AndroidOptions(encryptedSharedPreferences: true),
       _iosOptions =
           iosOptions ??
           const IOSOptions(accessibility: KeychainAccessibility.passcode),
       _windowsOptions = windowsOptions ?? const WindowsOptions();

  final FlutterSecureStorage _storage;
  final AndroidOptions _androidOptions;
  final IOSOptions _iosOptions;
  final WindowsOptions _windowsOptions;

  static const _prefix = 'secret_pw_';

  @override
  Future<void> storePassword(String accountId, String password) async {
    await _storage.write(
      key: '$_prefix$accountId',
      value: password,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      wOptions: _windowsOptions,
    );
  }

  @override
  Future<String?> readPassword(String accountId) {
    return _storage.read(
      key: '$_prefix$accountId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      wOptions: _windowsOptions,
    );
  }

  @override
  Future<void> removePassword(String accountId) {
    return _storage.delete(
      key: '$_prefix$accountId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      wOptions: _windowsOptions,
    );
  }
}

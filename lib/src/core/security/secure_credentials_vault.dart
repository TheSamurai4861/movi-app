import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:movi/src/core/security/credentials_vault.dart';

class SecureCredentialsVault implements CredentialsVault {
  SecureCredentialsVault({
    FlutterSecureStorage? storage,
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
    MacOsOptions? macOsOptions,
    LinuxOptions? linuxOptions,
    WindowsOptions? windowsOptions,
    WebOptions? webOptions,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _androidOptions =
           androidOptions ??
           const AndroidOptions(encryptedSharedPreferences: true),
       _iosOptions =
           iosOptions ??
           const IOSOptions(accessibility: KeychainAccessibility.passcode),
       _macOsOptions =
           macOsOptions ??
           const MacOsOptions(
             accessibility: KeychainAccessibility.first_unlock_this_device,
             useDataProtectionKeyChain: true,
           ),
       _linuxOptions = linuxOptions ?? const LinuxOptions(),
       _windowsOptions = windowsOptions ?? const WindowsOptions(),
       _webOptions =
           webOptions ??
           const WebOptions(
             dbName: 'movi_credentials',
             publicKey: 'MOVI_SECURE_STORAGE',
           );

  final FlutterSecureStorage _storage;
  final AndroidOptions _androidOptions;
  final IOSOptions _iosOptions;
  final MacOsOptions _macOsOptions;
  final LinuxOptions _linuxOptions;
  final WindowsOptions _windowsOptions;
  final WebOptions _webOptions;

  static const _prefix = 'secret_pw_';

  @override
  Future<void> storePassword(String accountId, String password) async {
    await _storage.write(
      key: '$_prefix$accountId',
      value: password,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      mOptions: _macOsOptions,
      lOptions: _linuxOptions,
      wOptions: _windowsOptions,
      webOptions: _webOptions,
    );
  }

  @override
  Future<String?> readPassword(String accountId) {
    return _storage.read(
      key: '$_prefix$accountId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      mOptions: _macOsOptions,
      lOptions: _linuxOptions,
      wOptions: _windowsOptions,
      webOptions: _webOptions,
    );
  }

  @override
  Future<void> removePassword(String accountId) {
    return _storage.delete(
      key: '$_prefix$accountId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      mOptions: _macOsOptions,
      lOptions: _linuxOptions,
      wOptions: _windowsOptions,
      webOptions: _webOptions,
    );
  }
}

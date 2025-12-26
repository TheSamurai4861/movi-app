class SecretStore {
  SecretStore({
    Map<String, String> initialSecrets = const {},
    String envFilePath = '.env', // unused on web
  }) : _secrets = Map<String, String>.from(initialSecrets);

  final Map<String, String> _secrets;

  Future<String?> read(String key) async {
    // Web: no dart:io, no runtime env. Only cached/initial secrets.
    return _secrets[key];
  }

  Future<void> write(String key, String value) async {
    _secrets[key] = value;
  }

  void preload(Map<String, String> entries) => _secrets.addAll(entries);
}

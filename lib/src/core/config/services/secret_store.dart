import 'dart:io';

class SecretStore {
  SecretStore({
    Map<String, String> initialSecrets = const {},
    this.envFilePath = '.env',
  }) : _secrets = Map<String, String>.from(initialSecrets);

  final Map<String, String> _secrets;
  final String envFilePath;
  Map<String, String>? _envFileCache;

  Future<String?> read(String key) async {
    if (_secrets.containsKey(key)) {
      return _secrets[key];
    }
    final envValue = String.fromEnvironment(key);
    if (envValue.isNotEmpty) {
      _secrets[key] = envValue;
      return envValue;
    }
    final processEnv = Platform.environment[key];
    if (processEnv != null && processEnv.isNotEmpty) {
      _secrets[key] = processEnv;
      return processEnv;
    }
    final fileValue = await _readFromEnvFile(key);
    if (fileValue != null) {
      _secrets[key] = fileValue;
      return fileValue;
    }
    return null;
  }

  Future<String?> _readFromEnvFile(String key) async {
    _envFileCache ??= await _loadEnvFile();
    return _envFileCache?[key];
  }

  Future<Map<String, String>> _loadEnvFile() async {
    final file = File(envFilePath);
    if (!await file.exists()) return {};
    final lines = await file.readAsLines();
    final map = <String, String>{};
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final index = trimmed.indexOf('=');
      if (index == -1) continue;
      final key = trimmed.substring(0, index).trim();
      final value = trimmed.substring(index + 1).trim();
      if (key.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }

  Future<void> write(String key, String value) async {
    _secrets[key] = value;
  }

  void preload(Map<String, String> entries) => _secrets.addAll(entries);
}

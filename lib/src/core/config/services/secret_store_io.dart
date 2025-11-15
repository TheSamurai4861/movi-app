import 'dart:io';

class SecretStore {
  SecretStore({
    Map<String, String> initialSecrets = const {},
    this.envFilePath = '.env',
    this.envFileCacheTtl = const Duration(minutes: 5),
  }) : _secrets = Map<String, String>.from(initialSecrets);

  final Map<String, String> _secrets;
  final String envFilePath;
  final Duration envFileCacheTtl;
  Map<String, String>? _envFileCache;
  DateTime? _lastEnvLoad;

  Future<String?> read(String key) async {
    if (_secrets.containsKey(key)) {
      return _secrets[key];
    }
    // Runtime environment variables via process env (desktop/mobile).
    final processEnv = Platform.environment[key];
    if (processEnv != null && processEnv.isNotEmpty) {
      _secrets[key] = processEnv;
      return processEnv;
    }
    // Fallback to .env file on disk.
    final fileValue = await _readFromEnvFile(key);
    if (fileValue != null) {
      _secrets[key] = fileValue;
      return fileValue;
    }
    return null;
  }

  Future<String?> _readFromEnvFile(String key) async {
    final now = DateTime.now();
    final cacheExpired =
        _lastEnvLoad == null || now.difference(_lastEnvLoad!) > envFileCacheTtl;
    if (_envFileCache == null || cacheExpired) {
      _envFileCache = await _loadEnvFile();
      _lastEnvLoad = now;
    }
    return _envFileCache?[key];
  }

  Future<Map<String, String>> _loadEnvFile() async {
    final candidates = await _candidateEnvFiles();
    for (final file in candidates) {
      if (await file.exists()) {
        final lines = await file.readAsLines();
        return _parseEnv(lines);
      }
    }
    return {};
  }

  Future<List<File>> _candidateEnvFiles() async {
    final files = <File>[];
    // Primary: configured path (relative or absolute).
    files.add(File(envFilePath));

    // Search upwards from current working directory.
    var dir = Directory.current;
    for (int i = 0; i < 6; i++) {
      files.add(File('${dir.path}${Platform.pathSeparator}.env'));
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    // Also search upwards from the script location if available.
    try {
      final scriptPath = Platform.script.toFilePath();
      var scriptDir = File(scriptPath).parent;
      for (int i = 0; i < 6; i++) {
        files.add(File('${scriptDir.path}${Platform.pathSeparator}.env'));
        final parent = scriptDir.parent;
        if (parent.path == scriptDir.path) break;
        scriptDir = parent;
      }
    } catch (_) {
      // Ignore if not available.
    }

    // Deduplicate paths.
    final unique = <String, File>{};
    for (final f in files) {
      unique[f.path] = f;
    }
    return unique.values.toList(growable: false);
  }

  Map<String, String> _parseEnv(List<String> lines) {
    final map = <String, String>{};
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final index = trimmed.indexOf('=');
      if (index == -1) continue;
      final key = trimmed.substring(0, index).trim();
      var value = trimmed.substring(index + 1).trim();
      // Strip surrounding quotes if present.
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith('\'') && value.endsWith('\''))) {
        value = value.substring(1, value.length - 1);
      }
      if (key.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }

  Future<void> write(String key, String value) async {
    _secrets[key] = value;
    await _persistEnvValue(key, value);
  }

  void preload(Map<String, String> entries) => _secrets.addAll(entries);

  void invalidateEnvFileCache() {
    _envFileCache = null;
    _lastEnvLoad = null;
  }

  Future<void> _persistEnvValue(String key, String value) async {
    Map<String, String> existing;
    if (_envFileCache != null) {
      existing = Map<String, String>.from(_envFileCache!);
    } else {
      existing = await _loadEnvFile();
    }
    existing[key] = value;
    final file = File(envFilePath);
    await file.create(recursive: true);
    final buffer = StringBuffer();
    for (final entry in existing.entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }
    await file.writeAsString(buffer.toString());
    _envFileCache = existing;
    _lastEnvLoad = DateTime.now();
  }
}

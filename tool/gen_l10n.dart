import 'dart:io';

Future<void> main(List<String> args) async {
  final isWindows = Platform.isWindows;
  final executable = isWindows ? 'flutter.bat' : 'flutter';
  final result = await Process.run(executable, <String>[
    'gen-l10n',
  ], workingDirectory: Directory.current.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}

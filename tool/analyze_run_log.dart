import 'dart:io';
import 'dart:convert';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'run.txt';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Run log not found: $path');
    exitCode = 2;
    return;
  }

  final bytes = file.readAsBytesSync();
  final content = _decodeLog(bytes);
  final lines = const LineSplitter().convert(content);

  var failedToPostMainThread = 0;
  final heroPrefetchLines = <String>[];
  final perfDiagLines = <String>[];
  final heroPrepareLines = <String>[];
  final heroHydrateCompletedLines = <String>[];
  final heroHydrateAbandonedLines = <String>[];
  final heroHydrateFailedLines = <String>[];
  final heroPrecacheCompletedLines = <String>[];
  final heroPrecacheAbandonedLines = <String>[];
  final heroPrecacheFailedLines = <String>[];
  final heroPrecacheTimeoutLines = <String>[];
  final heroSkippedActiveLines = <String>[];
  final moviePlayerLines = <String>[];

  for (final line in lines) {
    if (line.contains('Failed to post message to main thread')) {
      failedToPostMainThread++;
    }
    if (line.contains('[HeroPrefetch]')) {
      heroPrefetchLines.add(line);
    }
    if (!line.contains('[PerfDiag]')) {
      continue;
    }

    perfDiagLines.add(line);

    if (line.contains('op=home_hero_prepare')) {
      heroPrepareLines.add(line);
    }
    if (line.contains('op=home_hero_hydrate') &&
        line.contains('event=completed')) {
      heroHydrateCompletedLines.add(line);
    }
    if (line.contains('op=home_hero_hydrate') &&
        line.contains('event=abandoned')) {
      heroHydrateAbandonedLines.add(line);
    }
    if (line.contains('op=home_hero_hydrate') && line.contains('event=failed')) {
      heroHydrateFailedLines.add(line);
    }
    if (line.contains('op=home_hero_precache_image') &&
        line.contains('event=completed')) {
      heroPrecacheCompletedLines.add(line);
    }
    if (line.contains('op=home_hero_precache_image') &&
        line.contains('event=abandoned')) {
      heroPrecacheAbandonedLines.add(line);
    }
    if (line.contains('op=home_hero_precache_image') &&
        line.contains('event=failed')) {
      heroPrecacheFailedLines.add(line);
    }
    if (line.contains('op=home_hero_precache_image') &&
        line.contains('reason=timeout')) {
      heroPrecacheTimeoutLines.add(line);
    }
    if (line.contains('reason=another_hydration_active') ||
        line.contains('reason=another_precache_active')) {
      heroSkippedActiveLines.add(line);
    }
    if (line.contains('op=movie_playback_selection') ||
        line.contains('op=movie_variant_resolver') ||
        line.contains('op=player_open_source') ||
        line.contains('op=player_apply_preferred_tracks')) {
      moviePlayerLines.add(line);
    }
  }

  stdout.writeln('Run log: ${file.path}');
  stdout.writeln('Lines: ${lines.length}');
  stdout.writeln('Failed to post message to main thread: $failedToPostMainThread');
  stdout.writeln('HeroPrefetch lines: ${heroPrefetchLines.length}');
  stdout.writeln('PerfDiag lines: ${perfDiagLines.length}');
  stdout.writeln('');

  stdout.writeln('Home hero summary');
  stdout.writeln('prepare: ${heroPrepareLines.length}');
  stdout.writeln('hydrate completed: ${heroHydrateCompletedLines.length}');
  stdout.writeln('hydrate abandoned: ${heroHydrateAbandonedLines.length}');
  stdout.writeln('hydrate failed: ${heroHydrateFailedLines.length}');
  stdout.writeln('precache completed: ${heroPrecacheCompletedLines.length}');
  stdout.writeln('precache abandoned: ${heroPrecacheAbandonedLines.length}');
  stdout.writeln('precache failed: ${heroPrecacheFailedLines.length}');
  stdout.writeln('precache timeout: ${heroPrecacheTimeoutLines.length}');
  stdout.writeln('skipped because another task active: ${heroSkippedActiveLines.length}');
  stdout.writeln('');

  stdout.writeln('Key lines');
  _printFirstLast('first hero prepare', heroPrepareLines);
  _printFirstLast('first hero prefetch', heroPrefetchLines);
  _printFirstLast('last hydrate completed', heroHydrateCompletedLines);
  _printFirstLast('last hydrate abandoned', heroHydrateAbandonedLines);
  _printFirstLast('last precache completed', heroPrecacheCompletedLines);
  _printFirstLast('last precache failed', heroPrecacheFailedLines);
  _printFirstLast('last precache timeout', heroPrecacheTimeoutLines);
  _printFirstLast('last skipped active', heroSkippedActiveLines);
  _printFirstLast('last movie/player event', moviePlayerLines);

  final hasNewHeroSignals =
      heroHydrateAbandonedLines.isNotEmpty || heroPrecacheTimeoutLines.isNotEmpty;
  stdout.writeln('');
  stdout.writeln(
    'Heuristic: ${hasNewHeroSignals ? 'log includes new hero guardrail signals' : 'log may predate the latest hero guardrails'}',
  );
}

void _printFirstLast(String label, List<String> lines) {
  if (lines.isEmpty) {
    stdout.writeln('$label: none');
    return;
  }
  stdout.writeln('$label: ${lines.first}');
  if (lines.length > 1) {
    stdout.writeln('$label (last): ${lines.last}');
  }
}

String _decodeLog(List<int> bytes) {
  if (bytes.length >= 2) {
    final b0 = bytes[0];
    final b1 = bytes[1];
    if (b0 == 0xFF && b1 == 0xFE) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: true);
    }
    if (b0 == 0xFE && b1 == 0xFF) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: false);
    }
  }
  final zeroBytes = bytes.where((byte) => byte == 0).length;
  if (zeroBytes > bytes.length ~/ 8) {
    try {
      return _decodeUtf16(bytes, littleEndian: true);
    } catch (_) {
      return _decodeUtf16(bytes, littleEndian: false);
    }
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
  final units = <int>[];
  for (var index = 0; index + 1 < bytes.length; index += 2) {
    final first = bytes[index];
    final second = bytes[index + 1];
    units.add(littleEndian ? first | (second << 8) : (first << 8) | second);
  }
  return String.fromCharCodes(units);
}

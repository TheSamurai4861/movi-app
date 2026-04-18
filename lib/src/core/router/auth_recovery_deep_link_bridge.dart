import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'package:movi/src/core/router/app_route_paths.dart';

abstract interface class DeepLinkSource {
  Future<Uri?> getInitialUri();
  Stream<Uri> get uriStream;
}

final class AppLinksDeepLinkSource implements DeepLinkSource {
  AppLinksDeepLinkSource({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialUri() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;
}

enum DeepLinkDecisionResult { accepted, ignored }

enum DeepLinkConsumeSource {
  args('args'),
  initial('initial'),
  stream('stream'),
  unknown('unknown');

  const DeepLinkConsumeSource(this.label);
  final String label;
}

final class DeepLinkDecision {
  const DeepLinkDecision({
    required this.result,
    required this.reason,
    required this.source,
    this.targetRoute,
    this.canonicalKey,
  });

  final DeepLinkDecisionResult result;
  final String reason;
  final DeepLinkConsumeSource source;
  final String? targetRoute;
  final String? canonicalKey;
}

final class AuthRecoveryDeepLinkBridge {
  AuthRecoveryDeepLinkBridge({
    required this.navigateTo,
    DeepLinkSource? source,
    this.launchArgs = const <String>[],
    this.allowedSchemes = const <String>{'movi', 'movi-dev', 'movi-staging'},
    this.dedupWindow = const Duration(seconds: 5),
    DateTime Function()? now,
    void Function(String message)? logSink,
  }) : source = source ?? AppLinksDeepLinkSource(),
       _now = now ?? DateTime.now,
       _logSink = logSink ?? debugPrint;

  final void Function(String location) navigateTo;
  final DeepLinkSource source;
  final List<String> launchArgs;
  final Set<String> allowedSchemes;
  final Duration dedupWindow;
  final DateTime Function() _now;
  final void Function(String message) _logSink;

  StreamSubscription<Uri>? _subscription;
  final Map<String, DateTime> _recentHandledAt = <String, DateTime>{};

  Future<void> start() async {
    await _consumeLaunchArgs();
    await _consumeInitialLink();
    _subscription = source.uriStream.listen(
      (uri) => _consumeUri(uri, DeepLinkConsumeSource.stream),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _consumeLaunchArgs() async {
    for (final raw in launchArgs) {
      final uri = Uri.tryParse(raw.trim());
      if (uri == null || uri.scheme.isEmpty) {
        _logDecision(
          decision: const DeepLinkDecision(
            result: DeepLinkDecisionResult.ignored,
            reason: 'ignored_invalid_uri',
            source: DeepLinkConsumeSource.args,
          ),
          uriForLog: raw,
        );
        continue;
      }
      _consumeUri(uri, DeepLinkConsumeSource.args);
    }
  }

  Future<void> _consumeInitialLink() async {
    try {
      final uri = await source.getInitialUri();
      if (uri != null) {
        _consumeUri(uri, DeepLinkConsumeSource.initial);
      }
    } catch (error, stackTrace) {
      _logSink(
        'feature=deep_link action=consume result=ignored '
        'reason=initial_link_error source=${DeepLinkConsumeSource.initial.label} '
        'uri=<none> target=<none> detail="$error" stack="$stackTrace"',
      );
    }
  }

  void _consumeUri(Uri uri, DeepLinkConsumeSource sourceKind) {
    final decision = resolveAuthRecoveryRoute(
      uri,
      allowedSchemes: allowedSchemes,
      source: sourceKind,
    );
    if (decision.result == DeepLinkDecisionResult.ignored) {
      _logDecision(decision: decision, uriForLog: uri.toString());
      return;
    }

    final canonicalKey = decision.canonicalKey;
    if (canonicalKey == null) {
      _logDecision(
        decision: const DeepLinkDecision(
          result: DeepLinkDecisionResult.ignored,
          reason: 'ignored_invalid_uri',
          source: DeepLinkConsumeSource.unknown,
        ),
        uriForLog: uri.toString(),
      );
      return;
    }

    _purgeOldHandledEvents();
    final now = _now();
    final seenAt = _recentHandledAt[canonicalKey];
    if (seenAt != null && now.difference(seenAt) <= dedupWindow) {
      _logDecision(
        decision: DeepLinkDecision(
          result: DeepLinkDecisionResult.ignored,
          reason: 'ignored_duplicate',
          source: sourceKind,
          targetRoute: decision.targetRoute,
          canonicalKey: canonicalKey,
        ),
        uriForLog: uri.toString(),
      );
      return;
    }
    _recentHandledAt[canonicalKey] = now;

    _logDecision(decision: decision, uriForLog: uri.toString());
    navigateTo(decision.targetRoute!);
  }

  void _purgeOldHandledEvents() {
    final cutoff = _now().subtract(dedupWindow);
    _recentHandledAt.removeWhere((_, value) => value.isBefore(cutoff));
  }

  void _logDecision({
    required DeepLinkDecision decision,
    required String uriForLog,
  }) {
    final result = decision.result == DeepLinkDecisionResult.accepted
        ? 'accepted'
        : 'ignored';
    final target = decision.targetRoute ?? '<none>';
    final maskedUri = _maskUri(uriForLog);
    _logSink(
      'feature=deep_link action=consume result=$result '
      'reason=${decision.reason} uri=$maskedUri '
      'source=${decision.source.label} target=$target',
    );
  }
}

DeepLinkDecision resolveAuthRecoveryRoute(
  Uri uri, {
  Set<String> allowedSchemes = const <String>{
    'movi',
    'movi-dev',
    'movi-staging',
  },
  DeepLinkConsumeSource source = DeepLinkConsumeSource.unknown,
}) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (scheme.isEmpty) {
    return DeepLinkDecision(
      result: DeepLinkDecisionResult.ignored,
      reason: 'ignored_invalid_uri',
      source: source,
    );
  }
  if (!allowedSchemes.contains(scheme)) {
    return DeepLinkDecision(
      result: DeepLinkDecisionResult.ignored,
      reason: 'ignored_unsupported_scheme',
      source: source,
    );
  }
  if (host != 'auth') {
    return DeepLinkDecision(
      result: DeepLinkDecisionResult.ignored,
      reason: 'ignored_unsupported_host',
      source: source,
    );
  }
  if (path != AppRoutePaths.authUpdatePasswordCallback) {
    return DeepLinkDecision(
      result: DeepLinkDecisionResult.ignored,
      reason: 'ignored_unsupported_path',
      source: source,
    );
  }

  return DeepLinkDecision(
    result: DeepLinkDecisionResult.accepted,
    reason: 'accepted_recovery_update_password',
    source: source,
    targetRoute: AppRoutePaths.authUpdatePasswordCallback,
    canonicalKey: _canonicalDeepLinkKey(uri),
  );
}

String _canonicalDeepLinkKey(Uri uri) {
  final queryEntries = <String>[];
  final sortedKeys = uri.queryParametersAll.keys.toList()..sort();
  for (final key in sortedKeys) {
    final loweredKey = key.toLowerCase();
    final values = <String>[...uri.queryParametersAll[key] ?? const <String>[]]
      ..sort();
    if (values.isEmpty) {
      queryEntries.add('$loweredKey=');
      continue;
    }
    for (final value in values) {
      queryEntries.add('$loweredKey=$value');
    }
  }

  final query = queryEntries.join('&');
  return '${uri.scheme.toLowerCase()}|${uri.host.toLowerCase()}|'
      '${uri.path.toLowerCase()}|$query';
}

String _maskUri(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.queryParametersAll.isEmpty) return raw;

  final masked = <String, List<String>>{};
  for (final entry in uri.queryParametersAll.entries) {
    final isSensitive = _sensitiveQueryKeys.contains(entry.key.toLowerCase());
    masked[entry.key] = isSensitive
        ? List<String>.filled(entry.value.length, '***')
        : entry.value;
  }

  final queryParts = <String>[];
  for (final key in masked.keys.toList()..sort()) {
    final values = masked[key]!;
    if (values.isEmpty) {
      queryParts.add(Uri.encodeQueryComponent(key));
      continue;
    }
    for (final value in values) {
      queryParts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }
  }

  final queryString = queryParts.join('&');
  return uri.replace(query: queryString).toString();
}

const Set<String> _sensitiveQueryKeys = <String>{
  'access_token',
  'refresh_token',
  'token',
  'password',
  'otp',
  'code',
};

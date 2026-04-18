import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/auth_recovery_deep_link_bridge.dart';

void main() {
  group('resolveAuthRecoveryRoute', () {
    test('accepts movi auth update-password callback uri', () {
      final decision = resolveAuthRecoveryRoute(
        Uri.parse('movi://auth/update-password'),
        source: DeepLinkConsumeSource.args,
      );
      expect(decision.result, DeepLinkDecisionResult.accepted);
      expect(decision.reason, 'accepted_recovery_update_password');
      expect(decision.source, DeepLinkConsumeSource.args);
      expect(decision.targetRoute, AppRoutePaths.authUpdatePasswordCallback);
      expect(decision.canonicalKey, isNotNull);
    });

    test('rejects unsupported scheme', () {
      final decision = resolveAuthRecoveryRoute(
        Uri.parse('https://auth/update-password'),
      );
      expect(decision.result, DeepLinkDecisionResult.ignored);
      expect(decision.reason, 'ignored_unsupported_scheme');
    });

    test('rejects unsupported host', () {
      final decision = resolveAuthRecoveryRoute(
        Uri.parse('movi://account/update-password'),
      );
      expect(decision.result, DeepLinkDecisionResult.ignored);
      expect(decision.reason, 'ignored_unsupported_host');
    });

    test('rejects unsupported path', () {
      final decision = resolveAuthRecoveryRoute(
        Uri.parse('movi://auth/reset-password'),
      );
      expect(decision.result, DeepLinkDecisionResult.ignored);
      expect(decision.reason, 'ignored_unsupported_path');
    });
  });

  group('AuthRecoveryDeepLinkBridge', () {
    test('navigates once for duplicate launch/initial/stream uri', () async {
      final source = _FakeDeepLinkSource(
        initialUri: Uri.parse('movi://auth/update-password'),
      );
      final navigations = <String>[];
      final logs = <String>[];
      final bridge = AuthRecoveryDeepLinkBridge(
        source: source,
        launchArgs: const ['movi://auth/update-password'],
        navigateTo: navigations.add,
        logSink: logs.add,
      );

      await bridge.start();
      source.emit(Uri.parse('movi://auth/update-password'));
      await Future<void>.delayed(Duration.zero);
      await bridge.dispose();
      await source.dispose();

      expect(navigations, <String>[AppRoutePaths.authUpdatePasswordCallback]);
      expect(
        logs.where((line) => line.contains('reason=ignored_duplicate')).length,
        greaterThanOrEqualTo(1),
      );
    });

    test('ignores invalid uri and accepts valid one from stream', () async {
      final source = _FakeDeepLinkSource();
      final navigations = <String>[];
      final logs = <String>[];
      final bridge = AuthRecoveryDeepLinkBridge(
        source: source,
        launchArgs: const ['not-a-deep-link'],
        navigateTo: navigations.add,
        logSink: logs.add,
      );

      await bridge.start();
      source.emit(Uri.parse('movi://auth/update-password'));
      await Future<void>.delayed(Duration.zero);
      await bridge.dispose();
      await source.dispose();

      expect(navigations, <String>[AppRoutePaths.authUpdatePasswordCallback]);
      expect(
        logs.any((line) => line.contains('reason=ignored_invalid_uri')),
        isTrue,
      );
      expect(
        logs.any(
          (line) => line.contains('reason=accepted_recovery_update_password'),
        ),
        isTrue,
      );
    });

    test('allows same uri after dedup window expiration', () async {
      final source = _FakeDeepLinkSource();
      final navigations = <String>[];
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final bridge = AuthRecoveryDeepLinkBridge(
        source: source,
        navigateTo: navigations.add,
        now: () => now,
        dedupWindow: const Duration(seconds: 5),
      );

      await bridge.start();
      source.emit(Uri.parse('movi://auth/update-password'));
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(seconds: 6));
      source.emit(Uri.parse('movi://auth/update-password'));
      await Future<void>.delayed(Duration.zero);
      await bridge.dispose();
      await source.dispose();

      expect(navigations, <String>[
        AppRoutePaths.authUpdatePasswordCallback,
        AppRoutePaths.authUpdatePasswordCallback,
      ]);
    });

    test(
      'deduplicates equivalent query parameters regardless of order',
      () async {
        final source = _FakeDeepLinkSource();
        final navigations = <String>[];
        final bridge = AuthRecoveryDeepLinkBridge(
          source: source,
          navigateTo: navigations.add,
        );

        await bridge.start();
        source.emit(Uri.parse('movi://auth/update-password?b=2&a=1'));
        source.emit(Uri.parse('movi://auth/update-password?a=1&b=2'));
        await Future<void>.delayed(Duration.zero);
        await bridge.dispose();
        await source.dispose();

        expect(navigations, <String>[AppRoutePaths.authUpdatePasswordCallback]);
      },
    );

    test('masks sensitive query values in logs', () async {
      final source = _FakeDeepLinkSource();
      final logs = <String>[];
      final bridge = AuthRecoveryDeepLinkBridge(
        source: source,
        navigateTo: (_) {},
        logSink: logs.add,
      );

      await bridge.start();
      source.emit(
        Uri.parse(
          'movi://auth/update-password?access_token=abc&refresh_token=def&foo=bar',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await bridge.dispose();
      await source.dispose();

      final joinedLogs = logs.join('\n');
      expect(joinedLogs.contains('access_token=%2A%2A%2A'), isTrue);
      expect(joinedLogs.contains('refresh_token=%2A%2A%2A'), isTrue);
      expect(joinedLogs.contains('access_token=abc'), isFalse);
      expect(joinedLogs.contains('refresh_token=def'), isFalse);
    });
  });
}

final class _FakeDeepLinkSource implements DeepLinkSource {
  _FakeDeepLinkSource({this.initialUri});

  final Uri? initialUri;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialUri() async => initialUri;

  @override
  Stream<Uri> get uriStream => _controller.stream;

  void emit(Uri uri) => _controller.add(uri);

  Future<void> dispose() => _controller.close();
}

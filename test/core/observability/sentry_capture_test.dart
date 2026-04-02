import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:movi/src/core/logging/operation_context.dart';

class _InMemoryTransport implements Transport {
  _InMemoryTransport();

  final envelopes = <SentryEnvelope>[];

  @override
  Future<SentryId> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return SentryId.newId();
  }
}

void main() {
  test('Sentry captures non-fatal with release/env and operationId tag', () async {
    final transport = _InMemoryTransport();

    await Sentry.init(
      (options) {
        options.dsn = 'https://public@example.invalid/1';
        options.transport = transport;
        options.release = 'movi@r2-test';
        options.environment = 'test';
        options.sendDefaultPii = false;
        options.beforeSend = (event, hint) {
          final opId = currentOperationId();
          event.tags = <String, String>{
            ...?event.tags,
            if (opId != null) 'operationId': opId,
          };
          return event;
        };
      },
    );

    await runWithOperationId(() async {
      await Sentry.captureException(StateError('non_fatal_test'));
    }, operationId: 'op_test_456', prefix: 'test');

    expect(transport.envelopes, isNotEmpty);

    final hasEvent = transport.envelopes.any((env) {
      return env.items.any((item) => item.header.type == 'event');
    });
    expect(hasEvent, isTrue);

    // We validate tags through the event JSON serialization.
    bool validated = false;
    for (final env in transport.envelopes) {
      for (final item in env.items) {
        if (item.header.type != 'event') continue;
        final data = await item.dataFactory();
        final json = String.fromCharCodes(data);
        if (json.contains('"release":"movi@r2-test"') &&
            json.contains('"environment":"test"') &&
            json.contains('"operationId":"op_test_456"')) {
          validated = true;
          break;
        }
      }
      if (validated) break;
    }
    expect(validated, isTrue);

    await Sentry.close();
  });
}


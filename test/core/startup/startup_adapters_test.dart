import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/logging/operation_context.dart';
import 'package:movi/src/core/startup/infrastructure/startup_adapters.dart';

final class _SensitiveStackTrace implements StackTrace {
  @override
  String toString() =>
      'frame0 token=stack-secret\nframe1 password=stack-password';
}

void main() {
  test(
    'DebugPrintTelemetryAdapter sanitizes sensitive values and preserves operationId',
    () {
      final lines = <String>[];
      final adapter = DebugPrintTelemetryAdapter(printer: lines.add);

      runWithOperationId(
        () {
          adapter.error(
            'Authorization: Bearer abc.def.ghi',
            error: StateError(
              'password=hunter2 anonKey=abcdefghijklmnopqrstuvwx123456',
            ),
          );
        },
        operationId: 'op_startup_123',
        prefix: 'startup',
      );

      final output = lines.join('\n');
      expect(output, contains('[Startup][op=op_startup_123]'));
      expect(output, contains('Authorization: ****'));
      expect(output, isNot(contains('hunter2')));
      expect(output, isNot(contains('abcdefghijklmnopqrstuvwx123456')));
    },
  );

  test(
    'DebugPrintTelemetryAdapter redacts stack traces and keeps the startup prefix',
    () {
      final lines = <String>[];
      final adapter = DebugPrintTelemetryAdapter(printer: lines.add);

      runWithOperationId(
        () {
          adapter.error(
            'token=super-secret-value',
            stackTrace: _SensitiveStackTrace(),
          );
        },
        operationId: 'op_startup_123',
        prefix: 'startup',
      );

      final output = lines.join('\n');
      expect(output, contains('[Startup][op=op_startup_123][ERROR]'));
      expect(output, contains('token=****'));
      expect(output, contains('stackTrace=redacted'));
      expect(output, isNot(contains('stack-secret')));
      expect(output, isNot(contains('stack-password')));
      expect(output, isNot(contains('frame0')));
    },
  );
}

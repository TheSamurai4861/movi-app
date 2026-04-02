import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/adapters/console_logger.dart';
import 'package:movi/src/core/logging/operation_context.dart';

void main() {
  test('ConsoleLogger injects operationId from zone', () {
    final lines = <String>[];
    final logger = ConsoleLogger(printer: lines.add);

    runWithOperationId(() {
      logger.info(
        'feature=startup action=bootstrap result=progress message="step1"',
        category: 'startup',
      );
      logger.info(
        'feature=startup action=bootstrap result=success message="step2"',
        category: 'startup',
      );
    }, operationId: 'op_test_123', prefix: 'test');

    expect(lines, hasLength(2));
    expect(lines[0], contains('operationId=op_test_123'));
    expect(lines[1], contains('operationId=op_test_123'));
  });
}


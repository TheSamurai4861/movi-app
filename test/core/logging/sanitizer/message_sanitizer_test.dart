import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/logging/sanitizer/message_sanitizer.dart';

void main() {
  test('normalizes control whitespace around masked separators', () {
    final sanitizer = MessageSanitizer();

    final output = sanitizer.sanitize(
      'token \t= super-secret password:\nsecret-value',
    );

    expect(output, contains('token=****'));
    expect(output, contains('password: ****'));
    expect(output, isNot(contains('super-secret')));
    expect(output, isNot(contains('secret-value')));
    expect(output, isNot(contains('password:\n')));
  });
}

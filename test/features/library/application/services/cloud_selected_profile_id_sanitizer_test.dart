import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/library/application/services/cloud_selected_profile_id_sanitizer.dart';

void main() {
  const sanitizer = CloudSelectedProfileIdSanitizer();

  test('returns null for a local-only selected profile id', () {
    expect(sanitizer.sanitize('local_profile_123_456'), isNull);
  });

  test('returns null for an empty selected profile id', () {
    expect(sanitizer.sanitize('   '), isNull);
  });

  test('keeps a valid cloud uuid selected profile id', () {
    expect(
      sanitizer.sanitize('11111111-1111-4111-8111-111111111111'),
      '11111111-1111-4111-8111-111111111111',
    );
  });

  test('normalizes surrounding whitespace around a valid cloud uuid', () {
    expect(
      sanitizer.sanitize('  22222222-2222-4222-8222-222222222222  '),
      '22222222-2222-4222-8222-222222222222',
    );
  });
}

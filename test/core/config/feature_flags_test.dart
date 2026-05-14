import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/config/models/feature_flags.dart';

void main() {
  test('boot screen renderer rollout flag is disabled by default', () {
    const flags = FeatureFlags();

    expect(flags.enableBootScreenRenderer, isFalse);
  });

  test('copyWith can enable boot screen renderer without changing V2 routing', () {
    const flags = FeatureFlags(
      enableEntryJourneyStateModelV2: false,
      enableEntryJourneyRoutingV2: false,
    );

    final next = flags.copyWith(enableBootScreenRenderer: true);

    expect(next.enableBootScreenRenderer, isTrue);
    expect(next.enableEntryJourneyStateModelV2, isFalse);
    expect(next.enableEntryJourneyRoutingV2, isFalse);
  });
}

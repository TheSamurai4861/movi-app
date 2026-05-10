import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/resolve_home_degradation.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';

void main() {
  const resolver = ResolveHomeDegradation();

  test('maps no degradation to HomeReady', () {
    final readiness = resolver(
      const HomeDegradationInput(catalogMode: CatalogMode.fresh),
    );

    expect(readiness, isA<HomeReady>());
    final ready = readiness as HomeReady;
    expect(ready.reasonCode, StartupRecoveryReasonCodes.homeReady);
    expect(ready.catalogMode, CatalogMode.fresh);
  });

  test('maps feed failure to HomePartial', () {
    final readiness = resolver(
      const HomeDegradationInput(
        catalogMode: CatalogMode.cached,
        degradations: <HomeDegradation>[
          HomeDegradation(HomeDegradationKind.feedFailed),
        ],
      ),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(partial.reasonCode, StartupRecoveryReasonCodes.homeFeedFailed);
    expect(partial.catalogMode, CatalogMode.cached);
    expect(partial.actions, const [RecoveryAction.retryHomeSections]);
  });

  test('maps empty IPTV sections to HomePartial', () {
    final readiness = resolver(
      const HomeDegradationInput(
        catalogMode: CatalogMode.stale,
        degradations: <HomeDegradation>[
          HomeDegradation(HomeDegradationKind.iptvSectionsEmpty),
        ],
      ),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(
      partial.reasonCode,
      StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
    );
    expect(partial.catalogMode, CatalogMode.stale);
    expect(partial.actions, const [
      RecoveryAction.retryHomeSections,
      RecoveryAction.resyncSource,
    ]);
  });

  test('maps library timeout to HomePartial', () {
    final readiness = resolver(
      const HomeDegradationInput(
        catalogMode: CatalogMode.fresh,
        degradations: <HomeDegradation>[
          HomeDegradation(HomeDegradationKind.libraryPreloadTimeout),
        ],
      ),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(
      partial.reasonCode,
      StartupRecoveryReasonCodes.libraryPreloadTimeout,
    );
    expect(partial.actions, const [RecoveryAction.retryLibrary]);
  });

  test('maps library failure to HomePartial', () {
    final readiness = resolver(
      const HomeDegradationInput(
        catalogMode: CatalogMode.fresh,
        degradations: <HomeDegradation>[
          HomeDegradation(HomeDegradationKind.libraryPreloadFailed),
        ],
      ),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(partial.reasonCode, StartupRecoveryReasonCodes.libraryPreloadFailed);
    expect(partial.actions, const [RecoveryAction.retryLibrary]);
  });

  test('maps multiple degradations to HomePartial with combined actions', () {
    final readiness = resolver(
      const HomeDegradationInput(
        catalogMode: CatalogMode.cached,
        degradations: <HomeDegradation>[
          HomeDegradation(HomeDegradationKind.feedFailed),
          HomeDegradation(HomeDegradationKind.libraryPreloadTimeout),
          HomeDegradation(HomeDegradationKind.iptvSectionsEmpty),
        ],
      ),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(partial.reasonCode, StartupRecoveryReasonCodes.homePartial);
    expect(partial.catalogMode, CatalogMode.cached);
    expect(partial.actions, const [
      RecoveryAction.retryHomeSections,
      RecoveryAction.retryLibrary,
      RecoveryAction.resyncSource,
    ]);
  });

  test('does not expose source or catalog recovery as Home degradation', () {
    expect(
      HomeDegradationKind.values.map((kind) => kind.name),
      isNot(contains('catalogSnapshotMissing')),
    );
    expect(
      HomeDegradationKind.values.map((kind) => kind.name),
      isNot(contains('sourceRequired')),
    );
  });
}

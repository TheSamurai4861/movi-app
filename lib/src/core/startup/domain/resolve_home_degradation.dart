import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';

/// Degradable Home section detected after entry and catalog readiness.
enum HomeDegradationKind {
  feedFailed,
  iptvSectionsEmpty,
  libraryPreloadTimeout,
  libraryPreloadFailed,
}

/// A Home degradation that must not block Home when the catalog can open.
final class HomeDegradation {
  const HomeDegradation(this.kind);

  final HomeDegradationKind kind;
}

/// Pure input for deciding whether Home is fully ready or partially degraded.
final class HomeDegradationInput {
  const HomeDegradationInput({
    required this.catalogMode,
    this.degradations = const <HomeDegradation>[],
  }) : assert(
         catalogMode == CatalogMode.fresh ||
             catalogMode == CatalogMode.cached ||
             catalogMode == CatalogMode.stale,
       );

  final CatalogMode catalogMode;
  final List<HomeDegradation> degradations;
}

/// Resolves Home section failures into HomeReadiness without UI dependencies.
///
/// Source and catalog failures are intentionally not represented here. They
/// stay handled by [ResolveCatalogReadiness] and map to SourceRecoveryRequired.
final class ResolveHomeDegradation {
  const ResolveHomeDegradation();

  HomeReadiness call(HomeDegradationInput input) {
    if (input.degradations.isEmpty) {
      return HomeReady(
        reasonCode: StartupRecoveryReasonCodes.homeReady,
        catalogMode: input.catalogMode,
      );
    }

    final reasonCodes = input.degradations
        .map((degradation) => degradation.kind.reasonCode)
        .toSet();
    final reasonCode = reasonCodes.length == 1
        ? reasonCodes.single
        : StartupRecoveryReasonCodes.homePartial;

    return HomePartial(
      reasonCode: reasonCode,
      catalogMode: input.catalogMode,
      actions: _combineActions(input.degradations),
    );
  }

  List<RecoveryAction> _combineActions(List<HomeDegradation> degradations) {
    final actions = <RecoveryAction>[];
    for (final degradation in degradations) {
      for (final action in degradation.kind.actions) {
        if (!actions.contains(action)) {
          actions.add(action);
        }
      }
    }
    return actions;
  }
}

extension on HomeDegradationKind {
  String get reasonCode => switch (this) {
    HomeDegradationKind.feedFailed => StartupRecoveryReasonCodes.homeFeedFailed,
    HomeDegradationKind.iptvSectionsEmpty =>
      StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
    HomeDegradationKind.libraryPreloadTimeout =>
      StartupRecoveryReasonCodes.libraryPreloadTimeout,
    HomeDegradationKind.libraryPreloadFailed =>
      StartupRecoveryReasonCodes.libraryPreloadFailed,
  };

  List<RecoveryAction> get actions => switch (this) {
    HomeDegradationKind.feedFailed => const [RecoveryAction.retryHomeSections],
    HomeDegradationKind.iptvSectionsEmpty => const [
      RecoveryAction.retryHomeSections,
      RecoveryAction.resyncSource,
    ],
    HomeDegradationKind.libraryPreloadTimeout ||
    HomeDegradationKind.libraryPreloadFailed => const [
      RecoveryAction.retryLibrary,
    ],
  };
}

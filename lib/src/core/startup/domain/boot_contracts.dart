// Contracts for the boot refactor.
//
// This file is intentionally framework-agnostic: no Flutter, no Riverpod,
// no GetIt, no storage, no network clients.

/// Describes whether the local IPTV catalog can support opening Home.
enum CatalogMode {
  /// Local snapshot is present and considered up to date.
  fresh,

  /// Local snapshot is present and usable, but freshness is unknown.
  cached,

  /// Local snapshot is old but still usable.
  stale,

  /// No usable local snapshot exists.
  missing,

  /// Catalog preparation finished, but no useful content was found.
  empty,

  /// Catalog state cannot be determined.
  unavailable,
}

extension CatalogModeRules on CatalogMode {
  /// Whether this catalog state is enough to open Home.
  bool get canOpenHome => switch (this) {
    CatalogMode.fresh || CatalogMode.cached || CatalogMode.stale => true,
    CatalogMode.missing ||
    CatalogMode.empty ||
    CatalogMode.unavailable => false,
  };
}

/// User or system action proposed by startup recovery logic.
///
/// This enum only describes intent. UI layers decide how to render and execute
/// each action.
enum RecoveryAction {
  retry,
  exportLogs,
  login,
  createProfile,
  chooseProfile,
  addSource,
  chooseSource,
  reconnectSource,
  resyncSource,
  openHomeCached,
  retryHomeSections,
  retryLibrary,
}

extension RecoveryActionRules on Iterable<RecoveryAction> {
  /// `exportLogs` is diagnostic only and must not be the sole useful action.
  bool get hasPrimaryAction =>
      any((action) => action != RecoveryAction.exportLogs);
}

/// Decision that tells the entry flow where the user should go next.
sealed class EntryDecision {
  const EntryDecision({required this.reasonCode});

  /// Stable, log-safe reason. It must not contain secrets or raw identifiers.
  final String reasonCode;
}

/// Profile, source and an exploitable catalog are resolved.
final class OpenHome extends EntryDecision {
  const OpenHome({
    required super.reasonCode,
    required this.profileId,
    required this.sourceId,
    required this.catalogMode,
  }) : assert(profileId != ''),
       assert(sourceId != ''),
       assert(
         catalogMode == CatalogMode.fresh ||
             catalogMode == CatalogMode.cached ||
             catalogMode == CatalogMode.stale,
       );

  final String profileId;
  final String sourceId;
  final CatalogMode catalogMode;
}

/// Authentication is required before the entry flow can continue.
final class RequireAuth extends EntryDecision {
  const RequireAuth({required super.reasonCode});
}

/// A profile must be created or selected.
final class RequireProfile extends EntryDecision {
  const RequireProfile({required super.reasonCode});
}

/// An IPTV source must be added or reconnected.
final class RequireSource extends EntryDecision {
  const RequireSource({required super.reasonCode});
}

/// Multiple sources exist, but none is selected validly.
final class RequireSourceSelection extends EntryDecision {
  const RequireSourceSelection({required super.reasonCode});
}

/// A critical boot failure that cannot be represented as an auth/profile/source
/// action.
final class TechnicalBootFailure extends EntryDecision {
  const TechnicalBootFailure({
    required super.reasonCode,
    required this.message,
    required this.actions,
  }) : assert(actions.length > 0);

  final String message;
  final List<RecoveryAction> actions;
}

/// Content availability once Home is reachable.
sealed class HomeReadiness {
  const HomeReadiness({required this.reasonCode});

  /// Stable, log-safe reason. It must not contain secrets or raw identifiers.
  final String reasonCode;
}

/// Home can render its main content.
final class HomeReady extends HomeReadiness {
  const HomeReady({required super.reasonCode, required this.catalogMode})
    : assert(
        catalogMode == CatalogMode.fresh ||
            catalogMode == CatalogMode.cached ||
            catalogMode == CatalogMode.stale,
      );

  final CatalogMode catalogMode;
}

/// Home can render, but one content area is degraded.
final class HomePartial extends HomeReadiness {
  const HomePartial({
    required super.reasonCode,
    required this.catalogMode,
    required this.actions,
  }) : assert(actions.length > 0),
       assert(
         catalogMode == CatalogMode.fresh ||
             catalogMode == CatalogMode.cached ||
             catalogMode == CatalogMode.stale,
       );

  final CatalogMode catalogMode;
  final List<RecoveryAction> actions;
}

/// Home should not pretend the source is empty; the source/catalog needs a
/// dedicated recovery path.
final class SourceRecoveryRequired extends HomeReadiness {
  const SourceRecoveryRequired({
    required super.reasonCode,
    required this.actions,
  }) : assert(actions.length > 0);

  final List<RecoveryAction> actions;
}

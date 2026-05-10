import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/entry_journey_contracts.dart';

/// Stable reason codes emitted by [ResolveEntryDecision].
abstract final class EntryDecisionReasonCodes {
  static const authRequired = 'auth_required';
  static const profileRequired = 'profile_required';
  static const profileSelectionRequired = 'profile_selection_required';
  static const sourceRequired = 'source_required';
  static const sourceSelectionRequired = 'source_selection_required';
  static const entryReady = 'entry_ready';

  /// Temporary guard until the catalog contract is extracted in phase 3.
  static const catalogNotReadyForEntry = 'catalog_not_ready_for_entry';
}

/// Pure input for entry routing.
///
/// Adapters are responsible for reading repositories, repairing legacy
/// selections if needed and passing resolved identifiers.
final class EntryDecisionInput {
  const EntryDecisionInput({
    required this.requiresAuthenticatedSession,
    required this.session,
    required this.profiles,
    required this.sources,
    required this.resolvedProfileId,
    required this.resolvedSourceId,
    required this.catalogMode,
  });

  /// Whether this launch path must stop on auth when no session is available.
  ///
  /// The legacy boot still supports a local-first path without a cloud session,
  /// so this is intentionally explicit instead of derived from [session].
  final bool requiresAuthenticatedSession;
  final SessionContractSnapshot session;
  final ProfilesContractSnapshot profiles;
  final SourcesContractSnapshot sources;
  final String? resolvedProfileId;
  final String? resolvedSourceId;
  final CatalogMode catalogMode;
}

/// Resolves the startup entry destination from already-read snapshots.
///
/// This service is intentionally pure: no Flutter, no Riverpod, no GetIt,
/// no repositories, no storage, no network access and no logs.
final class ResolveEntryDecision {
  const ResolveEntryDecision();

  EntryDecision call(EntryDecisionInput input) {
    if (input.requiresAuthenticatedSession && !input.session.isAuthenticated) {
      return const RequireAuth(
        reasonCode: EntryDecisionReasonCodes.authRequired,
      );
    }

    if (input.profiles.count <= 0) {
      return const RequireProfile(
        reasonCode: EntryDecisionReasonCodes.profileRequired,
      );
    }

    final profileId = _firstPresent([
      input.resolvedProfileId,
      input.profiles.selectedProfileId,
    ]);
    if (!input.profiles.hasValidSelection || profileId == null) {
      return const RequireProfile(
        reasonCode: EntryDecisionReasonCodes.profileSelectionRequired,
      );
    }

    if (input.sources.totalCount <= 0) {
      return const RequireSource(
        reasonCode: EntryDecisionReasonCodes.sourceRequired,
      );
    }

    final sourceId = _firstPresent([
      input.resolvedSourceId,
      input.sources.selectedSourceId,
    ]);
    if (input.sources.requiresManualSelection ||
        !input.sources.hasValidSelection ||
        sourceId == null) {
      return const RequireSourceSelection(
        reasonCode: EntryDecisionReasonCodes.sourceSelectionRequired,
      );
    }

    if (!input.catalogMode.canOpenHome) {
      return const RequireSource(
        reasonCode: EntryDecisionReasonCodes.catalogNotReadyForEntry,
      );
    }

    return OpenHome(
      reasonCode: EntryDecisionReasonCodes.entryReady,
      profileId: profileId,
      sourceId: sourceId,
      catalogMode: input.catalogMode,
    );
  }

  String? _firstPresent(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

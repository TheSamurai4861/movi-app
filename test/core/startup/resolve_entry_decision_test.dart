import 'package:test/test.dart';

import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/entry_journey_contracts.dart';
import 'package:movi/src/core/startup/domain/resolve_entry_decision.dart';

void main() {
  const resolver = ResolveEntryDecision();

  test('routes missing required session to auth', () {
    final decision = resolver(
      _input(
        requiresAuthenticatedSession: true,
        session: const SessionContractSnapshot(
          status: SessionContractStatus.unauthenticated,
          reasonCode: 'session_absent',
        ),
      ),
    );

    expect(decision, isA<RequireAuth>());
    expect(decision.reasonCode, EntryDecisionReasonCodes.authRequired);
  });

  test('routes missing profile to profile creation', () {
    final decision = resolver(
      _input(
        profiles: const ProfilesContractSnapshot(
          count: 0,
          hasValidSelection: false,
          reasonCode: 'profile_required',
        ),
      ),
    );

    expect(decision, isA<RequireProfile>());
    expect(decision.reasonCode, EntryDecisionReasonCodes.profileRequired);
  });

  test('routes invalid profile selection to profile selection', () {
    final decision = resolver(
      _input(
        profiles: const ProfilesContractSnapshot(
          count: 2,
          hasValidSelection: false,
          selectedProfileId: 'missing_profile',
          reasonCode: 'profile_selection_required',
        ),
      ),
    );

    expect(decision, isA<RequireProfile>());
    expect(
      decision.reasonCode,
      EntryDecisionReasonCodes.profileSelectionRequired,
    );
  });

  test(
    'routes multiple profiles without local selection to profile selection',
    () {
      final decision = resolver(
        _input(
          profiles: const ProfilesContractSnapshot(
            count: 2,
            hasValidSelection: false,
            reasonCode: 'profile_selection_required',
          ),
          resolvedProfileId: null,
        ),
      );

      expect(decision, isA<RequireProfile>());
      expect(
        decision.reasonCode,
        EntryDecisionReasonCodes.profileSelectionRequired,
      );
    },
  );

  test('routes missing source to source creation', () {
    final decision = resolver(
      _input(
        sources: const SourcesContractSnapshot(
          localCount: 0,
          remoteCount: 0,
          hasValidSelection: false,
          requiresManualSelection: false,
          reasonCode: 'source_required',
        ),
      ),
    );

    expect(decision, isA<RequireSource>());
    expect(decision.reasonCode, EntryDecisionReasonCodes.sourceRequired);
  });

  test(
    'routes multiple sources without valid selection to source selection',
    () {
      final decision = resolver(
        _input(
          sources: const SourcesContractSnapshot(
            localCount: 2,
            remoteCount: 0,
            hasValidSelection: false,
            requiresManualSelection: true,
            reasonCode: 'source_selection_required',
          ),
          resolvedSourceId: null,
        ),
      );

      expect(decision, isA<RequireSourceSelection>());
      expect(
        decision.reasonCode,
        EntryDecisionReasonCodes.sourceSelectionRequired,
      );
    },
  );

  test('routes invalid source selection to source selection', () {
    final decision = resolver(
      _input(
        sources: const SourcesContractSnapshot(
          localCount: 2,
          remoteCount: 0,
          hasValidSelection: false,
          requiresManualSelection: false,
          selectedSourceId: 'missing_source',
          reasonCode: 'source_selection_required',
        ),
      ),
    );

    expect(decision, isA<RequireSourceSelection>());
    expect(
      decision.reasonCode,
      EntryDecisionReasonCodes.sourceSelectionRequired,
    );
  });

  test('routes valid profile and source to home', () {
    final decision = resolver(_input());

    expect(decision, isA<OpenHome>());
    final openHome = decision as OpenHome;
    expect(openHome.reasonCode, EntryDecisionReasonCodes.entryReady);
    expect(openHome.profileId, 'profile_1');
    expect(openHome.sourceId, 'source_1');
    expect(openHome.catalogMode, CatalogMode.cached);
  });

  test('routes selected source with ready catalog to home', () {
    final decision = resolver(
      _input(
        sources: const SourcesContractSnapshot(
          localCount: 1,
          remoteCount: 0,
          hasValidSelection: true,
          requiresManualSelection: false,
          selectedSourceId: 'source_ready',
          reasonCode: 'sources_ready',
        ),
        resolvedSourceId: 'source_ready',
        catalogMode: CatalogMode.fresh,
      ),
    );

    expect(decision, isA<OpenHome>());
    final openHome = decision as OpenHome;
    expect(openHome.reasonCode, EntryDecisionReasonCodes.entryReady);
    expect(openHome.sourceId, 'source_ready');
    expect(openHome.catalogMode, CatalogMode.fresh);
  });

  test('keeps local-first path available without a cloud session', () {
    final decision = resolver(
      _input(
        requiresAuthenticatedSession: false,
        session: const SessionContractSnapshot(
          status: SessionContractStatus.unauthenticated,
          reasonCode: 'local_mode',
        ),
      ),
    );

    expect(decision, isA<OpenHome>());
  });

  test('routes selected source with missing catalog to source action', () {
    final decision = resolver(_input(catalogMode: CatalogMode.missing));

    expect(decision, isA<RequireSource>());
    expect(
      decision.reasonCode,
      EntryDecisionReasonCodes.catalogNotReadyForEntry,
    );
  });
}

EntryDecisionInput _input({
  bool requiresAuthenticatedSession = false,
  SessionContractSnapshot session = const SessionContractSnapshot(
    status: SessionContractStatus.authenticated,
    userId: 'user_1',
    reasonCode: 'session_authenticated',
  ),
  ProfilesContractSnapshot profiles = const ProfilesContractSnapshot(
    count: 1,
    hasValidSelection: true,
    selectedProfileId: 'profile_1',
    reasonCode: 'profiles_ready',
  ),
  SourcesContractSnapshot sources = const SourcesContractSnapshot(
    localCount: 1,
    remoteCount: 0,
    hasValidSelection: true,
    requiresManualSelection: false,
    selectedSourceId: 'source_1',
    reasonCode: 'sources_ready',
  ),
  String? resolvedProfileId = 'profile_1',
  String? resolvedSourceId = 'source_1',
  CatalogMode catalogMode = CatalogMode.cached,
}) {
  return EntryDecisionInput(
    requiresAuthenticatedSession: requiresAuthenticatedSession,
    session: session,
    profiles: profiles,
    sources: sources,
    resolvedProfileId: resolvedProfileId,
    resolvedSourceId: resolvedSourceId,
    catalogMode: catalogMode,
  );
}

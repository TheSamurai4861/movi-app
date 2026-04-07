# Sous-phase 3.4 - Contrats backend et infra du tunnel

## Objectif

Definir les contrats utiles au tunnel d'entree avant implementation, avec:
- les ports critiques
- les payloads attendus
- les reason codes
- la distinction `must-have before home` vs `can-load-after-home`

Cette sous-phase ne choisit pas encore la composition technique finale. Elle fixe ce que l'orchestrateur doit pouvoir demander au backend, au local et a l'infrastructure.

## Principe directeur

Tous les contrats du tunnel doivent etre:
- explicites
- typables
- fail-safe
- compatibles `local-first, cloud-safe`

Le tunnel ne doit pas deduire son parcours a partir:
- d'exceptions opaques
- de booleans disperses
- de providers presentation

Il doit lire des resultats contractuels clairs.

## Taxonomie des contrats du tunnel

Le tunnel cible a besoin de 8 familles de contrats:

1. `startup status`
2. `connectivity`
3. `session restore and refresh`
4. `profiles inventory and selection`
5. `sources inventory`
6. `source activation and validation`
7. `pre-home readiness`
8. `local fallback and cloud resume`

## Forme de resultat recommandee

Recommandation:
- chaque port critique retourne soit un `snapshot`, soit un `result`
- les erreurs du tunnel sont typees, pas seulement logguees

Pseudo-forme recommandee:

```text
TunnelPortResult<T> {
  status: success | degraded | blocked
  data: T?
  reasons: Set<TunnelReasonCode>
  error: TunnelPortError?
}
```

Cette forme permet:
- de gerer le nominal
- de porter un degrade recuperable
- de distinguer un blocage fort

## Contrat 1 - Startup status

But:
- savoir si le systeme est pret a lancer le tunnel metier

Base existante utile:
- [startup_contracts.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/domain/startup_contracts.dart)

Port recommande:

```text
abstract interface class StartupStatusPort {
  Future<StartupStatusSnapshot> bootstrap();
}
```

Payload minimal:

```text
StartupStatusSnapshot {
  startupReady: bool
  safeMode: bool
  reasons: Set<TunnelReasonCode>
  durationMs: int
}
```

Reason codes principaux:
- `startup_pending`
- `startup_safe_mode`
- `startup_dependencies_failed`
- `startup_config_invalid`

Usage tunnel:
- `must-have before home`
- toujours requis avant toute autre resolution

## Contrat 2 - Connectivity

But:
- savoir si le reseau autorise sync cloud, verification session et preload distant

Port recommande:

```text
abstract interface class ConnectivityPort {
  Future<ConnectivitySnapshot> getCurrent();
  Stream<ConnectivitySnapshot> observe();
}
```

Payload minimal:

```text
ConnectivitySnapshot {
  networkAvailable: bool
  transport: wifi | cellular | ethernet | unknown
  internetReachable: bool
}
```

Reason codes principaux:
- `network_unavailable`
- `internet_unreachable`

Usage tunnel:
- `must-have before home` pour le flow retenu
- peut aussi piloter le passage en `blocked` ou `local_fallback`

## Contrat 3 - Session restore and refresh

But:
- restaurer ou verifier une session sans laisser l'UI deduire l'auth a la main

Base existante utile:
- [auth_repository.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/auth/domain/repositories/auth_repository.dart)

Port recommande:

```text
abstract interface class SessionSnapshotPort {
  Future<SessionSnapshotResult> resolve();
  Stream<SessionSnapshot> observe();
}
```

Payload minimal:

```text
SessionSnapshot {
  sessionResolved: bool
  hasSession: bool
  accountId: String?
  accountEmail: String?
}
```

Resultats attendus:
- `success` avec session
- `success` sans session
- `degraded` si cloud non joignable mais contexte local exploitable
- `blocked` si re-auth obligatoire et aucun fallback autorise

Reason codes principaux:
- `auth_missing`
- `auth_expired`
- `auth_reconfirmation_required`
- `cloud_auth_unreachable`

Usage tunnel:
- `must-have before home`
- pilote `auth_required`, `profile_required` ou progression nominale

## Contrat 4 - Profiles inventory and selection

But:
- charger les profils disponibles et resoudre si un profil est deja selectionne

Base existante utile:
- [profile_repository.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/profile/domain/repositories/profile_repository.dart)
- [selected_profile_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_profile_preferences.dart)

Ports recommandes:

```text
abstract interface class ProfilesInventoryPort {
  Future<ProfilesInventoryResult> load({required String? accountId});
}

abstract interface class SelectedProfilePort {
  Future<SelectedProfileResult> resolve({required List<ProfileSummary> profiles});
  Future<void> saveSelection(String profileId);
}
```

Payload minimal:

```text
ProfileSummary {
  profileId: String
  name: String
  avatarUrl: String?
  isKid: bool
}

ProfilesInventoryResult {
  profilesResolved: bool
  profiles: List<ProfileSummary>
}

SelectedProfileResult {
  hasSelectedProfile: bool
  selectedProfileId: String?
  resolvedFrom: persisted | inferred | none
}
```

Reason codes principaux:
- `profile_missing`
- `profile_selection_required`
- `profile_inventory_unavailable`
- `local_profile_only`

Usage tunnel:
- `must-have before home`

## Contrat 5 - Sources inventory

But:
- charger l'inventaire des sources disponibles pour le profil ou le compte courant

Bases existantes utiles:
- [iptv_repository.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/domain/repositories/iptv_repository.dart)
- [supabase_iptv_sources_repository.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart)

Port recommande:

```text
abstract interface class SourcesInventoryPort {
  Future<SourcesInventoryResult> load({required String? accountId});
}
```

Payload minimal:

```text
SourceSummary {
  sourceId: String
  label: String
  kind: xtream | stalker | other
  origin: cloud | local
}

SourcesInventoryResult {
  sourcesResolved: bool
  sources: List<SourceSummary>
}
```

Reason codes principaux:
- `source_missing`
- `sources_inventory_unavailable`
- `cloud_sync_partial`
- `local_fallback_active`

Usage tunnel:
- `must-have before home`

## Contrat 6 - Source activation and validation

But:
- resoudre la source active, verifier qu'elle est encore exploitable et persister la selection si necessaire

Base existante utile:
- [selected_iptv_source_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_iptv_source_preferences.dart)

Ports recommandes:

```text
abstract interface class SelectedSourcePort {
  Future<SelectedSourceResult> resolve({required List<SourceSummary> sources});
  Future<void> saveSelection(String sourceId);
}

abstract interface class SourceValidationPort {
  Future<SourceValidationResult> validate(String sourceId);
}
```

Payload minimal:

```text
SelectedSourceResult {
  hasSelectedSource: bool
  selectedSourceId: String?
  resolvedFrom: persisted | inferred | none
}

SourceValidationResult {
  selectedSourceValid: bool
  sourceId: String
  canRetry: bool
  canFallbackToChoice: bool
}
```

Reason codes principaux:
- `source_selection_required`
- `source_invalid`
- `source_validation_failed`
- `source_auth_invalid`
- `source_timeout`

Usage tunnel:
- `must-have before home`
- pilote `source_required` ou `preloading_home`

## Contrat 7 - Pre-home readiness

But:
- exprimer clairement ce que l'on doit attendre avant d'autoriser `home`

Bases existantes utiles:
- [app_launch_criteria.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_criteria.dart)
- [home_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/home/presentation/providers/home_providers.dart)
- [library_cloud_sync_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart)

Port recommande:

```text
abstract interface class HomePreloadPort {
  Future<HomePreloadResult> preload({
    required String profileId,
    required String sourceId,
  });
}
```

Payload minimal:

```text
HomePreloadResult {
  catalogReady: bool
  catalogHasContent: bool
  libraryReady: bool
  homePreloaded: bool
  durationMs: int
}
```

Reason codes principaux:
- `catalog_loading`
- `library_loading`
- `home_preload_running`
- `preload_slow`
- `source_catalog_empty`

Usage tunnel:
- `must-have before home`

Decision explicite:
- `Home vide` est autorise si:
  - `catalogReady = true`
  - `catalogHasContent = false`
  - `libraryReady = true`
  - `homePreloaded = true`

## Contrat 8 - Local fallback and cloud resume

But:
- rendre explicite la coexistence locale / cloud au lieu de la deduire implicitement

Port recommande:

```text
abstract interface class ContinuityModePort {
  Future<ContinuityResolutionResult> resolve();
  Future<CloudResumePlanResult> planResume();
}
```

Payload minimal:

```text
ContinuityResolutionResult {
  continuityMode: cloud | local_fallback
  canContinue: bool
  requiresUserChoice: bool
}

CloudResumePlanResult {
  resumePending: bool
  mergeStrategy: push_local | merge_into_existing | none
}
```

Reason codes principaux:
- `local_fallback_active`
- `cloud_resume_pending`
- `cloud_sync_partial`
- `merge_choice_required`

Usage tunnel:
- `must-have before home` si le mode de continuite conditionne le parcours
- sinon information annotee sur le state, sans bloquer la progression

## Distinction `must-have before home` vs `can-load-after-home`

## Must-have before home

Doit etre pret avant l'entree dans `home`:
- `startupReady`
- `networkAvailable` selon le flow retenu
- `sessionResolved`
- `hasSession` ou fallback explicitement autorise
- `profilesResolved`
- `hasSelectedProfile`
- `sourcesResolved`
- `hasSelectedSource`
- `selectedSourceValid`
- `catalogReady`
- `libraryReady`
- `homePreloaded`

## Can-load-after-home

Peut etre differe apres l'entree dans `home`:
- enrichissements non critiques de bibliotheque
- sections secondaires
- telemetry de confort
- sync cloud non bloquante
- contenus annexes non necessaires a la premiere peinture utile

Regle:
- ce qui n'est pas strictement requis pour tenir la promesse UX de `home prete` doit sortir du tunnel

## Catalogue d'erreurs typees recommande

## Erreurs bloquantes

- `network_unavailable`
- `auth_reconfirmation_required`
- `profile_creation_required_but_unavailable`
- `source_selection_required_but_unavailable`
- `preload_hard_failure`

## Erreurs degradees

- `cloud_sync_partial`
- `local_fallback_active`
- `source_validation_failed_retryable`
- `preload_slow`

## Erreurs techniques detaillees

- `timeout`
- `unauthorized`
- `forbidden`
- `unreachable`
- `invalid_payload`
- `dependency_failed`
- `empty_dataset`

## Mapping contrats -> TunnelCriteriaSnapshot

Le snapshot de criteria de `3.1` doit etre rempli a partir des contrats precedents:

| Criteria | Source contract |
| --- | --- |
| `startupReady` | `StartupStatusPort` |
| `networkAvailable` | `ConnectivityPort` |
| `sessionResolved` | `SessionSnapshotPort` |
| `hasSession` | `SessionSnapshotPort` |
| `profilesResolved` | `ProfilesInventoryPort` |
| `hasSelectedProfile` | `SelectedProfilePort` |
| `sourcesResolved` | `SourcesInventoryPort` |
| `hasSelectedSource` | `SelectedSourcePort` |
| `selectedSourceValid` | `SourceValidationPort` |
| `catalogReady` | `HomePreloadPort` |
| `catalogHasContent` | `HomePreloadPort` |
| `libraryReady` | `HomePreloadPort` |
| `homePreloaded` | `HomePreloadPort` |

## Decision log

1. Les contrats du tunnel doivent retourner des resultats structures, pas seulement des exceptions.
2. Le tunnel a besoin d'un contrat explicite pour la continuite `cloud / local_fallback`.
3. La validation de source est un contrat propre, distinct de l'inventaire de sources.
4. Le preload `home` doit devenir un port explicite de readiness, pas un detail enfoui dans `home_providers`.
5. `Home vide` est un resultat valide de `HomePreloadPort`, pas un echec de parcours.

## Points deferes a 3.5

Cette sous-phase ne tranche pas encore:
- qui implemente chaque port concretement
- comment `Riverpod` et `GetIt` vont injecter ces ports
- si certains ports sont regroupes dans des facades

Ces points seront traites en `3.5`.

## Verdict de sortie de la sous-phase 3.4

Verdict:
- la sous-phase `3.4` est suffisamment stable pour lancer `3.5`

Pourquoi:
- les contrats critiques du tunnel sont maintenant nommes
- les payloads minimaux sont poses
- les reason codes sont relies aux ports critiques
- la frontiere `must-have before home` vs `can-load-after-home` est explicite

## Prochaine etape recommandee

La suite logique est:
1. clarifier le role de `Riverpod`, `GetIt`, routeur et composition root
2. definir comment ces contrats seront injectes et observes
3. sortir le routing de la logique metier diffuse

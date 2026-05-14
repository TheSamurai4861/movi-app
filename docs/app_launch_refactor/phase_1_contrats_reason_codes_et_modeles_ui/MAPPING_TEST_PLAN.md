# Tests unitaires du mapping

## Synthese

Les tests ne doivent etre ajoutes au code qu'une fois `BootScreenModel` et son
mapper disponibles. Cette etape prepare le contrat de test afin que
l'implementation Phase 2/4 puisse etre verrouillee sans redecouvrir les cas.

Emplacement recommande :

```text
test/core/startup/presentation/
```

Fichiers cibles :

- `boot_screen_model_invariants_test.dart`
- `boot_ui_state_mapper_test.dart`
- `boot_no_reason_code_leak_test.dart`
- `boot_focus_contract_test.dart`

Les tests doivent rester unitaires : pas de widget tree complet, pas de router
reel, pas de reseau, pas de storage.

## Table de tests

| test | comportement couvert | contrat teste | donnees d'entree | assertion critique |
| --- | --- | --- | --- | --- |
| `boot_screen_model_invariants_test.dart` | Loading simple non interactif. | `BootScreenModel`, `BootScreenType.simpleLoading`. | Model `simpleLoading` avec reason `session_check`. | `isInteractive=false`, `primaryAction=null`, `secondaryAction=null`, `initialFocus=none`. |
| `boot_screen_model_invariants_test.dart` | Loading catalogue non interactif. | `BootScreenModel`, `BootScreenType.catalogLoading`. | Model `catalogLoading` avec reason `catalog_preparing`. | Aucune action focusable, `showLogo=true`, reason code present mais non affiche. |
| `boot_screen_model_invariants_test.dart` | Opening Home non interactif. | `BootScreenModel`, `BootScreenType.openingHome`. | Model `openingHome` avec reason `catalog_snapshot_cached`. | Destination `home` autorisee, aucune action, focus `none`. |
| `boot_screen_model_invariants_test.dart` | Ecran action requise valide. | `BootScreenModel`, `BootScreenType.actionRequired`. | Model `auth_required` avec action `login`. | `isInteractive=true`, `primaryAction=login`, `initialFocus=primaryAction`. |
| `boot_screen_model_invariants_test.dart` | Recovery valide. | `BootScreenModel`, `BootScreenType.recovery`. | Model `catalog_sync_timeout` avec `retry` + `chooseSource`. | Action principale obligatoire et secondaire optionnelle valide. |
| `boot_screen_model_invariants_test.dart` | `exportLogs` jamais seul. | `BootActionIntent.exportLogs`. | Model technique avec seulement `exportLogs`. | Construction refusee ou assertion mapper echoue. |
| `boot_ui_state_mapper_test.dart` | Tous les etats cibles sont couverts. | `BootScreenMapper`. | Liste exhaustive des etats de `TARGET_STATES.md`. | Aucun etat ne retourne fallback generique ou null. |
| `boot_ui_state_mapper_test.dart` | Startup technique. | `technical_startup -> simpleLoading`. | Etat technique startup. | Type `simpleLoading`, message utilisateur non vide, aucune action. |
| `boot_ui_state_mapper_test.dart` | Verification session. | `session_check -> simpleLoading`. | `AppLaunchPhase.auth` sans destination finale. | Type `simpleLoading`, reason `session_check`, non interactif. |
| `boot_ui_state_mapper_test.dart` | Auth requise. | `RequireAuth`, `auth_required`. | `EntryDecision.RequireAuth(reasonCode: auth_required)`. | Type `actionRequired`, action `login`, destination `auth`. |
| `boot_ui_state_mapper_test.dart` | Profil requis. | `RequireProfile`, `profile_required`. | `RequireProfile(reasonCode: profile_required)`. | Type `actionRequired`, action `createProfile`, destination `welcomeUser`. |
| `boot_ui_state_mapper_test.dart` | Selection profil requise. | `RequireProfile`, `profile_selection_required`. | `RequireProfile(reasonCode: profile_selection_required)`. | Type `actionRequired`, action `chooseProfile`, destination `welcomeUser`. |
| `boot_ui_state_mapper_test.dart` | Source requise. | `RequireSource`, `source_required`. | `RequireSource(reasonCode: source_required)`. | Type `actionRequired`, action `addSource`, destination `welcomeSources`. |
| `boot_ui_state_mapper_test.dart` | Selection source requise. | `RequireSourceSelection`, `source_selection_required`. | `RequireSourceSelection(reasonCode: source_selection_required)`. | Type `actionRequired`, action `chooseSource`, destination `chooseSource`. |
| `boot_ui_state_mapper_test.dart` | Preparation catalogue. | `AppLaunchPhase.catalogPreparing` ou projection equivalente. | Etat runtime `catalog_preparing`. | Type `catalogLoading`, non interactif, message dedie. |
| `boot_ui_state_mapper_test.dart` | Snapshot cached. | `CatalogMode.cached`, `catalog_snapshot_cached`. | `HomePartial(reasonCode: catalog_snapshot_cached, catalogMode: cached)`. | Type `openingHome`, destination `home`, jamais `recovery`. |
| `boot_ui_state_mapper_test.dart` | Snapshot stale. | `CatalogMode.stale`, `catalog_snapshot_stale`. | `HomePartial(reasonCode: catalog_snapshot_stale, catalogMode: stale)`. | Type `openingHome`, destination `home`, jamais `recovery`. |
| `boot_ui_state_mapper_test.dart` | Snapshot fresh. | `CatalogMode.fresh`, `catalog_snapshot_fresh`. | `HomeReady(reasonCode: catalog_snapshot_fresh)`. | Type `openingHome` ou navigation immediate Home. |
| `boot_ui_state_mapper_test.dart` | Timeout source. | `SourceRecoveryRequired`, `catalog_sync_timeout`. | Recovery actions `retry`, `chooseSource`. | Type `recovery`, action principale `retry`, secondaire `chooseSource`. |
| `boot_ui_state_mapper_test.dart` | Provider error. | `SourceRecoveryRequired`, `catalog_provider_error`. | Recovery actions `retry`, `chooseSource`. | Type `recovery`, titre/message non generiques. |
| `boot_ui_state_mapper_test.dart` | Credentials invalid. | `SourceRecoveryRequired`, `catalog_credentials_invalid`. | Recovery action `reconnectSource`. | Type `recovery`, action principale `reconnectSource`, pas `retry` comme action principale. |
| `boot_ui_state_mapper_test.dart` | Catalogue vide. | `SourceRecoveryRequired`, `catalog_empty`. | Recovery actions `resyncSource`, `chooseSource`. | Type `recovery`, action principale `resyncSource`. |
| `boot_ui_state_mapper_test.dart` | Catalogue indisponible localement. | `SourceRecoveryRequired`, `catalog_snapshot_unavailable`. | Recovery actions `retry`, `exportLogs`. | Type `recovery`, `exportLogs` secondaire uniquement. |
| `boot_ui_state_mapper_test.dart` | Erreur technique. | `StartupRecoveryPlan`, `boot_technical_failure`. | Plan retry + export logs. | Type `technicalFailure`, severity `error`, action `retry`. |
| `boot_ui_state_mapper_test.dart` | Home feed failed. | `HomePartial`, `home_feed_failed`. | Home degradation feed failed. | Type `homePartialNotice`, destination `home`, action `retryHomeSections`. |
| `boot_ui_state_mapper_test.dart` | Library failed. | `HomePartial`, `library_preload_failed`. | Home degradation library failed. | Type `homePartialNotice`, action `retryLibrary`. |
| `boot_ui_state_mapper_test.dart` | IPTV sections empty. | `HomePartial`, `home_iptv_sections_empty`. | Home degradation IPTV empty. | Type `homePartialNotice`, pas `catalog_empty`, Home reste ouverte. |
| `boot_ui_state_mapper_test.dart` | Multiple degradations. | `HomePartial`, `home_partial`. | Actions `retryHomeSections`, `retryLibrary`, `resyncSource`. | Type `homePartialNotice`, actions dedupliquees. |
| `boot_no_reason_code_leak_test.dart` | Aucun reason code dans les textes. | `BootScreenModel` text fields. | Tous les models produits par le mapper. | `title`, `message`, `secondaryMessage`, labels ne contiennent pas reason code brut ni `_`. |
| `boot_no_reason_code_leak_test.dart` | Pas de messages generiques. | Mapping UI. | Tous les models action/recovery. | Aucun texte `Erreur inconnue`, `Impossible de preparer la page d'accueil`, `Supabase`, exception brute. |
| `boot_focus_contract_test.dart` | Focus absent sur loading. | `BootFocusTarget`. | Models `simpleLoading`, `catalogLoading`, `openingHome`. | `initialFocus=none`. |
| `boot_focus_contract_test.dart` | Focus principal sur action/recovery. | `BootFocusTarget`. | Models `actionRequired`, `recovery`, `technicalFailure`. | `initialFocus=primaryAction`. |
| `boot_focus_contract_test.dart` | Home partial focus conditionnel. | `BootFocusTarget`, `homePartialNotice`. | Notice avec action puis notice sans action. | Avec action : `primaryAction`; sans action : `none`. |

## Assertions transversales

Ces assertions doivent etre appliquees a tous les models produits par le mapper :

- `reasonCode.trim().isNotEmpty`.
- `message.trim().isNotEmpty`.
- si `isInteractive == false` :
  - `primaryAction == null` ;
  - `secondaryAction == null` ;
  - `initialFocus == none`.
- si `isInteractive == true` :
  - `primaryAction != null` ;
  - `primaryActionLabel` non vide ;
  - `initialFocus == primaryAction`.
- si `secondaryAction != null` :
  - `secondaryActionLabel` non vide.
- si `secondaryAction == exportLogs` :
  - `primaryAction != null` ;
  - `primaryAction != exportLogs`.
- aucun champ texte utilisateur ne contient :
  - le `reasonCode` ;
  - un token avec underscore typique d'un code interne ;
  - un message exception provider brut ;
  - un identifiant source ou account id.

## Couverture minimale avant integration

Avant de brancher le mapper dans le runtime, ces tests doivent exister et passer :

```text
flutter test test/core/startup/presentation/boot_screen_model_invariants_test.dart
flutter test test/core/startup/presentation/boot_ui_state_mapper_test.dart
flutter test test/core/startup/presentation/boot_no_reason_code_leak_test.dart
flutter test test/core/startup/presentation/boot_focus_contract_test.dart
```

Ils doivent completer, pas remplacer :

```text
flutter test test/core/startup/resolve_entry_decision_test.dart
flutter test test/core/startup/resolve_catalog_readiness_test.dart
flutter test test/core/startup/resolve_home_degradation_test.dart
flutter test test/core/startup/startup_recovery_mapper_test.dart
```

## Definition de fini - etape 8

- Le mapping est couvert par des tests unitaires planifies.
- Les tests echouent si un etat cible n'a pas de modele UI.
- Les reason codes internes ne peuvent pas fuiter dans les textes UI.

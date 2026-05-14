# Decisions Phase 1 - Contrats, reason codes et modeles UI

## Synthese courte

La Phase 1 valide que le boot n'a pas besoin d'un second systeme metier. Les
contrats existants doivent rester la base :

- `CatalogMode` decide si Home peut ouvrir ;
- `EntryDecision` decide les actions auth/profil/source ;
- `HomeReadiness` separe Home ready, Home partiel et recovery source ;
- `RecoveryAction` porte les intentions techniques ;
- `StartupRecoveryReasonCodes` reste la source principale des reason codes
  startup/catalogue/Home.

Le nouveau travail consiste a ajouter une projection presentation :

```text
AppLaunchState / EntryDecision / HomeReadiness / StartupRecoveryPlan
  -> BootScreenModel
  -> renderer boot Figma
```

## Contrats conserves

| contrat | decision |
| --- | --- |
| `CatalogMode` | Conserver. `fresh`, `cached`, `stale` ouvrent Home. |
| `CatalogMode.canOpenHome` | Source canonique, a ne pas dupliquer. |
| `RecoveryAction` | Conserver comme enum d'intentions techniques. |
| `EntryDecision` | Conserver et projeter vers UI. |
| `HomeReadiness` | Conserver, surtout la separation `SourceRecoveryRequired` vs `HomePartial`. |
| `CatalogSnapshot` | Conserver comme snapshot local deja lu. |
| `ResolveEntryDecision` | Conserver. |
| `ResolveCatalogReadiness` | Conserver, avec decision produit documentee pour `cached/stale`. |
| `ResolveHomeDegradation` | Conserver. |
| `StartupRecoveryReasonCodes` | Conserver comme base des codes log-safe. |
| `AppLaunchState` | Conserver comme runtime, ne pas transformer en modele UI. |
| `TunnelState` | Conserver pour router/projection V2, pas pour renderer Figma. |

## Contrats a modifier ou clarifier

| sujet | changement requis | phase cible |
| --- | --- | --- |
| `AppLaunchPhase.catalogPreparing` | Ajouter une phase runtime ou equivalent pour exposer le refresh catalogue bloquant. | Phase 2/3 |
| `catalog_preparing` | Ajouter/confirmer un reason code log-safe pour l'etat en cours. | Phase 2/3 |
| `AppLaunchErrorCode.iptvCredentialsInvalid` | Ajouter un code runtime pour ne plus aplatir credentials invalid en provider error. | Phase 3 |
| `_catalogRefreshOutcomeForLaunchError` | Mapper `iptvCredentialsInvalid` vers `CatalogRefreshOutcome.credentialsInvalid`. | Phase 3 |
| `_mapIptvFailureToLaunchStep` | Mapper `AuthFailure`, `MissingCredentialsFailure` et `authInvalidCredentials` vers credentials invalid. | Phase 3 |
| Stalker refresh auth | Faire remonter `AuthFailure` quand handshake/profile/token prouve une auth invalide. | Phase 3 |
| `EntryDecisionReasonCodes` vs `StartupRecoveryReasonCodes` | Harmoniser ou documenter le pont dans le mapper UI. | Phase 2 |

## Nouveaux modeles

| modele | role | emplacement cible |
| --- | --- | --- |
| `BootScreenModel` | Contrat d'affichage entre runtime et ecrans Figma. | `lib/src/core/startup/presentation/boot_screen_model.dart` |
| `BootScreenType` | Type d'ecran : loading, catalogue, action, recovery, opening Home, notice Home, failure technique. | Meme fichier. |
| `BootActionIntent` | Intentions d'action UI, mappees depuis `RecoveryAction` ou destination. | Meme fichier. |
| `BootFocusTarget` | Contrat de focus initial TV/clavier. | Meme fichier. |
| `BootScreenSeverity` | Niveau visuel info/warning/error. | Meme fichier. |
| `BootScreenMapper` | Projection depuis `AppLaunchState` et contrats startup vers `BootScreenModel`. | `lib/src/core/startup/presentation/boot_screen_mapper.dart` |
| `bootScreenModelProvider` | Provider Riverpod exposant le model courant. | `lib/src/core/startup/presentation/boot_screen_providers.dart` |

## Reason codes ajoutes ou clarifies

| reason code | decision |
| --- | --- |
| `catalog_snapshot_cached` | Ouvre Home rapidement, jamais recovery source. |
| `catalog_snapshot_stale` | Ouvre Home rapidement, jamais recovery source. |
| `catalog_preparing` | A ajouter/confirmer pour l'etat de preparation catalogue en cours. |
| `catalog_snapshot_missing` | Signal de detection ou recovery, pas l'ecran final du refresh nominal. |
| `catalog_credentials_invalid` | Existe deja, mais emission runtime a completer. |
| `catalog_empty` | Recovery source avant Home, distinct de `home_iptv_sections_empty`. |
| `home_iptv_sections_empty` | Notice Home partiel apres ouverture, pas recovery source. |
| `home_partial` | Agregation de degradations Home apres ouverture. |

## Etats UI couverts

| famille | etats couverts | model cible |
| --- | --- | --- |
| Chargement simple | `technical_startup`, `session_check`, `profile_check`, `source_check`. | `simpleLoading` |
| Catalogue | `catalog_preparing`, `catalog_snapshot_missing` avant refresh. | `catalogLoading` |
| Ouverture Home | `catalog_snapshot_fresh`, `catalog_snapshot_cached`, `catalog_snapshot_stale`, `catalog_cached_ready`, `opening_home`, `home_ready`. | `openingHome` |
| Action requise | `auth_required`, `profile_required`, `profile_selection_required`, `source_required`, `source_selection_required`. | `actionRequired` |
| Recovery source | `source_timeout`, `provider_error`, `credentials_invalid`, `catalog_empty`, `catalog_snapshot_unavailable`. | `recovery` |
| Failure technique | `boot_config_timeout`, `boot_dependencies_timeout`, `boot_technical_failure`, `home_preload_invalid_state`. | `technicalFailure` |
| Home partiel | `home_sections_failed`, `library_failed`, `iptv_sections_empty`, `multiple_degradations`. | `homePartialNotice` |

## Etats encore bloques

| blocage | pourquoi | action suivante |
| --- | --- | --- |
| `catalogPreparing` non emis dans le code | `preloadCompleteHome` couvre encore plusieurs sous-etats. | Ajouter phase/sous-etat avant refresh bloquant. |
| `credentials_invalid` pas emis depuis boot réel | Le mapping runtime aplatit vers provider error. | Ajouter `iptvCredentialsInvalid` et mapping failures. |
| Stalker auth refresh trop silencieux | `_refreshAccountAuthInfo` catch/log sans faire echouer le refresh. | Faire remonter `AuthFailure` quand auth invalide explicite. |
| Renderer UI non branche | `BootScreenModel` est defini en docs seulement. | Implementer model, mapper et provider. |
| Handler actions absent | Les actions sont des intentions, pas encore executees centralement. | Phase 2 : `BootActionHandler` ou equivalent. |
| Localisation non faite | Les textes de mapping sont contractuels, pas encore `l10n`. | Phase 4/6 : l10n boot. |

## Tests a ajouter avant integration

| test | objectif |
| --- | --- |
| `boot_screen_model_invariants_test.dart` | Verrouiller les invariants du model. |
| `boot_ui_state_mapper_test.dart` | Verifier que chaque etat/reason code produit un `BootScreenModel`. |
| `boot_no_reason_code_leak_test.dart` | Empêcher reason codes et messages techniques dans les textes UI. |
| `boot_focus_contract_test.dart` | Verifier focus initial selon interaction. |
| `boot_screen_provider_test.dart` | Verifier `bootScreenModelProvider` sans side effect. |
| `app_launch_orchestrator_catalog_preparing_test.dart` | Verifier l'emission de `catalog_preparing`. |
| `app_launch_orchestrator_credentials_invalid_test.dart` | Verifier `catalog_credentials_invalid` depuis Xtream. |
| `app_launch_orchestrator_stalker_credentials_invalid_test.dart` | Verifier `catalog_credentials_invalid` depuis Stalker. |
| `launch_redirect_guard_catalog_preparing_test.dart` | Verifier que le guard ne redirige pas pendant preparation catalogue. |

## Plan d'implementation pour Phase 2

1. Ajouter `BootScreenModel`, `BootScreenMapper` et
   `bootScreenModelProvider`.
2. Ajouter les tests unitaires du model et du mapper.
3. Ajouter `catalogPreparing` dans la state machine ou un sous-etat runtime
   equivalent.
4. Verifier `LaunchRedirectGuard` pendant `catalogPreparing`.
5. Definir le handler des `BootActionIntent`.
6. Garder le fallback legacy tant que le renderer Figma n'est pas complet.

## Plan d'implementation pour Phase 3

1. Stabiliser le chemin catalogue :
   `snapshot missing -> catalog_preparing -> refresh -> cached/home`.
2. Implementer `iptvCredentialsInvalid`.
3. Mapper Xtream/Stalker auth invalid vers `CatalogRefreshOutcome.credentialsInvalid`.
4. Confirmer que `cached/stale` ne lance pas de refresh bloquant.
5. Ajouter les tests runtime sans snapshot, avec snapshot, timeout, provider,
   credentials invalid et empty.

## Plan d'implementation pour Phase 4

1. Implementer le renderer `BootScreenModel -> Widget`.
2. Reutiliser les composants existants :
   `MoviPrimaryButton`, `AppLabeledTextField`, `ProfileAvatarChip`,
   `MoviAssetIcon`, focus components.
3. Utiliser le logo reel `assets/branding/app_logo.svg`.
4. Respecter le texte bas d'ecran pour les chargements non interactifs.
5. Brancher progressivement le renderer sur `/launch` puis `/bootstrap`.

## Definition de fini - phase 1

- La table `reason code -> screen model -> actions -> destination` existe.
- La decision `cached/stale` est documentee.
- Les changements requis avant phase 2 sont identifies.
- Les contrats reutilisables sont conserves et non dupliques.
- Les etats UI importants sont couverts par un mapping.
- Les tests a ajouter avant integration sont listes.
- La phase 2 peut demarrer sans nouvelle exploration large des contrats.

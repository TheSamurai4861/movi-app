# Comportements a preserver

## Synthese

Les phases suivantes peuvent remplacer les surfaces UI du boot, mais ne doivent
pas changer les invariants fonctionnels ci-dessous.

Le principe a conserver est :

```text
decision metier stable -> etat UI explicite -> navigation controlee
```

Les reason codes, `RecoveryAction`, `EntryDecision`, `HomeReadiness` et
`AppLaunchCriteria` doivent rester la source technique. La nouvelle UI doit les
presenter sans exposer les details techniques a l'utilisateur.

## Table des invariants

| comportement | signal actuel | test existant | test manquant | risque |
| --- | --- | --- | --- | --- |
| Ouverture Home rapide avec snapshot exploitable | `CatalogSnapshotReader` retourne `CatalogMode.cached` avec playlists/items, `ResolveCatalogReadiness` retourne `HomePartial`, `AppLaunchCriteria.isHomeReady` devient true apres preload Home/library, destination `BootstrapDestination.home`. | `app_launch_orchestrator_local_mode_test`: `returns home without backend when local profile and local IPTV source exist`, `opens home from a local catalog snapshot even if foreground refresh would fail`, `opens home from a local catalog snapshot even if foreground refresh would time out`. `catalog_snapshot_test`, `resolve_catalog_readiness_test`. | Test UI `BootLoadingScreen`/mapper confirmant que le snapshot exploitable n'affiche pas un ecran recovery bloquant. | Regressions possibles : refresh bloque Home alors qu'un cache est ouvrable, Home devient inaccessible en offline, UX trop lente. |
| Redirection auth si session requise | `cloudAuthEnabled`, `AuthOrchestrator.bootstrapSession`, `EntryDecision RequireAuth`, destination `BootstrapDestination.auth`, guard vers `/auth/otp`. | `app_launch_orchestrator_local_mode_test`: `returns auth when cloud auth is enabled and no validated session exists`, `routes invalid cloud sessions to explicit auth reauthentication`. `resolve_entry_decision_test`: `routes missing required session to auth`. `launch_redirect_guard_reconnect_test`. | Test nouveau mapping verification session Figma -> routes auth, surtout retour `return_to=previous`. | Regressions possibles : Home accessible sans session quand session obligatoire, boucle auth/launch, perte du mode local-first quand auth non obligatoire. |
| Mode local-first sans session cloud quand autorise | `requiresAuthenticatedSession=false`, `hasSession` non requis par `AppLaunchCriteria.isHomeReady`, `ResolveEntryDecision` ouvre Home sans session. | `resolve_entry_decision_test`: `keeps local-first path available without a cloud session`. `app_launch_orchestrator_local_mode_test`: chemins local profile/source vers Home. | Test UI qui confirme qu'aucun ecran auth n'est affiche quand le lancement est local-first pret. | Regressions possibles : obligation auth accidentelle, blocage utilisateurs offline/local. |
| Creation d'un premier profil | Aucun profil local/cloud exploitable, destination `BootstrapDestination.welcomeUser`, `TunnelStage.profileRequired`. | `app_launch_orchestrator_local_mode_test`: `returns welcomeUser without backend when no local profile exists`. `resolve_entry_decision_test`: `routes missing profile to profile creation`. `entry_journey_shadow_bridge_test`. | Test du futur ecran `Resolution du profil - Creer un premier profil` et creation via `BootTextField`/`BootPrimaryButton`. | Regressions possibles : source/catalogue demandes avant profil, Home sans profil selectionne, focus initial incorrect sur le formulaire. |
| Selection d'un profil existant | Profils count > 1 ou selection invalide, `RequireProfile`, selection/reparation par preferences, destination `welcomeUser` selon contexte. | `resolve_entry_decision_test`: `routes invalid profile selection to profile selection`. `welcome_user_page_auth_priority_test`: scenarios profil/PIN. Tests `profiles_controller_test`. | Test du futur ecran `Choisir un profil` avec avatars, checkbox "se souvenir", focus TV. | Regressions possibles : mauvais profil actif, PIN enfant/adulte contourne, preference non persistee. |
| Ajout d'une source quand aucune source n'existe | `localAccounts` vides, destination `BootstrapDestination.welcomeSources`, reason `source_missing` / `sourceRequired`. | `app_launch_orchestrator_local_mode_test`: `returns welcomeSources without backend when local profile exists but no local source exists`. `resolve_entry_decision_test`: `routes missing source to source creation`. | Test futur ecran `Ajout d'une source` : champs, validation, action, route apres succes. | Regressions possibles : demande selection source alors qu'aucune source n'existe, formulaire non focusable, activation source non suivie du chargement catalogue. |
| Selection source quand plusieurs sources existent ou selection invalide | `sourceSelection`, `requiresManualSelection`, destination `BootstrapDestination.chooseSource`, route `/welcome/sources/select`. | `app_launch_orchestrator_local_mode_test`: `emits manual selection safe state telemetry when multiple sources require user choice`, `clears a stale selected source and routes to chooseSource when multiple local sources remain`. `resolve_entry_decision_test`: source selection. | Test futur ecran choix source + mapping depuis `RecoveryAction.chooseSource`. | Regressions possibles : mauvaise source active, selection stale conservee, chargement du mauvais catalogue. |
| Refresh source quand aucun snapshot exploitable n'existe | `CatalogMode.missing`/`empty`, `SourceRecoveryRequired`, `_ensureIptvCatalogReadyForLaunch`, `RefreshXtreamCatalog`/`RefreshStalkerCatalog`, relire snapshot `launch_after_blocking_refresh`. | `app_launch_orchestrator_local_mode_test`: `opens home when blocking refresh creates the missing local snapshot`, `routes to source recovery when no snapshot exists and refresh times out`, `routes to source recovery when no snapshot exists and provider refresh fails`, `routes to source recovery when refresh leaves catalog empty`. `resolve_catalog_readiness_test`. | Tests credentials invalid et erreurs Stalker ; test UI `Preparation du catalogue` sans messages techniques. | Regressions possibles : Home ouvert avec catalogue vide, refresh jamais lance, timeout/provider error mal mappe, spinner infini. |
| Recovery source catalogue avec actions appropriees | `ResolveCatalogReadiness` retourne `SourceRecoveryRequired` avec actions `retry`, `chooseSource`, `resyncSource`, `reconnectSource`, `exportLogs`; destination actuelle souvent `welcomeSources`. | `resolve_catalog_readiness_test`, `startup_recovery_mapper_test`, tests orchestrateur recovery source. | `boot_recovery_screen_test` et `boot_ui_state_mapper_test` pour verifier boutons/actions Figma. | Regressions possibles : action manquante, mauvais ecran recovery, reason code expose comme texte utilisateur. |
| Home partiel pour erreurs non critiques | `ResolveHomeDegradation` retourne `HomePartial`, `_setHomeDegradationNotice`, destination reste `home` si criteria techniques complets. | `resolve_home_degradation_test`. `app_launch_orchestrator_local_mode_test`: `opens Home partially when Home preload reports feed error`, `opens Home partially when IPTV Home sections are empty with openable catalog`, `opens Home partially when library preload times out`. `launch_redirect_guard_reconnect_test`: Home degrade reachable. | Test UI de notice Home partial / mapping non bloquant. | Regressions possibles : erreurs non critiques bloquent le boot, ou degradation silencieuse sans action retry. |
| Logs de boot exploitables | Logs `[Startup] action=phase_transition`, `catalog_snapshot`, `iptv_sync_*`, `catalog_minimal_ready`, `entry_journey_*`, reason codes stables. | `app_launch_orchestrator_local_mode_test`: telemetry enabled/disabled, manual selection telemetry. `startup_adapters_test`, `auth_recovery_deep_link_bridge_test` pour masquage. | Test `boot_no_generic_messages_test` et test logs catalogue Stalker/credentials invalid. | Regressions possibles : perte de diagnostic, PII dans logs, impossible de distinguer snapshot/refresh/Home. |
| Focus TV sur action principale | `FocusRegionScope`, `FocusRegionBinding.resolvePrimaryEntryNode`, `requestFocusOnMount`, focus nodes par surface (`SplashBootstrapRetry`, `WelcomeSourceSubmit`, etc.). | Tests focus core (`focus_region_scope_test`, `default_focus_orchestrator_test`), tests settings profile focus. Peu de tests boot directs. | `boot_focus_graph_test` pour auth/profil/source/recovery/loading. | Regressions possibles : premiere action non focusable sur TV, back/arrow cassés, ecran impossible a utiliser a la telecommande. |
| Router applique la destination sans boucles | `LaunchRedirectGuard`, `AppLaunchStateRegistry`, `TunnelStateRegistry`, `BootstrapDestination` -> route. | `launch_redirect_guard_reconnect_test`, `launch_redirect_guard_tunnel_surface_test`, `new_user_auth_launch_flow_test`. | Adapter ces tests aux nouvelles routes boot. | Regressions possibles : boucle `/launch`/`/bootstrap`, Home accessible trop tot, routes recovery inatteignables. |
| Retry ne relance pas plusieurs boots concurrents | `AppLaunchOrchestrator.run()` idempotent, `_ongoingRun`, `_runWithRetry`, `reset()` avant retry. | `app_launch_orchestrator_local_mode_test`: `run is idempotent when called concurrently`, retry/preload cases. | Test UI recovery : double tap retry ne declenche pas deux refreshs. | Regressions possibles : double refresh catalogue, etats intermediaires incoherents, logs dupliques. |

## Invariants par surface cible

| surface cible | invariants minimum |
| --- | --- |
| Chargement technique | Afficher logo et texte court, ne pas exposer reason code, garder safe mode/app update blocking. |
| Verification session | Respecter auth required, local-first si autorise, recovery update-password/forgot-password. |
| Resolution profil | Ne jamais ouvrir Home sans profil selectionne ; conserver PIN enfant/adulte. |
| Resolution source | Ne jamais ouvrir Home sans source active valide ; choisir source si plusieurs candidates. |
| Preparation catalogue | Refresh seulement si snapshot non exploitable ; ouvrir Home avec snapshot exploitable ; timeout/retry non infini. |
| Recovery source | Afficher actions derivees des contrats, pas des strings hardcodees. |
| Home partiel | Ouvrir Home si criteria essentiels prets, exposer degradation non bloquante. |

## Filet de securite avant phases suivantes

Tests a lancer prioritairement apres chaque tranche de refactor boot :

```text
flutter test test/core/startup
flutter test test/core/router
flutter test test/features/welcome
flutter test test/features/auth/presentation/auth_password_mode_and_reset_test.dart
```

Tests a creer avant suppression des widgets legacy :

```text
boot_ui_state_mapper_test.dart
boot_loading_screen_test.dart
boot_recovery_screen_test.dart
boot_focus_graph_test.dart
```

## Definition de fini - etape 9

- Les invariants sont explicites.
- Les risques de regression sont connus.
- Les phases suivantes peuvent changer le code avec un filet de securite.

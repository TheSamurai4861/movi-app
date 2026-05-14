# Inventaire des tests existants

## Synthese

La couverture actuelle est solide sur les contrats de boot, le router et
l'orchestrateur applicatif. Elle est plus faible sur les futurs ecrans Figma et
sur les composants UI boot a creer.

Points forts :

- contrats purs couverts : `ResolveEntryDecision`,
  `ResolveCatalogReadiness`, `ResolveHomeDegradation`,
  `StartupRecoveryMapper`, `CatalogSnapshotReader` ;
- chemin orchestration couvert en local-first, cloud auth, sources, catalogue,
  Home partiel, retry/idempotence ;
- router couvert pour destinations legacy et surface tunnel projetee ;
- quelques widgets legacy couverts (`SplashBootstrapPage`,
  `WelcomeSourceLoadingPage`, `WelcomeUserPage`).

Trous principaux :

- aucun test des futurs composants `BootHeader`, `BootLoadingScreen`,
  `BootRecoveryScreen`, variantes bouton/input/avatar ;
- pas de golden/screenshot test des ecrans boot Figma ;
- mapping UI `reasonCode -> ecran/actions/textes` encore inexistant ;
- credentials invalid catalogue couvert au niveau contrat pur, mais pas comme
  emission depuis l'orchestrateur ;
- erreurs Stalker du chemin boot peu couvertes ;
- focus TV des futurs ecrans boot non couvert.

## Table des tests

| test | fichier | comportement couvert | type | dependances | trou restant |
| --- | --- | --- | --- | --- | --- |
| App launch orchestrator local mode | `test/core/startup/app_launch_orchestrator_local_mode_test.dart` | Chemins `welcomeUser`, auth cloud, local-first degrade, profils, sources, selection source, catalog snapshot, refresh bloquant, Home partiel, telemetry entry journey, idempotence. | Integration provider/orchestrateur avec DB memoire. | `sqflite_common_ffi`, repositories locaux, `ProviderContainer`, fakes auth/home/logger/refresh Xtream/Stalker/cloud sync/preferences/Supabase. | Ne verifie pas la future UI boot. Credentials invalid catalogue et erreurs Stalker avalees restent a renforcer. |
| App startup gate app update | `test/core/startup/app_startup_gate_app_update_test.dart` | Affiche ecran update bloquant ou child quand update autorisee. | Widget test. | Overrides `appStartupProvider` / app update decision. | Pas de comparaison avec future surface boot technique. |
| App startup gate safe mode | `test/core/startup/app_startup_gate_safe_mode_test.dart` | Affiche safe mode si startup result `safeMode`, reason code visible. | Widget test. | Override `appStartupProvider`. | Verifier apres refactor que l'erreur technique boot Figma remplace/encapsule correctement l'existant. |
| App startup orchestrator | `test/core/startup/app_startup_orchestrator_test.dart` | Startup technique nominal, safe mode sur erreurs flavor/config/deps/IPTV/logging/app state/timeouts, recovery telemetry best-effort. | Unit/integration orchestrateur domaine. | Fakes ports startup, logger/telemetry. | Ne couvre pas le rendu UI des erreurs techniques. |
| Canonical tunnel projector | `test/core/startup/canonical_tunnel_state_projector_test.dart` | Projection auth/profile/source/preloading/ready depuis `AppLaunchState` vers `TunnelState`. | Unit pur. | Contrats `AppLaunchState`, `TunnelState`. | A adapter si de nouvelles phases boot remplacent `preloadCompleteHome`. |
| Catalog snapshot | `test/core/startup/catalog_snapshot_test.dart` | `CatalogMode.canOpenHome`, `CatalogSnapshot`, `CatalogSnapshotReader` missing/empty/cached/unavailable. | Unit pur avec fake repository. | `_FakeIptvLocalRepository`. | Pas de freshness/staleness derivee depuis TTL reel; reader ne lit pas cache metadata. |
| Entry journey shadow bridge | `test/core/startup/entry_journey_shadow_bridge_test.dart` | Mapping destinations legacy vers stages tunnel : auth, welcome user, choose source, preloading, ready home. | Unit pur. | `AppLaunchState`, `TunnelState`. | A adapter si nouvelles phases UI remplacent les stages projetes. |
| Resolve catalog readiness | `test/core/startup/resolve_catalog_readiness_test.dart` | Fresh/cached/stale, missing/unavailable, timeout/provider error/credentials invalid/empty, openable snapshot prioritaire. | Unit pur. | `CatalogSnapshot`, `CatalogRefreshOutcome`. | Contrat couvert, mais emission orchestrateur pour `credentialsInvalid` non couverte. |
| Resolve entry decision | `test/core/startup/resolve_entry_decision_test.dart` | Auth requis, profil requis/selection invalide, source requise/selection invalide, Home, local-first, catalogue non exploitable. | Unit pur. | `EntryDecisionInput` snapshots session/profiles/sources. | Ajouter tests si nouveaux etats UI source/profil ne doivent pas changer la decision metier. |
| Resolve home degradation | `test/core/startup/resolve_home_degradation_test.dart` | Home ready/partial, feed failed, IPTV sections empty, library timeout/failure, actions combinees. | Unit pur. | `HomeDegradationInput`. | Pas de rendu UI Home partial / notice future. |
| Startup adapters | `test/core/startup/startup_adapters_test.dart` | Sanitization telemetry/debug print, operationId, stack trace redaction. | Unit. | Adapter telemetry/logging. | Peu impacte par UI boot. |
| Startup recovery mapper | `test/core/startup/startup_recovery_mapper_test.dart` | Mapping erreurs startup/launch vers actions recovery, reason codes, retry/export logs/source/library/Home actions. | Unit pur. | `StartupRecoveryReasonCodes`, `RecoveryAction`. | Future UI doit tester le mapping de ces plans vers boutons/textes. |
| Auth recovery deep link bridge | `test/core/router/auth_recovery_deep_link_bridge_test.dart` | Deep links update-password acceptes/rejetes, dedup, logs masques. | Unit/router service. | Fake app links/logger/router. | Peu impacte sauf si routes auth boot changent. |
| Launch redirect guard reconnect | `test/core/router/launch_redirect_guard_reconnect_test.dart` | Home degrade reachable, auth return_to, bootstrap si Home pas pret, rerun auth stale, redirections auth explicites. | Router widget/integration. | `LaunchRedirectGuard`, fake auth repo/logger, `AppLaunchStateRegistry`, routes test. | A adapter si `/bootstrap` disparait ou si nouvelles routes boot remplacent les legacy. |
| Launch redirect guard tunnel surface | `test/core/router/launch_redirect_guard_tunnel_surface_test.dart` | Routing projete V2 : auth, ready home, auth recovery, update-password, source selection, source loading stable pendant preload. | Router widget/integration. | `TunnelStateRegistry`, feature flags V2, fake auth/logger. | A adapter si `welcomeSourceLoading` est supprime ou rendu purement presentationnel. |
| New user auth launch flow | `test/core/router/new_user_auth_launch_flow_test.dart` | Parcours complet nouveau user : launch, auth, welcome, sources loading, home. | Widget/integration router. | Fake logger/locale, router, providers. | Sera un test cle a adapter aux nouveaux ecrans boot et routes. |
| Splash bootstrap page progress | `test/features/welcome/presentation/splash_bootstrap_page_progress_test.dart` | Message de progression pendant `preloadCompleteHome`, suffix recovery, overlay reste visible. | Widget test legacy. | Overrides `appLaunchStateProvider`, `homeBootstrapProgressStageProvider`. | A remplacer par tests `BootLoadingScreen` et mapping etat boot -> texte bas d'ecran. |
| Welcome source loading page helpers | `test/features/welcome/presentation/welcome_source_loading_page_test.dart` | Resolution source active/selectionnee, offre choix autre source, format messages timeout/generic. | Unit pur sur helpers legacy. | Helpers exportes du widget. | A conserver temporairement; a deplacer vers domaine/orchestrateur si `WelcomeSourceLoadingPage` est supprime. |
| Welcome user page auth priority | `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart` | Priorite auth Supabase vs profil local, recovery retryable, PIN enfant/adulte. | Widget test. | Fake Supabase auth status, fake controllers profiles/selected profile/user settings, fake launch orchestrator, secure storage. | A adapter aux ecrans profil Figma et nouveaux composants avatar/checkbox. |
| Auth password mode/reset | `test/features/auth/presentation/auth_password_mode_and_reset_test.dart` | Routes auth OTP/password/forgot/update password, reset flow, validation, return_to previous, guard auth recovery. | Widget/router. | Fake auth repo/logger/locale, provider overrides reset/update submitters, `LaunchRedirectGuard`. | A adapter si verification de session Figma remplace les pages auth legacy. |
| Core auth orchestrator | `test/core/auth/auth_orchestrator_test.dart` | Bootstrap session, refresh success/offline/timeout, invalid session cleanup, signOut cleanup, telemetry secret redaction. | Unit domaine. | Fake auth repository/cleanup/logger/clock. | Contrat a conserver; pas d'UI boot. |
| Auth providers | `test/core/auth/presentation/providers/auth_providers_test.dart` | AuthController reutilise session resolue par launch, gere stream auth pendant build, cleanup switched user. | Provider test. | ProviderContainer, fake auth/session cleanup. | A conserver pour eviter double refresh apres refactor. |
| Profile repository/controller tests | `test/core/profile/...` | Fallback local/cloud, selection profil cloud, dialogs create/manage profile. | Unit/widget. | Fake repositories/controllers selon fichier. | Ne couvre pas le nouvel ecran boot profil Figma. |
| Settings profile switch tests | `test/features/settings/presentation/pages/settings_page_profile_switch_premium_gate_test.dart` | Switch profil premium/non-premium et focus graph settings. | Widget test. | Fake profiles/auth/library sync/preferences/focus orchestrator. | Utile pour focus/profil, mais pas directement boot. |
| Source deletion/reconnect/settings tests | `test/features/settings/presentation/...`, `test/core/state/app_state_provider_selected_source_test.dart` | Selection source persistante, suppression remote, reconnect validation, back key settings sources. | Unit/widget. | Fake auth/repositories/preferences. | Ne couvre pas ajout/selection source dans les futurs ecrans boot. |
| Home/widget tests connexes | `test/features/home/...` et tests Home partial dans orchestrateur | Home widgets et Home partial via orchestrateur. | Unit/widget. | Fakes Home/media selon fichier. | Pas de test visuel de notice Home partial issue du boot. |

## Tests a conserver

- Tous les tests de contrats purs dans `test/core/startup` :
  `resolve_*`, `catalog_snapshot_test`, `startup_recovery_mapper_test`.
- `app_launch_orchestrator_local_mode_test.dart`, qui protege les invariants
  fonctionnels du boot.
- Les tests `LaunchRedirectGuard`, surtout tant que les routes legacy restent
  en place.
- `new_user_auth_launch_flow_test.dart`, comme filet de bout en bout.
- Les tests auth/profile/source connexes, car le refactor boot ne doit pas
  casser les decisions metier existantes.

## Tests a adapter apres refactor

| test | adaptation probable |
| --- | --- |
| `splash_bootstrap_page_progress_test.dart` | Remplacer par tests du nouveau modele UI boot et `BootLoadingScreen`. |
| `welcome_source_loading_page_test.dart` | Deplacer les helpers source vers domaine/application si le widget est supprime. |
| `new_user_auth_launch_flow_test.dart` | Mettre a jour routes/widgets attendus avec les nouveaux ecrans boot. |
| `launch_redirect_guard_reconnect_test.dart` | Adapter si `/bootstrap` ou `welcomeSourceLoading` changent de role. |
| `launch_redirect_guard_tunnel_surface_test.dart` | Adapter le mapping surface tunnel vers nouvelles routes boot. |
| `welcome_user_page_auth_priority_test.dart` | Adapter aux nouveaux ecrans profil/auth et au composant avatar/checkbox. |
| `auth_password_mode_and_reset_test.dart` | Adapter si les ecrans verification session Figma remplacent les pages auth legacy. |

## Nouveaux tests necessaires

| nouveau test | objectif |
| --- | --- |
| `boot_ui_state_mapper_test.dart` | Mapper `AppLaunchState` / `HomeReadiness` / `RecoveryAction` vers ecrans Figma, titres, sous-titres, actions. |
| `boot_loading_screen_test.dart` | Verifier logo asset reel, texte bas d'ecran, absence de details techniques et layout stable. |
| `boot_recovery_screen_test.dart` | Verifier actions multiples : retry, chooseSource, resyncSource, reconnectSource, exportLogs. |
| `boot_header_test.dart` | Verifier logo non recolorise, titre/sous-titre, contraintes responsives. |
| `boot_text_field_test.dart` | Verifier decoration Figma, focus TV, password toggle. |
| `boot_profile_avatar_chip_test.dart` | Verifier initiale, selection, focus, tailles Figma. |
| `app_launch_orchestrator_credentials_invalid_test.dart` | Couvrir emission reelle de `catalogCredentialsInvalid` depuis une failure provider/auth. |
| `app_launch_orchestrator_stalker_failure_test.dart` | Couvrir les erreurs Stalker dans le refresh bloquant et leur reason code. |
| `boot_focus_graph_test.dart` | Verifier focus initial et navigation TV sur auth/profil/source/recovery. |
| `boot_no_generic_messages_test.dart` | Verifier que les reason codes et details techniques ne remontent pas comme texte utilisateur. |

## Definition de fini - etape 8

- Les tests a conserver sont identifies.
- Les tests a adapter apres refactor sont listes.
- Les nouveaux tests necessaires sont proposes.

# Audit phase 0 - Comportement actuel du boot

## Etape 1 - Inventaire des points d'entree

### Synthese

Le lancement actuel a deux niveaux distincts :

1. Bootstrap technique avant l'application principale.
   `main()` installe `AppStartupGate`, qui execute `appStartupProvider`.
   Tant que ce bootstrap n'est pas termine, `MyApp` et le router principal ne
   sont pas encore affiches.

2. Tunnel d'entree applicatif apres bootstrap technique.
   `MyApp` construit `MaterialApp.router`. Le router demarre par defaut sur
   `/launch`, qui affiche `_LaunchGate`. `_LaunchGate` appelle
   `appLaunchRunnerProvider('startup')`, lequel delegue a
   `AppLaunchOrchestrator.run()`.

Le premier ecran visible peut donc etre :

- `_StartupLoadingScreen` dans `AppStartupGate` si le bootstrap technique est
  encore en cours ;
- `_LaunchGate` avec `OverlaySplash` une fois `MyApp` affiche et le router
  initialise.

### Chemin observe

```text
main()
  -> WidgetsFlutterBinding.ensureInitialized()
  -> configuration globale Flutter / MediaKit / erreurs / device TV
  -> runApp(AppRestart)
  -> ProviderScope
  -> AppStartupGate
  -> appStartupProvider
  -> AppStartupOrchestrator.run()
  -> MyApp
  -> MaterialApp.router
  -> appRouterProvider
  -> GoRouter initialLocation /launch
  -> _LaunchGate
  -> appLaunchRunnerProvider('startup')
  -> AppLaunchOrchestrator.run()
  -> LaunchRedirectGuard redirige selon AppLaunchState / TunnelState
```

### Table des points d'entree

| point d'entree | fichier | responsabilite | dependances boot | notes |
| --- | --- | --- | --- | --- |
| `main(List<String> args)` | `lib/main.dart` | Initialise Flutter, les erreurs globales, MediaKit, le mode TV natif, puis installe `ProviderScope` et `AppStartupGate`. | `NativeTelevisionDevice`, `isTelevisionDeviceProvider`, `AppStartupGate`, `MyApp`. | C'est le point d'entree process. Il ne lance pas directement `AppLaunchOrchestrator`. |
| `AppStartupGate` | `lib/src/core/startup/app_startup_gate.dart` | Bloque l'affichage de `MyApp` tant que le bootstrap technique n'est pas termine. Affiche loading, erreur, safe mode ou app update blocking. | `appStartupProvider`, `appUpdateDecisionProvider`, `OverlaySplash`, `LaunchErrorPanel`. | Premier niveau de boot. Les erreurs ici sont des erreurs techniques avant router. |
| `appStartupProvider` | `lib/src/core/startup/app_startup_provider.dart` | Execute `AppStartupOrchestrator.run()` pour charger config, dependances, app state, logging, sync IPTV setup. | `AppStartupOrchestrator`, `ConfigAdapter`, `DependenciesAdapter`, `RiverpodAppStateControllerAdapter`, `IptvSyncAdapter`. | Ce provider est un `FutureProvider<StartupResult>`. Il est relance via `ref.invalidate`. |
| `MyApp` | `lib/src/app.dart` | Construit l'application principale avec `MaterialApp.router`, theme, locale, navigation remote et bootstrappers secondaires. | `appRouterProvider`, `currentLocaleProvider`, `currentAccentColorProvider`, `SubscriptionBootstrapper`, `LibraryCloudSyncBootstrapper`, `SeriesTrackingBootstrapper`. | Affiche seulement apres succes de `AppStartupGate`. |
| `appRouterProvider` | `lib/src/core/router/app_router.dart` | Cree le `GoRouter`, le `LaunchRedirectGuard`, definit la route initiale et branche les redirects. | `AppStateController`, `AppLogger`, `AuthRepository`, `AppLaunchStateRegistry`, `TunnelStateRegistry`, `featureFlagsProvider`. | Route initiale par defaut : `/launch`. Peut etre remplacee par `MOVI_INITIAL_ROUTE`. |
| route `/launch` / `_LaunchGate` | `lib/src/core/router/app_routes.dart` | Affiche un splash minimal et declenche le tunnel d'entree applicatif. | `appLaunchRunnerProvider`, `OverlaySplash`. | `_LaunchGate.initState()` appelle `appLaunchRunnerProvider('startup')` dans une microtask. |
| `appLaunchRunnerProvider` | `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart` | Logge le lancement applicatif puis appelle `AppLaunchOrchestrator.run()`. | `appLaunchOrchestratorProvider`, `LoggingService`. | C'est le declencheur direct de l'orchestrateur applicatif. |
| `appLaunchOrchestratorProvider` | `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart` | Expose `AppLaunchOrchestrator` comme `NotifierProvider`. | `AppLaunchOrchestrator`. | Produit `AppLaunchState`, observe par le guard et les surfaces de boot. |
| `AppLaunchOrchestrator.run()` | `lib/src/core/startup/app_launch_orchestrator.dart` | Execute le tunnel d'entree : startup, auth, profils, sources, catalogue, preload Home, destination. | Repositories auth/profil/source, preferences, catalog readers, refresh IPTV, home preload, registries, feature flags. | Source principale de decision du boot applicatif actuel. |
| `LaunchRedirectGuard` | `lib/src/core/router/launch_redirect_guard.dart` | Redirige selon auth, `AppLaunchState`, destination legacy ou `TunnelState` projete. | `AuthRepository`, `AppStateController`, `AppLaunchStateRegistry`, `TunnelStateRegistry`, flags entry journey. | Peut utiliser le routage projete si `enableEntryJourneyStateModelV2` et `enableEntryJourneyRoutingV2` sont actifs. |

### Premier widget applicatif affiche

Avant l'application principale, le premier widget visible est gere par
`AppStartupGate` :

- loading : `_StartupLoadingScreen`, qui affiche `OverlaySplash` ;
- erreur technique : `_StartupErrorScreen`, qui affiche `LaunchErrorPanel` ;
- safe mode : `_StartupSafeModeScreen`, qui affiche `LaunchErrorPanel` ;
- app update bloquante : `AppUpdateBlockedScreen`.

Apres succes de `AppStartupGate`, le premier widget du router principal est
`_LaunchGate`, car `GoRouter.initialLocation` vaut par defaut
`AppRoutePaths.launch`.

`_LaunchGate` affiche :

```text
Scaffold(body: OverlaySplash())
```

puis declenche le tunnel applicatif :

```text
Future.microtask(() => ref.read(appLaunchRunnerProvider)('startup'))
```

### Provider ou controller qui lance le boot

Le bootstrap technique est lance par :

```text
appStartupProvider -> AppStartupOrchestrator.run()
```

Le tunnel applicatif est lance par :

```text
_LaunchGate -> appLaunchRunnerProvider('startup') -> AppLaunchOrchestrator.run()
```

Le retry depuis `SplashBootstrapPage` utilise le meme runner :

```text
orchestrator.reset()
appLaunchRunnerProvider('retry')
```

### Flags et defines qui influencent le boot

| flag / define | fichier | effet observe | valeur actuelle par defaut observee |
| --- | --- | --- | --- |
| `MOVI_INITIAL_ROUTE` | `lib/src/core/router/app_router.dart` | Change la route initiale du `GoRouter`. | `AppRoutePaths.launch` si absent. |
| `FORCE_STARTUP_DETAILS` | `lib/src/core/startup/app_startup_gate.dart` | Force l'affichage des details techniques sur les erreurs de startup. | `false`. |
| `enableTelemetry` | `lib/src/core/config/models/feature_flags.dart` | Active la telemetrie generale. Conditionne aussi la telemetrie entry journey dans l'orchestrateur. | `true` dans dev/staging/prod actuels. |
| `enableEntryJourneyTelemetryV2` | `lib/src/core/config/models/feature_flags.dart` | Active les evenements `EntryJourneyTelemetry` si `enableTelemetry` est aussi actif. | `true` dans dev/staging/prod actuels. |
| `enableEntryJourneyStateModelV2` | `lib/src/core/config/models/feature_flags.dart` | Active le modele canonique/projete via `TunnelState` dans `AppLaunchOrchestrator` et le shadow orchestrator. | `false` dans dev/staging/prod actuels. |
| `enableEntryJourneyRoutingV2` | `lib/src/core/config/models/feature_flags.dart` | Permet au `LaunchRedirectGuard` d'utiliser le routage projete, mais seulement avec `enableEntryJourneyStateModelV2`. | `false` dans dev/staging/prod actuels. |
| `allowAuthStubFallback` | `lib/src/core/config/models/feature_flags.dart` | Autorise un fallback auth stub pendant l'initialisation des dependances. | `false` par defaut dans `FeatureFlags`. |
| `allowInMemoryStorageFallback` | `lib/src/core/config/models/feature_flags.dart` | Autorise un fallback SQLite memoire si le stockage persiste echoue. | `false` par defaut dans `FeatureFlags`. |

### Notes importantes pour les phases suivantes

- Le mot "boot" recouvre actuellement deux responsabilites differentes :
  startup technique avant `MyApp`, puis lancement applicatif apres `/launch`.
- Le premier ecran de boot Figma devra probablement remplacer ou adapter
  `_LaunchGate` / `SplashBootstrapPage`, mais pas forcement
  `AppStartupGate`, qui traite un niveau technique plus bas.
- `AppStartupGate` utilise deja `OverlaySplash` et `LaunchErrorPanel`, donc les
  messages generiques de startup technique sont aussi a auditer dans les phases
  UI/nettoyage.
- `LaunchRedirectGuard` peut fonctionner en mode legacy ou en mode routing V2
  projete. Les flags V2 sont presents mais desactives dans les environnements
  actuels.
- La route initiale peut etre forcee par `MOVI_INITIAL_ROUTE`. Les tests de boot
  doivent garder ce point en tete.

### Definition de fini - etape 1

- Le chemin depuis `main` jusqu'au premier ecran de boot est documente.
- Le provider qui lance le bootstrap technique est identifie.
- Le provider qui lance le tunnel applicatif est identifie.
- Les flags et defines qui changent le comportement de lancement sont listes.

## Etape 2 - Cartographie du routage boot

### Synthese

La cartographie detaillee est dans `boot_routes.md`.

Le routage boot actuel repose sur :

- les declarations de routes dans `app_routes.dart` ;
- le `LaunchRedirectGuard`, branche comme `GoRouter.redirect` et
  `refreshListenable` ;
- `AppLaunchOrchestrator`, qui produit une `BootstrapDestination` ;
- des navigations directes encore presentes dans plusieurs widgets welcome,
  auth et settings.

Routes boot documentees :

- `/launch` -> `_LaunchGate` ;
- `/auth/otp` -> `AuthPasswordPage` ou `AuthOtpPage` ;
- `/welcome/user` -> `WelcomeUserPage` ;
- `/welcome/sources` -> `WelcomeSourcePage` ;
- `/welcome/sources/select` -> `WelcomeSourceSelectPage` ;
- `/welcome/sources/loading` -> `WelcomeSourceLoadingPage` ;
- `/bootstrap` -> `SplashBootstrapPage` ;
- `/` -> `AuthGate(child: AppShellPage())`.

Observation importante : `/bootstrap` n'est pas une destination metier de
`BootstrapDestination`, mais reste une surface centrale du boot legacy. A
l'inverse, `/welcome/sources/loading` est bien une route de boot catalogue mais
n'est pas listee dans `AppRouteCatalog.criticalRoutes`; elle est traitee par une
exception dediee dans `LaunchRedirectGuard`.

### Decisions router vs orchestrateur

| decision | couche responsable actuelle | notes |
| --- | --- | --- |
| Route initiale | Router | `MOVI_INITIAL_ROUTE` peut remplacer `/launch`. |
| Lancement du tunnel applicatif | `_LaunchGate` | Appelle `appLaunchRunnerProvider('startup')`. |
| Destination metier | `AppLaunchOrchestrator` | Produit `BootstrapDestination`. |
| Application de la destination | `LaunchRedirectGuard` | Mappe `BootstrapDestination` vers une route. |
| Blocage Home si criteres incomplets | `LaunchRedirectGuard` | Redirige vers `/bootstrap`. |
| Chargement manuel apres ajout/selection source | `WelcomeSourceLoadingPage` | Contient encore logique catalogue et navigation vers Home. |
| Retour apres auth | Pages auth | Naviguent vers `/launch`. |
| Retry/reset depuis certaines pages | Widgets welcome/settings | Reset orchestrateur puis naviguent vers `/launch` ou `/bootstrap`. |

### Navigations directes identifiees

Les navigations directes principales sont documentees dans `boot_routes.md`.
Elles concernent surtout :

- retour auth vers `/launch` ;
- retry recovery vers `/launch` ;
- retour legacy vers `/bootstrap` ;
- ajout/selection source vers `/welcome/sources/loading` ;
- sortie de `WelcomeSourceLoadingPage` vers Home.

### Definition de fini - etape 2

- Toutes les routes boot sont reliees a un widget.
- Les navigations directes depuis les widgets sont identifiees.
- Les decisions prises par le router sont distinguees des decisions prises par
  l'orchestrateur.

## Etape 3 - Cartographie de l'orchestration

### Synthese

La cartographie detaillee est dans `orchestration.md`.

`AppLaunchOrchestrator` pilote le tunnel applicatif apres `/launch`. Il expose
`AppLaunchState`, maintient `AppLaunchCriteria`, met a jour
`AppLaunchStateRegistry` et `TunnelStateRegistry`, et produit la destination
consommee par `LaunchRedirectGuard`.

Phases actuelles :

- `init`
- `startup`
- `auth`
- `profiles`
- `sources`
- `localAccounts`
- `sourceSelection`
- `preloadCompleteHome`
- `done`

Transitions explicites :

- `init -> startup`
- `startup -> auth|done`
- `auth -> profiles|done`
- `profiles -> localAccounts|done`
- `localAccounts -> sources|sourceSelection|done`
- `sources -> localAccounts|sourceSelection|done`
- `sourceSelection -> preloadCompleteHome|done`
- `preloadCompleteHome -> done`

Observation importante : la phase `preloadCompleteHome` concentre plusieurs
etats UX distincts :

- verification snapshot catalogue ;
- refresh catalogue bloquant ;
- recovery source/catalogue ;
- preload Home ;
- preload library ;
- Home partiel.

Ces etats sont aujourd'hui visibles via `step`, `criteria`, logs, telemetry ou
`recoveryMessage`, mais pas comme phases dediees.

### Decisions principales

| decision | representation actuelle |
| --- | --- |
| Peut continuer sans session cloud | `AppLaunchCriteria.hasSession` n'est pas requis par `isHomeReady`. |
| Auth obligatoire | `completeSuccess(destination: auth)`. |
| Profil requis | `completeSuccess(destination: welcomeUser)`. |
| Source requise | `completeSuccess(destination: welcomeSources)`. |
| Selection source requise | `completeSuccess(destination: chooseSource)`. |
| Catalogue non recuperable | `completeSuccess(destination: welcomeSources, reasonCodeOverride: catalog recovery reason)`. |
| Home pret | `completeSuccess(destination: home)` avec `criteria.isHomeReady`. |
| Home partiel | `HomePartial` pose une degradation notice, mais Home reste atteignable. |
| Echec critique | `completeFailure()` avec `AppLaunchStatus.failure`. |

### Definition de fini - etape 3

- Les phases actuelles sont documentees.
- Les transitions implicites et explicites sont separees.
- Les etats qui n'ont pas encore de phase dediee sont listes.

## Etape 4 - Cartographie des contrats boot

### Synthese

La cartographie detaillee est dans `boot_contracts.md`.

Les contrats existants couvrent deja l'essentiel du futur refactor :

- decisions d'entree avec `EntryDecision` ;
- readiness catalogue avec `CatalogMode`, `CatalogSnapshot` et
  `ResolveCatalogReadiness` ;
- source recovery avec `SourceRecoveryRequired` ;
- Home complet/partiel avec `HomeReadiness` et `ResolveHomeDegradation` ;
- actions avec `RecoveryAction` ;
- reason codes avec `StartupRecoveryReasonCodes` ;
- etat runtime avec `AppLaunchState`, `AppLaunchPhase` et
  `AppLaunchCriteria`.

Conclusion : il ne faut pas reconstruire un nouveau modele complet. Il faut
ajouter un mapping UI stable au-dessus de ces contrats et etendre les zones ou
les etats Figma sont aujourd'hui implicites.

### Reutilisable

- `CatalogMode`
- `RecoveryAction`
- `EntryDecision`
- `HomeReadiness`
- `SourceRecoveryRequired`
- `StartupRecoveryReasonCodes`
- `ResolveEntryDecision`
- `ResolveCatalogReadiness`
- `ResolveHomeDegradation`
- `CatalogSnapshot`
- `AppLaunchCriteria`

### A etendre ou adapter

- `AppLaunchPhase`, car `preloadCompleteHome` couvre trop d'etats UX.
- `AppLaunchState`, qui doit alimenter un modele UI derive.
- `AppLaunchRecovery`, qui est actuellement auth-centrique.
- Le mapping catalogue `cached/stale`, actuellement traite comme `HomePartial`.
- Le mapping credentials invalid, dont le contrat existe mais dont l'emission
  reelle reste a verifier.

### A ne pas dupliquer

- `StartupRecoveryReasonCodes`
- `RecoveryAction`
- `EntryDecision`
- `BootstrapDestination`
- `TunnelState`

### Definition de fini - etape 4

- Les contrats reutilisables sont marques comme tels.
- Les concepts a etendre sont identifies.
- Les concepts a ne pas dupliquer sont identifies.

## Etape 5 - Cartographie catalogue et source

### Synthese

La cartographie detaillee est dans `catalog_source.md`.

Le chemin catalogue est execute dans `AppLaunchOrchestrator` pendant
`preloadCompleteHome`. L'orchestrateur lit un snapshot local avec
`CatalogSnapshotReader`, le passe a `ResolveCatalogReadiness`, puis lance un
refresh IPTV bloquant si le snapshot n'est pas ouvrable.

Chemin critique documente :

```text
catalog_snapshot_missing
  -> _ensureIptvCatalogReadyForLaunch()
  -> RefreshXtreamCatalog / RefreshStalkerCatalog
  -> persistence playlists/items + snapshot metadata
  -> catalog_snapshot_cached
  -> HomePartial ouvrable
  -> preload Home
  -> home
```

Point important : le snapshot qui decide l'ouverture Home est la presence
locale de playlists et d'items via `IptvLocalRepository`. Les snapshots caches
`XtreamCacheDataSource` et `StalkerCacheDataSource` sont bien persistants apres
refresh, mais `CatalogSnapshotReader` ne les lit pas directement.

### Conditions distinguees

| condition | signal actuel | decision actuelle |
| --- | --- | --- |
| Aucune source active | `activeIptvSourceIds` vide, log `no_active_sources`. | Refresh skip, puis catalogue non pret. |
| Source active inconnue localement | `missingActiveIds` non vide. | Log seulement, puis refresh continue. |
| Snapshot absent | `CatalogMode.missing`. | Refresh bloquant. |
| Playlists presentes sans items | `CatalogMode.empty` ou log `missing_playlist_items`. | Refresh bloquant. |
| Snapshot ouvrable | `CatalogMode.cached`. | Home ouvrable en `HomePartial`. |
| Refresh timeout | `iptvNetworkTimeout`. | Recovery `catalogSyncTimeout`. |
| Provider error | `iptvProviderError`. | Recovery `catalogProviderError`. |
| Credentials invalid | `CatalogRefreshOutcome.credentialsInvalid` existe. | Emission directe non observee dans le boot actuel. |
| Catalogue vide apres refresh | `iptvEmptyData` / `catalogEmpty`. | Recovery source vers `welcomeSources`. |
| Snapshot local indisponible | `CatalogMode.unavailable`. | Recovery `catalogSnapshotUnavailable`. |

### Points opaques pour l'UI

- Le refresh catalogue bloquant est cache dans `preloadCompleteHome`.
- Les sous-etats lecture snapshot, refresh source, verification apres refresh,
  preload Home et preload library n'ont pas de phase UI separee.
- Les cas `no_active_sources` et `active_sources_missing` peuvent etre aplatis
  en `catalogEmpty`.
- Les erreurs Stalker sont moins structurees que Xtream dans ce chemin.
- `fresh` et `stale` existent dans les contrats, mais le reader actuel produit
  surtout `missing`, `empty`, `cached` ou `unavailable`.

### Definition de fini - etape 5

- Le chemin `catalog_snapshot_missing -> refresh -> cached -> home` est
  documente.
- Les erreurs source distinguables sont listees.
- Les points ou l'UI reste opaque sont identifies.

## Etape 6 - Cartographie des widgets legacy

### Synthese

La cartographie detaillee est dans `legacy_widgets.md`.

Les widgets legacy du boot melangent actuellement trois responsabilites :

- affichage du boot et des erreurs ;
- actions utilisateur et focus TV ;
- decisions metier de source/catalogue, persistence et navigation.

Classement principal :

| widget | decision |
| --- | --- |
| `OverlaySplash` | Adapter pour la nouvelle UI boot. |
| `LaunchErrorPanel` | Adapter pour erreurs techniques, pas pour recovery metier complet. |
| `LaunchRecoveryBanner` | Remplacer. |
| `SplashBootstrapPage` | Remplacer comme surface boot principale. |
| `WelcomeSourcePage` | Refactor lourd. |
| `WelcomeSourceSelectPage` | Adapter en conservant la selection/focus. |
| `WelcomeSourceLoadingPage` | Extraire logique et remplacer l'UI. |

### Duplications identifiees

| duplication | consequence |
| --- | --- |
| Refresh catalogue dans `WelcomeSourceLoadingPage` et `AppLaunchOrchestrator`. | Deux chemins de timeout/provider error/catalogue vide. |
| Resolution source active dans widget et orchestrateur. | Risque d'etats divergents source absente/source invalide. |
| Navigation directe Home depuis `WelcomeSourceLoadingPage`. | Le widget contourne partiellement la decision router/orchestrateur. |
| Retry recovery dans plusieurs pages. | Actions reset/reload heterogenes. |
| Messages de chargement/recovery hardcodes. | Difficile de mapper proprement les ecrans Figma. |

### Messages a supprimer ou remplacer

- `recoveryMessage` concatene au message de splash.
- Mention utilisateur de `Supabase`.
- Messages techniques `Type de source inconnu`, `catalogue IPTV pas pret`.
- Labels hardcodes et melange FR-EN dans `WelcomeSourcePage`.
- Bouton hardcode `Reessayer` de `LaunchRecoveryBanner`.
- Compteur secondes de `OverlaySplash` si non retenu par la spec.

### Definition de fini - etape 6

- Les widgets a conserver, adapter ou remplacer sont classes.
- Les messages generiques a supprimer sont listes.
- Les duplications logique UI/orchestrateur sont identifiees.

## Etape 7 - Cartographie des composants UI reutilisables

### Synthese

La cartographie detaillee est dans `ui_components.md`.

Les composants de base sont deja presents :

- `MoviPrimaryButton` pour les actions principales ;
- `AppLabeledTextField` pour les champs ;
- `ProfileAvatarChip` pour les avatars profil ;
- `MoviAssetIcon` et `AppAssets` pour le logo et les icones ;
- les composants focus `FocusRegionScope`, `MoviFocusableAction`,
  `MoviFocusFrame`, `AppDirectionalFocusWrapper` et
  `MoviEnsureVisibleOnFocus`.

La palette et la typo Figma sont egalement deja couvertes par le theme :

- `rgb(20, 20, 20)` = `AppColors.darkBackground` ;
- `rgb(33, 96, 171)` = `AppColors.accent` ;
- Inter est deja la police du theme.

### Logo asset reel

Le logo reel a utiliser est :

```text
assets/branding/app_logo.svg
```

Il est expose par :

```text
AppAssets.iconAppLogoSvg
```

Le fallback raster existant est :

```text
assets/branding/app_icon.png
AppAssets.iconAppIconPng
```

Point important : `OverlaySplash` et `WelcomeHeader` recolorisent actuellement
le logo avec `color: accentColor`. Pour les ecrans boot Figma, il faut utiliser
le logo asset sans recolorisation si la maquette represente l'image reelle.

### Adaptations necessaires

| besoin | decision |
| --- | --- |
| Bouton Figma 250x50, radius 25, Inter 16/700 | Reutiliser `MoviPrimaryButton` avec variante boot. |
| Text input Figma radius 25, fond `#333333`, hauteur 50 | Reutiliser `AppLabeledTextField` avec decoration boot. |
| Avatar profil avec initiale | Adapter `ProfileAvatarChip` ou creer wrapper boot. |
| Header logo/titre/sous-titre | Creer `BootHeader`, `WelcomeHeader` n'est pas assez proche. |
| Chargement non interactif texte bas d'ecran | Creer/adaptater `BootLoadingScreen`, `OverlaySplash` est trop generique. |
| Recovery multi-actions | Creer `BootRecoveryScreen`; ne pas reutiliser `LaunchRecoveryBanner`. |
| Focus TV | Reutiliser les composants focus existants. |

### Variantes a creer

- `BootLogo`
- `BootHeader`
- `BootLoadingScreen`
- `BootPrimaryButton` ou configuration `MoviPrimaryButton.boot`
- `BootSecondaryButton`
- `BootTextField`
- `BootPasswordField`
- `BootProfileAvatarChip`
- `BootRememberChoiceCheckbox`
- `BootRecoveryScreen`

### Definition de fini - etape 7

- Les composants reutilisables sont confirmes.
- Les variantes a creer sont listees.
- Le logo asset reel est identifie.

## Etape 8 - Inventaire des tests existants

### Synthese

L'inventaire detaille est dans `existing_tests.md`.

La couverture est forte sur les contrats, l'orchestration et le router :

- `ResolveEntryDecision` ;
- `ResolveCatalogReadiness` ;
- `ResolveHomeDegradation` ;
- `StartupRecoveryMapper` ;
- `CatalogSnapshotReader` ;
- `AppLaunchOrchestrator` ;
- `LaunchRedirectGuard`.

La couverture est plus faible sur les futurs ecrans Figma :

- pas encore de test `BootLoadingScreen` ;
- pas encore de test `BootRecoveryScreen` ;
- pas encore de test du mapping UI `reasonCode -> texte/actions` ;
- pas encore de test du logo asset reel non recolorise ;
- pas encore de test focus TV sur les nouveaux ecrans boot.

### Tests a conserver

- Les tests de contrats purs dans `test/core/startup`.
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`.
- Les tests `LaunchRedirectGuard`.
- `test/core/router/new_user_auth_launch_flow_test.dart`.
- Les tests auth/profil/source connexes.

### Tests a adapter

| test | adaptation |
| --- | --- |
| `splash_bootstrap_page_progress_test.dart` | Remplacer par tests du nouveau modele UI boot. |
| `welcome_source_loading_page_test.dart` | Deplacer ou adapter les helpers si le widget legacy disparait. |
| `new_user_auth_launch_flow_test.dart` | Adapter au nouveau parcours UI/routes boot. |
| `launch_redirect_guard_*_test.dart` | Adapter si `/bootstrap` ou `welcomeSourceLoading` changent de role. |
| `welcome_user_page_auth_priority_test.dart` | Adapter aux nouveaux ecrans profil/auth Figma. |
| `auth_password_mode_and_reset_test.dart` | Adapter si les ecrans verification session remplacent les pages legacy. |

### Nouveaux tests necessaires

- `boot_ui_state_mapper_test.dart`
- `boot_loading_screen_test.dart`
- `boot_recovery_screen_test.dart`
- `boot_header_test.dart`
- `boot_text_field_test.dart`
- `boot_profile_avatar_chip_test.dart`
- `app_launch_orchestrator_credentials_invalid_test.dart`
- `app_launch_orchestrator_stalker_failure_test.dart`
- `boot_focus_graph_test.dart`
- `boot_no_generic_messages_test.dart`

### Definition de fini - etape 8

- Les tests a conserver sont identifies.
- Les tests a adapter apres refactor sont listes.
- Les nouveaux tests necessaires sont proposes.

## Etape 9 - Comportements a preserver

### Synthese

Les comportements a preserver sont detailles dans
`comportements_a_preserver.md`.

Invariants fonctionnels principaux :

- ouvrir Home rapidement avec un snapshot catalogue exploitable ;
- rediriger vers auth quand une session est requise ;
- conserver le mode local-first quand auth n'est pas obligatoire ;
- demander creation ou selection profil avant Home ;
- demander ajout ou selection source avant Home ;
- lancer un refresh source seulement quand aucun snapshot exploitable n'existe ;
- ouvrir Home partiellement pour les erreurs non critiques ;
- conserver des logs de boot exploitables ;
- garantir un focus TV sur l'action principale ;
- eviter les boucles router et les runs concurrents.

### Risques majeurs

| risque | protection existante |
| --- | --- |
| Home bloque malgre un catalogue local exploitable. | Tests orchestrateur local snapshot + `ResolveCatalogReadiness`. |
| Auth imposee alors que le mode local-first est autorise. | `ResolveEntryDecision` + tests orchestrateur local-first. |
| Catalogue vide ou source invalide ouvrant Home. | `AppLaunchCriteria`, tests refresh/catalog recovery. |
| Recovery affiche de mauvaises actions. | `StartupRecoveryMapper` et tests `ResolveCatalogReadiness`; nouveau test UI requis. |
| Perte de focus TV dans les nouveaux ecrans. | Tests focus core existants ; nouveau test boot focus requis. |
| Logs inutilisables apres refactor. | Tests telemetry/logging existants ; tests supplementaires requis pour UI/no generic messages. |

### Filet de securite prioritaire

```text
flutter test test/core/startup
flutter test test/core/router
flutter test test/features/welcome
flutter test test/features/auth/presentation/auth_password_mode_and_reset_test.dart
```

### Definition de fini - etape 9

- Les invariants sont explicites.
- Les risques de regression sont connus.
- Les phases suivantes peuvent changer le code avec un filet de securite.

## Etape 10 - Synthese Phase 0

### Synthese courte

La phase 0 confirme que le refactor du boot doit conserver deux niveaux
separes :

- le bootstrap technique avant `MyApp`, porte par `AppStartupGate` ;
- le tunnel applicatif apres `/launch`, porte par `AppLaunchOrchestrator`,
  `AppLaunchState` et `LaunchRedirectGuard`.

Le coeur metier existe deja. Les phases suivantes doivent surtout :

- exposer les sous-etats du boot dans un modele UI stable ;
- remplacer les surfaces legacy par les ecrans Figma ;
- supprimer les doublons entre widgets, router et orchestrateur ;
- renforcer les tests sur le mapping UI, les erreurs source et le focus TV.

### Etats deja couverts

| etat | couverture actuelle | reference |
| --- | --- | --- |
| Bootstrap technique en cours | `AppStartupGate` affiche `OverlaySplash`. | `AppStartupGate`, `appStartupProvider`. |
| Erreur technique avant app | `LaunchErrorPanel` affiche erreur, safe mode ou update bloquante. | `AppStartupGate`, `LaunchErrorPanel`. |
| Lancement applicatif | `/launch` affiche `_LaunchGate` et declenche `appLaunchRunnerProvider('startup')`. | `app_routes.dart`, `bootstrap_providers.dart`. |
| Auth requise | `EntryDecision` et `AppLaunchOrchestrator` redirigent vers `auth`. | `ResolveEntryDecision`, `AppLaunchPhase.auth`. |
| Profil requis | `profiles` redirige vers `welcomeUser`. | `AppLaunchPhase.profiles`. |
| Source requise | `sources` redirige vers `welcomeSources`. | `AppLaunchPhase.sources`. |
| Selection source requise | `sourceSelection` redirige vers `welcomeSourceSelect`. | `AppLaunchPhase.sourceSelection`. |
| Snapshot catalogue ouvrable | `CatalogMode.cached` permet Home partiel puis Home. | `CatalogSnapshotReader`, `ResolveCatalogReadiness`. |
| Home partiel | `HomeReadiness.partial` conserve Home avec degradation notice. | `ResolveHomeDegradation`, `HomePartial`. |
| Routing Home | `LaunchRedirectGuard` applique la destination `home`. | `LaunchRedirectGuard`. |

### Etats partiellement couverts

| etat | couverture actuelle | manque pour le refactor |
| --- | --- | --- |
| Lecture snapshot catalogue | Cachee dans `preloadCompleteHome`. | Etat UI explicite `checkingCatalog` ou equivalent. |
| Refresh catalogue bloquant | Execute dans `_ensureIptvCatalogReadyForLaunch`. | Etat UI dedie avec texte bas d'ecran Figma. |
| Verification apres refresh | Relit le snapshot apres refresh. | Etat UI/log distinct pour eviter l'opacite. |
| Preload Home | Dans `preloadCompleteHome`. | Etat UI separe de la preparation catalogue. |
| Preload library | Execute apres Home preload. | Etat UI/log separe si visible utilisateur. |
| Credentials invalid | Contrat `CatalogRefreshOutcome.credentialsInvalid` existe. | Emission runtime a confirmer et tester. |
| Stalker provider failure | Refresh Stalker existe. | Mapping reason code/log moins robuste que Xtream. |
| Catalogue stale/fresh | Contrats disponibles. | `CatalogSnapshotReader` produit surtout `cached`, pas `fresh/stale`. |
| Recovery source/catalogue | Reason codes et actions existent. | Ecran Figma multi-actions et mapping UI manquants. |

### Etats manquants

| etat manquant | raison |
| --- | --- |
| Modele UI boot canonique | `AppLaunchState` est metier/runtime, pas un contrat d'affichage Figma. |
| Mapping `reasonCode -> ecran -> texte -> actions` | Les reason codes existent, mais les textes/actions sont disperses. |
| Chargement non interactif Figma | `OverlaySplash` ne respecte pas le placement texte bas d'ecran. |
| Recovery Figma plein ecran | `LaunchRecoveryBanner` est un bandeau legacy. |
| Logo boot asset non recolorise | Les widgets existants recolorisent parfois le logo. |
| Tests anti-messages generiques | Aucun test ne verrouille les nouveaux textes utilisateur. |
| Tests focus TV des ecrans boot Figma | Les briques focus existent, pas le graphe des nouveaux ecrans. |

### Doublons a supprimer

| doublon | action recommandee |
| --- | --- |
| Refresh catalogue dans `WelcomeSourceLoadingPage` et `AppLaunchOrchestrator`. | Garder la decision metier dans l'orchestrateur ou un use case dedie, laisser le widget afficher l'etat. |
| Resolution source active dans widgets et orchestrateur. | Centraliser dans les contrats/use cases startup. |
| Navigation directe vers Home depuis `WelcomeSourceLoadingPage`. | Laisser `LaunchRedirectGuard` appliquer la destination finale. |
| Retry/reset implemente dans plusieurs surfaces. | Passer par une action boot unique mappee depuis le modele UI. |
| Messages de chargement/recovery hardcodes. | Centraliser dans le mapping UI Figma. |
| `/bootstrap` comme surface legacy en plus de `/launch`. | Clarifier ou retirer son role pendant le refactor router. |

### Widgets a remplacer

| widget | decision |
| --- | --- |
| `SplashBootstrapPage` | Remplacer comme surface principale du boot applicatif. |
| `LaunchRecoveryBanner` | Remplacer par un ecran recovery Figma. |
| `WelcomeSourceLoadingPage` | Remplacer l'UI et extraire la logique catalogue. |
| `OverlaySplash` pour boot applicatif | Remplacer ou limiter au bootstrap technique. |

### Widgets a conserver ou adapter

| widget / composant | decision |
| --- | --- |
| `AppStartupGate` | Conserver comme bootstrap technique, adapter seulement ses surfaces visuelles si necessaire. |
| `LaunchErrorPanel` | Conserver pour erreurs techniques, ne pas l'utiliser comme recovery metier principal. |
| `WelcomeSourcePage` | Refactor lourd : conserver les controles utiles, retirer logique/messages legacy. |
| `WelcomeSourceSelectPage` | Adapter, conserver selection source et focus. |
| `MoviPrimaryButton` | Reutiliser avec variante boot. |
| `AppLabeledTextField` | Reutiliser avec decoration boot. |
| `ProfileAvatarChip` | Adapter via wrapper boot. |
| `MoviAssetIcon` / `AppAssets` | Reutiliser pour `assets/branding/app_logo.svg`. |
| Composants focus | Reutiliser pour garantir l'action principale TV. |

### Tests a renforcer

| zone | test recommande |
| --- | --- |
| Mapping UI boot | `boot_ui_state_mapper_test.dart`. |
| Chargements Figma | `boot_loading_screen_test.dart`. |
| Recovery Figma | `boot_recovery_screen_test.dart`. |
| Header/logo | `boot_header_test.dart` avec logo asset non recolorise. |
| Champs | `boot_text_field_test.dart`. |
| Avatars profil | `boot_profile_avatar_chip_test.dart`. |
| Credentials invalid | `app_launch_orchestrator_credentials_invalid_test.dart`. |
| Stalker failure | `app_launch_orchestrator_stalker_failure_test.dart`. |
| Focus TV | `boot_focus_graph_test.dart`. |
| Textes utilisateur | `boot_no_generic_messages_test.dart`. |

### Fichiers candidats au refactor

| priorite | fichier | action |
| --- | --- | --- |
| Haute | `lib/src/core/startup/app_launch_orchestrator.dart` | Extraire ou expliciter les sous-etats de `preloadCompleteHome`. |
| Haute | `lib/src/core/router/app_routes.dart` | Remplacer les surfaces legacy du boot et clarifier `/launch` vs `/bootstrap`. |
| Haute | `lib/src/core/router/launch_redirect_guard.dart` | Verifier le role des destinations boot apres nouveau modele UI. |
| Haute | `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart` | Remplacer par l'ecran boot applicatif Figma. |
| Haute | `lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart` | Extraire logique catalogue, supprimer navigation directe Home. |
| Moyenne | `lib/src/features/welcome/presentation/pages/welcome_source_page.dart` | Adapter aux composants Figma et retirer messages legacy. |
| Moyenne | `lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart` | Adapter UI/focus au parcours boot cible. |
| Moyenne | `lib/src/core/widgets/overlay_splash.dart` | Limiter au bootstrap technique ou adapter en composant bas niveau. |
| Moyenne | `lib/src/core/widgets/launch_error_panel.dart` | Garder pour technique, separer du recovery metier. |
| Moyenne | `lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart` | Supprimer/remplacer apres migration recovery Figma. |
| Nouvelle surface | `lib/src/core/startup/presentation` ou equivalent | Ajouter modele UI boot, mapper et widgets Figma reutilisables. |
| Tests | `test/core/startup`, `test/core/router`, `test/features/welcome` | Adapter tests existants et ajouter les tests manquants listes. |

### Definition de fini - phase 0

- Les chemins existants sont connus.
- Les fichiers a modifier sont identifies.
- Les comportements a ne pas casser sont explicites.
- Les doublons et messages generiques a supprimer sont listes.
- Les composants reutilisables et variantes a creer sont identifies.
- Les tests a conserver, adapter et ajouter sont connus.
- La phase 1 peut demarrer sans nouvelle exploration large.

# Rollout et fallback legacy

## Decision

Le refactor boot garde trois interrupteurs separes :

- `enableEntryJourneyStateModelV2` : active la projection canonique
  `TunnelState` dans l'orchestrateur.
- `enableEntryJourneyRoutingV2` : autorise le guard a appliquer les surfaces
  routees depuis `TunnelState`, seulement si le state model V2 est aussi actif.
- `enableBootScreenRenderer` : nouveau flag dedie au futur renderer Figma base
  sur `BootScreenModel`.

Le renderer boot ne doit pas etre couple au routing V2. On doit pouvoir tester
le renderer sur `/launch` avec le routage legacy, et inversement tester le
routage V2 avec les surfaces legacy.

## Table de rollout

| flag | valeur defaut | chemin active | chemin fallback | rollback | log attendu |
| --- | --- | --- | --- | --- | --- |
| `enableEntryJourneyTelemetryV2` | `true` dans dev/staging/prod, mais effectif seulement si `enableTelemetry=true` | Emet les evenements `entry_journey_*` en shadow/observation. | Aucun changement de route ni d'UI. | Mettre a `false` si les logs sont trop bruyants. | `[EntryJourney] ... result=...` via `EntryJourneyTelemetry`. |
| `enableEntryJourneyStateModelV2` | `false` dans dev/staging/prod | `AppLaunchOrchestrator` projette `AppLaunchState` vers `TunnelState` canonique. | `LegacyTunnelStateBridge.fromLaunchState`. | Mettre a `false`; le guard revient aux destinations legacy. | `[Startup] action=phase_transition ...` reste; ajouter en Phase 3/4 un log `boot_rollout state_model=canonical|legacy`. |
| `enableEntryJourneyRoutingV2` | `false` dans dev/staging/prod | `LaunchRedirectGuard` utilise `TunnelSurfaceRouteMapper` si state model V2 actif. | Mapping legacy `BootstrapDestination -> route`. | Mettre a `false`; le guard applique a nouveau les destinations legacy. | Log guard cible : `boot_rollout routing=projected|legacy current=... target=... reason=...`. |
| `enableBootScreenRenderer` | `false` dans dev/staging/prod | `/launch` puis `/bootstrap` pourront consommer `bootScreenModelProvider` et rendre les ecrans Figma. | `OverlaySplash`, `SplashBootstrapPage`, pages welcome/source legacy. | Mettre a `false`; l'UI revient aux surfaces legacy sans changer orchestration/router. | Log cible : `boot_rollout renderer=figma|legacy screenType=... reason=... fallback=...`. |
| `allowAuthStubFallback` | `false` | Autorise un repository auth stub si Supabase n'est pas disponible. | Erreur de configuration ou auth normale. | Laisser `false` en execution normale; ne pas utiliser comme flag boot. | Logs auth/config existants uniquement. |
| `allowInMemoryStorageFallback` | `false` | Autorise SQLite memoire si le stockage persistant echoue. | Erreur stockage normale. | Laisser `false` en execution normale; ne pas utiliser comme flag boot. | Logs storage/config existants uniquement. |

## Ordre d'activation recommande

1. Garder `enableBootScreenRenderer=false` tant que les ecrans Figma ne sont pas
   branches.
2. Activer `enableEntryJourneyTelemetryV2` seul pour observer sans changer le
   routage.
3. Activer `enableEntryJourneyStateModelV2` en dev pour comparer projection et
   legacy.
4. Activer `enableEntryJourneyRoutingV2` seulement quand les tests router
   critiques couvrent auth, profil, source, loading source, Home et Home
   partiel.
5. Activer `enableBootScreenRenderer` d'abord sur `/launch` uniquement, avec
   fallback automatique vers `OverlaySplash` si le mapper retourne un modele
   incomplet.
6. Etendre le renderer a `/bootstrap` quand failure/recovery et Home non pret
   sont couverts.

## Fallback attendu

| surface | chemin refactor | fallback legacy | condition de rollback |
| --- | --- | --- | --- |
| `/launch` | `BootScreenModel` + renderer Figma | `_LaunchGate` + `OverlaySplash` | flag renderer off, mapper null, exception renderer |
| `/bootstrap` | renderer failure/recovery/home-preparing | `SplashBootstrapPage`, `LaunchErrorPanel`, `OverlaySplash` | flag renderer off, recovery non mappee |
| auth | pages auth existantes raccordees a `BootActionIntent.retry` | pages auth existantes | ne pas remplacer avant Phase 4 |
| profil | `WelcomeUserPage` raccordee au handler | `WelcomeUserPage` legacy | erreur formulaire ou profil non mappe |
| source | `WelcomeSourcePage` / `WelcomeSourceSelectPage` raccordees au handler | pages source legacy | erreur formulaire ou selection non mappee |
| chargement catalogue | orchestration catalogue cible Phase 3 | `WelcomeSourceLoadingPage` | tant que refresh catalogue reste dans le widget |

## Rollback simple

Pour revenir au comportement stable actuel :

```dart
FeatureFlags(
  enableEntryJourneyStateModelV2: false,
  enableEntryJourneyRoutingV2: false,
  enableBootScreenRenderer: false,
)
```

Ce rollback conserve :

- l'orchestrateur legacy `AppLaunchOrchestrator`;
- le mapping `BootstrapDestination -> route`;
- les pages auth/profil/source existantes;
- `OverlaySplash` et `SplashBootstrapPage`.

## Logs a ajouter pendant le branchement UI

Les logs existants distinguent deja une partie du boot :

- `[AppLaunch] action=run reason=...`
- `[Startup] action=phase_transition ...`
- `[Startup] action=catalog_readiness ...`
- `[Startup] action=preload_home ...`
- `[EntryJourney] ...` quand la telemetry V2 est active.

Les phases suivantes doivent ajouter des logs log-safe aux points de bascule :

| point | log attendu |
| --- | --- |
| provider renderer lu | `[Startup] action=boot_renderer result=selected mode=figma|legacy reason=...` |
| fallback renderer | `[Startup] action=boot_renderer result=fallback code=mapper_null|renderer_error mode=legacy` |
| guard routing V2 | `[Startup] action=boot_routing result=projected current=... target=... reason=...` |
| guard routing legacy | `[Startup] action=boot_routing result=legacy current=... target=... destination=...` |
| rollback manuel | `[Startup] action=boot_rollout result=disabled renderer=false routingV2=false stateModelV2=false` |

Les logs ne doivent jamais afficher les textes utilisateur du
`BootScreenModel`; seuls `screenType`, `reasonCode`, routes et flags sont
autorises.

## Tests a prevoir

| test | scenario | assertion critique |
| --- | --- | --- |
| `feature_flags_test.dart` | flag renderer par defaut | `enableBootScreenRenderer == false` |
| `boot_renderer_fallback_test.dart` | flag off | `/launch` conserve `OverlaySplash` |
| `boot_renderer_fallback_test.dart` | mapper null ou exception renderer | fallback legacy et log `boot_renderer result=fallback` |
| `launch_redirect_guard_boot_alignment_test.dart` | routing V2 off | guard reste en mapping legacy |
| `launch_redirect_guard_tunnel_surface_test.dart` | routing V2 on + state model V2 on | guard applique surfaces projetees |

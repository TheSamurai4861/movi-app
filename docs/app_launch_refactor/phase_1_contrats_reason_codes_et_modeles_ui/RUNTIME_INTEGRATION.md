# Integration minimale au runtime

## Decision

Le branchement minimal doit ajouter un provider de projection UI sans changer
immediatement le routage ni supprimer les surfaces legacy.

Provider cible :

```text
bootScreenModelProvider
```

Emplacement cible :

```text
lib/src/core/startup/presentation/boot_screen_providers.dart
```

Sources :

- `appLaunchStateProvider` comme source runtime principale ;
- `BootScreenMapper` comme projection `AppLaunchState -> BootScreenModel` ;
- contrats domaine existants pour les cas action/recovery ;
- `TunnelStateRegistry` seulement pour coherence router/projection, pas comme
  modele UI final.

## Table d'integration

| source runtime | projection | provider expose | consommateur actuel | consommateur cible | fallback |
| --- | --- | --- | --- | --- | --- |
| `appLaunchStateProvider` | `BootScreenMapper.fromLaunchState(AppLaunchState)` | `bootScreenModelProvider` | `_LaunchGate` affiche `OverlaySplash`; `SplashBootstrapPage` lit orchestrateur. | Nouveau renderer boot sur `/launch` ou `/bootstrap`. | Si mapper retourne null ou flag desactive, conserver `OverlaySplash` / `SplashBootstrapPage`. |
| `AppLaunchState.status=idle/running` | Etat loading derive selon phase. | `bootScreenModelProvider` | `OverlaySplash` generique. | `BootLoadingScreen` avec message specifique. | Message legacy `Preparation de l'accueil...`. |
| `AppLaunchPhase.auth/profiles/sources/sourceSelection` | `session_check`, `profile_check`, `source_check` ou action required selon destination/reason. | `bootScreenModelProvider` | Pages welcome/auth legacy + router. | Loading simple ou action required Figma. | Garder routes auth/welcome existantes comme pages d'action. |
| `AppLaunchPhase.catalogPreparing` cible | `catalog_preparing`. | `bootScreenModelProvider` | Etat cache dans `preloadCompleteHome`. | `BootLoadingScreen` catalogue. | Tant que la phase n'existe pas, mapper depuis sous-etat/reason code si disponible, sinon legacy splash. |
| `HomeReadiness` / reason catalogue | `openingHome`, `recovery`, `homePartialNotice`. | `bootScreenModelProvider` ou mapper dedie Home notice. | Recovery via `welcomeSources`, Home degradation notice existante. | `BootRecoveryScreen` avant Home, notice Home partiel apres Home. | Conserver `LaunchRecoveryBanner`/notice existante jusqu'a Phase 4/5. |
| `StartupRecoveryPlan` | `technicalFailure`. | Provider technique separe ou entree du mapper. | `AppStartupGate` + `LaunchErrorPanel`. | `BootRecoveryScreen` technique si choisi. | Garder `LaunchErrorPanel` pour startup technique. |
| `TunnelStateRegistry` | Coherence router/projection uniquement. | Aucun nouveau provider UI direct. | `LaunchRedirectGuard` routing V2 optionnel. | Reste router/projection route, pas renderer Figma. | Si flags V2 off, comportement legacy inchange. |
| `LaunchRedirectGuard` | Destination router finale. | Aucun provider UI. | Redirige selon `AppLaunchState` ou `TunnelState`. | Continue a appliquer les destinations. | Ne pas brancher `BootScreenModel` dans le guard en Phase 1. |

## Provider cible

Pseudo-structure :

```dart
final bootScreenMapperProvider = Provider<BootScreenMapper>((ref) {
  return const BootScreenMapper();
});

final bootScreenModelProvider = Provider<BootScreenModel>((ref) {
  final launchState = ref.watch(appLaunchStateProvider);
  final mapper = ref.watch(bootScreenMapperProvider);
  return mapper.fromLaunchState(launchState);
});
```

Le provider doit rester pur :

- pas de navigation ;
- pas de side effect ;
- pas de refresh ;
- pas de log obligatoire ;
- pas de lecture storage/reseau.

## Interaction avec `TunnelStateRegistry`

`TunnelStateRegistry` reste utile pour :

- routing V2 ;
- comparaison shadow ;
- surface router abstraite.

Il ne doit pas devenir la source principale du rendu Figma parce que ses stages
sont trop grossiers :

- `preloadingHome` ne distingue pas `catalog_preparing` et `opening_home` ;
- `sourceRequired` ne distingue pas toutes les recoveries source ;
- Home partiel n'est pas assez riche pour une notice UI finale.

Decision : `BootScreenModel` observe `AppLaunchState` directement en Phase 2,
avec un mapper dedie. `TunnelState` peut etre utilise comme fallback de
coherence, pas comme modele UI.

## Interaction avec `LaunchRedirectGuard`

Le guard doit continuer a appliquer les destinations.

Regles :

- `BootScreenModel` ne decide pas seul la navigation ;
- les destinations du model sont des intentions pour le handler/UI ;
- `LaunchRedirectGuard` reste source d'application router ;
- pendant `catalogPreparing`, le guard ne doit pas rediriger vers une recovery
  tant qu'aucune destination finale n'est produite ;
- les routes auth/profil/source restent atteignables comme pages d'action.

En Phase 2, il faudra verifier que l'ajout de `AppLaunchPhase.catalogPreparing`
ne casse pas les conditions :

```text
launchState.status == running && isStartupRoute -> rester /launch
launchState.status == success -> appliquer destination
```

## Fallback legacy

Le fallback temporaire est explicite :

| surface | comportement cible | fallback jusqu'a migration |
| --- | --- | --- |
| `/launch` / `_LaunchGate` | Lire `bootScreenModelProvider` et afficher renderer boot. | `OverlaySplash`. |
| `/bootstrap` / `SplashBootstrapPage` | Remplacer par renderer boot ou wrapper autour du model. | `SplashBootstrapPage` existant. |
| Erreurs techniques startup | `BootRecoveryScreen` technique si retenu. | `LaunchErrorPanel`. |
| Recovery source | `BootRecoveryScreen`. | `WelcomeSourcePage`, `WelcomeSourceLoadingPage`, `LaunchRecoveryBanner` selon chemin legacy. |
| Home partiel | Notice Home partiel. | Notice/degradation existante. |

Le fallback doit etre controle par un flag de rollout si l'implementation UI est
branchée avant suppression legacy :

```text
enableBootScreenModelRenderer
```

Ce flag n'existe pas encore. Il peut etre ajoute en Phase 2/4 si le branchement
progressif est necessaire.

## Limites pour la Phase 2

Cette integration minimale ne resout pas encore :

- l'ajout effectif de `AppLaunchPhase.catalogPreparing` ;
- le mapping runtime `credentialsInvalid` ;
- la suppression des navigations directes legacy ;
- le remplacement de `SplashBootstrapPage` ;
- le handler central des actions `BootActionIntent` ;
- les textes localises definitifs ;
- les widgets Figma finaux.

Elle donne seulement un point stable pour brancher ces changements.

## Tests a prevoir

| test | objectif |
| --- | --- |
| `boot_screen_provider_test.dart` | `bootScreenModelProvider` observe `appLaunchStateProvider` et produit un model stable. |
| `boot_screen_provider_no_side_effect_test.dart` | Lire le provider ne lance pas navigation/run/refresh. |
| `launch_redirect_guard_catalog_preparing_test.dart` | Le guard reste sur `/launch` pendant `catalogPreparing`. |
| `boot_renderer_fallback_test.dart` | Flag off ou mapper indisponible garde `OverlaySplash`/legacy. |
| `boot_tunnel_state_coherence_test.dart` | `BootScreenModel` et `TunnelState` ne divergent pas sur les destinations majeures. |

## Definition de fini - etape 9

- Le point de branchement UI est connu.
- La phase 2 peut raccorder orchestration/routage sans redecouvrir les contrats.
- Le fallback legacy est explicite pendant la migration.

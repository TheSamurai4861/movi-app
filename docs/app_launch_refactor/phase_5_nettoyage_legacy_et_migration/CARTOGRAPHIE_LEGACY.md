# Phase 5.1 - Cartographie legacy

Objectif: inventorier les surfaces boot coexistantes et poser, pour chacune,
le statut de migration cible (remplacement par renderer unifie ou conservation).

## Perimetre

Surfaces demandees dans la roadmap:

- `SplashBootstrapPage`
- `LaunchErrorPanel`
- `LaunchRecoveryBanner`
- `OverlaySplash`
- `WelcomeSourceLoadingPage`

## Tableau de cartographie

| Surface | Etats affiches | Dependances (providers/routes/bridges) | Remplacant cible | Decision 5.1 |
| --- | --- | --- | --- | --- |
| `SplashBootstrapPage` | Chargements boot (`simpleLoading`, `catalogLoading`, `openingHome`) + recovery actionnable (`bootModel.isInteractive` ou `launchState.error != null`) | Providers: `appLaunchStateProvider`, `bootScreenModelProvider`, `homeBootstrapProgressStageProvider`. Actions: `executeBootAction` + `BootActionRequest`. Focus: `FocusRegionScope` (`AppFocusRegionId.splashBootstrapPrimary`). Route: `AppRouteIds.bootstrap` (`/bootstrap`). | Cible principale du renderer unifie (point d'entree tunnel boot). | **Conserver comme hote principal**; extraire renderer dedie en 5.2 seulement si utile. |
| `LaunchErrorPanel` | Recovery erreur avec une action principale retry (+ details optionnels) | Pas de provider direct; encapsule `BootRecoveryPanel`. Usages: `AppStartupGate` (startup), `ProviderResultsPage` et `ProviderAllResultsPage` (recherche). Pas de route dediee. | Pour boot: `BootRecoveryPanel` deja utilise. Pour recherche: panneau erreur feature-level. | **Scinder par contexte**: conserver hors boot (recherche), reduire usage boot au strict necessaire. |
| `LaunchRecoveryBanner` | Bandeau retry compact quand `launchRecovery.isRetryable` (welcome/shell) | Depend de `appLaunchStateProvider.recovery` dans `WelcomeUserPage`, `WelcomeSourcePage`, `WelcomeSourceSelectPage`, `AppShellPage`. Actions: `executeBootAction` (welcome) ou `appLaunchOrchestratorProvider.reset()` + `context.go('/launch')` (shell). Pas de route dediee. | Soit remplacer par surface recovery unifiee, soit conserver comme variante compacte hors tunnel splash. | **A auditer en 5.3/5.4**: conserver temporairement, harmoniser style et role. |
| `OverlaySplash` | Chargement non interactif (logo centre + spinner/message bas) | Wrapper de `BootSimpleLoadingScreen`. Usages larges (startup, auth gate, home loading overlay, pages movie/tv/person/saga, welcome source loading). Pas de route dediee. | Primitive de chargement transverse (pas strictement boot). | **Conserver** comme composant shared; ne pas supprimer en bloc. |
| `WelcomeSourceLoadingPage` | Chargement catalogue source, erreurs retry/select source, puis transition Home | Providers/services: `authRepositoryProvider`, `appLaunchOrchestratorProvider`, `asp.appStateControllerProvider`, `slProvider` (`IptvLocalRepository`, `SelectedIptvSourcePreferences`), use cases `refreshXtreamCatalog`/`refreshStalkerCatalog`, `shellControllerProvider`, `executeBootAction`. Routes: `AppRouteIds.welcomeSourceLoading` (`/welcome/sources/loading`), retours vers `/welcome/sources` ou `/welcome/sources/select`, sortie Home via action boot. | Remplacement par tunnel boot unifie + actions source standardisees. | **Candidat prioritaire a reduction/suppression** (duplication forte logique catalogue/orchestrateur). |

## Dependances transverses a noter (bridges)

- Bridge shadow legacy -> tunnel: `LegacyTunnelStateBridge` via
  `entryJourneyShadowOrchestratorProvider` (dans `bootstrap_providers.dart`).
- Compat navigation paths: `AppRouteNames` (alias de `AppRoutePaths`) encore
  utilises dans des flux welcome legacy.

## Synthese migration (sortie 5.1)

- Surfaces a garder comme base:
  - `SplashBootstrapPage` (hote principal du boot unifie).
  - `OverlaySplash` (loading shared hors boot strict).
- Surfaces a migrer/resserrer:
  - `WelcomeSourceLoadingPage` (priorite haute).
  - usages boot de `LaunchErrorPanel`.
  - usages `LaunchRecoveryBanner` a trier par contexte.
- Surfaces a conserver hors boot:
  - `LaunchErrorPanel` sur pages recherche.

## Prochaines etapes alimentees par cette cartographie

- 5.2: brancher explicitement le renderer unifie sur le chemin principal sans
  concurrence UI.
- 5.3: retirer la logique catalogue critique de `WelcomeSourceLoadingPage`.
- 5.4: classifier routes legacy en `conservee` / `redirigee` / `supprimee`.

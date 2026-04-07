# Sous-phase 3.5 - Composition root, routing et state management

## Objectif

Clarifier le role de `Riverpod`, `GetIt`, du routeur et du composition root dans l'architecture cible du tunnel.

Cette sous-phase ne re-ouvre pas les contrats metier. Elle fixe comment ces contrats seront:
- assembles
- exposes
- observes
- derives en surfaces UI

## Diagnostic de l'existant

Le wiring actuel repose deja sur une combinaison `GetIt + Riverpod + GoRouter`, mais les responsabilites restent floues.

Constats principaux:
- [di.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/di/di.dart) expose `GetIt` dans Riverpod via `slProvider`
- [app_router.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_router.dart) construit `GoRouter` dans un provider Riverpod, mais lui injecte `AppLaunchStateRegistry`
- [app_state_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_controller.dart) est un `Notifier` Riverpod qui lit lui-meme dans `GetIt`
- beaucoup de providers presentation lisent directement `slProvider`
- [app.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/app.dart) consomme `appRouterProvider` comme point d'entree applicatif

Probleme:
- `GetIt` sert a la fois de composition root et de container de lecture presentation
- `Riverpod` sert a la fois de store UI et de bridge vers `GetIt`
- le routeur consomme encore un etat de tunnel transitoire plutot qu'un contrat canonique

## Doctrine cible recommandee

La cible recommandee est:

- `GetIt` assemble les implementations concretes
- `Riverpod` expose les facades, stores et derivees utiles a la presentation
- `GoRouter` projette l'etat en navigation
- le composition root initialise et relie ces briques une seule fois

En une phrase:
- `GetIt builds`
- `Riverpod exposes`
- `Orchestrator decides`
- `GoRouter projects`

## 1. Role cible de `GetIt`

`GetIt` reste le composition container principal pour:
- adapters infra
- repositories concrets
- services SDK
- use cases d'application
- ports relies a des implementations concretes

`GetIt` doit etre la ou l'on:
- instancie
- relie
- remplace en test d'integration

`GetIt` ne doit pas etre:
- la source de verite d'etat UI
- un mecanisme de lecture direct depuis la majorite des widgets
- un substitut a des providers d'exposition applicative

## Regle cible pour `GetIt`

Autorise:
- `injector.dart` et modules d'enregistrement
- bindings infra
- tests qui poussent un scope GetIt isole

A reduire fortement:
- `ref.watch(slProvider)<SomeService>()` dans les widgets et providers presentation

## 2. Role cible de `Riverpod`

`Riverpod` devient la couche d'exposition et d'observation de l'application vers l'UI.

`Riverpod` doit porter:
- `TunnelState` observe par la presentation
- commandes UI-friendly derivees de l'orchestrateur
- `appRouterProvider`
- etats UI locaux ou ecran-specifiques
- derivees de presentation

`Riverpod` ne doit pas:
- assembler toute l'infrastructure
- reconstruire des services metier complexes a la volee
- devenir un deuxieme service locator generaliste

## Regle cible pour `Riverpod`

Autorise:
- providers d'acces a l'orchestrateur
- providers de lecture `TunnelState`
- providers de mapping `TunnelState -> target surface`
- providers UI temporaires et testables

A reduire:
- providers presentation qui lisent plusieurs services concrets dans `slProvider` pour refaire un mini use case

## 3. Role cible du composition root

Le composition root doit devenir l'endroit unique qui:
- bootstrape la plateforme et le systeme
- enregistre les implementations concretes dans `GetIt`
- construit les adapters de ports
- expose a `Riverpod` les facades finales utiles a l'UI

Le composition root ne doit pas:
- contenir la logique de progression du tunnel
- coder le routage metier

## Forme cible

Le composition root doit relier:

1. `startup infra`
2. `entry_journey ports`
3. `EntryJourneyOrchestrator`
4. `presentation providers`
5. `GoRouter`

## 4. Role cible du routeur

Le routeur garde une valeur forte, mais sa mission change.

Le routeur doit:
- observer un etat deja decide
- mapper cet etat a une surface ou route
- proteger la navigation incoherente
- conserver la compatibilite des chemins

Le routeur ne doit plus:
- recalculer les gardes profil/source/auth
- deduire le parcours a partir de multiples stores
- heberger une machine d'etat metier implicite

## Regle cible pour `GoRouter`

`GoRouter` ne sait pas "quoi faire ensuite".

Il sait seulement:
- "quelle surface correspond a cet etat"
- "cette URL est-elle acceptable ou faut-il la rabattre"

## 5. Role cible du store d'etat du tunnel

Le tunnel doit avoir une seule source de verite observable:
- `TunnelState`

Cette source de verite doit etre exposee:
- via l'orchestrateur
- et observee par Riverpod

Le registre actuel `AppLaunchStateRegistry` peut servir de pont temporaire, mais ne doit pas rester le modele metier final.

## Architecture cible de composition

## Niveau 1 - GetIt

Contenu:
- repositories concrets
- adapters de ports
- services de preload
- use cases
- orchestrateur du tunnel

Exemples:
- `StartupStatusPort` implementation
- `SessionSnapshotPort` implementation
- `ProfilesInventoryPort` implementation
- `HomePreloadPort` implementation
- `EntryJourneyOrchestrator`

## Niveau 2 - Riverpod

Contenu:
- provider d'acces a l'orchestrateur
- provider d'observation de `TunnelState`
- provider derive `target surface`
- providers UI ecran-specifiques

Exemples recommandes:

```text
entryJourneyOrchestratorProvider
tunnelStateProvider
tunnelSurfaceProvider
tunnelCommandsProvider
```

## Niveau 3 - GoRouter

Contenu:
- lecture de `tunnelSurfaceProvider`
- projection vers route/surface
- protection contre les ouvertures manuelles incoherentes

## Regles de composition recommandees

## Regle 1 - Un seul point de creation de l'orchestrateur

L'orchestrateur doit etre cree une seule fois dans le composition root.

Interdit:
- creer un orchestrateur par page
- recreer l'orchestrateur dans plusieurs providers presentation

## Regle 2 - Riverpod n'instancie pas l'infra lourde

Riverpod peut lire l'orchestrateur ou une facade.

Il ne doit pas:
- assembler a la volee plusieurs repositories concrets pour reconstruire le tunnel

## Regle 3 - Les widgets lisent des providers de facades, pas `GetIt` directement

Cible:
- un widget du tunnel lit `tunnelStateProvider`
- il declenche `tunnelCommandsProvider.retry()`

Il ne lit pas:
- `SelectedProfilePreferences`
- `RefreshXtreamCatalog`
- `SupabaseClient`

## Regle 4 - Le routeur n'observe qu'un derive stable

Le routeur doit observer:
- un derive stable de type `TunnelSurface`

Pas:
- plusieurs providers heterogenes
- des booleans auth/profile/source disperses

## Regle 5 - `AppStateController` sort du tunnel strict

`AppStateController` reste un store applicatif transverse pour:
- locale
- theme
- connectivite generale
- autres etats globaux utiles hors tunnel

Il ne doit plus etre:
- un ingredient central de la machine d'etat du tunnel

## Mapping cible des outils

| Outil | Role cible | Ce qu'il ne doit plus faire |
| --- | --- | --- |
| `GetIt` | assembler implementations et use cases | servir d'API de lecture UI generalisee |
| `Riverpod` | exposer etats, commandes, derivees presentation | devenir le moteur de composition infra |
| `GoRouter` | projeter `TunnelSurface` en navigation | recalculer le parcours metier |
| `EntryJourneyOrchestrator` | calculer et publier `TunnelState` | connaitre widgets, routes ou `BuildContext` |
| `AppStateController` | store app-level transverse | piloter les decisions auth/profile/source du tunnel |

## Proposition concrete de providers cibles

## Providers du tunnel

Recommandation:

```text
final entryJourneyOrchestratorProvider = Provider<EntryJourneyOrchestrator>(...)
final tunnelStateProvider = StreamProvider<TunnelState>(...)
final tunnelSurfaceProvider = Provider<TunnelSurface>(...)
final tunnelCommandsProvider = Provider<TunnelCommandsFacade>(...)
```

## Facade de commandes

Une petite facade de commandes peut aider la presentation:

```text
TunnelCommandsFacade {
  Future<void> retry()
  Future<void> restartJourney()
  Future<void> submitAuthCompleted()
  Future<void> submitProfileChosen(String profileId)
  Future<void> submitSourceChosen(String sourceId)
}
```

But:
- eviter d'exposer toute la surface interne de l'orchestrateur a l'UI

## Proposition concrete de routing derive

Le routeur doit idealement observer un derive simple:

```text
enum TunnelSurface {
  preparingSystem,
  auth,
  createProfile,
  chooseProfile,
  chooseSource,
  loadingMedia,
  home,
}
```

Mapping recommande:
- `preparing_system -> preparingSystem`
- `auth_required -> auth`
- `profile_required -> createProfile` ou `chooseProfile`
- `source_required -> chooseSource`
- `preloading_home -> loadingMedia`
- `ready_for_home -> home`

Le detail `createProfile` vs `chooseProfile` peut rester un derive de criteria, sans devenir un second state model.

## Sort de `slProvider`

Decision recommandee:
- `slProvider` peut survivre comme bridge technique
- mais il ne doit plus etre la porte d'entree par defaut de la presentation

Usage acceptable:
- modules de transition
- tests
- quelques bindings de haut niveau

Usage a reduire:
- lecture directe de services dans les pages du tunnel
- providers UI qui ne font que proxy vers `GetIt`

## Sort de `appRouterProvider`

Decision recommandee:
- conserver [app_router.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_router.dart) comme point d'entree du routeur
- remplacer progressivement sa dependance a `AppLaunchStateRegistry` par une lecture de derive `TunnelSurface`

Sequence de migration recommandee:
1. introduire `tunnelSurfaceProvider`
2. faire lire ce derive par le routeur
3. rabattre `LaunchRedirectGuard` sur un role de protection simple
4. retirer la logique metier restante

## Sort de `LaunchRedirectGuard`

Decision recommandee:
- conserver temporairement la structure actuelle
- lui retirer progressivement:
  - les deducions auth/profile/source
  - les re-mappings metier

A terme, `LaunchRedirectGuard` doit seulement:
- empecher les entrees incoherentes
- rabattre vers la surface derivee

## Decision log `Riverpod / GetIt / routeur`

1. `GetIt` reste le conteneur d'assemblage principal.
2. `Riverpod` devient la couche d'exposition officielle vers l'UI.
3. `slProvider` passe d'usage courant a bridge de transition.
4. Le routeur observe un derive stable de `TunnelState`, pas un puzzle de signaux.
5. `AppStateController` sort du coeur du tunnel.
6. L'orchestrateur est la seule source de verite de parcours.

## Risques si on ne clarifie pas cette composition

- duplication durable entre `Riverpod` et `GetIt`
- providers presentation qui reconstruisent des pans de logique metier
- routeur toujours responsable du parcours
- tests difficiles car l'etat du tunnel restera distribue
- regressions lors de la migration des ecrans du tunnel

## Points deferes a 3.6

Cette sous-phase ne tranche pas encore:
- l'ordre concret de migration ecran par ecran
- les feature flags exacts
- les points de rollback

Ces points seront traites en `3.6`.

## Verdict de sortie de la sous-phase 3.5

Verdict:
- la sous-phase `3.5` est suffisamment stable pour lancer `3.6`

Pourquoi:
- chaque outil de composition a maintenant un role net
- le futur wiring du tunnel est lisible
- la relation entre orchestrateur, UI et routeur est clarifiee

## Prochaine etape recommandee

La suite logique est:
1. definir une strategie de migration realiste
2. positionner les feature flags utiles
3. fixer les points de coexistence et de rollback

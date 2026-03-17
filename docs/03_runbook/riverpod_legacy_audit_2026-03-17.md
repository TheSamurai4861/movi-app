# Audit de la dette legacy Riverpod du 17 mars 2026

## But

Ce document realise le `Lot 1.4. Dette legacy Riverpod`.

Il vise a :

- isoler les usages restants de `state_notifier` ;
- identifier les usages de `flutter_riverpod/legacy.dart` ;
- mesurer la surface reelle de migration ;
- proposer une strategie de sortie propre.

Documents lies :

- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)
- [package_upgrade_plan_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/package_upgrade_plan_2026-03-17.md)

Date :

- 17 mars 2026

---

## Synthese

La dette legacy Riverpod est faible et bien localisee.

Au moment de l'audit, un seul flux fonctionnel repose encore sur `state_notifier` :

- l'orchestration du bootstrap applicatif

Concretement, les usages detectes sont limites a :

- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)
- [`bootstrap_providers.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)

Conclusion :

- la dette existe bien ;
- elle n'est pas diffusee dans tout le projet ;
- elle peut etre traitee comme un chantier cible, sans refonte globale de Riverpod.

---

## Usages detectes

### `state_notifier`

Usage detecte :

- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)

Constat :

- `AppLaunchOrchestrator` etend `StateNotifier<AppLaunchState>`

### `flutter_riverpod/legacy.dart`

Usage detecte :

- [`bootstrap_providers.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)

Constat :

- le provider expose l'orchestrateur via `StateNotifierProvider<AppLaunchOrchestrator, AppLaunchState>`

### Portee applicative

Consommateurs detectes :

- [`splash_bootstrap_page.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart)
- [`welcome_user_page.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/welcome/presentation/pages/welcome_user_page.dart)
- [`iptv_source_add_page.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/settings/presentation/pages/iptv_source_add_page.dart)
- [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart)

Observation importante :

- le modele legacy ne pilote pas toute l'application ;
- il pilote surtout le bootstrap et ses redirections.

---

## Particularite architecturale a ne pas casser

L'orchestrateur legacy n'est pas seul.

Le projet maintient aussi un miroir `ChangeNotifier` :

- [`AppLaunchStateRegistry`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)

Ce registre est injecte dans :

- [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)
- [`launch_redirect_guard.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/launch_redirect_guard.dart)
- [`app_router.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_router.dart)

Role du registre :

- fournir un `ChangeNotifier` compatible avec `GoRouter.refreshListenable`
- permettre au routeur de se reevaluer lors des changements d'etat de lancement

Conclusion :

- la migration ne consiste pas seulement a remplacer `StateNotifierProvider`
- il faut aussi preserver ou remplacer proprement le mecanisme de refresh du routeur

---

## Evaluation de la surface de migration

### Ce qui est simple

- la zone legacy est petite ;
- il n'y a qu'un provider Riverpod legacy explicite ;
- l'etat `AppLaunchState` est deja bien centralise ;
- les points d'entree de lecture et d'action sont peu nombreux.

### Ce qui demande de la prudence

- l'orchestrateur a beaucoup de dependances injectees ;
- il expose plusieurs methodes imperativees comme `run()` et `reset()` ;
- il synchronise son etat vers `AppLaunchStateRegistry` ;
- le routeur depend de ce registre pour ses redirections.

### Niveau de difficulte estime

- migration de provider seule : faible a moyenne
- migration complete provider + bridge routeur : moyenne
- suppression complete du registre `ChangeNotifier` : moyenne a forte

---

## Strategie recommandee

### Phase 1. Migration minimale vers les primitives Riverpod modernes

Objectif :

- retirer `flutter_riverpod/legacy.dart`
- retirer `state_notifier`
- conserver temporairement `AppLaunchStateRegistry`

Approche :

- remplacer `StateNotifierProvider` par une primitive moderne Riverpod
- garder un bridge vers `AppLaunchStateRegistry` pour `GoRouter`
- ne pas toucher a la logique metier du bootstrap dans le meme lot

Benefice :

- dette legacy supprimee sans reouvrir le routeur

### Phase 2. Rationalisation du bridge routeur

Objectif :

- reevaluer si `AppLaunchStateRegistry` est encore necessaire

Approche :

- etudier un mecanisme plus direct entre l'etat Riverpod et `GoRouter`
- supprimer le registre seulement si une alternative stable existe

Benefice :

- architecture plus coherente
- moins de duplication d'etat

---

## Decision pour ce lot

Le lot est maintenant considere conforme au niveau implementation.

Ce qui est desormais vrai :

- `AppLaunchOrchestrator` n'utilise plus `StateNotifier`
- le provider legacy a ete remplace par une primitive Riverpod moderne
- `flutter_riverpod/legacy.dart` n'est plus importe
- `state_notifier` n'est plus une dependance directe du projet
- `AppLaunchStateRegistry` est conserve provisoirement pour `GoRouter.refreshListenable`

La strategie de migration en deux temps reste valable :

1. sortie du legacy Riverpod
2. rationalisation eventuelle du bridge routeur

---

## Etat d'implementation

Implementation appliquee :

- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)
- [`bootstrap_providers.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)
- [`pubspec.yaml`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml)

Choix retenu :

- migration vers `Notifier<AppLaunchState>`
- conservation de `run()` et `reset()`
- conservation du miroir `AppLaunchStateRegistry`
- absence volontaire de refonte du routeur dans le meme lot

---

## Definition de fini atteinte

La dette legacy est consideree comme traitee pour ce lot car :

- `state_notifier` n'est plus dans `pubspec.yaml`
- `flutter_riverpod/legacy.dart` n'est plus importe
- le bootstrap reste expose via un provider moderne
- `GoRouter` continue de s'appuyer sur `AppLaunchStateRegistry`
- `run()` et `reset()` restent disponibles via `ref.read(appLaunchOrchestratorProvider.notifier)`

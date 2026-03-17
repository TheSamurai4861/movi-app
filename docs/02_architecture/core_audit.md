# Audit de `core/`

## Objectif

Ce document audite [`lib/src/core/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core) sous l'angle de la clarte :

- responsabilites par sous-module ;
- zones saines ;
- zones denses ou ambiguës ;
- priorites de clarification ;
- politique de commentaires recommandee.

## Contexte

Audit realise le 17 mars 2026 sur l'etat reel du depot.

Le dossier `core/` n'est pas seulement un socle technique.
Il contient aussi plusieurs domaines transverses metier : auth, parental, profile, reporting.

---

## Vue d'ensemble

Sous-modules les plus lourds en volume :

- [`storage/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage)
  Plus gros volume total observe, avec SQLite et repositories locaux.
- [`profile/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/profile)
  Module riche avec UI, providers, use cases et persistence.
- [`parental/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/parental)
  Domaine transverse complet avec use cases, policies et UI.
- [`startup/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup)
  Peu de fichiers mais tres forte criticite.
- [`router/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router)
  Faible en nombre, central en impact.
- [`di/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di)
  Petit perimetre mais fort couplage global.

Fichiers les plus denses repérés :

- [`iptv_local_repository.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/repositories/iptv_local_repository.dart)
- [`manage_profile_dialog.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart)
- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)
- [`sqlite_database.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/database/sqlite_database.dart)
- [`network_executor.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/network/network_executor.dart)
- [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)
- [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart)

Lecture :

- le vrai risque de lisibilite n'est pas le nombre de fichiers
- ce sont surtout :
  - les fichiers massifs ;
  - les modules transverses qui composent tout le runtime ;
  - les points de jonction entre Riverpod, GetIt, router et stockage

---

## Diagnostic par sous-module

### `startup`

Etat :

- clair dans son intention ;
- critique pour tout le runtime ;
- encore dense dans l'orchestration.

Fichiers pivots :

- [`app_startup_gate.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_gate.dart)
- [`app_startup_provider.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)
- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)

Verdict :

- module structurellement sain ;
- priorite forte sur les commentaires de flux et la reduction de densite des gros fichiers.

### `di`

Etat :

- tres central ;
- role clair ;
- fichier principal tres dense.

Fichiers pivots :

- [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)
- [`di.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/di.dart)

Verdict :

- module necessairement couple ;
- besoin de clarte documentaire plus que de commentaires ligne a ligne ;
- bon candidat futur a une decomposition par sous-enregistrements.

### `router`

Etat :

- role clair ;
- composition globale assumee ;
- couplage fort a l'ensemble des features.

Fichiers pivots :

- [`app_router.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_router.dart)
- [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart)
- [`launch_redirect_guard.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/launch_redirect_guard.dart)

Verdict :

- structure saine ;
- le cout de lecture vient surtout du volume de routes, pas d'un mauvais rangement.

### `state`

Etat :

- petit module ;
- bonne centralisation du state global ;
- bon endroit pour exposer la source de verite UI transversale.

Fichiers pivots :

- [`app_state_controller.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/state/app_state_controller.dart)
- [`app_state_provider.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/state/app_state_provider.dart)

Verdict :

- zone assez claire ;
- besoin surtout de conventions stables, pas d'un gros refactoring.

### `storage`

Etat :

- plus grosse zone technique transverse ;
- forte densite fonctionnelle ;
- risque de "god files" dans les repositories locaux.

Fichiers pivots :

- [`sqlite_database.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/database/sqlite_database.dart)
- [`iptv_local_repository.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/repositories/iptv_local_repository.dart)
- [`playlist_local_repository.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/repositories/playlist_local_repository.dart)
- [`storage_module.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/services/storage_module.dart)

Verdict :

- priorite tres forte de clarification ;
- le module est utilement centralise, mais plusieurs fichiers meritent d'etre decoupes ou mieux documentes.

### `network`

Etat :

- globalement bien structure ;
- README interne deja utile ;
- `network_executor.dart` reste une zone dense.

Verdict :

- module plutot sain ;
- bon exemple de clarté structurelle dans `core`.

### `config`

Etat :

- perimetre clair ;
- forte importance runtime ;
- plusieurs models et services bien separes.

Verdict :

- module sain ;
- priorité faible sur le découpage, moyenne sur la documentation d'usage.

### `security`

Etat :

- perimetre petit ;
- responsabilites claires ;
- bon candidat pour une documentation courte et stable.

Verdict :

- module sain ;
- pas besoin de commenter plus partout, seulement de garder les interfaces claires.

### `preferences`

Etat :

- petit ;
- role bien borne ;
- README deja present et utile.

Verdict :

- module sain ;
- bon exemple de clarification par README court plutot que par commentaires partout.

### `logging`

Etat :

- module transverse technique ;
- structure correcte ;
- plusieurs classes utilitaires qui gagnent a etre documentees en entree de fichier.

Verdict :

- module plutot sain ;
- clarte surtout amelioree par doc comments de surface.

### `widgets`

Etat :

- dossier volumineux ;
- role utile ;
- risque modere de devenir un "catalogue fourre-tout".

Verdict :

- surveiller la discipline de rangement ;
- les widgets tres specifiques devraient rester dans leurs features.

### `profile`

Etat :

- module riche et assez bien structure ;
- README interne present mais corrompu avant correction ;
- zone lourde cote UI.

Verdict :

- structure saine ;
- priorite moyenne sur la clarification des gros dialogs et des providers.

### `parental`

Etat :

- vrai domaine transverse complet ;
- plusieurs couches ;
- logique sensible mais relativement bien rangee.

Verdict :

- module sain mais sensible ;
- les commentaires doivent se concentrer sur les regles de decision, pas sur l'UI.

---

## Etat des commentaires et doc comments

Constat important :

- un grand nombre de fichiers `core` n'ont pas de doc d'entree de fichier ;
- cela ne signifie pas qu'ils sont "mal commentes" ;
- le vrai manque se situe surtout sur :
  - les barrels publics ;
  - les fichiers pivots du runtime ;
  - les gros fichiers a logique non triviale.

Conclusion :

- il ne faut pas chercher a commenter chaque fichier de facon uniforme ;
- il faut prioriser les points de comprehension.

### Priorite 1

Ajouter ou maintenir une doc claire sur :

- barrels publics de `core`
- startup
- DI
- router
- storage
- state

### Priorite 2

Ajouter des commentaires structurels dans les gros fichiers :

- sections
- invariants
- regles de synchronisation
- contrats implicites

### Priorite 3

Eviter :

- les commentaires qui repetent le code ;
- les commentaires UI triviaux ;
- les blocs anciens non maintenus.

---

## Priorites de clarification

### Critique

- [`iptv_local_repository.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/repositories/iptv_local_repository.dart)
- [`sqlite_database.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/database/sqlite_database.dart)
- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)
- [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)

### Haute

- [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart)
- [`network_executor.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/network/network_executor.dart)
- [`manage_profile_dialog.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart)

### Moyenne

- barrels `core/*/*.dart` exposes publiquement
- widgets transverses les plus utilises
- services logging et providers de profile

---

## Correctifs evidents appliques pendant l'audit

- documentation des barrels publics prioritaires de `core`
- reparation du README corrompu de [`core/profile/README.md`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/profile/README.md)

---

## Suite recommandee

Ordre de travail le plus rentable :

1. clarifier les barrels et README transverses
2. reprendre `storage` et `startup`
3. reprendre `di` et `router`
4. ensuite seulement revisiter les gros dialogs `profile`

## Derniere mise a jour

2026-03-17

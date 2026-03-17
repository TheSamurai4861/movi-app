# Project Overview

## Objectif

Ce document donne une vue d'ensemble du projet `Movi`.

Il sert a comprendre rapidement :

- ce que fait l'application ;
- comment elle est construite ;
- quelles sont ses briques principales ;
- quels dossiers et services sont centraux ;
- quels sont les points d'attention avant de commencer a travailler dessus.

## Contexte

`Movi` est une application Flutter orientee consommation de contenus video.

D'apres la structure du projet et les modules presents, l'application couvre notamment :

- l'authentification ;
- le bootstrap de session et de configuration au demarrage ;
- la navigation applicative ;
- la gestion de profils, preferences et controles parentaux ;
- la lecture video ;
- la bibliotheque utilisateur et les playlists ;
- des integrations autour de contenus IPTV ;
- la recherche, les fiches media, les personnes et les sagas ;
- la localisation multilingue.

Le projet est deja structure avec une separation entre socle technique transverse et fonctionnalites produit.

## Stack technique

Le projet repose principalement sur :

- Flutter
- Dart `^3.9.2`
- `flutter_riverpod` pour le state management
- `get_it` pour l'injection de dependances
- `go_router` pour la navigation
- `dio` pour les appels reseau
- `supabase_flutter` pour certaines integrations backend
- `sqflite` et `sqflite_common_ffi` pour le stockage local
- `flutter_secure_storage` pour le stockage sensible
- `media_kit` pour la lecture media
- `google_fonts` pour la typographie
- le systeme `l10n` de Flutter pour la traduction

La configuration et le lancement utilisent aussi des variables d'environnement via `--dart-define` et potentiellement un fichier `.env`.

## Plateformes retenues a ce stade

Le perimetre recommande actuellement est le suivant :

- `android` : support officiel
- `windows` : support officiel pour le developpement local
- `ios` : support conditionnel
- `macos` : hors perimetre officiel
- `linux` : hors perimetre officiel
- `web` : hors perimetre officiel

Reference :

- [platform_scope_decision_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/platform_scope_decision_2026-03-17.md)

## Structure generale du code

La structure observee dans `lib/` est la suivante :

- [lib/main.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
  Point d'entree de l'application.
- [lib/src/app.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/app.dart)
  Construction du `MaterialApp.router`.
- [lib/src/core](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core)
  Infrastructure transverse, services globaux et briques techniques partagees.
- [lib/src/features](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features)
  Fonctionnalites produit organisees par domaine.
- [lib/src/shared](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared)
  Composants, services et modeles partages entre plusieurs features.
- [lib/l10n](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/l10n)
  Fichiers de localisation et code genere associe.

## Organisation fonctionnelle

### Socle transverse

Les dossiers majeurs de `core/` couvrent notamment :

- `startup`
- `router`
- `state`
- `di`
- `config`
- `network`
- `error`
- `logging`
- `storage`
- `security`
- `preferences`
- `supabase`
- `theme`
- `widgets`

Le dossier `core/` joue donc le role de fondation technique de l'application.

### Fonctionnalites produit

Les features identifiees dans `lib/src/features/` sont notamment :

- `auth`
- `home`
- `iptv`
- `library`
- `movie`
- `tv`
- `player`
- `playlist`
- `search`
- `settings`
- `welcome`
- `person`
- `saga`
- `category_browser`
- `shell`

Certaines features suivent deja une organisation proche de la Clean Architecture avec des sous-dossiers :

- `data`
- `domain`
- `presentation`
- parfois `application`

Cela montre une volonte de structurer le projet par fonctionnalite tout en gardant des couches explicites.

## Flux global de l'application

D'apres le point d'entree actuel :

1. L'application initialise Flutter et certains comportements plateforme.
2. Le moteur media est initialise.
3. La gestion globale des erreurs est mise en place.
4. L'app est demarree dans un `ProviderScope`.
5. Un `AppStartupGate` execute la logique de bootstrap avant de rendre l'application principale.
6. `MyApp` configure ensuite le router, le theme, la locale et le shell global.

Les fichiers centraux pour comprendre ce flux sont :

- [lib/main.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
- [lib/src/app.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/app.dart)
- [lib/src/core/startup](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup)
- [lib/src/core/router](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router)
- [lib/src/core/state](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/state)

## Integrations et donnees

Le projet combine plusieurs sources et mecanismes de donnees :

- reseau HTTP via `dio`
- backend et services associes via `supabase_flutter`
- stockage local SQLite via `sqflite`
- stockage securise via `flutter_secure_storage`
- configuration runtime via variables d'environnement

Cela implique que le comportement de l'application depend a la fois :

- de la configuration locale du poste ;
- des cles/API fournies au lancement ;
- de la disponibilite de certains services externes ;
- de la coherence entre cache local et donnees distantes.

## Localisation

Le projet est internationalise.

La configuration `l10n` indique :

- les fichiers source dans [lib/l10n](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/l10n)
- `app_en.arb` comme template principal
- `app_localizations.dart` comme fichier genere
- `untranslated.txt` comme sortie pour les messages non traduits

La localisation fait partie du fonctionnement standard de l'application et doit etre prise en compte dans les evolutions UI et produit.

## Build et execution

Le projet semble supporter plusieurs modes d'execution et de build, notamment avec flavors ou variables d'environnement.

Des indices clairs existent dans :

- [pubspec.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml)
- [codemagic.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml)
- [lib/src/core/config](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config)
- [android/app/build.gradle.kts](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/app/build.gradle.kts)

Les usages deja visibles dans le projet montrent :

- un mode `dev`
- un mode `prod`
- l'usage de `--dart-define` pour passer les cles et le contexte d'environnement

## Points d'attention pour un nouveau contributeur

Avant de modifier le projet, il faut garder en tete :

- l'application melange `Riverpod` et `GetIt`, donc il faut bien identifier la source de verite d'un service ou d'un etat avant toute modification ;
- le dossier `core/` est riche et peut contenir a la fois de la pure infrastructure et des logiques plus proches du produit ;
- plusieurs features semblent deja structurees en couches, mais cette organisation n'est pas necessairement uniforme partout ;
- le demarrage applicatif est un point sensible, car il combine bootstrap, configuration, DI, routing et etat global ;
- une partie du comportement depend de services externes et de secrets d'environnement ;
- la lecture media et les usages IPTV sont probablement des zones a forte complexite fonctionnelle.

## Documents a lire ensuite

Pour devenir rapidement operationnel sur le projet, l'ordre de lecture recommande est :

1. `docs/01_onboarding/quick_start.md`
2. `docs/01_onboarding/environment_setup.md`
3. `docs/01_onboarding/commands.md`
4. `docs/02_architecture/codebase_map.md`
5. `docs/02_architecture/dependency_rules.md`
6. `docs/05_ai_context/ai_project_brief.md`

## Limites de ce document

Ce document est une vue d'ensemble fondee sur la structure et les points d'entree du projet.

Il ne remplace pas :

- une cartographie detaillee du code ;
- une documentation exhaustive des features ;
- une specification produit ;
- un runbook de debug ou de release.

Son role est de donner un cadre commun et une comprehension initiale fiable.

## Derniere mise a jour

2026-03-17

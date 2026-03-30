# Quick Start

## Objectif

Ce document permet de lancer `Movi` rapidement en local avec le minimum de contexte.

Il cible surtout :

- un developpeur qui ouvre le projet pour la premiere fois ;
- une IA qui doit savoir comment executer et verifier l'application ;
- un contributeur qui veut lancer l'app sans lire toute l'architecture.

Perimetre recommande a ce stade :

- `android` et `windows` : plateformes officielles
- `ios` : plateforme supportee conditionnellement
- `macos`, `linux`, `web` : hors perimetre officiel

## Prerequis minimum

Avant de lancer le projet, verifier que les outils suivants sont disponibles :

- Flutter installe et fonctionnel
- Dart inclus avec Flutter
- un SDK Android et/ou un environnement Windows selon la cible principale
- un environnement iOS/macOS seulement si tu travailles explicitement sur la cible iOS
- un device ou un emulateur configure

Le projet utilise Flutter avec Dart `^3.9.2` d'apres [pubspec.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml).

## Vue rapide du lancement

Le demarrage de l'application passe par :

- [lib/main.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
- [lib/src/core/startup/app_startup_provider.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)

Au lancement, l'application :

1. initialise Flutter ;
2. initialise certains services globaux ;
3. charge l'environnement applicatif ;
4. enregistre la configuration runtime ;
5. initialise les dependances ;
6. demarre l'application via un `AppStartupGate`.

Cela signifie qu'un probleme de config ou de variable d'environnement peut bloquer l'app tres tot.

## Premier lancement recommande

### 1. Installer les dependances

Depuis la racine du projet :

```bash
flutter pub get
```

### 2. Verifier que Flutter est sain

```bash
flutter doctor
```

Si `flutter doctor` remonte un probleme bloquant sur la plateforme cible, le corriger avant d'aller plus loin.

### 3. Preparer les variables d'environnement

Le projet utilise des variables passees via `--dart-define` ou `--dart-define-from-file`.

Les cles visibles dans le depot sont notamment :

- `APP_ENV`
- `TMDB_API_KEY`
- `TMDB_API_KEY_PROD`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

En pratique, pour un lancement local simple, le plus probable est de disposer d'un fichier `.env` a la racine.

Exemple de logique visible dans le projet :

- `APP_ENV=dev` ou `APP_ENV=prod`
- cle TMDB
- URL et cle anonyme Supabase

Important :

- en `release` + `prod`, la cle TMDB est traitee comme requise au demarrage ;
- selon les parcours testes, Supabase peut aussi etre necessaire pour un run realiste.

### 4. Lancer l'application

Commande la plus simple :

```bash
flutter run
```

Cette commande peut suffire si ton environnement local fournit deja les variables attendues ou si certains chemins de secours existent.

### 5. Lancement recommande avec fichier `.env`

Pour un lancement plus fiable, utiliser :

```bash
flutter run -d windows --dart-define-from-file=.env
```

Cette commande est la meilleure base locale visible dans le projet pour un run Windows.

## Commandes utiles selon le cas

### Run local basique

```bash
flutter run
```

### Run Windows avec `.env`

```bash
flutter run -d windows --dart-define-from-file=.env
```

### Run Android flavor `dev`

```bash
flutter run --flavor dev -t lib/main.dart --dart-define-from-file=.env
```

### Run profile flavor `prod`

```bash
flutter run --profile --flavor prod -t lib/main.dart --dart-define-from-file=.env
```

## Flavors et environnements

Le projet declare plusieurs environnements applicatifs et plusieurs flavors Android.

Environnements applicatifs observes :

- `dev`
- `staging`
- `prod`

Flavors Android observes dans [android/app/build.gradle.kts](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/app/build.gradle.kts) :

- `dev`
- `stage`
- `prod`

Point d'attention :

- le code Dart parle de `staging`, alors que le flavor Android s'appelle `stage` ;
- il faut donc eviter d'assumer qu'un nom de flavor Android est strictement identique au nom d'environnement applicatif.

## Verification rapide apres lancement

Une fois l'application lancee, verifier au minimum :

- que l'app demarre sans crash immediat ;
- que l'ecran de bootstrap ne reste pas bloque indefiniment ;
- que la navigation principale s'affiche ;
- qu'aucune erreur critique de config n'apparait dans les logs ;
- que le chargement initial ne casse pas l'UI.

## Commandes de verification utiles

Analyse statique :

```bash
flutter analyze
```

Tests :

```bash
flutter test
```

Ces deux commandes sont utiles avant et apres une modification.

## Problemes frequents a verifier en premier

Si l'application ne demarre pas correctement, verifier dans cet ordre :

1. les dependances avec `flutter pub get`
2. l'etat de l'environnement Flutter avec `flutter doctor`
3. la presence et le contenu du fichier `.env`
4. la cible de lancement choisie
5. les variables `APP_ENV`, `TMDB_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`
6. les logs produits pendant `appStartupProvider`

Les zones de code les plus utiles pour diagnostiquer un echec de lancement sont :

- [lib/main.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
- [lib/src/core/startup/app_startup_provider.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)
- [lib/src/core/config](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config)
- [android/app/build.gradle.kts](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/app/build.gradle.kts)
- [codemagic.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml)

## Sequence recommandee pour un nouveau contributeur

Si tu viens d'arriver sur le projet, la sequence la plus sure est :

1. `flutter pub get`
2. `flutter doctor`
3. verifier `.env`
4. lancer `flutter run -d windows --dart-define-from-file=.env`
5. si besoin, tester ensuite le flavor Android `dev`
6. lancer `flutter analyze`
7. lancer `flutter test`

## Limites de ce document

Ce document couvre le premier demarrage local.

Il ne remplace pas :

- un guide complet d'environnement ;
- une documentation release ;
- une cartographie d'architecture ;
- un runbook de debug approfondi.

## Derniere mise a jour

2026-03-17

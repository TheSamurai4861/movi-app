# Commandes de run et capture de logs

Ce guide donne des commandes PowerShell prêtes a copier pour lancer l'application
et capturer les logs proprement dans le workspace.

## Prerequis

Le projet lit sa configuration via les `dart-define`. En local, on utilise ici :

- `--dart-define-from-file=.env`

Le fichier `.env` doit contenir au minimum les cles visibles dans
`.env.example` :

```dotenv
APP_ENV=dev
TMDB_API_KEY=
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_PROJECT_REF=your-project
TMDB_API_KEY_PROD=
HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=
```

## Preparation

Creer le dossier de sortie des logs :

```powershell
New-Item -ItemType Directory -Force output | Out-Null
```

Optionnel, si tu veux repartir d'un etat propre avant un run :

```powershell
flutter clean
flutter pub get
```

## Run Windows avec logs

Run standard :

```powershell
flutter run -d windows --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-windows.log
```

Run tres verbeux :

```powershell
flutter run -d windows -v --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-windows-verbose.log
```

## Run Android avec logs

Si un emulateur ou device Android est connecte :

```powershell
flutter run -d android --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-android.log
```

## Analyse statique avec logs

```powershell
flutter analyze *>&1 | Tee-Object -FilePath output/flutter-analyze.log
```

## Tests avec logs

Tous les tests :

```powershell
flutter test --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-test.log
```

Un seul fichier de test :

```powershell
flutter test test/features/movie/data/services/movie_playback_variant_resolver_impl_test.dart --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-test-movie-variant.log
```

## Build Windows avec logs

```powershell
flutter build windows --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-windows.log
```

## Build APK avec logs

```powershell
flutter build apk --debug --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-apk-debug.log
```

## Variante Premium forcee

Si tu veux reproduire localement un run premium force :

```powershell
flutter run -d windows --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true --dart-define=FORCE_PREMIUM=true --dart-define=ALLOW_FORCE_PREMIUM_IN_RELEASE=true *>&1 | Tee-Object -FilePath output/flutter-run-windows-premium.log
```

## Ce qu'il faut me donner ensuite

Quand tu veux que j'analyse un log, envoie simplement :

- la commande lancee
- le chemin du log, par exemple `output/flutter-run-windows.log`
- le symptome attendu vs observe
- l'heure approximative du moment ou ca casse si le log est long

Exemple :

```text
Analyse output/flutter-run-windows.log, le run bloque apres startup_ready.
```

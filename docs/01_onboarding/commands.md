# Commands

## Objectif

Ce document centralise les commandes utiles du projet `Movi`.

Il sert a :

- lancer l'application ;
- verifier l'etat du projet ;
- executer les tests ;
- construire les builds ;
- utiliser les scripts internes du depot ;
- distinguer les commandes standard des commandes occasionnelles.

## Regles d'usage

- toutes les commandes sont executees depuis la racine du projet ;
- quand une commande depend de secrets ou d'un contexte d'environnement, cela est indique ;
- les commandes presentes ici sont basees sur le depot actuel ;
- si une commande n'est plus utilisee, elle doit etre retiree de ce document.

## Commandes essentielles

Installer les dependances :

```bash
flutter pub get
```

Verifier l'environnement Flutter :

```bash
flutter doctor
```

Analyser le projet :

```bash
flutter analyze
```

Executer les tests :

```bash
flutter test
```

## Lancement de l'application

### Lancement minimal

```bash
flutter run
```

Usage :

- utile pour un premier essai rapide ;
- peut echouer si la configuration runtime attend des variables absentes.

### Lancement Windows avec `.env`

```bash
flutter run -d windows --dart-define-from-file=.env
```

Usage :

- commande locale la plus pratique visible dans le projet ;
- recommandee pour un run reproductible avec configuration locale.

### Lancement Android flavor `dev`

```bash
flutter run --flavor dev -t lib/main.dart --dart-define-from-file=.env
```

Usage :

- run Android en environnement de developpement ;
- suppose un `.env` coherent avec `APP_ENV=dev`.

### Lancement profile flavor `prod`

```bash
flutter run --profile --flavor prod -t lib/main.dart --dart-define-from-file=.env
```

Usage :

- utile pour tester un comportement plus proche de la production ;
- demande une configuration plus propre et complete.

## Qualite et verification

### Analyse statique

```bash
flutter analyze
```

### Tests

```bash
flutter test
```

### Nettoyage puis reinstallation des dependances

```bash
flutter clean
flutter pub get
```

Usage :

- utile si un build local ou l'environnement Flutter est incoherent ;
- utile avant certains tests de release.

## Build Android

### Build app bundle production

```bash
flutter build appbundle --release --flavor prod -t lib/main.dart
```

Usage :

- build Android de production ;
- necessite la configuration de signature si le build doit etre signe.

### Variante mentionnee dans le projet

```bash
flutter build appbundle --release --flavor prod
```

Usage :

- visible dans la documentation Android du depot ;
- a preferer avec `-t lib/main.dart` pour rester explicite.

### Emplacement de sortie attendu

```text
build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

## Build iOS

Statut recommande :

- iOS est traite comme plateforme supportee conditionnellement ;
- ces commandes sont surtout utiles en CI ou sur une machine macOS preparee pour cette cible.

Les workflows iOS observes dans [codemagic.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml) utilisent notamment :

### Build IPA dev non signe

```bash
flutter build ipa --release --no-codesign \
  --target=lib/main.dart \
  --dart-define=APP_ENV=dev \
  --dart-define=TMDB_API_KEY=${TMDB_API_KEY} \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=FORCE_STARTUP_DETAILS=true
```

### Build IPA prod non signe

```bash
flutter build ipa --release --no-codesign \
  --target=lib/main.dart \
  --dart-define=APP_ENV=prod \
  --dart-define=TMDB_API_KEY=${TMDB_API_KEY} \
  --dart-define=TMDB_API_KEY_PROD=${TMDB_API_KEY} \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
```

Usage :

- commandes surtout utiles en CI ou sur une machine macOS configuree ;
- non necessaires pour le developpement courant si tu ne cibles pas iOS.

## Signature Android

### Build release signe

```bash
flutter build appbundle --release --flavor prod
```

Prerequis :

- `MOVI_KEYSTORE`
- `MOVI_STORE_PASSWORD`
- `MOVI_ALIAS`
- `MOVI_KEY_PASSWORD`

La configuration detaillee est decrite dans :

- [android/SIGNING_SETUP.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/SIGNING_SETUP.md)

### Verification de signature d'un AAB

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Inspection d'un AAB avec bundletool

```bash
bundletool build-apks --bundle=build/app/outputs/bundle/prodRelease/app-prod-release.aab --output=temp.apks --mode=universal
unzip -l temp.apks
```

## Localisation

Le projet utilise la generation Flutter l10n avec [l10n.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/l10n.yaml).

Commande habituelle Flutter pour regenerer la localisation :

```bash
flutter gen-l10n
```

Usage :

- utile apres modification des fichiers `.arb` ;
- a valider avec le flux reel du projet si un script interne remplace cette commande dans certains cas.

## Scripts internes

Le dossier [scripts](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/scripts) contient plusieurs scripts Python utilitaires.

### Generer un outline numerote de `lib/`

```bash
python scripts/outline_and_export.py --methods-in-classes
```

Usage :

- genere un index numerote et un outline du code Dart ;
- utile pour les audits, le travail avec IA et la cartographie rapide du depot.

### Generer un outline concatene avec selection

```bash
python scripts/concat_lib_outline.py --select "89,90,91,98,29,28,25,27,148,83,84,85,82,86,447,450,451,449,448,52" --export-content --content-only
```

Usage :

- commande tres orientee audit ponctuel ;
- a adapter selon la selection de fichiers voulue ;
- utile pour preparer un dump de contexte pour relecture ou IA.

### Script d'extraction present dans le depot

```bash
python scripts/extract_folder_to_dump.py
```

Usage :

- le script existe dans le depot ;
- consulter son aide ou son contenu avant usage, car ses options ne sont pas documentees ici.

## Commandes PowerShell historiques

Certaines commandes de travail historiques etaient orientees dump local sous Windows.

Exemple de pattern observe :

```powershell
tree /F lib > architecture.txt
```

Usage :

- utile pour produire rapidement une vue arborescente ;
- commande pratique mais non essentielle au fonctionnement du projet.

## Commandes utiles en sequence

### Sequence de verification rapide

```bash
flutter pub get
flutter analyze
flutter test
```

### Sequence de reset local

```bash
flutter clean
flutter pub get
flutter run -d windows --dart-define-from-file=.env
```

### Sequence de build Android production

```bash
flutter clean
flutter pub get
flutter build appbundle --release --flavor prod -t lib/main.dart
```

## Commandes a utiliser avec prudence

Les commandes suivantes dependent fortement du contexte local :

- builds iOS
- commandes de signature Android
- scripts Python avec selection manuelle de fichiers
- commandes utilisant des variables d'environnement shell

Bonne pratique :

- ne pas copier une commande de build/release sans verifier les prerequis de configuration ;
- preferer les commandes simples de run/analyze/test pour commencer ;
- documenter toute commande recurrente ajoutee au projet.

## Commandes absentes volontairement

Ce document n'inclut pas :

- commandes non reliees au depot actuel ;
- aliases shell personnels ;
- commandes temporaires de debug non stabilisees ;
- commandes destructives non necessaires au flux normal.

## Derniere mise a jour

2026-03-17

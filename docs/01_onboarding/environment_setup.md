# Environment Setup

## Objectif

Ce document explique comment preparer l'environnement local pour executer et builder `Movi`.

Il couvre :

- les outils requis ;
- les variables d'environnement attendues ;
- le role du fichier `.env` ;
- les environnements applicatifs et flavors ;
- les points a verifier pour les builds locaux et release.

Perimetre recommande a ce stade :

- `android` et `windows` : plateformes officielles
- `ios` : plateforme supportee conditionnellement
- `macos`, `linux`, `web` : hors perimetre officiel

## Outils requis

Pour travailler sur le projet, il faut au minimum :

- Flutter installe et fonctionnel
- Dart inclus via Flutter
- un SDK Android si tu cibles Android
- un environnement desktop compatible si tu cibles Windows/macOS
- Java JDK pour Android et pour certains outils de build/signature

Le projet declare Dart `^3.9.2` dans [pubspec.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml).

Commande de verification recommandee :

```bash
flutter doctor
```

## Fichiers et points de configuration importants

Les principaux fichiers a connaitre pour la configuration sont :

- [pubspec.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml)
- [codemagic.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml)
- [android/app/build.gradle.kts](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/app/build.gradle.kts)
- [lib/src/core/config/env/environment.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/env/environment.dart)
- [lib/src/core/config/env/dev_environment.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/env/dev_environment.dart)
- [lib/src/core/config/models/supabase_config.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/models/supabase_config.dart)
- [lib/src/core/config/services/secret_store_io.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/services/secret_store_io.dart)
- [lib/src/core/startup/app_startup_provider.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)

## Modes de configuration supportes

Le projet lit sa configuration via deux mecanismes principaux :

1. `--dart-define` ou `--dart-define-from-file`
2. fallback local via le fichier `.env` pour certains secrets lus au runtime

En pratique, il faut raisonner ainsi :

- la configuration compile-time passe via `flutter run/build --dart-define...`
- certains secrets peuvent aussi etre resolves depuis l'environnement systeme ou `.env`

## Fichier `.env`

Le projet attend un fichier local `.env` a la racine du projet.

Un gabarit versionne est disponible dans [/.env.example](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/.env.example).

Le projet peut lire `.env` de deux manieres :

- directement via `--dart-define-from-file=.env` au lancement Flutter ;
- via la logique de `SecretStore`, qui cherche aussi un fichier `.env` sur disque.

Le parser `.env` du projet attend des lignes au format :

```dotenv
KEY=value
```

Regles utiles :

- lignes vides ignorees ;
- lignes commencant par `#` ignorees ;
- guillemets simples ou doubles supportes autour des valeurs ;
- pas de syntaxe avancee type interpolation shell garantie.

Bonne pratique :

- garder `.env` local uniquement ;
- ne jamais versionner de vraies cles API ou secrets ;
- partir de `.env.example` pour creer ton fichier local.

## Variables d'environnement identifiees

Les variables visibles dans le depot sont :

- `APP_ENV`
- `TMDB_API_KEY`
- `TMDB_API_KEY_DEV`
- `TMDB_API_KEY_STAGING`
- `TMDB_API_KEY_PROD`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_PROJECT_REF`
- `HTTP_PROXY`
- `HTTPS_PROXY`
- `NO_PROXY`
- `FORCE_STARTUP_DETAILS`

Variables Android release observees :

- `MOVI_KEYSTORE`
- `MOVI_STORE_PASSWORD`
- `MOVI_ALIAS`
- `MOVI_KEY_PASSWORD`

## Variables les plus importantes pour un run local

### `APP_ENV`

Role :

- selectionne l'environnement applicatif utilise par le projet.

Valeurs observees dans le code :

- `dev`
- `staging`
- `prod`

### `TMDB_API_KEY`

Role :

- cle d'acces utilisee pour les appels relies a TMDB.

Notes :

- une cle generique est supportee via `TMDB_API_KEY` ;
- des variantes par environnement existent aussi ;
- en `release` + `prod`, l'absence de cle est traitee comme bloquante.

### `SUPABASE_URL`

Role :

- URL du projet Supabase cible.

Format attendu :

```text
https://<project-ref>.supabase.co
```

### `SUPABASE_ANON_KEY`

Role :

- cle anonyme Supabase.

### `SUPABASE_PROJECT_REF`

Role :

- valeur optionnelle de verification pour s'assurer que l'app pointe vers le bon projet Supabase.

Utilite :

- aide a detecter une mauvaise URL de projet.

## Exemple de structure `.env`

Le document ne donne pas de vraies valeurs, mais la structure locale attendue ressemble a ceci :

```dotenv
APP_ENV=dev
TMDB_API_KEY=your_tmdb_key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_PROJECT_REF=your-project
```

Selon tes usages, tu peux aussi ajouter :

```dotenv
TMDB_API_KEY_PROD=your_prod_tmdb_key
HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=
```

## Environnements applicatifs

Le code Dart declare les environnements suivants :

- `dev`
- `staging`
- `prod`

Ils sont definis dans [lib/src/core/config/env/environment.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/env/environment.dart) et construits dans [lib/src/core/config/env/dev_environment.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/env/dev_environment.dart).

Chaque environnement embarque :

- un label
- des endpoints
- des timeouts
- des feature flags par defaut
- des metadonnees d'application

## Flavors Android

Le projet Android declare les flavors suivants :

- `dev`
- `stage`
- `prod`

Point important :

- le flavor Android `stage` ne correspond pas exactement au nom Dart `staging` ;
- il faut donc bien distinguer flavor de build Android et environnement applicatif Dart.

## Priorite de resolution des secrets

Pour certaines valeurs, la logique visible dans le projet est la suivante :

1. valeur fournie directement via `--dart-define`
2. variable d'environnement systeme
3. lecture du fichier `.env`

Cela veut dire qu'un comportement inattendu peut venir :

- d'une valeur definie dans le shell ;
- d'un `.env` a la racine ;
- d'un `--dart-define` plus prioritaire ;
- d'un mismatch entre flavor Android et `APP_ENV`.

## Setup local recommande

Sequence recommandee pour preparer un poste :

1. installer Flutter et verifier `flutter doctor`
2. executer `flutter pub get`
3. creer ou verifier le fichier `.env` a la racine
4. renseigner au minimum `APP_ENV`, `TMDB_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`
5. lancer l'application avec `--dart-define-from-file=.env`

Commande recommandee :

```bash
flutter run -d windows --dart-define-from-file=.env
```

Ou sur Android flavor `dev` :

```bash
flutter run --flavor dev -t lib/main.dart --dart-define-from-file=.env
```

## Configuration Android release

Pour builder une version Android signee, les variables suivantes sont utilisees :

- `MOVI_KEYSTORE`
- `MOVI_STORE_PASSWORD`
- `MOVI_ALIAS`
- `MOVI_KEY_PASSWORD`

Le detail de cette configuration est documente dans :

- [android/SIGNING_SETUP.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/SIGNING_SETUP.md)
- [android/PLAY_CONSOLE_CHECKLIST.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/PLAY_CONSOLE_CHECKLIST.md)

Recommandation :

- ne jamais stocker les mots de passe de signature dans un fichier versionne ;
- preferer `~/.gradle/gradle.properties` ou un systeme de secrets CI.

## Proxy et reseau

Le projet supporte aussi des variables de proxy pour certains usages reseau :

- `HTTP_PROXY`
- `HTTPS_PROXY`
- `NO_PROXY`

Ces valeurs peuvent influencer les clients HTTP non-Dio et certains comportements en environnement restreint.

Si tu es sur un reseau d'entreprise ou un environnement filtre, pense a verifier ce point.

## Verification apres setup

Une fois l'environnement configure, verifier au minimum :

- que `flutter pub get` passe ;
- que `flutter run` ou `flutter run --dart-define-from-file=.env` demarre ;
- que le bootstrap ne plante pas sur la config ;
- que Supabase est correctement configure si le parcours teste en depend ;
- que l'environnement attendu apparait dans les logs de startup.

## Erreurs classiques de configuration

Les erreurs les plus probables sont :

- fichier `.env` absent ;
- `TMDB_API_KEY` manquante ;
- `SUPABASE_URL` invalide ;
- `SUPABASE_ANON_KEY` vide ;
- `APP_ENV` incoherent avec le mode de lancement ;
- confusion entre `stage` et `staging` ;
- presence d'une variable systeme qui surcharge une valeur attendue ;
- configuration release Android incomplete pour la signature.

## Bonnes pratiques

- ne jamais commiter de secrets reels ;
- garder `.env` local uniquement ;
- utiliser `--dart-define-from-file=.env` pour les runs locaux reproductibles ;
- documenter toute nouvelle variable ajoutee au projet ;
- separer clairement les variables de run local, de CI et de release ;
- verifier les logs de startup apres un changement de config.

## Limites de ce document

Ce document decrit la structure de configuration visible dans le depot.

Il ne remplace pas :

- un inventaire complet des secrets par environnement ;
- la documentation CI/CD ;
- un guide release detaille par plateforme.

## Derniere mise a jour

2026-03-17

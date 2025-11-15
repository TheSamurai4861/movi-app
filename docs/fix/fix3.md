## Phase 1 — Vérifier que Codemagic injecte bien la clé TMDB

**Objectif :** être sûr à 100 % que `TMDB_API_KEY` n’est pas vide pendant le build.

### Étape 1 — Loguer la *longueur* de la clé dans Codemagic

Ajoute une étape entre `Install dependencies` et `Build unsigned IPA` :

```yaml
    scripts:
      - name: Install dependencies
        script: flutter pub get

      - name: Check TMDB key length
        script: |
          # NE PAS afficher la clé entière dans les logs
          echo "TMDB_API_KEY length: ${#TMDB_API_KEY}"
          if [ -z "$TMDB_API_KEY" ]; then
            echo "ERROR: TMDB_API_KEY is empty"
            exit 1
          fi

      - name: Build unsigned IPA (archive)
        script: |
          echo "Building iOS IPA with injected TMDB API key..."
          flutter build ipa --release --no-codesign \
            --dart-define=TMDB_API_KEY=${TMDB_API_KEY}
```

✅ **À vérifier dans les logs Codemagic :**

* Tu dois voir un truc du genre : `TMDB_API_KEY length: 196` (ou autre, mais > 0).
* Si c’est `0` → souci côté Codemagic (variable mal définie, faute de frappe, etc.).

---

### Étape 2 — Aligner les noms des `dart-define` avec ton code

Dans ton code, tu peux très bien avoir :

```dart
const tmdbKey = String.fromEnvironment('TMDB_API_KEY');
```

…mais il est possible que ton `dev_environment.dart` ou `AppConfigFactory` utilise d’autres noms, du style :

* `TMDB_API_KEY_DEV`
* `TMDB_API_KEY_PROD`
* `TMDB_BEARER_TOKEN`, etc.

**Solution défensive :** passer *tous* les noms possibles au build, au moins le temps du debug :

```yaml
- name: Build unsigned IPA (archive)
  script: |
    echo "Building iOS IPA with injected TMDB API key..."
    flutter build ipa --release --no-codesign \
      --dart-define=TMDB_API_KEY=${TMDB_API_KEY} \
      --dart-define=TMDB_API_KEY_DEV=${TMDB_API_KEY} \
      --dart-define=TMDB_API_KEY_PROD=${TMDB_API_KEY}
```

Ensuite dans ton code, assure-toi que tu lis bien l’une de ces valeurs (et que `ensureValid` vérifie *uniquement* qu’elle n’est pas vide).

---

## Phase 2 — Isoler si le problème vient de ton bootstrap ou d’iOS

**Idée :** faire un build ultra simple qui ne fait *rien* sauf afficher un texte.
Si ça marche → ton problème est bien dans `registerConfig` / DI / router.
Si ça plante déjà → souci côté configuration iOS / plugins.

### Étape 3 — Créer une `main_ios_diag.dart` minimaliste

Ajoute un fichier temporaire :

```dart
// lib/main_ios_diag.dart
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Movi iOS diag – ça démarre 👍'),
        ),
      ),
    ),
  );
}
```

Puis, adapte *temporairement* ton script Codemagic pour cibler cette entrée :

```yaml
flutter build ipa --release --no-codesign \
  --target=lib/main_ios_diag.dart \
  --dart-define=TMDB_API_KEY=${TMDB_API_KEY}
```

✅ **Résultat attendu :**

* Si l’app installée affiche “Movi iOS diag – ça démarre 👍” →
  🔒 iOS / pipeline OK → le problème vient de ton vrai `main.dart` ou de la config.
* Si même ça donne écran blanc →
  il y a un souci plus bas niveau (config iOS, version Flutter bizarre, plugin natif, etc.).

On va supposer que **ça démarre** (99 % de chances).

---

## Phase 3 — Réintroduire ton vrai bootstrap, mais étape par étape

On passe maintenant à ton vrai `main.dart`.
But : trouver **la ligne exacte** qui fait crasher en release.

### Étape 4 — Instrumenter ton `main.dart` en “stages”

Version simplifiée de l’idée :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Log minimal
  debugPrint('Stage 1: main() started');

  try {
    debugPrint('Stage 2: before registerConfig');
    final config = await registerConfig(...);
    debugPrint('Stage 3: after registerConfig OK');

    debugPrint('Stage 4: before initDependencies');
    await initDependencies(config: config, ...);
    debugPrint('Stage 5: after initDependencies OK');

    debugPrint('Stage 6: before LoggingModule.register');
    await LoggingModule.register(config: config);
    debugPrint('Stage 7: after LoggingModule.register OK');

    debugPrint('Stage 8: before runApp');
    runApp(...);
    debugPrint('Stage 9: after runApp (should not see this often)');
  } catch (e, st) {
    debugPrint('FATAL in main(): $e');
    debugPrint('$st');

    // Option: UI d’erreur temporaire
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Startup error: $e')),
        ),
      ),
    );
  }
}
```

**Ce que ça t’apporte :**

* Les `debugPrint` apparaîtront :

  * dans les logs du simulateur / device via Xcode ;
  * et au minimum dans `flutter logs -d <device>` si tu lances en debug avec un Mac.
* Tu sauras si ça casse :

  * juste après `registerConfig()` → TMDB key/config;
  * pendant `initDependencies()` → DB, path_provider, etc.;
  * ou pendant l’enregistrement du logger / router.

---

## Phase 4 — Vérifier que la TMDB key est bien “non vide” dans Flutter

### Étape 5 — Loguer la valeur dans ton `AppConfig` (en release)

Dans la méthode où tu construis ta config (ou dans `ensureValid`), ajoute temporairement :

```dart
debugPrint('TMDB key: "${config.network.tmdbApiKey}"');
debugPrint('TMDB key is empty? ${config.network.tmdbApiKey.isEmpty}');
```

⚠️ Pour éviter de leak la clé dans les logs, tu peux loguer seulement quelques caractères + la longueur :

```dart
final k = config.network.tmdbApiKey;
debugPrint('TMDB key length: ${k.length}');
if (k.isNotEmpty) {
  debugPrint('TMDB key prefix: ${k.substring(0, 8)}...');
}
```

✅ **Interprétation :**

* Si `length = 0` → ton `String.fromEnvironment('XXX')` ne lit pas le bon nom → revoir la **Phase 1, Étape 2**.
* Si `length > 0` → la clé est bien présente → alors :

  * soit `ensureValid` vérifie autre chose (base URL, etc.),
  * soit le crash vient après (DI, DB, router…).

---

## Phase 5 — Durcir ton bootstrap + éviter le white screen

Une fois la cause trouvée (par ex. TMDB key vide ou autre), tu peux mettre en place une solution “clean” :

### Étape 6 — Ne plus *crasher* en dev si la clé manque

Pattern classique :

```dart
AppConfig ensureValid({required bool requireTmdbKey}) {
  if (requireTmdbKey && network.tmdbApiKey.isEmpty) {
    throw StateError('TMDB API key missing for this flavor');
  }

  if (!requireTmdbKey && network.tmdbApiKey.isEmpty) {
    debugPrint('[WARN] TMDB key is empty, app will run in "offline" mode');
  }

  return this;
}
```

Et dans `main()` :

```dart
final config = await registerConfig(
  flavor: flavor,
  requireTmdbKey: kReleaseMode, // en dev: false, en release: true
);
```

Résultat :

* En **release** : si la clé est absente → crash (normal, build mal configuré).
* En **dev** : l’app **ne crashe plus**, tu peux afficher un message d’erreur dans l’UI au lieu d’un écran blanc.

---

### Étape 7 — Utiliser un widget d’“app startup” (optionnel mais très propre)

À plus long terme, le top serait de sortir toute l’init asynchrone de `main()` pour la mettre dans un `FutureProvider` (Riverpod) et un widget qui :

* affiche une splash / loader pendant l’init ;
* affiche une UI d’erreur claire si l’init échoue.

Mais ça, tu pourras le faire quand le problème immédiat sera réglé.

---

## Récap rapide des étapes à suivre

1. **(Codemagic)** Loguer `TMDB_API_KEY length` dans la pipeline et fail si vide.
2. **(Codemagic)** Passer *tous* les `--dart-define` que ton code peut lire (`TMDB_API_KEY`, `_DEV`, `_PROD`).
3. **(Flutter)** Tester un `main_ios_diag.dart` ultra simple → vérifier que l’app affiche un texte → isoler le problème à ton bootstrap.
4. **(Flutter)** Instrumenter `main.dart` avec des `debugPrint` “Stage X” autour de `registerConfig`, `initDependencies`, `LoggingModule.register`, `runApp`.
5. **(Flutter)** Loguer `tmdbApiKey.length` et un préfixe pour vérifier que la clé arrive bien dans `AppConfig`.
6. **(Flutter)** Adapter `ensureValid` avec `requireTmdbKey: kReleaseMode` pour éviter le white screen en dev.
7. **(Optionnel)** Plus tard : refactor vers un `appStartupProvider` propre (Riverpod) et une UI de démarrage/erreur.
# Fix 5 — iOS bloqué sur AppStartupGate alors que Windows passe

Objectif : expliquer pourquoi la build iOS restait bloquée sur l’écran d’amorçage et livrer un correctif + plan d’action pour les secrets/logs.

---

## Diagnostic
- **Symptômes**
  - Sur iOS (build release), l’écran `AppStartupGate` ne se ferme jamais.
  - Sur Windows (build debug), l’app continue normalement.
  - Aucun `app.log` local côté iOS, rendant le diagnostic compliqué.
- **Observations clés**
  - `app_startup_provider` appelait `registerConfig(... requireTmdbKey: kReleaseMode)`.
  - Les builds iOS release sont lancées avec `APP_ENV=dev` (ou staging) **sans** injecter `TMDB_API_KEY` via `--dart-define` → la clé existait seulement dans `.env` local sur desktop.
  - Dans ce cas, `AppConfig.ensureValid()` jette immédiatement une `StateError` (clé requise en release) → `AppStartupGate` affiche juste l’écran de chargement (sans log fichier), d’où la sensation de blocage.
  - Sur Windows debug, `kReleaseMode == false` : le même manque de clé est ignoré, d’où la différence de comportement.

**Conclusion :** la condition “clé obligatoire” était basée uniquement sur `kReleaseMode`, elle doit dépendre du flavor (prod/staging vs dev) ET il faut documenter l’injection de `TMDB_API_KEY` pour iOS.

---

## Correctif code
- **Fichier :** `lib/src/core/startup/app_startup_provider.dart`
  1. Calcul d’un booléen `requireTmdbKey = kReleaseMode && flavor.isProduction;` → seuls les builds release **prod** sont bloquants si la clé manque. Les builds release “dev” restent tolérantes.
  2. Ajout d’un `debugPrint('[Startup] flavor=... requireTmdbKey=...')` pour lire instantanément dans la console quel mode est actif et si la clé est requise.
  3. Passage du booléen au `registerConfig` (remplace l’ancien `kReleaseMode`).

**Effet :** une build iOS release “dev” ou “staging” ne plante plus si la clé n’est pas fournie. Pour prod, l’échec reste volontairement bloquant.

---

## Actions build / Secrets
1. **Toujours injecter la clé TMDB côté CI / Xcode**
   - `flutter build ipa --dart-define=TMDB_API_KEY=<clé>` ou via Codemagic `--dart-define=TMDB_API_KEY=${TMDB_API_KEY}`.
   - Ajouter un check dans le pipeline : `[[ -n "$TMDB_API_KEY" ]] || { echo "TMDB_API_KEY manquante"; exit 64; }`.
2. **Définir l’environnement**
   - Continuer à fournir `--dart-define=APP_ENV=dev|staging|prod` pour aligner le flavor.
   - Les builds release destinées à l’App Store doivent impérativement utiliser `APP_ENV=prod` + clé TMDB valide.

---

## Logs iOS
- `app.log` est écrit dans `Documents/app.log` **dans le sandbox de l’app** (pas dans le repo).
- Pour le récupérer : Xcode → `Devices & Simulators` → sélectionner l’app → `Download Container` → `AppData/Documents/app.log`.
- Pendant le debug, préférer la console (`flutter run -d <device>`) : les nouveaux logs `[Startup] flavor=...` y apparaissent même si le fichier n’est pas créé.

---

## Validation
1. `flutter run -d <simu iOS>` avec `--dart-define=APP_ENV=dev` sans clé → App démarre + logs `[Startup] flavor=Dev ... requireTmdbKey=false`.
2. Rebuild avec `--release --dart-define=APP_ENV=prod` sans clé → `AppStartupGate` passe en erreur (comportement attendu : clé obligatoire en prod).
3. Rebuild prod avec clé `TMDB_API_KEY` → appOK, logs TMDB visibles.

---

## Résultat
- Plus de blocage “fantôme” sur iOS lorsque l’on teste un binaire release en environnement dev/staging.
- Check clair dans les logs concernant le flavor et l’exigence TMDB.
- Process documenté pour retrouver `app.log` iOS et injecter la clé dans les pipelines.

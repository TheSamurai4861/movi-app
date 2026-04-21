# Roadmap temporaire - Logs Release (orientee actions projet)

Date: 2026-04-19
Portee: chaque etape ci-dessous doit produire une modification concrete du code.

## 1. Regle de base

Une etape n'est validee que si:
- un ou plusieurs fichiers du projet sont modifies,
- la verification associee est executee,
- la checklist de l'etape est cochee.

## 2. Cible release

En release, conserver uniquement:
- `warn` / `error` utiles au diagnostic.
- erreurs globales non capturees.
- degrades fonctionnels significatifs.

En release, desactiver:
- `debugPrint(...)` non critique.
- `dev.log(...)` non critique.
- traces de progression startup/DB/cache/UI debug.

## 3. Perimetre de validation fige

Ce chantier valide un perimetre cible et non un nettoyage global de tous les
logs du repository.

Perimetre inclus:
- `lib/src/core/supabase/supabase_module.dart`
- `lib/src/core/performance/performance_module.dart`
- `lib/src/core/startup/app_startup_gate.dart`
- `lib/src/core/storage/database/sqlite_database.dart`
- `lib/src/core/storage/database/sqlite_database_paths.dart`
- `lib/src/core/storage/database/sqlite_database_maintenance.dart`
- `lib/src/features/movie/data/repositories/movie_repository_impl.dart`
- `lib/src/features/search/presentation/providers/search_history_providers.dart`
- `lib/src/features/search/data/datasources/search_history_local_data_source.dart`
- `lib/src/features/search/presentation/pages/genre_results_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
- `lib/src/core/notifications/flutter_local_notification_gateway.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/network/network_executor.dart`
- `lib/src/core/storage/services/storage_module.dart`
- `lib/src/core/auth/auth_module.dart`

Hors perimetre pour cette validation:
- tout autre `debugPrint(...)`, `dev.log(...)` ou logger legacy present dans le
  reste du repository,
- les nettoyages opportunistes sans lien direct avec les fichiers ci-dessus,
- les refactors d'architecture ou changements de comportement non necessaires au
  bruit release.

Regle de decision:
- la validation de ce chantier se fait uniquement sur le perimetre inclus,
- un log legacy trouve hors perimetre n'invalide pas ce chantier,
- un log legacy trouve dans le perimetre inclus bloque la validation finale.

## 4. Format uniforme obligatoire

Format cible unique pour warnings/erreurs:

`[Feature] action=<action> result=<result> code=<code_optionnel> context=<contexte_minimal>`

Exemples:
- `[Startup] action=bootstrap result=failure code=iptv_network_timeout context=source=xtream`
- `[Network] action=request result=retry context=uri=/tv/123 attempt=2`

Contraintes:
- une ligne principale par evenement,
- pas de secrets (password/token/credentials/url signee),
- pas de prefixes legacy en release (`[DEBUG]`, `[BOOTSTRAP]`, etc.).

## 5. Plan d'execution (actions concretes)

### Etape 1 - Supabase startup: retirer le bruit release

Action projet:
- Modifier `lib/src/core/supabase/supabase_module.dart`.
- Encapsuler les logs de progression (`START`, `COMPLETE`, timings) en `kDebugMode` ou les supprimer.
- Conserver seulement les warnings/erreurs utiles en format uniforme.

Definition of done:
- Plus de log verbeux startup Supabase visible en release.
- Les erreurs de configuration/initialisation restent visibles et actionnables.

Verification:
```powershell
rg -n "SupabaseModule.register: START|SupabaseModule.register: COMPLETE|\[DEBUG\]\[Startup\]" lib/src/core/supabase/supabase_module.dart
```

Checklist:
- [x] Fichier modifie
- [x] Verification executee
- [x] Logs restants conformes au format

### Etape 2 - Performance startup: couper traces techniques

Action projet:
- Modifier `lib/src/core/performance/performance_module.dart`.
- Supprimer/guarder en debug les traces de progression et timings.
- Conserver uniquement les anomalies release (`warn/error`) au format uniforme.

Definition of done:
- Les traces techniques de register/configuration ne sortent plus en release.

Verification:
```powershell
rg -n "\[DEBUG\]\[Startup\]|PerformanceModule.register:" lib/src/core/performance/performance_module.dart
```

Checklist:
- [x] Fichier modifie
- [x] Verification executee
- [x] Logs restants conformes au format

### Etape 3 - Startup gate: eliminer logs de statut UI

Action projet:
- Modifier `lib/src/core/startup/app_startup_gate.dart`.
- Retirer logs de statut non incident (`loading`, `ready`).
- Garder uniquement logs d'erreur/degrade utiles.

Definition of done:
- Plus de logs release pour les etats nominaux de l'ecran de startup.

Verification:
```powershell
rg -n "\[Startup\] loading|\[Startup\] ready|\[AppUpdate\] loading" lib/src/core/startup/app_startup_gate.dart
```

Checklist:
- [x] Fichier modifie
- [x] Verification executee
- [x] Logs restants conformes au format

### Etape 4 - SQLite bootstrap: couper logs d'initialisation

Action projet:
- Modifier:
  - `lib/src/core/storage/database/sqlite_database.dart`
  - `lib/src/core/storage/database/sqlite_database_paths.dart`
  - `lib/src/core/storage/database/sqlite_database_maintenance.dart`
- Garder uniquement les erreurs ou modes degrades pertinents en release.
- Les traces techniques (open path, PRAGMA detail, timings) passent en debug-only.

Definition of done:
- Plus de bruit DB release hors incident.

Verification:
```powershell
rg -n "\[DEBUG\]\[Startup\]|\[DB\]" lib/src/core/storage/database
```

Checklist:
- [x] Fichiers modifies
- [x] Verification executee
- [x] Logs restants conformes au format

### Etape 5 - Remplacer dev.log non critiques

Action projet:
- Modifier:
  - `lib/src/features/movie/data/repositories/movie_repository_impl.dart`
  - `lib/src/features/search/presentation/providers/search_history_providers.dart`
  - `lib/src/features/search/data/datasources/search_history_local_data_source.dart`
- Remplacer `dev.log` par:
  - suppression si debug pur,
  - ou `AppLogger.warn/error` si incident utile release.

Definition of done:
- Plus de `dev.log` non justifies en release dans ces fichiers.

Verification:
```powershell
rg -n "dev\.log\(|developer\.log\(" lib/src/features/movie lib/src/features/search
```

Checklist:
- [x] Fichiers modifies
- [x] Verification executee
- [x] Logs restants conformes au format

### Etape 6 - Nettoyage UI debug non critique

Action projet:
- Modifier:
  - `lib/src/features/search/presentation/pages/genre_results_page.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
  - `lib/src/core/notifications/flutter_local_notification_gateway.dart`
- Supprimer `debugPrint` non incident ou les passer en debug-only.

Definition of done:
- Plus de logs UI debug en release dans ces zones.

Verification:
```powershell
rg -n "debugPrint\(" lib/src/features/search/presentation/pages/genre_results_page.dart lib/src/features/welcome/presentation/pages/welcome_user_page.dart lib/src/core/notifications/flutter_local_notification_gateway.dart
```

Checklist:
- [x] Fichiers modifies
- [x] Verification executee
- [x] Logs restants conformes au format

### Etape 7 - Uniformisation finale warn/error

Action projet:
- Parcourir les logs `warn/error` restants des modules critiques et harmoniser le message au format cible.
- Priorite:
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/network/network_executor.dart`
  - `lib/src/core/storage/services/storage_module.dart`
  - `lib/src/core/auth/auth_module.dart`

Definition of done:
- Tous les logs release utiles suivent le meme schema de message.

Verification:
```powershell
rg -n "\.warn\(|\.error\(|LogLevel\.warn|LogLevel\.error" lib/src
rg -n "\[DEBUG\]|\[BOOTSTRAP\]|warn:|error happened" lib/src
```

Checklist:
- [x] Fichiers modifies
- [x] Verification executee
- [x] Format uniforme applique

### Etape 8 - Validation release

Action projet:
- Executer un run/build release avec capture logs.
- Verifier qu'on ne voit que warnings/erreurs utiles.

Verification:
```powershell
flutter build windows --release --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-windows-release.log
rg -n "\[DEBUG\]|\[BOOTSTRAP\]|loading|ready|cache_hit|cache_miss" output/flutter-build-windows-release.log
```

Definition of done:
- Aucun bruit debug detecte dans les logs release collectes.
- Les erreurs critiques restent presentes et lisibles.

Checklist:
- [ ] Build release execute
- [ ] Logs verifies
- [ ] Resultat valide

## 6. Suivi execution

Statut global:
- [x] Etape 1
- [x] Etape 2
- [x] Etape 3
- [x] Etape 4
- [x] Etape 5
- [x] Etape 6
- [x] Etape 7
- [ ] Etape 8

Validation statique complementaire executee le 2026-04-21:
- `flutter analyze`: OK
- scan des prefixes legacy dans `lib/src/core/startup`, `lib/src/core/storage`,
  `lib/src/core/network`, `lib/src/core/auth`, `lib/src/core/supabase`: OK
- `dev.log` / `developer.log` restants detectes uniquement dans
  `lib/src/features/iptv/...`, donc hors perimetre fige de ce chantier

Validation build release executee le 2026-04-21:
- commande: `flutter build windows --release --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-windows-release.log`
- log: `output/flutter-build-windows-release.log`
- resultat build: OK
- scan bruit interdit (`[DEBUG]`, `[BOOTSTRAP]`, `loading`, `ready`,
  `cache_hit`, `cache_miss`) dans le log capture: aucune occurrence

Revue manuelle orientee diagnostic executee le 2026-04-21:
- commande analysee: `flutter build windows --release --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-windows-release.log`
- chemin du log: `output/flutter-build-windows-release.log`
- comportement attendu: log de build release court, sans bruit debug interdit,
  sans secret visible, avec un resultat de build explicite
- comportement observe: 2 lignes uniquement
  - `Building Windows application... 50,7s`
  - `Built build\windows\x64\runner\Release\movi.exe`
- heure approximative: `2026-04-21 06:23`
- conclusion: le log de build est propre, lisible et sans fuite apparente
- limite: ce log valide le build release, pas encore les logs runtime produits
  par l'application une fois lancee

## 7. Statut dossier

Ce dossier est temporaire. Suppression possible apres completion des 8 etapes.

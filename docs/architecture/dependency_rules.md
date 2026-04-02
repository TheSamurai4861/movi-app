# Règles d’architecture — dépendances / imports (Phase 2)

## Statut et conformité
- **Lot** : (Phase 2) `PH2-LOT-001` — Jalon M1
- **Référentiel** : `docs/rules_nasa.md` (§5, §16, §17, §27)
- **Objectif** : définir des règles **testables** et **bloquantes** pour empêcher la réintroduction des violations d’architecture.

## Définitions (modèle de couches)

### Couches (minimales)
Le code est structuré (observé dans `lib/src/`) autour de :
- **domain** : `lib/src/**/domain/**` (entités, value objects, usecases, repositories abstraits)
- **data** : `lib/src/**/data/**` (dtos, datasources, impl repositories, adapters)
- **presentation** : `lib/src/**/presentation/**` (pages, widgets, providers/controllers UI)
- **core** (transverse) : `lib/src/core/**`
- **shared** (transverse) : `lib/src/shared/**`

### “Feature boundary” (frontière de feature)
Une **feature** est un module sous `lib/src/features/<featureName>/`.
Règle générale : une feature ne dépend pas d’une autre feature **sauf** via un contrat explicitement approuvé.

## Règles bloquantes (C2) — families Phase 2

### ARCH-R1 — Interdit : `presentation -> data` (**C2**)
- **Intention** : empêcher la UI d’atteindre les détails d’infrastructure.
- **Détection (testable)** :
  - Un fichier sous `lib/src/**/presentation/**` ne doit pas importer un chemin sous `lib/src/**/data/**`.
- **Exemple refusé**
  - `lib/src/features/movie/presentation/...` importe `package:movi/src/features/movie/data/...`
- **Exemple accepté**
  - `presentation` importe `domain` (`.../domain/...`) ou `application` (si présent), ou `shared/presentation`.

### ARCH-R2 — Interdit : `domain -> data` (**C2**)
- **Intention** : les abstractions ne dépendent pas des implémentations.
- **Détection (testable)** :
  - Un fichier sous `lib/src/**/domain/**` ne doit pas importer un chemin sous `lib/src/**/data/**`.
- **Exemple refusé**
  - `.../domain/usecases/...` importe `.../data/datasources/...`
- **Exemple accepté**
  - `domain` importe `shared/domain` ou des packages standards (`dart:*`, `package:flutter/foundation.dart`).

### ARCH-R3 — Interdit : `presentation -> SDK externe` (**C2**)
- **Intention** : isoler les SDK externes derrière `data` (adapters) ou `core` (infrastructure).
- **Détection (testable)** :
  - Un fichier sous `lib/src/**/presentation/**` ne doit pas importer un package tiers non Flutter/Dart, notamment :
    - `package:supabase_flutter/*`
    - `package:dio/*`
    - `package:sqflite/*`
    - `package:get_it/*` (voir règle locator R5)
    - autres `package:<vendor>/...` listés en allow/deny (à maintenir).
- **Exemple refusé**
  - `presentation/pages/...` importe `package:supabase_flutter/supabase_flutter.dart`
- **Exemple accepté**
  - `presentation` importe un service du projet (ex : `package:movi/src/core/...`) qui encapsule l’SDK.

### ARCH-R4 — Interdit : `feature -> feature` hors contrats approuvés (**C2**)
- **Intention** : éviter le couplage spaghetti entre features.
- **Détection (testable)** :
  - Un fichier sous `lib/src/features/<A>/...` ne doit pas importer `lib/src/features/<B>/...` si `<A> != <B>`,
  - **sauf** si l’import cible un “contrat approuvé” (ex : `lib/src/shared/**` ou un dossier d’API inter-feature explicitement listé).
- **Exemple refusé**
  - `features/movie/...` importe `features/library/...`
- **Exemple accepté**
  - `features/movie/...` importe `shared/domain/...` ou `core/...`.

## Règle locator (UI) — bloquante (C2)

### ARCH-R5 — Interdit : accès direct au locator en UI (**C2**)
- **Intention** : empêcher la UI (pages/widgets/controllers/providers) d’atteindre directement GetIt (`sl`) et de créer du couplage non testable.
- **Périmètre UI** :
  - `lib/src/**/presentation/pages/**`
  - `lib/src/**/presentation/widgets/**`
  - `lib/src/**/presentation/providers/**` (considéré UI)
  - `lib/src/**/presentation/controllers/**` (si présent)
- **Détection (testable)** :
  - Dans les fichiers du périmètre ci-dessus, interdire :
    - `import 'package:get_it/get_it.dart'`
    - `import 'package:movi/src/core/di/di.dart'` (si cela expose `sl`)
    - appels `GetIt.instance`, `sl.get<T>()`, `sl<T>()`, `GetIt.I`
- **Exemples refusés**
  - `presentation/providers/...` qui fait `import 'package:get_it/get_it.dart';` puis `GetIt.instance<...>()`
  - `presentation/pages/...` qui importe `package:movi/src/core/di/di.dart` et lit `sl<...>()`
- **Exemples acceptés**
  - UI qui dépend uniquement de providers Riverpod (`Provider`, `WidgetRef`) et reçoit ses dépendances via injection testable.

## Exceptions / dérogations
- Toute exception à une règle bloquante doit être :
  - justifiée,
  - tracée (logbook),
  - et, si nécessaire, formalisée comme **dérogation** (cf. `docs/rules_nasa.md` §26).

## Sortie attendue pour l’outillage (M2)
L’outil de contrôle d’architecture (script/lint) devra :
- mapper chaque violation à un **ID règle** (`ARCH-R1..R5`),
- produire un rapport lisible (CSV/MD/JSON),
- sortir en **non-zero** si une règle bloquante est violée.

## Exécution locale (Jalon M2)

### Commandes (toutes plateformes)

Self-check (preuve minimale) :

```text
dart run tool/arch_lint.dart --canary
```

Exécution “enforce” + rapport daté :

```text
dart run tool/arch_lint.dart --out docs/architecture/reports/arch_violations_YYYY-MM-DD.md
```

Mur anti-réintroduction (baseline) :

```text
dart run tool/arch_lint.dart --baseline docs/architecture/reports/arch_violations_baseline.md --out docs/architecture/reports/arch_violations_delta.md
```

Suite canary (preuve de détection R1..R5) :

```text
dart run tool/arch_lint.dart --scope tool/arch_lint_canary --canary-fixtures --expect-all-rules --out docs/architecture/reports/arch_canary_report.md
```

### Sorties attendues
- Un fichier de rapport `docs/architecture/reports/arch_violations_*.md`.
- **Exit code non-zero** si violation bloquante détectée.
 - En mode `--baseline`, exit code non-zero uniquement si **nouvelles** violations vs baseline.


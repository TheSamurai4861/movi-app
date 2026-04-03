# Phase 2 — Rapport initial des violations restantes (baseline) — 2026-04-02

## Statut et conformité
- **Phase / Jalon** : Phase 2 — **M4** (rapport initial des violations restantes)
- **Référentiel** : `docs/rules_nasa.md` (§25, §27)
- **Source de vérité brute** : `docs/architecture/reports/arch_violations_2026-04-02.md`
- **Génération** : `dart run tool/arch_lint.dart --out docs/architecture/reports/arch_violations_2026-04-02.md`

## Objet
Établir une **photographie mesurable** des violations d’architecture (imports/dépendances) afin de :
- comparer l’évolution dans le temps ;
- alimenter le classement (M5) par criticité/coût ;
- prouver la capacité à mesurer le graphe (critère d’arrêt Phase 2).

## Résumé (baseline)
- **Violations totales** : 442 (cf. rapport source).
- **Répartition par règles (ARCH-R1..R5)** : voir `arch_violations_2026-04-02.md`.

## Mapping familles Phase 0 (V1–V4) → règles Phase 2 (ARCH-R*)

| Famille (Phase 0) | Description | Règles Phase 2 | Notes |
|---|---|---|---|
| **V1/V2** | `* -> data` | `ARCH-R1` (presentation→data), `ARCH-R2` (domain→data) | correspond à `SYS-ARCH-001` |
| **V3** | locator en UI | `ARCH-R5` | correspond à `SYS-ARCH-002` |
| **V4** | SDK externe en presentation | `ARCH-R3` | correspond à `SYS-ARCH-003` |
| (Phase 2 ajout) | feature→feature hors contrats | `ARCH-R4` | couplage inter-features (bloquant) |

## Classement par zones de code (méthode)
Méthode de regroupement (déterministe) :
- **core** : `lib/src/core/**`
- **shared** : `lib/src/shared/**`
- **features/<name>** : `lib/src/features/<name>/**`
- **autres** : tout ce qui n’entre pas dans les catégories ci-dessus

> Note: ce rapport fournit la **méthode** et le **lien vers la preuve brute**.  
> Le détail exhaustif (fichier/ligne/import) est dans `arch_violations_2026-04-02.md`.

## Annexes (liens)
- Rapport brut (exhaustif) : `docs/architecture/reports/arch_violations_2026-04-02.md`
- Mur anti-réintroduction (delta) : `docs/architecture/reports/arch_violations_delta.md`
- Canary (preuve détection R1..R5) : `docs/architecture/reports/arch_canary_report.md`

---

## Priorisation (M5) — criticité (C/L) + coût (S/M/L)

### Méthode (déterministe)

- **Criticité de base par règle** :
  - `ARCH-R1` / `ARCH-R2` (*→data) : `C2` par défaut
  - `ARCH-R3` (SDK externe en presentation) : `C2` si SDK touche données/auth ; sinon `C3`
  - `ARCH-R4` (feature→feature) : `C2` par défaut ; `C3` si strictement UI
  - `ARCH-R5` (locator en UI) : `C2` par défaut
- **Promotion par zone L1** : toute violation touchant `lib/src/core/auth|startup|storage|parental` est **au minimum** `C2/L1` (ou `C1` si fail-open / fuite données).
- **Coût** :
  - **S** : 1–3 fichiers, extraction/rewiring local
  - **M** : 4–10 fichiers, création adapter/usecase + wiring
  - **L** : >10 fichiers ou refactor transversal (risque régression large)

### Liste — violations touchant zones L1 (core/auth|startup|storage|parental)

| ID backlog | ruleId | Fichier (ligne) | Zone | C | L | Coût | Dépendances / action recommandée |
|---|---|---|---|---|---|---|---|
| `ARCH-BLK-001` | `ARCH-R5` | `lib/src/core/auth/presentation/providers/auth_providers.dart:8` | core/auth | `C2` | `L1` | M | Retirer `di.dart` de UI ; passer par providers testables |
| `ARCH-BLK-002` | `ARCH-R5` | `lib/src/core/parental/presentation/providers/parental_access_providers.dart:3` | core/parental | `C2` | `L1` | M | Même traitement (locator en UI) |
| `ARCH-BLK-003` | `ARCH-R1` | `lib/src/core/parental/presentation/providers/parental_access_providers.dart:5` | core/parental | `C2` | `L1` | M | Extraire abstraction domain/application ; adapter data |
| `ARCH-BLK-004` | `ARCH-R5` | `lib/src/core/parental/presentation/providers/parental_providers.dart:3` | core/parental | `C2` | `L1` | M | Retirer locator de UI |
| `ARCH-BLK-005` | `ARCH-R1` | `lib/src/core/parental/presentation/providers/parental_providers.dart:5` | core/parental | `C2` | `L1` | M | Dépendre de domain/application uniquement |
| `ARCH-BLK-006` | `ARCH-R1` | `lib/src/core/parental/presentation/providers/parental_providers.dart:6` | core/parental | `C2` | `L1` | M | idem |
| `ARCH-BLK-007` | `ARCH-R1` | `lib/src/core/parental/presentation/providers/parental_providers.dart:7` | core/parental | `C2` | `L1` | M | idem |
| `ARCH-BLK-008` | `ARCH-R5` | `lib/src/core/parental/presentation/providers/pin_recovery_providers.dart:3` | core/parental | `C2` | `L1` | M | Retirer locator de UI |

> Remarque : aucune occurrence `core/startup` ou `core/storage` n’apparaît dans les premières lignes du rapport brut daté ; si nécessaire, compléter en parcourant l’intégralité de `arch_violations_2026-04-02.md`.

### Échantillon “top N” par règle (prêt à traiter)

Objectif : fournir des points d’entrée concrets par famille, sans lister les 442 occurrences.

#### `ARCH-R1` (presentation→data) — exemples
- `lib/src/core/parental/presentation/providers/parental_access_providers.dart:5` (L1)
- `lib/src/features/home/presentation/widgets/home_hero_carousel.dart:23`
- `lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:24`
- `lib/src/features/library/presentation/providers/library_providers.dart:10`
- `lib/src/features/library/presentation/providers/library_remote_providers.dart:7`

#### `ARCH-R2` (domain→data) — exemples
- `lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:5`
- `lib/src/features/home/domain/services/home_hero_metadata_service.dart:2`
- `lib/src/features/home/domain/services/movie_playback_service.dart:8`
- `lib/src/features/library/domain/services/playlist_backdrop_service.dart:3`
- `lib/src/shared/domain/services/enrichment_check_service.dart:1`

#### `ARCH-R3` (presentation→SDK externe) — exemples
- `lib/src/core/reporting/presentation/widgets/report_problem_sheet.dart:3`
- `lib/src/core/subscription/presentation/providers/subscription_providers.dart:3`
- `lib/src/features/auth/presentation/auth_otp_controller.dart:5`
- `lib/src/features/movie/presentation/providers/movie_detail_providers.dart:2`
- `lib/src/features/welcome/presentation/providers/welcome_providers.dart:1`

#### `ARCH-R4` (feature→feature) — exemples
- `lib/src/features/auth/presentation/auth_otp_page.dart:13`
- `lib/src/features/category_browser/data/category_browser_data_module.dart:3`
- `lib/src/features/home/data/home_feed_data_module.dart:3`
- `lib/src/features/home/data/repositories/home_feed_repository_impl.dart:5`
- `lib/src/features/home/data/repositories/home_feed_repository_impl.dart:19`

#### `ARCH-R5` (locator en UI) — exemples
- `lib/src/core/auth/presentation/providers/auth_providers.dart:8` (L1)
- `lib/src/core/profile/presentation/controllers/profiles_controller.dart:6`
- `lib/src/core/subscription/presentation/providers/subscription_providers.dart:5`
- `lib/src/features/home/presentation/providers/home_providers.dart:7`
- `lib/src/features/iptv/presentation/providers/iptv_accounts_providers.dart:3`

### Backlog par priorité (synthèse)

- **Priorité haute** : `C2/L1` coût **M** (core/auth, core/parental) — items `ARCH-BLK-001..008`
- **Priorité moyenne** : `C2/L2` coût M/L (couplages `ARCH-R4` inter-features + `ARCH-R1` sur features centrales)
- **Priorité basse** : `C3/L2-L4` coût S/M (cas `ARCH-R3` non data-critical, UI-only)


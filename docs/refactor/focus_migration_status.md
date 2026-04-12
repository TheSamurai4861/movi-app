# Focus Refactor - Phase A Audit Final et Gel du Perimetre

Date snapshot: 2026-04-12
Perimetre: `lib/src`
Source of truth: ce document

## 0) Statut Phase B (moteur directionnel)

- Statut: **B termine (code + tests core)**
- `FocusRegionScope` supporte maintenant: `left`, `right`, `up`, `down`, `back`.
- Regle unifiee:
  - directions flechees: tentative locale `focusInDirection(...)`, puis fallback orchestrateur `resolveExit(...)`.
  - `back/escape/backspace`: exit orchestrateur direct.
- `handleDirectionalExits: false` reste le coupe-circuit global.

Validation ciblee Phase B:

```bash
flutter test test/core/focus/presentation/focus_region_scope_test.dart
flutter test test/core/focus/application/default_focus_orchestrator_test.dart
flutter test test/core/focus
```

## 1) Baseline chiffree (commandes + resultats)

Commandes utilisees:

```bash
rg -n "MoviRouteFocusBoundary\(" lib/src
rg -n "onUnhandledLeft\s*:" lib/src
rg -n "onUnhandledBack\s*:" lib/src
rg -n "FocusRegionScope\(" lib/src
rg -n "MoviOverlayFocusScope\(" lib/src
```

Resultats snapshot:

- `MoviRouteFocusBoundary(`: **18** occurrences (dont **17** ecrans + 1 fichier composant core)
- `onUnhandledLeft:`: **0** occurrence
- `onUnhandledBack:`: **17** occurrences
- `FocusRegionScope(`: **33** occurrences
- `MoviOverlayFocusScope(`: **14** occurrences

Interpretation rapide:

- Le socle moderne (`FocusRegionScope`) est deja largement deploye.
- Le legacy structurel route-level persiste sur 17 ecrans.
- Le callback legacy principal encore actif est `onUnhandledBack`.

Post-L1 (apres migration des 5 ecrans critiques) :

- `MoviRouteFocusBoundary(`: **13** occurrences
- `onUnhandledBack:` (features): **11** occurrences

Post-L2 (apres migration des 4 pages detail) :

- `MoviRouteFocusBoundary(`: **9** occurrences
- `onUnhandledBack:` (features): **7** occurrences

## 2) Inventaire technique legacy (ecrans a migrer)

Criteres:

- Legacy: ecran qui utilise `MoviRouteFocusBoundary`.
- Pattern actuel:
  - `boundary`: legacy majoritaire.
  - `mixte`: boundary + handlers clavier locaux structurels.
- Dependance shell:
  - `high`: flux principal depuis Home/Search/Library/Settings.
  - `medium`: flux secondaire ou page annexe.
  - `low`: flux onboarding/auth local.

| screen | current_pattern | target_pattern | priority | risk | batch | owner | status |
|---|---|---|---|---|---|---|---|
| `features/search/presentation/pages/search_results_page.dart` | scope + back local (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P0 | high | L1 | focus-refactor | migrated |
| `features/search/presentation/pages/genre_results_page.dart` | scope + back local (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P0 | high | L1 | focus-refactor | migrated |
| `features/category_browser/presentation/pages/category_page.dart` | scope + back local (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P0 | high | L1 | focus-refactor | migrated |
| `features/settings/presentation/pages/iptv_sources_page.dart` | scope + back local + overlays (migre) | `FocusRegionScope` + `exitMap(left)` + overlay policy unifiee | P0 | high | L1 | focus-refactor | migrated |
| `features/settings/presentation/pages/iptv_connect_page.dart` | scope + back local (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P0 | medium | L1 | focus-refactor | migrated |
| `features/movie/presentation/pages/movie_detail_page.dart` | scope + back local + key handlers (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P1 | high | L2 | focus-refactor | migrated |
| `features/tv/presentation/pages/tv_detail_page.dart` | scope + back local + key handlers (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P1 | high | L2 | focus-refactor | migrated |
| `features/person/presentation/pages/person_detail_page.dart` | scope + back local + key handlers (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P1 | medium | L2 | focus-refactor | migrated |
| `features/saga/presentation/pages/saga_detail_page.dart` | scope + back local + key handlers (migre) | `FocusRegionScope` + `exitMap(left)` + fallback back route local | P1 | medium | L2 | focus-refactor | migrated |
| `features/settings/presentation/pages/about_page.dart` | boundary + `onUnhandledBack` | `FocusRegionScope` + `exitMap(back/left)` | P2 | low | L3A | focus-refactor | todo |
| `features/settings/presentation/pages/iptv_source_add_page.dart` | boundary + `onUnhandledBack` + overlay (mixte) | `FocusRegionScope` + `exitMap(back/left)` + overlay policy unifiee | P2 | medium | L3A | focus-refactor | todo |
| `features/settings/presentation/pages/iptv_source_select_page.dart` | boundary + `onUnhandledBack` (mixte) | `FocusRegionScope` + `exitMap(back/left)` | P2 | medium | L3A | focus-refactor | todo |
| `features/welcome/presentation/pages/welcome_source_select_page.dart` | boundary + `onUnhandledBack` (mixte) | `FocusRegionScope` + `exitMap(back/left)` | P2 | medium | L3A | focus-refactor | todo |
| `features/welcome/presentation/pages/welcome_source_loading_page.dart` | boundary + `onUnhandledBack` (mixte) | `FocusRegionScope` + `exitMap(back/left)` | P2 | low | L3A | focus-refactor | todo |
| `features/auth/presentation/auth_otp_page.dart` | boundary + `onUnhandledBack` + directional handlers (mixte) | `FocusRegionScope` + `exitMap(back)` + orchestrator only | P2 | medium | L3B | focus-refactor | todo |
| `core/parental/presentation/pages/pin_recovery_page.dart` | boundary + `onUnhandledBack` | `FocusRegionScope` + `exitMap(back)` | P2 | low | L3B | focus-refactor | todo |
| `features/welcome/presentation/pages/splash_bootstrap_page.dart` | boundary + `onUnhandledBack` | `FocusRegionScope` + deterministic entry/fallback | P2 | low | L3B | focus-refactor | todo |

Exceptions documentees L1:

- `search_results`, `genre_results`, `category`, `iptv_sources`, `iptv_connect` conservent un `back` route-local via handler de page pour respecter le back stack existant.
- Les sorties structurelles migratees en L1 sont `left -> shellSidebar` via `exitMap`.

Exceptions documentees L2:

- `movie_detail`, `tv_detail`, `person_detail`, `saga_detail` conservent un `back` route-local via handler de page pour preserver le comportement historique des pages detail.
- Les sorties structurelles migratees en L2 sont `left -> shellSidebar` via `exitMap`.

## 3) Inventaire handlers structurels (hors boundary legacy)

Ce bloc sert a preparer la phase E (reduction imperative) pour les pages deja migrees en scope.

Pages scope avec `handleDirectionalExits: false` + handlers clavier locaux:

- `features/search/presentation/pages/genre_all_results_page.dart`
- `features/search/presentation/pages/provider_all_results_page.dart`
- `features/search/presentation/pages/provider_results_page.dart`
- `features/settings/presentation/pages/settings_subtitles_page.dart`
- `features/welcome/presentation/pages/welcome_source_page.dart`
- `features/welcome/presentation/pages/welcome_user_page.dart`

Autres points structurels shell/orchestrator a garder sous controle:

- `features/shell/presentation/pages/app_shell_page.dart` (transitions globales clavier)
- `features/library/presentation/pages/library_page.dart` (resolveExit direct)
- `features/settings/presentation/pages/settings_page.dart` (resolveExit direct)
- `features/search/presentation/pages/search_page.dart` (resolveExit direct)

## 4) Conventions gelees (contract de migration)

Ces regles sont obligatoires pour qu un ecran soit marque `migrated`.

1. `FocusRegionScope` obligatoire pour la region racine de page.
2. `regionId` explicite (`AppFocusRegionId`) et stable.
3. `FocusRegionBinding` explicite:
   - `resolvePrimaryEntryNode` requis
   - `resolveFallbackEntryNode` requis sauf exception documentee
4. `exitMap` explicite pour `DirectionalEdge.left` et `DirectionalEdge.back` au minimum (sauf ecrans intentionalement modaux).
5. Transitions structurelles via `FocusOrchestrator` uniquement.
6. Interdit pour un ecran `migrated`:
   - `MoviRouteFocusBoundary`
   - callbacks ad hoc structurels type `onUnhandledBack/onUnhandledLeft`
7. Overlays/dialogs:
   - `FocusOverlayScope` ou wrapper `MoviOverlayFocusScope`
   - politique restitution: trigger -> region origine -> fallback explicite -> shell fallback.

## 5) Backlog executable B/C (ordre fige)

Convention ticket:

- 1 ticket = 1 ecran
- output attendu: migration + tests + criteres done valides

### Lot L1 - Flux shell critiques (5 ecrans)

1. `search_results_page.dart`
   - Contexte: sortie vers shell et back critique navigation Search.
   - Strategie: boundary -> scope root + exitMap left/back.
   - Tests: back key, left edge, restore entry.
   - Done: zero boundary, transitions via orchestrator.

2. `genre_results_page.dart`
3. `category_page.dart`
4. `iptv_sources_page.dart`
5. `iptv_connect_page.dart`

### Lot L2 - Pages detail fort trafic (4 ecrans)

6. `movie_detail_page.dart`
7. `tv_detail_page.dart`
8. `person_detail_page.dart`
9. `saga_detail_page.dart`

Regle lot L2:

- Preserver navigation locale (hero/actions/listes) mais deleguer sorties structurelles.

### Lot L3A - Peripherique settings/onboarding (5 ecrans)

10. `about_page.dart`
11. `iptv_source_add_page.dart`
12. `iptv_source_select_page.dart`
13. `welcome_source_select_page.dart`
14. `welcome_source_loading_page.dart`

### Lot L3B - Auth/parental/bootstrap (3 ecrans)

15. `auth_otp_page.dart`
16. `pin_recovery_page.dart`
17. `splash_bootstrap_page.dart`

### Ticket transverse CI guard

18. `CI-FOCUS-GUARD`
- But: bloquer la reintroduction de `MoviRouteFocusBoundary(` hors whitelist transitoire.
- Methode: script check (rg) en CI + failure message actionnable.
- Done: pipeline rouge si nouvel usage hors whitelist.

## 6) Checklist Ready for Migration (Phase A done gate)

- [x] Chaque occurrence legacy dans `lib/src` mappee a une ligne de matrice.
- [x] Aucun ecran prioritaire sans batch.
- [x] Contract cible defini pour 100% des ecrans inventories.
- [x] Baseline `rg` archivee dans ce document.
- [ ] Relecture croisee tech+produit sur criticite et ordre des lots.

## 7) Validation operationnelle Phase A

Rejouer avant passage en phase B:

```bash
# 1) verifier baseline legacy
rg -n "MoviRouteFocusBoundary\(" lib/src
rg -n "onUnhandledBack\s*:" lib/src

# 2) verifier socle moderne en place
rg -n "FocusRegionScope\(" lib/src

# 3) verifier chaque ecran de la matrice existe
rg -n "search_results_page|genre_results_page|category_page|iptv_sources_page|iptv_connect_page|movie_detail_page|tv_detail_page|person_detail_page|saga_detail_page|about_page|iptv_source_add_page|iptv_source_select_page|welcome_source_select_page|welcome_source_loading_page|auth_otp_page|pin_recovery_page|splash_bootstrap_page" lib/src
```

## 8) Notes et hypotheses retenues

- Perimetre strict: `lib/src`.
- Taille de lot cible: 3 a 5 ecrans.
- Priorisation: risque UX navigation > volume de code.
- Owner par defaut en attendant allocation nominative: `focus-refactor`.
- Ce document remplace les notes disperses et sert de reference unique phase A.

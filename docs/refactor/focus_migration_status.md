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
flutter test test/core/focus/presentation/focus_overlay_scope_test.dart
flutter test test/core/focus/presentation/movi_overlay_focus_scope_test.dart
flutter test test/core/focus/legacy_focus_guard_test.dart
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

Post-L3A (apres migration de `about`, `iptv_source_add`, `iptv_source_select`, `welcome_source_select`, `welcome_source_loading`) :

- `MoviRouteFocusBoundary(`: **4** occurrences (dont **3** ecrans + 1 fichier composant core)
- `onUnhandledBack:` (ecrans restants): **3** occurrences

Post-L3B (apres migration de `auth_otp`, `pin_recovery`, `splash_bootstrap`) :

- `MoviRouteFocusBoundary(`: **1** occurrence (fichier composant core uniquement)
- `onUnhandledBack:`: **0** occurrence dans `lib/src`

Post-E1 (reduction imperative ciblee `auth_otp` + `pin_recovery`) :

- `auth_otp_page.dart` et `pin_recovery_page.dart` reutilisent maintenant un helper partage `FocusDirectionalNavigation` pour la navigation clavier locale et la validation defensive de `requestFocus()`.
- Aucun changement d'UI ou de stack de navigation n'est introduit.
- Ces deux ecrans restent **semi-imperatifs** tant que leurs regions internes / sorties structurelles ne sont pas declarativisees davantage.

Post-E2 (reduction imperative ciblee `welcome_source` + `welcome_user`) :

- `welcome_source_page.dart` et `welcome_user_page.dart` reutilisent maintenant le helper partage `FocusDirectionalNavigation` pour la navigation clavier locale et la validation defensive de `requestFocus()`.
- Aucun changement d'UI, de flux onboarding ou de stack de navigation n'est introduit sur ce lot.
- Ces deux ecrans restent **semi-imperatifs** tant que leurs regions internes / sorties structurelles ne sont pas declarativisees davantage.

Post-E3 (reduction imperative ciblee `genre_all_results` + `provider_all_results` + `provider_results`) :

- Les trois pages Search reutilisent maintenant `FocusDirectionalNavigation` pour les handlers `back` route-local, les transitions directionnelles entre regions et les `requestFocus()` defensifs encore utiles.
- Aucun changement d'UI, de flux Search ou de stack de navigation n'est introduit sur ce lot.
- Ces trois ecrans restent **semi-imperatifs** tant que leurs regions internes / sorties structurelles ne sont pas declarativisees davantage.

Post-E4 (reduction imperative ciblee `settings_subtitles`) :

- `settings_subtitles_page.dart` reutilise maintenant `FocusDirectionalNavigation` pour le `back` route-local, la navigation directionnelle locale (groupes horizontaux, listes verticales, sliders) et les `requestFocus()` defensifs encore utiles.
- Aucun changement d'UI, de stack de navigation ou de politique premium n'est introduit sur ce lot.
- Cet ecran reste **semi-imperatif** tant que ses sous-regions / sorties structurelles ne sont pas declarativisees davantage.

Post-E5 (reduction imperative ciblee `search_page`) :

- `search_page.dart` reutilise maintenant `FocusDirectionalNavigation` pour ses transitions clavier root, ses `requestFocus()` defensifs et certains `onKeyEvent` dupliques sur les cartes animees.
- Aucun changement d'UI, de flux Search ou de politique de sortie structurelle n'est introduit sur ce lot.
- Cet ecran reste **semi-imperatif** tant que les transitions shell/contenu et ses sous-regions ne sont pas davantage declarativisees.

Post-E6 (reduction imperative ciblee `sidebar_nav` + `app_shell_page`) :

- `sidebar_nav.dart` reutilise maintenant `FocusDirectionalNavigation` pour la navigation clavier verticale et la validation defensive de `requestFocus()`.
- `app_shell_page.dart` centralise ses transitions clavier shell/sidebar dans des helpers dedies, tout en deleguant toujours les sorties structurelles au coordinator/orchestrateur.
- Aucun changement d'UI, de layout shell ou de politique de navigation n'est introduit sur ce lot.
- Le shell reste **partiellement semi-imperatif** tant que les transitions structurelles globales ne sont pas encore plus declarativisees.

Post-E7 (reduction imperative ciblee `library_page` + `settings_page`) :

- `library_page.dart` reutilise maintenant `FocusDirectionalNavigation` pour plusieurs transitions clavier locales, ses `requestFocus()` defensifs les plus repetes et certains `onKeyEvent` dupliques sur la recherche / les actions / les dialogs.
- `settings_page.dart` reutilise maintenant `FocusDirectionalNavigation` pour la navigation clavier du carrousel profils, le bouton d'ajout, la tuile premium et les sorties horizontales vers la sidebar.
- Aucun changement d'UI, de layout ou de politique de navigation n'est introduit sur ce lot.
- Ces deux ecrans restent **partiellement semi-imperatifs** tant que leurs sous-regions et leurs sorties structurelles ne sont pas davantage declarativisees.

Post-E8 (guard anti-retour legacy) :

- Un test repo `test/core/focus/legacy_focus_guard_test.dart` bloque maintenant la reintroduction de `MoviRouteFocusBoundary(` hors du fichier core legacy lui-meme.
- Le meme garde-fou bloque aussi la reintroduction des callbacks `onUnhandledBack` / `onUnhandledLeft` hors du wrapper legacy.
- `MoviRouteFocusBoundary` est marque `@Deprecated` pour signaler explicitement qu'il ne doit plus etre reutilise dans les ecrans metier.
- Aucun changement d'UI, de navigation runtime ou d'overlay n'est introduit sur ce lot ; il s'agit d'un verrou de non-regression repo/CI.


Post-E9 (hardening overlays profils/settings + wrapper MoviOverlayFocusScope) :

Post-E10 (hardening overlays hors Settings critiques) :

- `ReportProblemSheet` accepte maintenant aussi `originRegionId`, `fallbackRegionId` et `overlayRegionId`, puis forwarde explicitement ces regions vers `MoviOverlayFocusScope`.
- Les callsites `movie_detail`, `tv_detail` et `welcome_user` declarent maintenant explicitement leur region d'origine / fallback pour les overlays parentaux et de signalement problematique, afin de rendre la restitution du focus plus deterministe.
- Les dialogs overlays `iptv_source_add` (confirmation "utiliser maintenant") et `iptv_sources` (confirmation suppression) declarent maintenant explicitement leur region d'origine / fallback IPTV.
- Aucun changement d'UI, de layout ou de stack de navigation n'est introduit sur ce lot ; l'objectif est uniquement de reduire les politiques implicites de restitution du focus sur les overlays restants les plus critiques.

- `MoviOverlayFocusScope` expose maintenant aussi `originRegionId`, `overlayRegionId` et `fallbackRegionId` pour permettre aux callsites de rester sur le wrapper legacy tout en declarant une politique de restitution explicite.
- `CreateProfileDialog` et `ManageProfileDialog` recoivent maintenant le `triggerFocusNode` depuis `settings_page.dart` et declarent `settingsPrimary` comme region d'origine / fallback explicite pour leur overlay racine desktop/TV.
- Aucun changement d'UI, de layout ou de stack de navigation n'est introduit ; ce lot vise uniquement a rendre la restitution du focus plus deterministe quand le trigger initial n'est plus reutilisable (creation / edition de profils).

Post-E15 (surfaces non-Search alignees sur `navigation_helpers`) :

- Les surfaces Home, Category Browser, Library et plusieurs widgets de pages detail (`movie_detail`, `tv_detail`, `saga_detail`) transmettent maintenant explicitement leur `originRegionId` / `fallbackRegionId` aux helpers `navigateToMovieDetail`, `navigateToTvDetail`, `navigateToPersonDetail` et `navigateToSagaDetail`.
- Les callsites disposant deja d'un `FocusNode` concret (`category_grid`, cast `movie_detail`, cast `tv_detail`) transmettent aussi explicitement leur `triggerFocusNode` pour rendre la restitution du focus plus deterministe quand un overlay parental/premium s'ouvre depuis une carte/item reellement focusable.
- Aucun changement d'UI, de layout ou de flux metier n'est introduit sur ce lot ; l'objectif est uniquement d'etendre hors Search la politique `origin/fallback` deja appliquee aux surfaces gardees les plus critiques.

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
| `features/settings/presentation/pages/about_page.dart` | scope + back local (migre) | `FocusRegionScope` + fallback back route local | P2 | low | L3A | focus-refactor | migrated |
| `features/settings/presentation/pages/iptv_source_add_page.dart` | scope + back local + overlay (migre) | `FocusRegionScope` + overlay policy existante + fallback back route local | P2 | medium | L3A | focus-refactor | migrated |
| `features/settings/presentation/pages/iptv_source_select_page.dart` | scope + back local (migre) | `FocusRegionScope` + fallback back route local | P2 | medium | L3A | focus-refactor | migrated |
| `features/welcome/presentation/pages/welcome_source_select_page.dart` | scope + back local (migre) | `FocusRegionScope` + fallback back route local | P2 | medium | L3A | focus-refactor | migrated |
| `features/welcome/presentation/pages/welcome_source_loading_page.dart` | scope + back local (migre) | `FocusRegionScope` + fallback back route local | P2 | low | L3A | focus-refactor | migrated |
| `features/auth/presentation/auth_otp_page.dart` | scope + back local + directional handlers (migre) | `FocusRegionScope` + fallback back route local | P2 | medium | L3B | focus-refactor | migrated |
| `core/parental/presentation/pages/pin_recovery_page.dart` | scope + back local + directional handlers (migre) | `FocusRegionScope` + fallback back route local | P2 | low | L3B | focus-refactor | migrated |
| `features/welcome/presentation/pages/splash_bootstrap_page.dart` | scope + deterministic entry/fallback (migre) | `FocusRegionScope` + deterministic entry/fallback | P2 | low | L3B | focus-refactor | migrated |

Exceptions documentees L1:

- `search_results`, `genre_results`, `category`, `iptv_sources`, `iptv_connect` conservent un `back` route-local via handler de page pour respecter le back stack existant.
- Les sorties structurelles migratees en L1 sont `left -> shellSidebar` via `exitMap`.

Exceptions documentees L2:

- `movie_detail`, `tv_detail`, `person_detail`, `saga_detail` conservent un `back` route-local via handler de page pour preserver le comportement historique des pages detail.
- Les sorties structurelles migratees en L2 sont `left -> shellSidebar` via `exitMap`.

Exceptions documentees L3A:

- `about`, `iptv_source_add`, `iptv_source_select`, `welcome_source_select`, `welcome_source_loading` migrent vers `FocusRegionScope` mais conservent un `back` route-local pour ne pas modifier le stack de navigation existant.
- Les handlers directionnels intra-page et la politique overlay existante sont conserves en l'etat sur ce lot pour limiter le risque de regression UX.

Exceptions documentees L3B:

- `auth_otp` et `pin_recovery` migrent vers `FocusRegionScope` mais conservent un `back` route-local pour preserver le stack de navigation des flows auth / parental.
- `auth_otp` et `pin_recovery` conservent aussi leurs handlers directionnels intra-page ; ils passent donc dans l'inventaire de reduction imperative de la phase suivante.
- `splash_bootstrap` migre vers `FocusRegionScope` avec entree/fallback deterministes, sans introduire de nouvelle sortie structurelle.

## 3) Inventaire handlers structurels (hors boundary legacy)

Ce bloc sert a preparer la phase E (reduction imperative) pour les pages deja migrees en scope.

Pages scope avec `handleDirectionalExits: false` + handlers clavier locaux:

- `features/auth/presentation/auth_otp_page.dart` (helper partage extrait ; regions internes encore locales)
- `core/parental/presentation/pages/pin_recovery_page.dart` (helper partage extrait ; regions internes encore locales)
- `features/search/presentation/pages/genre_all_results_page.dart` (helper partage extrait ; transitions de regions encore locales)
- `features/search/presentation/pages/provider_all_results_page.dart` (helper partage extrait ; transitions de regions encore locales)
- `features/search/presentation/pages/provider_results_page.dart` (helper partage extrait ; transitions de regions encore locales)
- `features/settings/presentation/pages/settings_subtitles_page.dart` (helper partage extrait ; sous-regions et sorties structurelles encore locales)
- `features/welcome/presentation/pages/welcome_source_page.dart` (helper partage extrait ; regions internes encore locales)
- `features/welcome/presentation/pages/welcome_user_page.dart` (helper partage extrait ; regions internes encore locales)

Autres points structurels shell/orchestrator a garder sous controle:

- `features/shell/presentation/pages/app_shell_page.dart` (transitions globales clavier centralisees ; shell encore partiellement semi-imperatif)
- `features/shell/presentation/widgets/navigation/sidebar_nav.dart` (navigation clavier verticale centralisee ; focus structurel encore pilote par le shell)
- `features/library/presentation/pages/library_page.dart` (resolveExit direct)
- `features/settings/presentation/pages/settings_page.dart` (resolveExit direct)
- `features/search/presentation/pages/search_page.dart` (helper partage extrait ; root declaratif, transitions shell/contenu encore directes)

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

Post-E9bis (apres explicitation overlays Settings):

- `showPremiumFeatureLockedSheet(...)` supporte maintenant `originRegionId`/`fallbackRegionId` et les callsites Settings / Settings subtitles les renseignent explicitement.
- `RestrictedContentSheet.show(...)` supporte maintenant `originRegionId`/`fallbackRegionId` et les callsites Settings les renseignent explicitement.
- Les overlays Settings critiques restaurent maintenant le focus vers `settingsPrimary` / `settingsSubtitlesPrimary` de facon deterministe avant fallback shell.


Post-E12 (navigation helpers region-aware sur surfaces Search):

- `navigation_helpers.dart` supporte maintenant `triggerFocusNode` / `originRegionId` / `fallbackRegionId` sur les guards parental et premium.
- Les surfaces Search avec regions explicites (`search_page`, `search_results_page`, `genre_all_results_page`, `genre_results_page`, `provider_results_page`, `provider_all_results_page`) renseignent maintenant l'origine/fallback lors des navigations detail guardees.
- En cas de refus parental/premium sur ces surfaces, la restitution du focus peut retomber sur la region source de facon plus deterministe au lieu de rester entierement implicite.


## 1.g) Lot E16 — regions explicites de routes secondaires et overlays player

Statut: fait.

Ce lot termine un reliquat de finition sur deux surfaces encore implicites:

- `library_playlist_detail_page.dart` expose maintenant une region explicite `libraryPlaylistDetailPrimary` via `FocusRegionScope`; les navigations movie/tv resolues depuis la playlist transmettent aussi `triggerFocusNode`, `originRegionId` et `fallbackRegionId` au helper de navigation.
- `video_player_page.dart` expose maintenant une region explicite `videoPlayerPrimary`; l'overlay parental de garde et les menus player (audio, sous-titres, fit mode) transmettent des informations explicites d'origine/fallback a `MoviOverlayFocusScope`.
- `settings_subtitles_page.dart` aligne enfin l'overlay premium verrouille sur la sous-region `settingsSubtitlesPremium` au lieu de s'en remettre seulement au trigger focus.

Aucun changement d'UI ou de stack de navigation n'est introduit; l'objectif est uniquement de rendre la restitution du focus plus deterministe sur ces surfaces secondaires.

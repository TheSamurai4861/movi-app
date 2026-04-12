## Phase C — Migration Écrans Legacy vers `FocusRegionScope`

### Résumé
Objectif: migrer tous les écrans encore en `MoviRouteFocusBoundary` vers `FocusRegionScope` selon la matrice Phase A, sans changer le comportement UX.  
Cible de sortie: **0 usage écran** de `MoviRouteFocusBoundary`, sorties structurelles via orchestrateur, et non-régression clavier validée par lot.

### Implémentation (ordre figé)
1. **Préparation commune (une seule fois)**
- Appliquer un template unique de migration par écran:
  - root `FocusRegionScope(regionId, binding, exitMap)`
  - remplacement `onUnhandledBack`/`onUnhandledLeft` par `exitMap` + `resolveExit`
  - conserver la navigation locale (grille/formulaire) inchangée.
- Règle: pas d’ajout d’API publique, pas de refonte UI.

2. **Lot L1 — Flux shell critiques (priorité P0)**
- Écrans: `search_results_page`, `genre_results_page`, `category_page`, `iptv_sources_page`, `iptv_connect_page`.
- Pour chaque écran:
  - migrer le root boundary -> scope,
  - définir `exitMap(left/back -> shellSidebar ou cible page)`,
  - garder handlers locaux uniquement pour navigation intra-écran.
- Gate lot L1:
  - navigation shell -> écran -> shell validée,
  - back déterministe,
  - aucune perte de focus silencieuse.

3. **Lot L2 — Détails fort trafic (P1)**
- Écrans: `movie_detail_page`, `tv_detail_page`, `person_detail_page`, `saga_detail_page`.
- Stratégie:
  - scope root + sous-régions minimales si nécessaire (hero/actions/listes),
  - sorties structurelles centralisées, logique locale conservée.
- Gate lot L2:
  - parcours hero/actions/listes non régressé,
  - sortie gauche/back cohérente sur chaque écran.

4. **Lot L3A/L3B — Périphérique settings/onboarding/auth (P2)**
- L3A: `about_page`, `iptv_source_add_page`, `iptv_source_select_page`, `welcome_source_select_page`, `welcome_source_loading_page`.
- L3B: `auth_otp_page`, `pin_recovery_page`, `splash_bootstrap_page`.
- Objectif: homogénéiser les écrans restants avec le même contrat scope/binding/exitMap.
- Gate fin de lot:
  - aucun callback structurel ad hoc résiduel dans ces écrans.

5. **Clôture Phase C**
- Retirer l’usage écran de `MoviRouteFocusBoundary` (le composant peut rester temporairement pour compat technique, mais non référencé par pages migrées).
- Mettre à jour le statut dans `docs/refactor/focus_migration_status.md` (par écran + lot).

### Tests et validation
1. **Validation par ticket écran**
- Cas minimaux:
  - entrée primaire,
  - sortie `left`,
  - sortie `back`,
  - restauration focus (dernier nœud valide sinon primary/fallback).

2. **Validation par lot**
- `flutter test test/core/focus`
- tests widget/feature ciblés des écrans migrés du lot
- smoke manuel clavier (TV/desktop): shell -> écran -> shell, ouverture/fermeture overlay si concerné.

3. **Validation fin Phase C**
- Contrôle repo:
  - `rg -n "MoviRouteFocusBoundary\\(" lib/src` ne doit plus retourner d’écrans métier.
  - `rg -n "onUnhandledBack\\s*:|onUnhandledLeft\\s*:" lib/src/features` doit être nul sur écrans migrés.

### Hypothèses (defaults)
- Priorisation inchangée: risque UX navigation > volume de code.
- Pas de changement d’API publique pendant Phase C.
- Overlays restent gérés via `MoviOverlayFocusScope/FocusOverlayScope` (pas de refonte overlay complète en C).
- Si un écran présente un risque élevé de régression, il peut être découpé en 2 tickets max (root scope puis sous-régions), sans modifier l’ordre des lots.
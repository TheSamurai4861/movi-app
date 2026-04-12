# PRD — Refactor Performance & Render Stability

## 1. Contexte

Après les chantiers:

1. `1_localizations.md`
2. `2_focus.md`
3. `3_architecture_boundaries.md`
4. `4_monolith_pages_decomposition.md`
5. `5_quality_gates_and_repo_hygiene.md`
6. `6_data_contracts_and_error_boundaries.md`
7. `7_observability_and_runtime_diagnostics.md`

la base devient plus saine et observable. Le prochain risque majeur est la performance perçue et la stabilité de rendu.

Le projet comporte des écrans et flux lourds (TV detail, movie detail, search, settings, home hero, sync, playback transitions) où les coûts de build/layout/paint, les rebuilds inutiles, les chargements concurrents et les side effects peuvent dégrader l'expérience (jank, latence d'interaction, scroll/focus instables).

Ce PRD formalise le chantier 8: stabiliser les performances runtime et instaurer des garde-fous de non-régression mesurables.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Risque de jank sur écrans complexes
   - UI dense, animations, changements d'état fréquents.

2. Rebuilds trop larges
   - widgets/pages reconstruits au-delà du nécessaire.

3. Coûts asynchrones concurrents mal bornés
   - fetch/retry/cache parfois simultanés sans orchestration claire.

4. Variabilité de startup et des transitions
   - performances perçues différentes selon device/réseau.

5. Manque de budget perf explicite
   - difficile de trancher "acceptable/non acceptable" sans seuils.

### 2.2 Causes racines

- absence de budget perf produit consolidé.
- instrumentation perf inégale entre flows.
- contrôle partiel des rebuilds/providers.
- stratégie de cache/préchargement pas toujours pilotée par coût.

---

## 3. Objectifs

### 3.1 Objectif principal

Améliorer la fluidité et la stabilité de rendu sur les parcours critiques avec une stratégie de mesure, optimisation et non-régression.

### 3.2 Objectifs détaillés

1. Définir un budget performance explicite sur parcours clés.
2. Réduire les rebuilds inutiles sur hotspots UI.
3. Stabiliser frame times sur interactions critiques.
4. Optimiser loading/caching/préchargement sans surconsommation.
5. Industrialiser la surveillance perf en CI (au moins smoke perf).

### 3.3 KPI de succès

1. Diminution des frames > budget sur parcours P1.
2. Réduction du temps de rendu/interactions sur écrans ciblés.
3. Baisse des rebuild counts sur widgets critiques.
4. Absence de régression perf significative sur releases suivantes.

---

## 4. Hors périmètre

Ne font pas partie du chantier, sauf ajustement strictement nécessaire:

- redesign visuel des écrans.
- changement de stack UI/framework.
- optimisation micro prématurée hors parcours critiques.
- refonte fonctionnelle des features.

Le chantier cible la stabilité runtime mesurable.

---

## 5. Principes directeurs

1. Mesurer avant d'optimiser.
2. Prioriser le ressenti utilisateur sur les parcours critiques.
3. Éviter les optimisations qui complexifient sans gain prouvé.
4. Garder des changements localisés et testables.
5. Aucune optimisation ne doit dégrader la lisibilité architecture.

---

## 6. Architecture cible performance

## 6.1 Budget performance cible

Définir des budgets sur:

1. startup initial (cold/warm),
2. transition vers pages lourdes,
3. interactions principales (scroll, focus movement, ouverture sheet/dialog),
4. lancement playback.

Chaque budget doit inclure:

1. seuil cible,
2. seuil alerte,
3. environnement de mesure.

## 6.2 Instrumentation standard

1. points de mesure communs sur parcours P1.
2. logs/metrics perf corrélés (avec conventions chantier 7).
3. sortie synthétique exploitable en CI/local.

## 6.3 Stratégie de rendu

Règles:

1. limiter périmètre des rebuilds (`select`, découpage widgets, memoisation).
2. isoler parties statiques des parties dynamiques.
3. contrôler listeners/timers/controllers pour éviter rafales.
4. réduire coûts de layout/paint sur sections lourdes.

## 6.4 Stratégie de loading/caching

1. préchargement ciblé sur actions probables.
2. cache invalide de manière explicite et limitée.
3. déduplication requêtes concurrentes.
4. fallback progressif pour éviter blocage UI.

---

## 7. Périmètres prioritaires (ordre)

## 7.1 Priorité P1

1. `tv_detail_page` (interactions, sections lourdes, focus/scroll)
2. `search_page` (rebuilds et chargements)
3. `home_hero_carousel` (rendu/animation)

## 7.2 Priorité P2

1. `settings_page`
2. `movie_detail_page`
3. providers critiques liés au playback/sync

## 7.3 Priorité P3

1. harmonisation globale des patterns perf
2. extension à parcours secondaires

---

## 8. Chantiers techniques prioritaires

## Lot A — Baseline et budgets

Objectif:

- poser la vérité de mesure et les seuils.

Actions:

1. capturer baseline perf sur parcours P1.
2. définir budgets cibles/alertes.
3. documenter protocole de mesure.

Résultat attendu:

- référentiel perf partagé et actionnable.

## Lot B — Render stability

Objectif:

- réduire jank/rebuilds inutiles.

Actions:

1. découper widgets critiques par responsabilité de rendu.
2. appliquer sélecteurs provider plus fins.
3. limiter rebuild cascades.

Résultat attendu:

- frame pacing plus stable sur P1.

## Lot C — Async orchestration & cache

Objectif:

- éviter charges concurrentes et latences évitables.

Actions:

1. dédupliquer fetch/retry concurrents.
2. clarifier stratégie cache + invalidation.
3. améliorer progressivité de chargement.

Résultat attendu:

- réduction latence perçue et fluctuations.

## Lot D — Non-régression perf

Objectif:

- empêcher retour en arrière.

Actions:

1. smoke perf en CI sur parcours ciblés.
2. seuils d'alerte sur métriques clés.
3. rapport delta perf par lot.

Résultat attendu:

- régressions détectées avant merge/release.

---

## 9. Backlog initial (ordre imposé)

## Epic A — Perf baseline

Story A1:

- protocole de mesure standard.

Story A2:

- baseline P1 capturée.

Story A3:

- budgets validés.

## Epic B — UI render optimization

Story B1:

- réduction rebuilds `tv_detail_page`.

Story B2:

- réduction rebuilds `search_page`.

Story B3:

- stabilisation `home_hero_carousel`.

## Epic C — Async/cache optimization

Story C1:

- déduplication requêtes critiques.

Story C2:

- invalidation cache plus fine.

Story C3:

- progressive loading optimisé.

## Epic D — Quality gates perf

Story D1:

- smoke perf CI.

Story D2:

- seuils alertes/perf budget.

Story D3:

- rapport delta perf.

## Epic E — Consolidation

Story E1:

- extension P2/P3.

Story E2:

- documentation patterns perf.

Story E3:

- baseline post-refactor.

---

## 10. Critères d'acceptation

## 10.1 Critères de mesure

1. Baseline perf documentée pour parcours P1.
2. Budgets perf explicites validés.
3. Rapport de delta perf disponible.

## 10.2 Critères techniques

1. Rebuilds inutiles réduits sur hotspots migrés.
2. Stabilité des frames améliorée sur interactions critiques.
3. Async orchestration/caching rationalisés sur périmètre ciblé.

## 10.3 Critères qualité opérationnelle

1. Smoke perf CI actif.
2. Alerte en cas de régression au-delà des seuils.
3. Aucun changement fonctionnel involontaire.

---

## 11. Plan de test

## 11.1 Tests de performance instrumentés

À couvrir:

1. startup et transition vers pages P1.
2. interaction focus/scroll sur pages lourdes.
3. rendu sections critiques (hero, listes, tabs).

## 11.2 Tests fonctionnels non-régression

À couvrir:

1. parcours utilisateur inchangés (TV/Search/Home/Settings/Movie).
2. gestion des états loading/error inchangée.

## 11.3 Tests de stabilité

À couvrir:

1. comportement sous charge réseau variable.
2. répétition d'actions rapides (navigation, retry, changement onglet).
3. absence de fuite timers/listeners/controllers.

## 11.4 Validation CI

1. exécution smoke perf.
2. comparaison baseline/delta.
3. alerte/réjection sur dépassement seuil critique.

---

## 12. Plan de migration

## Étape 1 — Baseline et budget

Livrables:

1. protocole mesure.
2. baseline P1.
3. budgets cibles.

## Étape 2 — Pilote sur hotspot principal

Livrables:

1. optimisation `tv_detail_page`.
2. preuves de gain mesuré.

## Étape 3 — Extension P1

Livrables:

1. `search_page` + `home_hero_carousel`.
2. stabilisation instrumentation.

## Étape 4 — Extension P2

Livrables:

1. `settings_page` + `movie_detail_page`.
2. optimisation providers critiques.

## Étape 5 — Consolidation P3

Livrables:

1. généralisation patterns,
2. documentation finale,
3. baseline post-chantier.

---

## 13. Risques et mitigations

## Risque 1 — Optimisation sans impact réel

Mitigation:

- prioriser uniquement changements avec gain mesuré.

## Risque 2 — Complexification du code

Mitigation:

- refactor localisé, lisible, revues ciblées.

## Risque 3 — Régression fonctionnelle

Mitigation:

- tests non-régression obligatoires à chaque lot.

## Risque 4 — Mesure instable/non reproductible

Mitigation:

- protocole de mesure standardisé + environnement fixe de référence.

---

## 14. Indicateurs de succès

Le chantier est considéré réussi si:

1. les parcours P1 sont visiblement plus fluides.
2. les métriques perf clés s'améliorent par rapport à baseline.
3. les régressions perf sont détectées précocement en CI.
4. les optimisations restent compatibles avec architecture et maintenabilité.

---

## 15. Décisions de conception à retenir

1. La performance est pilotée par budgets explicites.
2. Les optimisations doivent être mesurées avant/après.
3. Les hotspots P1 sont traités avant extension globale.
4. La non-régression perf est industrialisée en CI.
5. La lisibilité du code reste un critère de succès.

---

## 16. Résultat attendu final

À l'issue du chantier 8, le projet doit disposer:

1. d'une expérience plus fluide sur parcours critiques,
2. de rendus plus stables sur écrans complexes,
3. d'un dispositif de surveillance perf empêchant les régressions majeures.

Ce chantier doit transformer la performance en propriété pilotée, mesurée et durable.

---

## 17. Annexe — Résumé opérationnel

### En une phrase

Le chantier 8 fait passer la performance d'un effort ponctuel à un système de budgets, mesures et garde-fous de stabilité.

### Priorités absolues

1. baseline + budgets P1.
2. optimisation rendu hotspots (`tv_detail`, `search`, `home_hero`).
3. orchestration async/cache maîtrisée.
4. smoke perf CI + delta perf.

### Règle d'or

Une optimisation sans gain mesuré et reproductible n'est pas une optimisation validée.

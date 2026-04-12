# PRD — Refactor de décomposition des pages monolithiques

## 1. Contexte

Après les chantiers:

1. `1_localizations.md`
2. `2_focus.md`
3. `3_architecture_boundaries.md`

le prochain levier de maintenabilité est la décomposition des écrans et providers monolithiques.

Le repo contient plusieurs fichiers "hotspots" avec une forte concentration de responsabilités (UI, orchestration, logique de flux, focus, navigation, erreurs, side effects). Cette concentration ralentit les évolutions, augmente la probabilité de régression et rend les tests coûteux.

Exemples de taille observée:

- `lib/src/features/tv/presentation/pages/tv_detail_page.dart` (~4017 lignes)
- `lib/src/features/settings/presentation/pages/settings_page.dart` (~1983 lignes)
- `lib/src/features/search/presentation/pages/search_page.dart` (~1658 lignes)
- `lib/src/features/movie/presentation/providers/movie_detail_providers.dart` (hotspot violations + responsabilités mixtes)

Le problème n'est pas uniquement la taille brute. Le problème principal est le mélange de couches et de responsabilités dans les mêmes unités.

Ce PRD définit la cible de refactor: découper les monolithes en unités cohérentes, testables et lisibles, sans changement UX/fonctionnel.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Widgets/pages "god objects"
   - build methods volumineux,
   - état local dense,
   - logique de navigation/focus mélangée au rendu.

2. Providers "god hubs"
   - composition de trop nombreux use-cases/services dans un seul fichier,
   - invalide/invalidateMany difficile à tracer,
   - dépendances croisées lourdes.

3. Effets de bord dispersés
   - ouverture de sheets/dialogs/navigation,
   - timers/listeners/controllers,
   - logique de retry/recovery mixée à l'UI.

4. Testabilité dégradée
   - tests lourds à écrire et maintenir,
   - faible isolation des comportements,
   - diagnostics de bugs plus lents.

5. Coût de revue élevé
   - PRs sur ces fichiers sont difficiles à valider,
   - risques cachés dans des zones non liées.

### 2.2 Causes racines

- croissance incrémentale des features sans découpage systématique.
- extraction tardive des services de page.
- conventions de taille/cohésion non imposées.
- surcharge des points d'entrée UI.

---

## 3. Objectifs

### 3.1 Objectif principal

Transformer les pages/providers monolithiques en modules cohérents par responsabilité, avec comportement inchangé.

### 3.2 Objectifs détaillés

1. Séparer explicitement:
   - rendu UI,
   - orchestration de flux,
   - actions utilisateur,
   - effets de bord.
2. Réduire la complexité locale des fichiers hotspots.
3. Augmenter la granularité de test (unit + widget ciblés).
4. Faciliter les évolutions futures sans effet domino.
5. Améliorer la lisibilité et la vitesse de revue.

### 3.3 KPI de succès

1. Baisse de taille et de complexité des hotspots ciblés.
2. Hausse du nombre de tests ciblés stables.
3. Diminution des régressions sur pages critiques après refactor.
4. Réduction des PRs "monolithiques" sur ces périmètres.

---

## 4. Hors périmètre

Ne font pas partie du chantier, sauf ajustement strictement nécessaire:

- redesign visuel des écrans.
- modification de parcours fonctionnels métier.
- refonte complète du routing global.
- refonte focus globale (déjà traitée chantier 2).
- réécriture exhaustive de toutes les pages du repo.

Le chantier cible d'abord les hotspots à plus fort risque.

---

## 5. Principes directeurs

1. Refactor pur, sans changement fonctionnel voulu.
2. Migration incrémentale par vertical slice.
3. Une responsabilité principale par fichier.
4. Préférer composition simple à abstraction générique prématurée.
5. Couvrir chaque extraction par tests avant extension.
6. Éviter les mega-PRs de découpage.

---

## 6. Architecture cible (UI/Application locale)

## 6.1 Modèle de découpage cible

Chaque page critique doit converger vers ce modèle:

1. `Page` (entrypoint)
   - assemble sections et branche providers.
   - contient le minimum d'état local indispensable.

2. `PageController` / `PageFacade` (application locale)
   - orchestre actions utilisateur,
   - encapsule enchaînement async et règles de flux.

3. `PageSections` (UI composition)
   - widgets dédiés par bloc de layout,
   - props explicites et minimales.

4. `PageActions` (effets de bord contrôlés)
   - navigation/dialog/sheet/snackbar,
   - handlers isolés et testables.

5. `PageStateAdapters` (mapping UI)
   - transforme états providers en view data.

## 6.2 Règles de découpage

1. Une section UI ne lit pas le locator.
2. Une section UI n'appelle pas directement data layer.
3. Les side effects sont centralisés dans des handlers dédiés.
4. Les providers de page ne doivent pas devenir de nouveaux monolithes.
5. Les noms de fichiers reflètent la responsabilité exacte.

---

## 7. Hotspots prioritaires (ordre)

## 7.1 Priorité P1

1. `tv_detail_page.dart`
2. `movie_detail_providers.dart`

## 7.2 Priorité P2

1. `settings_page.dart`
2. `search_page.dart`

## 7.3 Priorité P3

1. `tv_detail_providers.dart`
2. providers transverses critiques liés aux pages ci-dessus

Ordre imposé:

1. TV detail (page)
2. Movie detail providers
3. Settings page
4. Search page
5. Providers associés restants

---

## 8. Plan de migration

## Étape 1 — Cadre technique commun

Livrables:

1. conventions de découpage (page/controller/sections/actions).
2. checklist de revue refactor monolithe.
3. gabarit de test minimal par extraction.

Résultat attendu:

- approche homogène avant migration hotspots.

## Étape 2 — Pilote sur `tv_detail_page.dart`

Livrables:

1. extraction des sections héro, saisons, cast, actions secondaires.
2. extraction handlers navigation/dialog/sheet.
3. extraction logique d'orchestration dans facade/controller local.

Résultat attendu:

- page allégée avec comportement identique.

## Étape 3 — Providers movie detail

Livrables:

1. split du provider hub en groupes cohérents:
   - état lecture,
   - favoris/playlist,
   - enrichissement.
2. contrats internes lisibles et tests unitaires.

Résultat attendu:

- dépendances explicitement regroupées, invalidations compréhensibles.

## Étape 4 — Settings/Search pages

Livrables:

1. extraction sections UI dédiées.
2. extraction handlers d'actions utilisateur.
3. réduction du code événementiel inline.

Résultat attendu:

- pages lisibles, review-friendly, mieux testables.

## Étape 5 — Consolidation

Livrables:

1. nettoyage final des helpers obsolètes.
2. harmonisation conventions de nommage.
3. validation non-régression complète.

---

## 9. Backlog détaillé

## Epic A — Conventions et outillage

Story A1:

- formaliser les règles de découpage dans docs.

Story A2:

- définir seuils d'alerte "taille/complexité" pragmatiques.

Story A3:

- intégrer checklist refactor monolithe dans les revues.

## Epic B — TV Detail decomposition

Story B1:

- extraire sections UI majeures.

Story B2:

- extraire handlers de side effects.

Story B3:

- extraire orchestration de page.

Story B4:

- couvrir par tests widget ciblés.

## Epic C — Movie providers decomposition

Story C1:

- séparer providers par responsabilité métier.

Story C2:

- réduire accès transverses implicites.

Story C3:

- tests unitaires de flux d'invalidation.

## Epic D — Settings/Search decomposition

Story D1:

- extraction sections + actions de settings.

Story D2:

- extraction sections + actions de search.

Story D3:

- tests non-régression ciblés.

## Epic E — Stabilisation

Story E1:

- revue architecture post-refactor.

Story E2:

- correction résiduelle de couplages parasites.

Story E3:

- baseline finale de complexité pour suivi.

---

## 10. Critères d'acceptation

## 10.1 Critères de structure

1. Les pages migrées n'agrègent plus UI + orchestration + side effects dans un seul bloc.
2. Les sections UI principales sont extraites en widgets dédiés.
3. Les actions/navigation/dialog sont encapsulées dans handlers dédiés.
4. Les providers monolithiques sont découpés en sous-ensembles cohérents.

## 10.2 Critères fonctionnels

1. Aucun changement de parcours utilisateur sur écrans migrés.
2. Focus/navigation existants restent cohérents.
3. États de chargement/erreur restent inchangés côté UX.

## 10.3 Critères qualité

1. Ajout de tests ciblés sur sections/actions extraites.
2. Réduction de complexité lisible en revue.
3. Aucun nouveau couplage architecture interdit introduit.

---

## 11. Plan de test

## 11.1 Unit tests

À couvrir:

1. controllers/facades de page.
2. action handlers (cas nominal + erreur).
3. mappings state -> view models locaux.

## 11.2 Widget tests

À couvrir:

1. sections extraites (rendu et interactions principales).
2. scénarios composés sur page migrée.
3. continuité focus/navigation sur cas critiques.

## 11.3 Non-régression

Smoke manual minimum:

1. TV detail:
   - lecture épisode,
   - action favorite/track,
   - navigation saisons.
2. Movie detail:
   - reprise lecture,
   - favoris,
   - ajout playlist.
3. Settings/Search:
   - actions principales,
   - dialogs/sheets.

## 11.4 Validation architecture

1. exécuter `dart run tool/arch_lint.dart`.
2. confirmer aucune violation nouvelle sur périmètre migré.
3. vérifier alignement avec `3_architecture_boundaries.md`.

---

## 12. Risques et mitigations

## Risque 1 — Refactor cosmétique sans bénéfice réel

Mitigation:

- imposer extraction par responsabilité + tests, pas simple déplacement de code.

## Risque 2 — Régression comportementale

Mitigation:

- migration par petits lots, tests ciblés, smoke systématique.

## Risque 3 — Multiplication de fichiers sans cohérence

Mitigation:

- conventions de nommage et structure imposées avant migration.

## Risque 4 — Dette déplacée vers providers

Mitigation:

- découper aussi les providers hubs, pas uniquement la vue.

---

## 13. Indicateurs de succès

Le chantier est considéré réussi si:

1. les hotspots ciblés sont décomposés sans régression UX.
2. les pages critiques deviennent lisibles et maintenables.
3. les tests ciblés augmentent sur la logique extraite.
4. les PR futures sur ces zones sont plus petites et plus sûres.
5. le chantier 3 (boundaries) est renforcé, pas contourné.

---

## 14. Décisions de conception à retenir

1. Découpage par responsabilités explicites.
2. Refactor incrémental orienté hotspots.
3. Aucun changement fonctionnel volontaire.
4. Tests comme garde-fou obligatoire de chaque extraction.
5. Alignement strict avec frontières définies au chantier 3.

---

## 15. Résultat attendu final

À l'issue du chantier, le projet doit disposer de pages/providers:

- plus petits, plus clairs, plus testables.
- moins risqués à faire évoluer.
- compatibles avec une architecture propre et stable.

Le gain attendu est une baisse nette du coût de maintenance et des régressions sur les écrans à forte complexité.

---

## 16. Annexe — Résumé opérationnel

### En une phrase

Le chantier 4 transforme les pages/providers monolithiques en modules composés et testables, sans modifier l'expérience utilisateur.

### Priorités absolues

1. TV detail page.
2. Movie detail providers.
3. Settings/Search pages.
4. Consolidation tests + validation arch.

### Règle d'or

Si une extraction ne réduit ni complexité ni risque, elle ne fait pas partie du chantier.

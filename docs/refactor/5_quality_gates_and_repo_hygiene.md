# PRD — Refactor Quality Gates & Repo Hygiene

## 1. Contexte

Après les chantiers:

1. `1_localizations.md`
2. `2_focus.md`
3. `3_architecture_boundaries.md`
4. `4_monolith_pages_decomposition.md`

le prochain risque principal n'est plus seulement technique, il est opérationnel: sans garde-fous robustes, la dette revient vite.

Le projet dispose déjà d'outils utiles (`arch_lint`, tests, conventions), mais ils ne sont pas encore suffisamment industrialisés pour garantir:

- zéro régression architecture en continu,
- qualité minimale uniforme en PR,
- hygiène repository durable.

Ce PRD formalise un chantier dédié à la mise en place de quality gates fiables et d'une hygiène repo stricte.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Les violations architecture peuvent réapparaître sans blocage systématique en CI.
2. Les checks de qualité ne sont pas toujours homogènes entre contributions.
3. Le repo contient des artefacts parasites (exemple: `desktop.ini` versionnés dans `lib/`).
4. Le signal qualité PR est parfois trop tardif ou incomplet.
5. Le suivi de progression (baseline/delta) n'est pas centralisé de manière opérationnelle.

### 2.2 Causes racines

- absence d'une policy globale "quality gates obligatoires".
- garde-fous techniques partiellement manuels.
- conventions repo/hygiène non verrouillées au niveau pipeline.
- manque de métriques standardisées de suivi de dette.

---

## 3. Objectifs

### 3.1 Objectif principal

Installer un système de qualité exécutable et bloquant qui empêche la réintroduction de dette et maintient un repo propre par défaut.

### 3.2 Objectifs détaillés

1. Rendre `arch_lint` bloquant avec politique "no new violations".
2. Standardiser les quality gates PR (analyse, lint, tests ciblés).
3. Mettre en place une hygiène repo anti-artefacts parasites.
4. Ajouter un reporting baseline/delta exploitable à chaque lot.
5. Réduire le temps de détection des régressions.

### 3.3 KPI de succès

1. 100% des PR passent par le même pipeline de contrôle.
2. 0 nouvelle violation architecture acceptée en merge.
3. 0 artefact interdit versionné (`desktop.ini`, etc.).
4. Tendance d'amélioration visible sur les deltas architecture/tests.

---

## 4. Hors périmètre

Ne font pas partie du chantier, sauf ajustement strictement nécessaire:

- refonte de l'architecture métier.
- réécriture complète des suites de tests existantes.
- migration d'outil CI vers une nouvelle plateforme.
- changement fonctionnel produit.

Le chantier porte sur les garde-fous qualité et l'hygiène du dépôt.

---

## 5. Principes directeurs

1. Un gate bloquant doit être simple, fiable et reproductible.
2. Aucune règle ambiguë: chaque échec doit être actionnable.
3. Fast feedback d'abord (ordre des checks optimisé).
4. Pas de gate "cosmétique" sans impact réel sur le risque.
5. Les conventions repo doivent être auto-enforcées autant que possible.

---

## 6. Architecture cible des quality gates

## 6.1 Pipeline qualité cible (ordre recommandé)

1. Checks rapides:
   - format/lint statique,
   - validation fichiers interdits.
2. Architecture:
   - `dart run tool/arch_lint.dart`
   - contrôle delta "no new violations".
3. Tests:
   - suite rapide obligatoire (smoke/unitaires critiques),
   - suites additionnelles selon périmètre.
4. Reporting:
   - publication du résumé des deltas.

## 6.2 Politique "No New Violations"

Règle:

- une PR ne peut pas être mergée si elle augmente le nombre de violations par règle (`ARCH-R1..R5`) ou globalement.

Tolérance:

- une baisse est autorisée,
- un statu quo peut être autorisé temporairement selon scope,
- une hausse est bloquante.

## 6.3 Hygiène repo cible

1. Interdire les fichiers parasites OS/IDE dans le versioning.
2. Renforcer `.gitignore` pour artefacts connus.
3. Ajouter un check CI "forbidden files".
4. Ajouter un check local optionnel pré-commit (non bloquant serveur).

---

## 7. Chantiers techniques prioritaires

## Lot A — Architecture gate en CI

Objectif:

- rendre la règle architecture incontestable au merge.

Actions:

1. intégrer `arch_lint` au pipeline principal.
2. comparer baseline/delta automatiquement.
3. échouer la PR si nouvelle violation.

Résultat attendu:

- dette architecture ne peut plus croître en silence.

## Lot B — Test gates minimaux obligatoires

Objectif:

- garantir un socle de non-régression rapide.

Actions:

1. définir une suite smoke/unitaire obligatoire.
2. exécuter cette suite sur chaque PR.
3. garder un temps d'exécution compatible productivité.

Résultat attendu:

- régressions critiques détectées avant merge.

## Lot C — Repo hygiene hardening

Objectif:

- supprimer et empêcher artefacts non pertinents.

Actions:

1. nettoyer artefacts déjà versionnés.
2. renforcer `.gitignore`.
3. ajouter check CI fichiers interdits.

Résultat attendu:

- dépôt propre et stable.

## Lot D — Reporting qualité

Objectif:

- pilotage mesurable des progrès.

Actions:

1. générer résumé de qualité par PR (arch/test/hygiène).
2. conserver baseline de référence datée.
3. publier tendance hebdomadaire/mensuelle.

Résultat attendu:

- décisions guidées par données, pas perception.

---

## 8. Backlog initial (ordre imposé)

## Epic A — Gate architecture

Story A1:

- brancher `arch_lint` en CI.

Story A2:

- implémenter blocage "no new violations".

Story A3:

- publier delta par règle dans les logs CI.

## Epic B — Gate tests

Story B1:

- définir suite minimale obligatoire.

Story B2:

- brancher exécution systématique en PR.

Story B3:

- standardiser la sortie et l'interprétation des échecs.

## Epic C — Hygiène repo

Story C1:

- supprimer fichiers parasites déjà trackés.

Story C2:

- renforcer `.gitignore` et conventions.

Story C3:

- ajouter check CI "forbidden files".

## Epic D — Observabilité qualité

Story D1:

- baseline versionnée des indicateurs.

Story D2:

- rapport de delta automatique par PR.

Story D3:

- synthèse périodique qualité.

## Epic E — Durcissement process

Story E1:

- mettre à jour docs de contribution.

Story E2:

- checklist PR alignée quality gates.

Story E3:

- revue post-déploiement des gates (faux positifs/temps).

---

## 9. Hotspots et cas prioritaires

1. Architecture violations report:
   - `docs/architecture/reports/arch_violations_2026-04-12.md`
2. Zones critiques de non-régression:
   - welcome,
   - tv/movie detail,
   - settings,
   - search.
3. Artefacts parasites connus:
   - `desktop.ini` dans arborescence `lib/`.

---

## 10. Critères d'acceptation

## 10.1 Critères de gouvernance

1. Toute PR exécute les quality gates obligatoires.
2. Aucune PR avec nouvelle violation architecture n'est mergeable.
3. Les conventions d'hygiène repo sont documentées et enforceables.

## 10.2 Critères techniques

1. `arch_lint` est intégré et bloquant sur condition de régression.
2. Suite de tests minimale obligatoire en place.
3. Check fichiers interdits opérationnel.
4. `.gitignore` couvre les artefacts ciblés.

## 10.3 Critères de qualité opérationnelle

1. Rapport delta disponible en sortie CI.
2. Temps de feedback acceptable pour les développeurs.
3. Taux de faux positifs maîtrisé.

---

## 11. Plan de test

## 11.1 Tests de pipeline

À valider:

1. PR factice avec nouvelle violation arch -> pipeline échoue.
2. PR factice sans nouvelle violation -> gate architecture passe.
3. PR avec fichier interdit -> gate hygiène échoue.

## 11.2 Tests de robustesse

À valider:

1. logs d'échec explicites et actionnables.
2. absence de faux positifs fréquents.
3. comportement stable sur rerun pipeline.

## 11.3 Non-régression produit

Smoke minimal à conserver:

1. welcome bootstrap.
2. tv/movie detail actions principales.
3. settings actions principales.
4. search interactions clés.

---

## 12. Plan de migration

## Étape 1 — Baseline et spécification des gates

Livrables:

1. baseline qualité datée.
2. définition officielle des gates obligatoires.

## Étape 2 — Activation progressive en mode avertissement

Livrables:

1. gates actives non bloquantes temporairement.
2. collecte des faux positifs et ajustements.

## Étape 3 — Passage en bloquant

Livrables:

1. activation des gates bloquantes.
2. policy merge alignée.

## Étape 4 — Stabilisation

Livrables:

1. tuning performance pipeline.
2. documentation contribution finalisée.

---

## 13. Risques et mitigations

## Risque 1 — Pipeline trop lent

Mitigation:

- ordonner checks rapides d'abord, suite minimale obligatoire optimisée.

## Risque 2 — Faux positifs trop fréquents

Mitigation:

- phase d'observation avant blocage strict + règles explicites.

## Risque 3 — Contournement des gates

Mitigation:

- rendre les gates obligatoires au merge et visibles en revue.

## Risque 4 — Friction équipe excessive

Mitigation:

- messages d'erreur actionnables + documentation concise + feedback rapide.

---

## 14. Indicateurs de succès

Le chantier est réussi si:

1. aucune régression architecture nouvelle n'est mergée.
2. les artefacts parasites disparaissent et ne reviennent pas.
3. le signal qualité PR devient cohérent et fiable.
4. la trajectoire de dette s'améliore sprint après sprint.

---

## 15. Décisions de conception à retenir

1. Le merge est conditionné par des quality gates obligatoires.
2. La règle "no new violations" est non négociable.
3. L'hygiène repo est enforceable par automation.
4. Le reporting qualité fait partie du delivery, pas un extra.

---

## 16. Résultat attendu final

À l'issue du chantier, le projet doit disposer:

1. d'une CI qui bloque les régressions architecture/qualité.
2. d'un dépôt propre sans artefacts parasites.
3. d'un suivi mesurable et transparent des progrès.

Le but final est de sécuriser durablement les chantiers 3 et 4 en empêchant toute rechute structurelle.

---

## 17. Annexe — Résumé opérationnel

### En une phrase

Le chantier 5 industrialise la qualité: ce qui est attendu devient automatiquement vérifié et bloquant.

### Priorités absolues

1. `arch_lint` bloquant + no new violations.
2. suite tests minimale obligatoire.
3. check fichiers interdits + hygiène repo.
4. reporting baseline/delta exploitable.

### Règle d'or

Si un risque peut être empêché automatiquement en CI, il ne doit plus reposer sur une vérification manuelle.

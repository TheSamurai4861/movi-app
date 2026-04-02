# Roadmap — Phase 2 : Mur de dépendances et gel des violations futures

## Références et conformité
- **Plan source** : `movi_nasa_refactor_plan_v3.md` — Phase 2 (Mur de dépendances et gel des violations futures).
- **Règles applicables** : `docs/rules_nasa.md` (preuve, traçabilité, quality gates, contrôle renforcé si C1/L1).
- **Traçabilité changement** : `docs/traceability/change_logbook.md` (lot Phase 2 à créer avant exécution).
- **Index des preuves** : `docs/quality/validation_evidence_index.md` (référencer les rapports/outils exécutés).
- **Contexte risques** : `docs/risk/system_risk_register.md` (entrées `SYS-ARCH-001..003`).

## Objectif (Phase 2)
Empêcher toute aggravation de l’architecture **avant** de corriger l’existant, en rendant les violations **mesurables** et **bloquantes** en CI.

## Périmètre
### Inclusions
- Règles d’import par couche (domain/data/presentation + frontières feature).
- Contrôles automatiques (local + CI) pour refuser les violations.
- Rapport initial des violations restantes + classement (criticité/coût).

### Hors périmètre (par défaut)
- Refactor massif de toutes les violations (ce sera une phase ultérieure) ; ici, on construit le **mur** et la **mesure**.

## Quality gates (bloquants)
- **No evidence, no merge** : chaque ajout de règle/outil/rapport doit être indexé dans `docs/quality/validation_evidence_index.md`.
- **Traçabilité minimale** : chaque lot d’outillage doit être tracé dans `docs/traceability/change_logbook.md`.
- **Aucune nouvelle violation** : les contrôles CI doivent empêcher la réintroduction.

## Livrables attendus (issus du plan)
- `docs/architecture/dependency_rules.md`
- scripts / lint de contrôle d’architecture (versionnés)
- rapport initial des violations (versionné/archivé)

## Roadmap (WBS) — activités obligatoires, critères d’acceptation et preuves

### Jalon M1 — Règles d’import autorisées par couche
**But** : expliciter, de façon non ambiguë, les dépendances autorisées/interdites.

- **Travaux**
  - Définir le modèle de couches (au minimum : `domain`, `data`, `presentation`) + règles inter-features.
  - Formaliser les interdits du plan :
    - `presentation -> data`
    - `domain -> data`
    - `presentation -> SDK externe`
    - `feature -> feature` hors contrats approuvés
  - Définir la politique “locator” : interdiction en pages/widgets/controllers UI.
- **Critères d’acceptation**
  - Les règles sont écrites de manière testable (ex: motifs de chemins, conventions de noms).
  - Chaque règle a une justification et un niveau de sévérité (au moins `C2` pour blocantes).
- **Preuves à indexer**
  - `docs/architecture/dependency_rules.md` versionné + entrée `PH?-EVD-???` dans `docs/quality/validation_evidence_index.md`.

### Jalon M2 — Contrôles automatiques (local + CI) contre imports interdits
**But** : transformer les règles en contrôles exécutables et bloquants.

- **Travaux**
  - Implémenter un script/lint d’architecture (ex: scan imports) produisant :
    - **exit code non-zero** si violation bloquante,
    - un rapport lisible (CSV/MD/JSON).
  - Intégrer l’exécution en CI (Codemagic ou équivalent) comme quality gate.
- **Critères d’acceptation**
  - En CI, un PR qui introduit une violation **échoue**.
  - Les résultats sont reproductibles et archivables (log/rapport versionné ou attaché en artefact).
- **Preuves à indexer**
  - Logs CI + rapport généré (artefact daté) référencés dans `docs/quality/validation_evidence_index.md`.

### Jalon M3 — Interdictions CI explicites (les 4 familles du plan)
**But** : garantir que les violations ciblées ne réapparaissent jamais.

- **Travaux**
  - Rendre bloquantes les interdictions :
    - `presentation -> data`
    - `domain -> data`
    - `presentation -> SDK externe`
    - `feature -> feature` hors contrats approuvés
  - Ajouter la règle “locator in UI” (pages/widgets/controllers).
- **Critères d’acceptation**
  - Un test “canary” (ou preuve minimale) démontre que chaque famille de violation est bien détectée.
- **Preuves à indexer**
  - Rapport canary (même si documentaire) + logs d’exécution.

### Jalon M4 — Rapport initial des violations restantes
**But** : établir une baseline mesurable (photographie) de l’existant.

- **Travaux**
  - Exécuter le contrôle sur la base actuelle et produire un rapport complet des violations.
  - Classer par famille (V1–V4) et par zone de code.
- **Critères d’acceptation**
  - Le rapport est complet, stable, et peut être comparé dans le temps.
- **Preuves à indexer**
  - Rapport daté archivé + référence dans `docs/quality/validation_evidence_index.md`.

### Jalon M5 — Classement des violations (criticité + coût)
**But** : prioriser rationnellement la correction future.

- **Travaux**
  - Pour chaque violation, assigner :
    - criticité changement (`C1..C4`) et classe composant (`L1..L4`) si applicable,
    - coût estimatif (S/M/L) + dépendances de refactor.
  - Identifier les violations touchant `L1` (startup/auth/storage/parental) comme candidates à traitement prioritaire.
- **Critères d’acceptation**
  - Les violations sont triées en backlog “prêt à traiter” (risque/impact/coût).
- **Preuves à indexer**
  - Tableau de priorisation versionné (dans le rapport ou document séparé) + entrée d’index.

## Gate de sortie (Phase 2)
**Aucun nouveau code** ne doit pouvoir réintroduire une violation bloquante : un PR volontairement fautif doit échouer (preuve).

## Critères d’arrêt
- règles non automatisées ;
- violations nouvelles encore acceptées ;
- impossibilité de mesurer l’évolution du graphe de dépendances.

## Checklist “fin de phase” (à cocher avant clôture)
- [ ] `docs/architecture/dependency_rules.md` publié et revu
- [ ] contrôle architecture exécuté localement et en CI (bloquant)
- [ ] 4 familles d’interdictions + “locator in UI” démontrées (preuve canary)
- [ ] rapport baseline des violations produit et archivé
- [ ] violations classées par criticité + coût
- [ ] entrées ajoutées dans `docs/traceability/change_logbook.md`
- [ ] preuves référencées dans `docs/quality/validation_evidence_index.md`


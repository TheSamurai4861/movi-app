# Roadmap — Phase 3 : Inventaire des flux critiques et des invariants

## Références et conformité
- **Plan source** : `movi_nasa_refactor_plan_v3.md` — Phase 3 (Inventaire des flux critiques et des invariants).
- **Règles applicables** : `docs/rules_nasa.md` (traçabilité §6, risques §8/§9, tests §15, documentation §23, artefacts de preuve §25, quality gates §27).
- **Traçabilité changement** : `docs/traceability/change_logbook.md` (entrées à ajouter si création/modification d’artefacts).
- **Index des preuves** : `docs/quality/validation_evidence_index.md` (référencer chaque livrable et tout résultat d’exécution).
- **Contexte risques** : `docs/risk/system_risk_register.md` et livrables Phase 1 (`docs/risk/failure_modes.md`, `docs/risk/hazard_analysis.md`) si déjà produits.

## Objectif (Phase 3)
Définir **ce qui ne doit pas casser** avant tout refactor structurel (Phase 4+), en rendant explicites :
- les **flux critiques**,
- leurs **invariants**,
- les **transitions d’état**,
- les **états sûrs** et comportements dégradés,
- l’**observabilité** attendue,
- les **tests de non-régression** requis,
- le **rollback** possible.

## Périmètre
### Flux minimaux à modéliser (issus du plan)
- démarrage applicatif ;
- restauration de session ;
- authentification / déconnexion ;
- sélection et lecture d’une source vidéo ;
- résolution movie/tv ;
- profils et restrictions parentales ;
- synchronisation locale/cloud ;
- settings impactant le runtime ;
- diagnostics et remontée de problèmes.

### Hors périmètre (par défaut)
- Implémenter le refactor des modules (Phase 4+) : ici, on produit le **cadre vérifiable** et les **scénarios**.
- Optimisations performance non pilotées par mesure (sauf si nécessaires à un invariant).

## Hypothèses et décisions de cadrage
- La Phase 3 est une **phase de qualification** : on accepte de produire des documents et des matrices **avant** de modifier le noyau.
- Toute lacune bloquante identifiée sur un flux (absence d’observabilité, invariants ambigus, rollback non plausible) est traitée comme **risque** (au minimum **C2** ; **C1** si flux L1 / sécurité / données).

## Quality gates (bloquants)
- **No evidence, no merge** : chaque livrable (matrice, spécification, preuves) doit être référencé dans `docs/quality/validation_evidence_index.md` (§25).
- **Traçabilité minimale** : tout invariant critique doit être relié à une exigence et à une vérification (§6).
- **Changements C1/C2** : aucun refactor critique (Phase 4+) ne démarre tant que les invariants et tests associés ne sont pas formalisés (§27).
- **Aucun état implicite** : transitions, erreurs et états sûrs doivent être explicités (sinon présumés risqués) (§2, §9, §11).

## Livrables attendus (issus du plan)
- `docs/traceability/requirements_traceability.md`
- `docs/traceability/verification_matrix.md`
- **Matrice des invariants et non-régressions critiques** (format recommandé : markdown versionné dans `docs/traceability/`)

## Roadmap (WBS) — activités obligatoires, critères d’acceptation et preuves

### Jalon M1 — Définition du périmètre et des identifiants (exigences, flux, invariants)
**But** : rendre la suite des artefacts **traçables** et comparables dans le temps.

- **Travaux**
  - Définir un schéma d’identifiants :
    - Flux : `PH3-FLOW-###`
    - Exigences : `PH3-REQ-###`
    - Invariants : `PH3-INV-###`
    - Scénarios de test : `PH3-TST-###`
  - Définir un gabarit unique “fiche flux” (voir M2).
- **Critères d’acceptation**
  - Chaque flux du périmètre a un identifiant et un owner (même si “à compléter”).
  - Les conventions sont cohérentes avec `docs/rules_nasa.md` (§6, §25).
- **Preuves à indexer**
  - Section “conventions” dans `requirements_traceability.md` et/ou `verification_matrix.md`.

### Jalon M2 — Fiches “Flux critique” complètes (préconditions → transitions → erreurs → état sûr)
**But** : modéliser chaque flux minimal selon le plan, de façon exploitable par le refactor (Phase 4+).

- **Travaux**
  - Pour chaque flux `PH3-FLOW-*`, documenter au minimum :
    - **préconditions** (env, session, réseau, storage, droits) ;
    - **transitions d’état** (diagramme ou table) ;
    - **invariants** (liste `PH3-INV-*`) ;
    - **effets de bord** (IO, réseau, cache, analytics, auth) ;
    - **erreurs nominales** et **anormales** (catégorisées §11) ;
    - **état sûr** en échec partiel (fail-closed si L1 / sécurité) ;
    - **observabilité** minimale (logs/events/metrics corrélables §14) ;
    - **rollback possible** (manuel / kill switch / feature flag / version N-1).
- **Critères d’acceptation**
  - Les transitions “critiques” ne dépendent pas d’un ordre implicite non documenté.
  - Chaque erreur critique a une stratégie : message utilisateur + diagnostic + action (retry contrôlé, fallback, blocage).
- **Preuves à indexer**
  - Matrice (ou annexes) versionnées + revue par pair.

### Jalon M3 — Matrice des invariants (système + données) et classification criticité (C/L)
**But** : distinguer ce qui est non négociable et calibrer le niveau de preuve requis.

- **Travaux**
  - Établir une matrice “Invariant → flux → composants → données → criticité” :
    - Criticité changement : `C1..C4`
    - Classe composant : `L1..L4`
  - Pour chaque invariant `PH3-INV-*` :
    - définir le **signal de rupture** (comment on sait que c’est cassé) ;
    - définir le **mode dégradé acceptable** (ou “interdit”).
- **Critères d’acceptation**
  - Tous les invariants `C1/C2` ont une stratégie de test associée (M4).
  - Aucun invariant critique n’est “non vérifiable” sans dérogation (§26).
- **Preuves à indexer**
  - Matrice des invariants versionnée + entrée dans `validation_evidence_index.md`.

### Jalon M4 — Matrice de vérification (tests requis) : de l’invariant à l’évidence
**But** : relier chaque invariant à une vérification adaptée (tests + preuves CI), conformément à §6, §15, §25.

- **Travaux**
  - Produire `docs/traceability/verification_matrix.md` couvrant :
    - `PH3-INV-*` → type(s) de tests : unit/widget/integration/E2E
    - prérequis outillage (mocks autorisés/interdits, fixtures, test data)
    - “preuve attendue” (log CI, artefact, rapport)
  - Définir des scénarios **négatifs** obligatoires sur chemins critiques (timeouts, offline, session invalide, storage indispo, parental bloquant).
- **Critères d’acceptation**
  - Chaque invariant `C1/C2` a au moins un test prévu (ou une vérification indépendante + justification).
  - Les tests sont déterministes et isolables (principe §15.1).
- **Preuves à indexer**
  - `verification_matrix.md` versionné + revue.

### Jalon M5 — Requirements traceability (exigences ↔ flux ↔ invariants ↔ vérifications)
**But** : rendre l’ensemble auditable (“source de besoin → implémentation → vérification”) avant le refactor.

- **Travaux**
  - Produire `docs/traceability/requirements_traceability.md` avec au minimum :
    - `PH3-REQ-*` → `PH3-FLOW-*` → `PH3-INV-*` → `PH3-TST-*`
    - liens vers docs Phase 1 (risques, failure modes, hazard analysis) quand pertinent.
- **Critères d’acceptation**
  - Tout flux critique a au moins une exigence et une vérification associées.
  - Les liens sont suffisants pour une revue indépendante (§16).
- **Preuves à indexer**
  - `requirements_traceability.md` versionné + entrée `PH3-EVD-*` (à créer) dans `validation_evidence_index.md`.

### Jalon M6 — Gate de démarrage Phase 4 (précondition de refactor)
**But** : verrouiller la règle du plan : aucun lot critique ne démarre sans invariants et scénarios.

- **Travaux**
  - Définir une checklist “pré-Phase 4” basée sur :
    - invariants `C1/C2` couverts par tests prévus (ou dérogations)
    - observabilité minimale définie
    - rollback plausible (au moins documentaire)
  - Définir critères d’arrêt :
    - invariant C1 non couvert,
    - absence d’état sûr sur flux L1,
    - absence de stratégie rollback sur refactor C1/C2.
- **Critères d’acceptation**
  - La checklist peut être utilisée comme gate de PR / démarrage lot.
- **Preuves à indexer**
  - Checklist versionnée (dans un des livrables) + entrée logbook si décision d’architecture.

## Rôles, responsabilités et revue
- **Owner Phase 3** : responsable de la complétude des flux/invariants et de la qualité de la traçabilité.
- **Reviewers** :
  - au minimum 1 revue par pair ;
  - contrôle renforcé (2 reviewers dont 1 indépendant) si invariants classés `C1` / flux `L1` sont touchés (§16).

## Gate de sortie (Phase 3)
La phase ne se clôture que si :
- les flux minimaux sont documentés avec transitions/invariants/états sûrs/observabilité/tests/rollback ;
- la traçabilité “exigence → invariant → vérification” est présente et exploitable ;
- la matrice de vérification rend les scénarios de non-régression **actionnables** (Phase 4+).

## Check-list “fin de phase” (à cocher avant clôture)
- [ ] Flux minimaux modélisés (préconditions → transitions → erreurs → état sûr → observabilité → rollback)
- [ ] Matrice invariants + classification C/L (au moins pour invariants critiques)
- [ ] `docs/traceability/requirements_traceability.md` publié et revu
- [ ] `docs/traceability/verification_matrix.md` publié et revu
- [ ] Scénarios de non-régression critiques listés et reliés aux invariants
- [ ] Entrées ajoutées dans `docs/quality/validation_evidence_index.md` (preuves Phase 3)
- [ ] Traçabilité lot / décisions ajoutées dans `docs/traceability/change_logbook.md`


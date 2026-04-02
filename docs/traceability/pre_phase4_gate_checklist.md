# Gate “pré-Phase 4” — Checklist de démarrage refactor (Phase 3 / Jalon M6)

- **Document ID** : `TRACE-PH3-GATE-P4-001`
- **Version** : `v1`
- **Statut** : `draft`
- **Références** : `docs/rules_nasa.md` §6 (traçabilité), §8–§9 (risques/L1), §15 (tests), §25 (preuves), §27 (quality gates) ; `docs/roadmap/phase_3_inventaire_flux_critiques_invariants.md` (Jalon M6).

## Objet

Cette checklist définit le **gate de démarrage** des lots Phase 4+ (refactor) : **aucun lot C1/C2 (et a fortiori L1) ne démarre** sans :

- traçabilité `PH3-REQ → PH3-FLOW → PH3-INV → PH3-TST`,
- vérifications prévues (tests) + preuves attendues,
- observabilité minimale (signaux de rupture),
- stratégie de rollback/containment plausible,
- ou **dérogation formelle** (réf. `docs/rules_nasa.md` §26).

## Périmètre d’application

Appliquer ce gate à tout PR/lot Phase 4+ qui :

- touche des composants **L1** (auth/session, parental, secrets/PII, storage sensible, startup), ou
- modifie un comportement classé **C1/C2**.

## Mapping aux règles `docs/rules_nasa.md` (références)

| Section du gate | Règle(s) |
|---|---|
| Objet + périmètre | §3 (C/L), §27 (quality gates) |
| Checklist A (Traçabilité) | §6 |
| Checklist B (Vérifications) | §15 |
| Checklist C (Négatifs fail-closed L1/C1) | §8–§9, §15 |
| Checklist D (Observabilité + preuves) | §14, §25 |
| Checklist E (Risques + rollback/containment) | §8, §27 |
| Critères STOP | §8, §27 |
| Preuves attendues + indexation | §25 |
| Exigences de revue | §16, §27 |

## Sources de vérité (Phase 3)

- **Invariants + C/L + observabilité** : `docs/traceability/invariant_matrix.md`
- **Matrice invariants → tests → preuves** : `docs/traceability/verification_matrix.md`
- **Traçabilité exigences** : `docs/traceability/requirements_traceability.md`
- **Risques / hazards Phase 1 (L1)** :
  - `docs/risk/hazard_analysis.md`
  - `docs/risk/failure_modes.md`
  - (optionnel) `docs/risk/system_risk_register.md`

## Checklist “pré-Phase 4” (GO / NO-GO)

### A) Traçabilité minimale (règle §6) — **NO-GO si KO**

- [ ] Tous les invariants **C1/C2** impactés par le lot apparaissent dans `invariant_matrix.md` (pas d’invariant implicite).
- [ ] Pour chaque invariant C1/C2 impacté, une chaîne existe dans `requirements_traceability.md` :
  - `PH3-REQ-*` → `PH3-FLOW-*` → `PH3-INV-*` → `PH3-TST-*`
- [ ] Aucun invariant C1/C2 impacté n’est “non testable” sans dérogation (§26).

### B) Vérifications (tests) prévues (règle §15) — **NO-GO si KO**

- [ ] Pour chaque invariant C1/C2 impacté, au moins 1 scénario `PH3-TST-*` est défini avec :
  - type (`unit` / `widget` / `integration` / `E2E`)
  - preuve attendue (voir §Preuves)
- [ ] Les tests prévus sont **déterministes** et isolables (principe §15.1) : pas de dépendance réseau non contrôlée, pas d’horloge réelle sans contrôle, pas de flakiness acceptée.

### C) Scénarios négatifs obligatoires (L1/C1) — **NO-GO si KO**

Le lot doit couvrir explicitement (si invariants concernés) des scénarios **fail-closed** :

- [ ] **Auth/session** : `PH3-TST-003`, `PH3-TST-004`, `PH3-TST-007`
- [ ] **Parental** : `PH3-TST-015`, `PH3-TST-016`

### D) Observabilité minimale (règle §14 + §25) — **NO-GO si KO**

- [ ] Pour chaque invariant C1/C2 impacté, le **signal de rupture** et l’**observabilité minimale** sont définis (réf. `invariant_matrix.md`).
- [ ] Les logs/artefacts de preuve sont **corrélables** (IDs ou champs stables) et exploitables.
- [ ] Les preuves attendues sont **sans secrets/PII** (réf. invariants de redaction).

### E) Risques + containment + rollback (règle §8 + gate §27) — **NO-GO si KO**

- [ ] Pour chaque invariant **C1** impacté : risques/hazards associés référencés (Phase 1) et stratégie de mitigation/containment décrite.
- [ ] Le lot décrit un **rollback plausible** :
  - `feature flag` / `kill switch` / procédure / version N-1
  - critères d’activation du rollback (quels signaux déclenchent l’arrêt)
- [ ] Les **états sûrs** attendus (safe states) restent valides en échec partiel (fail-closed si L1).

## Critères d’arrêt (STOP) — blocants

Arrêter le lot / refuser le démarrage si l’un des points suivants est vrai :

- **STOP-01** : un invariant **C1** impacté n’a pas de `PH3-TST-*` défini.
- **STOP-02** : un flux **L1** impacté n’a pas d’**état sûr** documenté (ou l’état sûr dépend d’un comportement implicite/non observé).
- **STOP-03** : un refactor **C1/C2** impactant ne possède pas de stratégie de rollback/containment plausible.
- **STOP-04** : la preuve attendue n’est pas reproductible/archivable, ou risque de contenir secrets/PII.

## Preuves attendues (règle §25) — format minimal

Pour tout invariant couvert par un `PH3-TST-*` exécuté en CI :

- **Log CI** : commande (`flutter test`/`flutter analyze`/integration), nom de test/scénario, résultat.
- **Artefacts** (si applicable) : snapshots/goldens/rapports déposés en artefacts CI.
- **Redaction** : pour invariants “no secrets/PII”, inclure un rapport de scan (patterns) ou une preuve de sanitizer.

Indexation attendue :

- Référencer les preuves dans `docs/quality/validation_evidence_index.md` (au moment de l’exécution Phase 4+).
- Ajouter une entrée `docs/traceability/change_logbook.md` si le gate change (décision d’architecture / règle de merge).

## Snippet PR (Phase 4+) — prêt à copier-coller

```markdown
### Gate pré-Phase 4 (TRACE-PH3-GATE-P4-001)

- [ ] Changement classé C? / composant classé L? (réf. `docs/rules_nasa.md` §3)
- [ ] Chaîne `PH3-REQ → PH3-FLOW → PH3-INV → PH3-TST` pour tous invariants C1/C2 impactés
- [ ] `verification_matrix.md` couvre les invariants impactés (type + preuve attendue)
- [ ] Scénarios négatifs L1/C1 couverts si applicable (`PH3-TST-003/004/007`, `PH3-TST-015/016`)
- [ ] Observabilité minimale + signaux de rupture confirmés (`invariant_matrix.md`)
- [ ] Rollback/containment défini (flag/kill switch/procédure) + stop criteria
- [ ] Preuves attendues sans secrets/PII (redaction OK)
```

## Exigences de revue (règle §16 / §27)

- **Par défaut** : 1 reviewer minimum.
- **Renforcée** : 2 reviewers minimum (dont 1 indépendant) si le lot impacte des invariants **L1** et/ou **C1**.


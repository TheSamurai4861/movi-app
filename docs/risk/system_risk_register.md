# Registre des risques système — initial Phase 1 (transmission depuis Phase 0)

**Lot de provenance** : `PH0-LOT-012`  
**Source** : verdict Phase 0 (étape 10.2) + inventaire violations d’architecture (étape 8.2)  
**Date initiale** : `2026-04-02`  

---

## 1) Objet

Ce document constitue la **version initiale** du registre de risques système attendu en **Phase 1** (`docs/risk/system_risk_register.md`, plan v3).  
Il agrège :
- les **risques résiduels** identifiés lors du verdict de sortie Phase 0 ;
- les **violations d’architecture bloquantes** détectées en Phase 0 (à traiter pour empêcher toute réintroduction en Phase 1/Phase 2).

Le contenu ci-dessous doit être **enrichi** en Phase 1 (hazard analysis, threat model, mapping risques → mitigations → détectabilité → rollback).

---

## 2) Risques résiduels transmis (issus du verdict 10.2)

### Résumé des gaps de preuve (NASA-like)

| ID risque | Type | Description (résiduel Phase 0) | Impact attendu | C/L (indicatif) | Source |
|---|---|---|---|---|---|
| `SYS-RISK-001` | Quality gate / tests | Tests baseline non-verts (3 échecs) | Régression possible sur flux critiques (player selection, sync sous-titres) | `C2/L2` (indicatif) | `18_verdict_sortie_phase_0_10_2.md` + `08_baseline_tests_automatises.md` |
| `SYS-RISK-002` | Observabilité / runbook | Runbooks opérationnels absents pour l’exploitation/détection/diagnostic | Diagnostic et recovery non exploitables en incident | `C3/L3` | `15_flux_critiques_couverture_9_1.md` + `validation_evidence_index.md` |
| `SYS-RISK-003` | Corrélation & métriques | Corrélation opérationnelle “exploitables” et métriques minimales non démontrées | Détection tardive / diagnostic incomplet | `C3/L3` | `15_flux_critiques_couverture_9_1.md` |
| `SYS-RISK-004` | Release/rollback discipline | Stratégie rollback opérationnelle versionnée non démontrée | Retour arrière incertain en cas d’échec | `C3/L3` | `validation_evidence_index.md` (PH0-BL-GAP-014) |
| `SYS-RISK-005` | CI/CD preuves | Pipeline minimal & exécution reproductible non démontrés en CI versionné | Difficulté à garantir l’évolution et la rejouabilité | `C2/L2` | `10_inventaire_ci_cd_pipelines.md` + `validation_evidence_index.md` |

---

## 3) Violations d’architecture à traiter (transmission depuis inventaire 8.2)

Référence principale :
- `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/14_inventaire_violations_architecture_8_2.md`

### Cartographie par familles de violations (V1–V4)

| ID risque | Famille violation | Description | Criticité attendue | L présumé (indicatif) | Source |
|---|---|---|---|---|---|
| `SYS-ARCH-001` | V1/V2 `* -> data` | Violation séparation responsabilités (`presentation -> data`, `domain -> data`) | `C2` (conservatrice) | `L2` | `14_inventaire_violations_architecture_8_2.md` |
| `SYS-ARCH-002` | V3 `locator in UI` | Accès direct au locator dans pages/widgets UI | `C2` | `L2/L3` | `14_inventaire_violations_architecture_8_2.md` |
| `SYS-ARCH-003` | V4 `SDK externes in presentation` | Import explicite de SDK externe dans la couche présentation | `C2/C3` | `L1/L2/L3` | `14_inventaire_violations_architecture_8_2.md` |

### Niveaux d’actions attendus en Phase 1/Phase 2

- Phase 1 : qualification (risques résiduels) + préparation “contrôles anti-réintroduction” (scripts/lints/validation).
- Phase 2 : automatiser les règles “imports interdits” et produire le rapport “violations restantes” (plan v3, Phase 2).

---

## 4) Mitigation initiale (à compléter en Phase 1)

| ID risque | Mitigation initiale (indicative) | Résultat attendu |
|---|---|---|
| `SYS-RISK-001` | Corriger les 3 tests non-verts et archiver une nouvelle campagne baseline | Gate §27 tests satisfaites |
| `SYS-RISK-002` | Produire `docs/operations/runbooks/*` et lier runbooks aux flux critiques | Diagnostic/recovery documentés et versionnés |
| `SYS-RISK-003` | Définir modèle corrélation + instrumenter métriques minimales (ou justifier) | Observabilité minimale exploitable |
| `SYS-RISK-004` | Produire `rollback_strategy` / runbook et tester rehearsal | Rollback défini et exploitable |
| `SYS-RISK-005` | Définir pipeline minimal “preuves” en CI et archiver logs/artefacts | Rejouabilité et traçabilité |
| `SYS-ARCH-001..003` | Appliquer règles d’architecture automatiques et produire rapport violations restantes | Empêcher toute aggravation / réintroduction |

---

## 5) Chaîne de preuves (liens)

- Verdict de sortie Phase 0 : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md`
- Index preuves : `docs/quality/validation_evidence_index.md`
- Inventaire violations d’architecture : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/14_inventaire_violations_architecture_8_2.md`


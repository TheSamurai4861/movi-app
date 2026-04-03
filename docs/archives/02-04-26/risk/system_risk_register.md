# Registre des risques système — initial Phase 1 (transmission depuis Phase 0)

**Lot de provenance** : `PH0-LOT-012`  
**Source** : verdict Phase 0 (étape 10.2) + inventaire violations d’architecture (étape 8.2)  
**Date initiale** : `2026-04-02`  

---

## 0) Schéma du registre (obligatoire — NASA-like)

Règle : **toute entrée** du registre doit être exploitable en audit, c’est-à-dire inclure a minima :

- **Criticité** : `C1..C4` + **classe** `L1..L4` (ou justification si indéterminée).
- **Owner** : responsable nommé (persona/role).
- **Stratégies** : **mitigation**, **containment**, **rollback** (ou kill switch/équivalent), **détectabilité**.
- **Statut** : `à_qualifier` / `ouvert` / `mitigé` / `accepté_par_dérogation` / `clos`.
- **Traçabilité** : lien vers logbook (`docs/traceability/change_logbook.md`) et/ou preuve (`docs/quality/validation_evidence_index.md`) lorsque disponible.

Format recommandé : table “registre opérationnel” ci-dessous, puis sections de détail si nécessaire.

---

## 1) Objet

Ce document constitue la **version initiale** du registre de risques système attendu en **Phase 1** (`docs/risk/system_risk_register.md`, plan v3).  
Il agrège :
- les **risques résiduels** identifiés lors du verdict de sortie Phase 0 ;
- les **violations d’architecture bloquantes** détectées en Phase 0 (à traiter pour empêcher toute réintroduction en Phase 1/Phase 2).

Le contenu ci-dessous doit être **enrichi** en Phase 1 (hazard analysis, threat model, mapping risques → mitigations → détectabilité → rollback).

---

## 2) Registre opérationnel (Phase 1 — M1)

### 2.1 Couverture explicite par domaine (périmètre Phase 1)

| Domaine | Classe présumée | Risques couverts (IDs) | Statut de couverture |
|---|---|---|---|
| Startup / bootstrap | `L1` | `SYS-P1-STARTUP-001` | initial (conservateur) |
| Auth / session | `L1` | `SYS-P1-AUTH-001` | initial (conservateur) |
| Network | `L2` (et `L1` pour tokens) | `SYS-P1-NET-001` | initial (conservateur) |
| Storage | `L1` | `SYS-P1-STO-001` | initial (conservateur) |
| Player / playback | `L2` | `SYS-P1-PLY-001` | initial (conservateur) |
| IPTV | `L2` | `SYS-P1-IPTV-001` | initial (conservateur) |
| Parental / profils | `L1` | `SYS-P1-PAR-001` | initial (conservateur) |

### 2.2 Table — risques Phase 1 (normalisés)

| ID | Domaine | Type | Description | Impact maximal | C | L | Détectabilité (min.) | Mitigation (min.) | Containment (min.) | Rollback / Kill switch | Owner | Statut | Source / liens |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `SYS-RISK-001` | Qualité / flux critiques | Quality gate / tests | Tests baseline non-verts (transmis Phase 0) | Régression possible sur flux critiques (player selection, sync sous-titres) | `C2` | `L2` | CI `flutter test` + artefacts de campagne | Corriger échecs + ajouter non-régression ciblée | Geler merges C2+ tant que non vert | Revenir à dernier état “tests verts” + revert PR | Release manager / QA | `mitigé` (Phase 0 R1) | `docs/quality/validation_evidence_index.md` (PH0-BL-Q-502) |
| `SYS-RISK-002` | Opérations | Observabilité / runbook | Runbooks absents (transmis Phase 0) | Diagnostic et recovery non exploitables en incident | `C3` | `L3` | Sentry + logs corrélables + runbooks | Produire runbooks + index | Désactiver actions risquées si non opérables | Procédures rollback existantes | Ops owner | `mitigé` (Phase 0 R2/R3) | `docs/operations/runbooks/*` + index preuves |
| `SYS-RISK-003` | Opérations | Corrélation & métriques | Corrélation “exploitables” et métriques minimales non démontrées (Phase 0) | Détection tardive / diagnostic incomplet | `C3` | `L3` | `operationId` + métriques minimum | Instrumenter corrélation + métriques | Dégrader fonctionnalités non observables | N/A (opérationnel) | Ops owner | `mitigé` (Phase 0 R2) | `docs/operations/observability/*` |
| `SYS-RISK-004` | Release | Rollback discipline | Rollback versionné non démontré (Phase 0) | Retour arrière incertain | `C3` | `L3` | Runbooks rollback + rehearsal | Versionner stratégie + runbooks | Stop rollout / hotfix | Runbooks par plateforme | Release manager | `mitigé` (Phase 0 R3) | `docs/operations/rollback/*` |
| `SYS-RISK-005` | CI/CD | Preuves CI | Pipeline minimal non démontré en CI (Phase 0) | Évolution non rejouable / non traçable | `C2` | `L2` | Workflow CI + logs `ci_proofs/*` | Versionner pipeline + exécuter par PR | Bloquer merge si pipeline rouge | Revenir au pipeline validé (re-baseline) | Release manager | `mitigé` (Phase 0 R4) | `codemagic.yaml` + index preuves |
| `SYS-ARCH-001` | Architecture | V1/V2 `* -> data` | Violations de séparation responsabilités | Aggravation architecture / régressions systémiques | `C2` | `L2` | Rapport violations + CI guard | Règles import interdites + lint | Bloquer nouveaux imports interdits | Revert changement fautif | Architect / Tech lead | `ouvert` | `14_inventaire_violations_architecture_8_2.md` |
| `SYS-ARCH-002` | Architecture | V3 `locator in UI` | Locator accessible depuis UI | Couplage + effets de bord / testabilité | `C2` | `L2` | Rapport violations + CI guard | Interdire locator en UI | Bloquer réintroduction | Revert | Architect / Tech lead | `ouvert` | `14_inventaire_violations_architecture_8_2.md` |
| `SYS-ARCH-003` | Architecture | V4 `SDK externes in presentation` | SDK externes importés en présentation | Surface sécurité + couplage | `C2` | `L2` | Rapport violations + CI guard | Isoler SDK derrière adapters | Bloquer nouveaux imports | Revert | Architect / Tech lead | `ouvert` | `14_inventaire_violations_architecture_8_2.md` |
| `SYS-P1-STARTUP-001` | Startup | Robustesse / sécurité | Échec bootstrap non maîtrisé (crash, boucle, état incohérent) | Crash au démarrage / indisponibilité majeure | `C1` | `L1` | Crash rate + logs bootstrap + Sentry | States explicites + timeouts + “fail safe screen” | Bloquer entrée dans features tant que préconditions non vraies | Flag “safe_mode_startup” (à définir M6) + rollback app | Core owner | `à_qualifier` | `docs/risk/component_criticality.md` (Startup L1) |
| `SYS-P1-AUTH-001` | Auth | Sécurité / contrôle d’accès | Contournement ou incohérence session (fail-open) | Accès non autorisé / fuite données | `C1` | `L1` | Logs auth (sans secrets) + événements “gate decision” | Fail-closed sur état indéterminé + invalidation session | Désactiver parcours premium/risqués en cas d’incertitude | Flag “auth_gate_strict” (à définir M6) + rollback | Security owner | `à_qualifier` | `docs/risk/component_criticality.md` (Auth L1) |
| `SYS-P1-NET-001` | Network | Intégration / fiabilité | Réseau instable/non géré (timeouts, retries, offline) sur flux critiques | Blocage utilisateur / comportements implicites | `C2` | `L2` | Taux d’échec, latence, timeouts | Timeouts + retry contrôlé + messages actionnables | Dégrader features dépendantes réseau | Flag par feature (à définir M6) | Core owner | `à_qualifier` | `docs/rules_nasa.md` §11, §21 |
| `SYS-P1-STO-001` | Storage | Données / confidentialité | Données sensibles stockées/loggées en clair ou corruption prefs | Fuite secrets/PII / perte intégrité | `C1` | `L1` | Audits secrets + logs sanitizés + tests | Secure storage + redaction logs + validations | Désactiver persistance sensible si doute | Flag “disable_sensitive_persistence” (à définir M6) | Data owner | `à_qualifier` | `docs/risk/component_criticality.md` (Storage L1) |
| `SYS-P1-PLY-001` | Player | Fiabilité | Crash/échec lecture sur sélection source / tracks / sous-titres | Indisponibilité fonction centrale | `C2` | `L2` | Error rate playback + logs “playback result” | Fallback de source/variant + gestion erreurs déterministe | Désactiver options avancées en mode dégradé | Flag “disable_advanced_tracks” (à définir M6) | Feature owner | `à_qualifier` | Runbooks RBK-104/105 |
| `SYS-P1-IPTV-001` | IPTV | Intégration | Entrées IPTV invalides (playlist, endpoints) provoquent erreurs non contenues | Blocage ingestion/lecture | `C2` | `L2` | Taux d’échec ingestion + logs | Validation stricte + timeouts + limites | Désactiver ingestion auto / fallback catalogue | Flag “iptv_ingestion_off” (à définir M6) | Feature owner | `à_qualifier` | `docs/risk/component_criticality.md` (IPTV L2) |
| `SYS-P1-PAR-001` | Parental | Safety / contrôle contenu | Bypass contrôle parental (fail-open) | Exposition contenu restreint | `C1` | `L1` | Logs “parental decision” + tests négatifs | Fail-closed + invariants de restriction | Désactiver lecture si classification inconnue | Flag “parental_strict_mode” (à définir M6) | Safety owner | `à_qualifier` | `docs/risk/component_criticality.md` (Parental L1) |

### 2.2.1 Kill switches / feature flags (liste) — lien M6

| Flag | Risques couverts | Condition d’activation | Effet attendu (containment) | Observabilité minimale | Runbook / rollback |
|---|---|---|---|---|---|
| `safe_mode_startup` | `SYS-P1-STARTUP-001` | bootstrap instable / crash loop | bascule en écran safe mode, désactive features risquées | log “safe_mode_startup=true” + event | rollback release (RBK) |
| `auth_gate_strict` | `SYS-P1-AUTH-001` | auth/session indéterminée | fail-closed ; blocage actions sensibles | log “auth_gate_strict decision” | rollback config/release |
| `disable_sensitive_persistence` | `SYS-P1-STO-001` | doute sur stockage sensible | désactive persistance sensible | log “sensitive_persistence=off” | rollback release |
| `disable_advanced_tracks` | `SYS-P1-PLY-001` | crash player / erreurs tracks | désactive options avancées tracks/subtitles | log “advanced_tracks=off” | rollback release |
| `iptv_ingestion_off` | `SYS-P1-IPTV-001` | ingestion instable / endpoints down | désactive ingestion IPTV | log “iptv_ingestion=off” | rollback release |
| `parental_strict_mode` | `SYS-P1-PAR-001` | classification inconnue | deny-by-default | log “parental_strict_mode decision” | rollback config/release |

### 2.3 Exigences C1 (gate Phase 1) — checklist de complétude

Règle de sortie Phase 1 : **aucun risque C1 connu** ne doit rester non visible, non classé, ni sans stratégie de **mitigation + containment + rollback + détectabilité**.

| ID | C/L | Statut | Preuve mitigation/containment/rollback/détectabilité | Dépendance M6 (kill switch/flag) |
|---|---|---|---|---|
| `SYS-P1-STARTUP-001` | `C1/L1` | `à_qualifier` | À compléter via `docs/risk/failure_modes.md` + `docs/risk/hazard_analysis.md` | `safe_mode_startup` |
| `SYS-P1-AUTH-001` | `C1/L1` | `à_qualifier` | À compléter via `docs/security/threat_model.md` + `docs/risk/hazard_analysis.md` | `auth_gate_strict` |
| `SYS-P1-STO-001` | `C1/L1` | `à_qualifier` | À compléter via `docs/security/secret_inventory.md` + `docs/risk/failure_modes.md` | `disable_sensitive_persistence` |
| `SYS-P1-PAR-001` | `C1/L1` | `à_qualifier` | À compléter via `docs/risk/hazard_analysis.md` + tests négatifs | `parental_strict_mode` |

---

## 3) Risques résiduels transmis (issus du verdict 10.2) — détail historique

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


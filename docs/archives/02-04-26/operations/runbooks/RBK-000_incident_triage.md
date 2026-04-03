# Runbook — Incident triage (commun)

**Runbook ID** : `RBK-000`  
**Statut** : `draft` (R2)  
**Références** : `docs/rules_nasa.md` §14 (observabilité), §23 (doc d’exploitation), §25 (preuves) ; `docs/quality/validation_evidence_index.md` (`PH0-BL-GAP-015..017`).

---

## 1) Objectif

Standardiser la démarche **détection → diagnostic → mitigation** pour les incidents affectant Movi, de manière reproductible et auditable.

---

## 2) Signaux (minimum) à consulter

- **Crash / erreurs non-fatales** : Sentry (release, env, stacktraces) — voir `docs/operations/observability/sentry_setup.md`.
- **Logs applicatifs** : console + fichiers (si `FileLogger` activé) — format et corrélation : `docs/operations/observability/logging_schema.md`.
- **Latences / timings** : événements `performance`/diagnostic (si présents) — voir `docs/operations/observability/metrics_minimum.md`.

---

## 3) Étapes de triage (checklist)

1. **Classifier l’impact**
   - utilisateurs touchés (estimation),
   - blocage total vs dégradé,
   - régression depuis une release/tag donnée.
2. **Identifier la release & l’environnement**
   - `env` (`dev/staging/prod`),
   - `release` (version app + build number),
   - plateforme (Android/Windows/iOS).
3. **Récupérer une corrélation**
   - identifier un `operationId` (ou `opId`) dans les logs,
   - regrouper tous les événements liés à cet ID.
4. **Rechercher des patterns**
   - erreurs répétées par catégorie (`network`, `auth`, `player`, `storage`…),
   - spikes (taux d’échec / crash).
5. **Mitigation**
   - activer mode dégradé si disponible,
   - désactiver feature à risque si un kill-switch existe,
   - rollback selon procédure (R3).
6. **Escalade**
   - fournir : `operationId`, release, env, stacktrace, reproduction.

---

## 4) Données interdites (confidentialité)

Conformément à `docs/rules_nasa.md` §13 :
- ne jamais copier/coller tokens, cookies, secrets,
- ne pas exposer PII (email, identifiants bruts, etc.).

---

## 5) Artefacts attendus (preuve)

- extrait logs **sanitisés** (incluant `operationId`) ;
- lien Sentry (ou export anonymisé) avec tags release/env ;
- référence au runbook flux (RBK-101..108).


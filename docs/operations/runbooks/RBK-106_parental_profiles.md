# Runbook — Profils et restrictions parentales

**Runbook ID** : `RBK-106`  
**Flux** : Profils et restrictions parentales  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Profils et restrictions parentales”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Contenu restreint visible alors qu’il devrait être bloqué.
- Contenu légitime bloqué (faux positif).
- PIN/contrôle parental non appliqué.

## Signaux attendus (observabilité)

- `operationId` pour une tentative d’accès contenu restreint.
- Logs `parental` indiquant la décision (bloqué/autorisé) + raison localisée **sans PII**.
- Sentry pour exceptions liées au gating.

## Diagnostic (checklist)

1. Filtrer par `operationId`.
2. Vérifier la “reason” de restriction (ex. rating, catégorie, règle).
3. Vérifier le profil actif (identifiant anonymisé, pas de PII).

## Mitigation

- Forcer une ré-auth PIN (si implémentée).
- Basculer profil et reproduire.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


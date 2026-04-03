# Runbook — Restauration de session / état persistant

**Runbook ID** : `RBK-102`  
**Flux** : Restauration de session / état persistant  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Restauration de session / état persistant”).  
**Statut** : `draft` (R2)

---

## Symptômes

- L’app “oublie” une source active / un profil.
- Préférences perdues (sous-titres, langue, qualité).
- Boucle de chargement / état incohérent après relance.

## Signaux attendus (observabilité)

- `operationId` pour la séquence de restauration.
- Logs `state`/`prefs` avec clés **non sensibles** (jamais de secrets).
- Événements “fallback” visibles (ex : valeur par défaut appliquée).

## Diagnostic (checklist)

1. Rechercher erreurs storage (sqflite/secure storage) via Sentry/logs.
2. Filtrer logs par `operationId` et isoler la phase “read prefs”.
3. Vérifier si un fallback s’est déclenché (et pourquoi).

## Mitigation

- Clear cache / reset prefs (si option UI/diagnostic existe).
- En cas de corruption locale, fournir procédure de reset + relance.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


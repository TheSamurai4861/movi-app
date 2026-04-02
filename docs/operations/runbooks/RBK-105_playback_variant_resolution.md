# Runbook — Résolution des variantes (movie/tv) / playback selection

**Runbook ID** : `RBK-105`  
**Flux** : Résolution movie/tv (variants/playback selection)  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Résolution movie/tv (variants/playback selection)”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Mauvaise langue audio/sous-titres choisie malgré préférences.
- Mauvaise qualité choisie.
- Sélection “pinned” non appliquée.

## Signaux attendus (observabilité)

- `operationId` pour la résolution.
- Logs `selection` avec :
  - `preferences` (langue/qualité) **sans PII**,
  - `reason` de la décision,
  - `variants=<n>`.

## Diagnostic (checklist)

1. Filtrer logs sur `operationId`.
2. Vérifier préférences lues (codes langue, rank qualité).
3. Vérifier la raison (`reason`) et la variante finale.

## Mitigation

- Effacer la variante mémorisée (si fonctionnalité existante) et retenter.
- Changer temporairement préférences pour confirmer l’effet.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


# Runbook — Synchronisation locale / cloud (library)

**Runbook ID** : `RBK-107`  
**Flux** : Synchronisation locale / cloud  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Synchronisation locale / cloud”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Playlist/bibliothèque non synchronisée entre appareils.
- Sync bloquée / boucle infinie.
- Erreurs réseau durant sync.

## Signaux attendus (observabilité)

- `operationId` pour une tentative de sync.
- Logs `sync` avec `result`, `errorCategory`, et compteurs (ex : items upsertés) **sans données sensibles**.
- Sentry : erreurs Supabase/HTTP.

## Diagnostic (checklist)

1. Filtrer logs par `operationId`.
2. Vérifier la phase : fetch remote → diff → upsert local → push remote.
3. Identifier si un fallback “non-blocking” est actif (ex : remote error ignorée).

## Mitigation

- Retry manuel.
- Dégrader : continuer en local si remote indisponible (si supporté).

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


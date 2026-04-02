# Runbook — Sélection et lecture d’une source vidéo

**Runbook ID** : `RBK-104`  
**Flux** : Sélection et lecture d’une source vidéo  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Sélection et lecture d’une source vidéo”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Bouton “Watch” n’ouvre rien / ne lance pas le player.
- Player s’ouvre mais la source est vide/incorrecte.
- Erreur “not available” alors que des variantes existent.

## Signaux attendus (observabilité)

- `operationId` pour l’action “play”.
- Logs `player` / `movie_play_action` (ou équivalent) avec `result` et nombre de variantes.
- Erreurs dans le player (`media_kit`) ou dans la résolution de source.

## Diagnostic (checklist)

1. Filtrer par `operationId` et vérifier :
   - décision de sélection (auto vs manual vs unavailable),
   - variante choisie (id non sensible),
   - navigation vers route `/player`.
2. Vérifier erreurs Sentry pour stacktraces côté UI/navigation/player.

## Mitigation

- Si ambiguïté variantes : forcer sélection manuelle (si UI disponible).
- Si source indisponible : vérifier disponibilité IPTV/source active.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


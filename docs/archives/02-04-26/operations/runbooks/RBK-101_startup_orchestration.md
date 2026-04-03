# Runbook — Démarrage applicatif / orchestration

**Runbook ID** : `RBK-101`  
**Flux** : Démarrage applicatif / orchestration  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Démarrage applicatif / orchestration”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Écran noir / app bloquée au lancement.
- Navigation vers Home non atteinte.
- Crash immédiat au démarrage.

## Signaux attendus (observabilité)

- `operationId` unique pour la séquence de démarrage.
- Logs `startup` / `orchestration` avec `result=success|fail`.
- Erreurs stacktraces en cas d’exception.

## Diagnostic (checklist)

1. Vérifier release/env (Sentry + logs).
2. Filtrer logs par `operationId`.
3. Identifier le dernier “step” réussi (ex : init config, init storage, init profile, load catalog).
4. Vérifier dépendances externes impliquées (réseau, Supabase si utilisé à ce stade).

## Mitigation

- Redémarrage (si transient) puis comparaison `operationId`.
- Basculer en mode local/offline si supporté (si feature existe).
- Escalader avec : `operationId`, release, env, “step” bloquant.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


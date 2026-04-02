# Runbook — Authentification / déconnexion (et gating premium)

**Runbook ID** : `RBK-103`  
**Flux** : Authentification / déconnexion (et gating)  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Authentification / déconnexion (et gating)”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Utilisateur bloqué sur écran welcome/login.
- Déconnexion intempestive.
- Premium non reconnu / gating incohérent.

## Signaux attendus (observabilité)

- `operationId` pour “login”, “logout”, “refresh session”.
- Logs `auth` et `subscription` avec `result=success|fail` (sans tokens).
- Erreurs réseau/SDK (Supabase) visibles côté Sentry/logs.

## Diagnostic (checklist)

1. Vérifier erreurs Sentry (Supabase/auth).
2. Filtrer logs par `operationId` et identifier l’étape (credentials, session restore, fetch profile, gating).
3. Vérifier le statut réseau et timeouts.

## Mitigation

- Forcer un logout complet puis relogin.
- Si gating premium : relancer la récupération/validation (si une action existe) ; sinon escalader.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).


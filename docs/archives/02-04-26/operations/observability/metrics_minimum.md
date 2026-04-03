# Observabilité — métriques minimum & alerting (R2)

**Document** : `OPS-OBS-MET-001`  
**Statut** : `draft` (R2)  
**Références** : `docs/rules_nasa.md` §14.1 (minimum requis), §25 (preuves).

---

## 1) Objectif

Définir un **socle minimal** de métriques de santé exploitables pour Movi, aligné sur `docs/rules_nasa.md` §14.1.

Ce document décrit :
- quelles métriques suivre,
- comment les obtenir avec l’existant (logs/diagnostics) + Sentry,
- un alerting minimal (seuils à ajuster).

---

## 2) Métriques minimales (NASA §14.1)

### 2.1 Taux de crash

- **Source** : Sentry (crash-free sessions / crash rate).
- **Tags requis** : `release`, `environment`, `platform`.
- **Signal** : augmentation du crash rate après une release.

### 2.2 Taux d’échec des opérations critiques

- **Source** : logs corrélables (voir `docs/operations/observability/logging_schema.md`).
- **Modèle** : chaque flux critique émet des événements avec `feature`, `action`, `result`.
- **Métrique** :
  - `failure_rate(feature,action) = count(result=fail) / count(all results)`

### 2.3 Latence des opérations clés

- **Source** : événements de performance (ex : `PerformanceDiagnosticLogger`) + logs (`durationMs`).
- **Métrique** :
  - p50/p95 de `durationMs` par `feature/action`

### 2.4 Disponibilité des dépendances externes

- **Dépendances typiques** : Supabase, réseaux IPTV, HTTP (Dio).
- **Source** : événements d’erreurs catégorisées (`errorCategory=network|sdk`) + Sentry.
- **Métrique** : taux d’erreurs réseau / timeouts par minute.

### 2.5 Volume d’erreurs par catégorie

- **Source** : Sentry (non-fatals) + logs `errorCategory`.
- **Métrique** : erreurs par minute, top catégories.

---

## 3) Alerting minimal (proposition)

> Ces seuils sont **indicatifs** : ils doivent être ajustés selon le trafic réel.

- **Crash rate** : alerte si crash rate > baseline + X% après une release.
- **Auth** : alerte si `feature=auth action=login result=fail` dépasse un seuil.
- **Playback** : alerte si `feature=player action=play result=fail` dépasse un seuil.
- **Sync** : alerte si `feature=sync action=cloudSync result=fail` dépasse un seuil.
- **Dépendances** : alerte si timeouts réseau en hausse sur 5 min glissantes.

---

## 4) Preuves attendues (R2)

- Existence du schéma de logs corrélables (`logging_schema.md`) + preuve `operationId`.
- Preuve Sentry (voir `docs/operations/observability/sentry_setup.md`) montrant capture non-fatale + tags `release/env`.


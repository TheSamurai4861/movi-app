# Modes d’échec (Failure Modes) — Phase 1

## Statut et conformité
- **Lot** : `PH1-LOT-004`
- **Référentiel** : `docs/rules_nasa.md` (§11, §14, §21, §25, §27)
- **But** : décrire, par domaine Phase 1, comment le système échoue, comment on le détecte, et quel état sûr/rollback/containment s’applique.

## Conventions
- **Détectabilité minimale** : logs structurés + Sentry (si activé) + métriques minimum (cf. `docs/operations/observability/metrics_minimum.md`).
- **État sûr** : comportement attendu lorsque la dépendance ou le module est partiellement indisponible (fail-safe / fail-closed selon le domaine).
- **Liens risques** : chaque section référence les IDs du registre `docs/risk/system_risk_register.md`.

## 1) Startup / bootstrap (L1)
**Risques liés** : `SYS-P1-STARTUP-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Crash au démarrage | config invalide, exception non catchée | app ne démarre pas | indisponibilité majeure (`C1`) | crash rate + Sentry | validations fail-fast + guards | écran “safe mode” au lieu de navigation | `safe_mode_startup` (M6) + rollback release | app démarre en mode dégradé, sans features risquées |
| Boucle de bootstrap | retry infini, état incohérent | chargement infini | blocage utilisateur | logs startup + watchdog | timeouts + compteur retry | couper l’étape fautive | `safe_mode_startup` (M6) | écran erreur actionnable |

## 2) Auth / session (L1)
**Risques liés** : `SYS-P1-AUTH-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Fail-open auth | état session indéterminé traité comme OK | accès non autorisé | sécurité/confidentialité (`C1`) | logs “gate decision” (sans secrets) | fail-closed si doute | désactiver parcours premium/risqués | `auth_gate_strict` (M6) | utilisateur non-auth par défaut |
| Session invalide | token expiré / null | redirections erratiques | blocage | logs auth + métriques erreurs | invalidation + re-login | limiter retries | rollback config | écran login clair |

## 3) Network (L2/L1 tokens)
**Risques liés** : `SYS-P1-NET-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Timeout API | réseau lent/instable | opérations bloquées | dégradation majeure (`C2`) | taux timeout + latence | timeouts + retry contrôlé | désactiver features dépendantes | flags par feature (M6) | offline UX + actions actionnables |
| Proxy mal configuré | env proxy | requêtes échouent | indispo partielle | logs proxy | validation + option disable proxy | fallback sans proxy | flag (M6) | réseau direct si possible |

## 4) Storage (L1)
**Risques liés** : `SYS-P1-STO-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Donnée sensible en clair | mauvaise persistance | fuite via fichiers/logs | confidentialité (`C1`) | scans + audits + tests | secure storage + redaction | désactiver persistance sensible | `disable_sensitive_persistence` (M6) | feature fonctionne sans persistance sensible |
| Corruption prefs | écriture interrompue | comportement erratique | `C2/C3` | logs + erreurs parsing | validations + reset contrôlé | reset partiel | rollback release | defaults sûrs |

## 5) Player / playback (L2)
**Risques liés** : `SYS-P1-PLY-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Source invalide | URL/variant manquant | lecture impossible | `C2` | error rate playback | fallback de variant | désactiver options avancées | `disable_advanced_tracks` (M6) | message actionnable + retry |
| Crash player | lib/SDK | crash | `C2` | crash rate | guards + try/catch zones critiques | safe mode lecture | rollback release | écran erreur |

## 6) IPTV (L2)
**Risques liés** : `SYS-P1-IPTV-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Playlist invalide | entrée utilisateur | exceptions / blocage | `C2` | logs ingestion | validation stricte | désactiver ingestion auto | `iptv_ingestion_off` (M6) | ignorer entrée + feedback |
| Endpoint down | service IPTV | timeouts | `C2` | latence + erreurs | timeouts + retries | fallback catalogue | flag (M6) | navigation sans IPTV |

## 7) Parental / profils (L1)
**Risques liés** : `SYS-P1-PAR-001`

| Mode d’échec | Déclencheur | Symptômes | Impact | Détectabilité | Mitigation | Containment | Rollback / Kill switch | État sûr |
|---|---|---|---|---|---|---|---|---|
| Fail-open parental | classification inconnue | contenu affiché | safety (`C1`) | logs “parental decision” + tests | fail-closed | bloquer lecture | `parental_strict_mode` (M6) | contenu restreint par défaut |

## Preuves attendues (à indexer)
- Snapshot daté de ce document + entrée `PH1-EVD-XXX` dans `docs/quality/validation_evidence_index.md`.
- Entrée logbook associée : `PH1-LOT-004` dans `docs/traceability/change_logbook.md`.


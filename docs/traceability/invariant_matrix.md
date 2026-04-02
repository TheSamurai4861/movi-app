# Matrice des invariants — Phase 3 (C/L + données + détection)

- **Document ID** : `TRACE-PH3-INV-MTX-001`
- **Version** : `v1`
- **Statut** : `draft`
- **Références** : `docs/rules_nasa.md` §3 (C/L), §6 (traçabilité), §8–§9 (risques/L1), §11 (erreurs), §14 (observabilité), §15 (tests), §25 (preuves), §27 (quality gates) ; `movi_nasa_refactor_plan_v3.md` Phase 3.
- **Source invariants** : `docs/traceability/requirements_traceability.md` (sections `PH3-FLOW-001..009`).

## Objet
Cette matrice classifie chaque invariant `PH3-INV-*` par **criticité de changement** (`C1..C4`) et **classe composant** (`L1..L4`), et explicite :
- le **signal de rupture** (détection),
- le **mode dégradé acceptable** (ou `interdit`),
- l’**état sûr attendu**,
- l’**observabilité minimale** requise,
- le **pointeur de vérification** (`PH3-TST-*`) préparant le Jalon M4.

## Règles de classification (rappel)
- `L1/C1` par défaut si l’invariant touche : startup crash loop, auth/session (fail-open), parental (fail-open), fuite secrets/PII, persistance sensible.
- `C2/L2` si blocage utilisateur majeur sans impact sécurité/safety direct (timeouts, spinner infini, UX), ou intégrité non sensible.
- Toute exception doit être justifiée (tailoring `docs/rules_nasa.md` §7 / dérogations §26 si nécessaire).

## Matrice (Phase 3 — Jalon M3)

| Invariant ID | Flux | Énoncé (assertable) | Composant(s) impacté(s) | Données concernées | L | C | Signal de rupture | Mode dégradé acceptable | État sûr attendu | Observabilité minimale | Vérification prévue |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `PH3-INV-001` | `PH3-FLOW-001` | Pas de crash loop de bootstrap | `core/startup` | none | `L1` | `C1` | crash rate + logs startup + Sentry | `SafeMode` | app démarre en `SafeMode` | logs startup + métrique crash | `PH3-TST-001` |
| `PH3-INV-002` | `PH3-FLOW-001` | Exceptions bootstrap capturées → `SafeMode` | `core/startup` | config | `L1` | `C1` | log `bootstrap_failed` + absence `Ready` | `SafeMode` | écran safe mode/actionnable | logs + event error | `PH3-TST-002` |
| `PH3-INV-003` | `PH3-FLOW-001` | Décision route initiale observable & déterministe | `core/startup` `core/routing` | session state | `L1` | `C2` | log `route_decision` manquant/incohérent | route non-auth + safe mode | navigation limitée et stable | logs décision + corrélation | `TBD` |
| `PH3-INV-004` | `PH3-FLOW-001` | Incertitude sécurité → non-auth (fail-closed) | `core/auth` `core/startup` | session token | `L1` | `C1` | accès zone auth sans validation | `LoggedOut` | utilisateur non-auth par défaut | logs `auth_gate_decision` | `PH3-TST-003` |
| `PH3-INV-005` | `PH3-FLOW-002` | Validation impossible ≠ session OK (fail-open interdit) | `core/auth` `core/session` | session token | `L1` | `C1` | accès zone auth sans `session_validated=true` | non-auth | `LoggedOut` | logs validation session | `PH3-TST-004` |
| `PH3-INV-006` | `PH3-FLOW-002` | Session expirée → invalidation + login (pas de boucle) | `core/auth` | session token | `L1` | `C2` | >N redirects auth / T | clear + login | écran login clair | logs redirects + métrique | `PH3-TST-005` |
| `PH3-INV-007` | `PH3-FLOW-002` | Timeout/offline ne bloque pas la nav (pas de spinner infini) | `core/network` `core/session` | none | `L1` | `C2` | spinner “restore” > T | `SessionUnknown` → non-auth | UI navigable non-auth | logs watchdog + métrique | `TBD` |
| `PH3-INV-008` | `PH3-FLOW-002` | Aucun token/PII loggé en restauration | `core/session` `logging` | session token/PII | `L1` | `C1` | scan logs détecte secrets | redaction + logs minimaux | logs sans secrets | sanitizer + tests redaction | `PH3-TST-006` |
| `PH3-INV-009` | `PH3-FLOW-003` | Auth “OK” seulement avec preuve explicite | `core/auth` | session token | `L1` | `C1` | `isAuthenticated=true` sans `AuthSuccess` | `LoggedOut` | blocage actions sensibles | logs auth result | `PH3-TST-007` |
| `PH3-INV-010` | `PH3-FLOW-003` | Logout invalide tokens localement (et remote si applicable) | `core/auth` `core/storage` | session token | `L1` | `C1` | tokens présents après logout | `LoggedOut` | token absent + non-auth | audit storage + logs | `PH3-TST-008` |
| `PH3-INV-011` | `PH3-FLOW-003` | Erreur auth actionnable sans secret | `core/auth` `logging` | secrets | `L1` | `C1` | logs contiennent tokens/messages sensibles | message générique + code | `LoggedOut` | logs redacted + reason code | `TBD` |
| `PH3-INV-012` | `PH3-FLOW-003` | Retries auth bornés | `core/auth` | none | `L1` | `C2` | >N tentatives auto/min | backoff + stop | `LoggedOut` | métrique retries | `PH3-TST-009` |
| `PH3-INV-013` | `PH3-FLOW-004` | Pas de lecture sans source résolue valide | `player` `core/media` | source URL | `L2` | `C2` | `playback_start` sans `source_resolve_ok` | erreur + retry | `PlaybackError` actionnable | logs resolve/start | `TBD` |
| `PH3-INV-014` | `PH3-FLOW-004` | Erreur playback actionnable | `player` | none | `L2` | `C2` | `PlaybackError` sans UI msg/log | retry/changer source | `PlaybackError` | logs `play_error` + UX | `PH3-TST-011` |
| `PH3-INV-015` | `PH3-FLOW-004` | Pas de buffering infini (timeouts bornés) | `player` `network` | none | `L2` | `C2` | `Buffering` > T | fallback/stop | `PlaybackError` | métrique buffering | `PH3-TST-010` |
| `PH3-INV-016` | `PH3-FLOW-004` | Pas d’URL signée/token en logs | `player` `logging` | tokens/URLs | `L1` | `C1` | scan logs détecte URL signée | redaction | logs sans secrets | sanitizer + scan | `PH3-TST-012` |
| `PH3-INV-017` | `PH3-FLOW-005` | Résolution movie/tv déterministe | `catalog` | none | `L2` | `C2` | mismatch résultats | fallback + retry | `ResolveError` actionnable | logs resolve + test | `PH3-TST-014` |
| `PH3-INV-018` | `PH3-FLOW-005` | 404/timeout → UI navigable + message | `catalog` `network` | none | `L2` | `C2` | écran figé/erreur manquante | cache partiel | `ResolveError` | logs `resolve_error` | `TBD` |
| `PH3-INV-019` | `PH3-FLOW-005` | Pas de spinner infini (timeout + retry contrôlé) | `network` | none | `L2` | `C2` | requête > T | fallback cache | `ResolveError` | métrique timeout | `PH3-TST-013` |
| `PH3-INV-020` | `PH3-FLOW-006` | Policy inconnue → deny (fail-closed) | `core/parental` | contenus restreints | `L1` | `C1` | contenu visible en `PolicyUnknown` | bloquer lecture | `DecisionDeny` | logs `parental_decision` | `PH3-TST-015` |
| `PH3-INV-021` | `PH3-FLOW-006` | Décision parentale observable (reason code) | `core/parental` | none | `L1` | `C2` | pas de log décision | deny | blocage explicite | logs + reason code | `PH3-TST-017` |
| `PH3-INV-022` | `PH3-FLOW-006` | Pas de bypass deep-link/autoplay | `core/parental` `player` | contenus restreints | `L1` | `C1` | playback sans décision | deny | blocage lecture | logs + test négatif | `PH3-TST-016` |
| `PH3-INV-023` | `PH3-FLOW-006` | Pas de PII (profil/âge) dans logs parentaux | `core/parental` `logging` | PII | `L1` | `C1` | logs contiennent PII | redaction | logs minimaux | scan + sanitizer | `TBD` |
| `PH3-INV-024` | `PH3-FLOW-007` | Sync ne bloque pas le runtime | `sync` | prefs | `L2` | `C2` | UI bloquée par sync | sync off/différé | `SyncIdle` | logs phases + métrique | `TBD` |
| `PH3-INV-025` | `PH3-FLOW-007` | Écritures cloud idempotentes / sans doublons | `sync` `network` | prefs/historique | `L2` | `C2` | doublons après retry | backoff + idempotence | sync dégradée | logs retries | `PH3-TST-018` |
| `PH3-INV-026` | `PH3-FLOW-007` | Pas de données sensibles en sync sans protection | `sync` `security` | secrets/PII | `L1` | `C1` | payload contient secrets/PII | sync off | sync désactivée | scan payload + logs | `TBD` |
| `PH3-INV-027` | `PH3-FLOW-007` | Résolution conflit explicite & observable | `sync` | prefs | `L2` | `C2` | divergence sans log | règle explicite | sync déterministe | log `conflict_resolution` | `PH3-TST-019` |
| `PH3-INV-028` | `PH3-FLOW-008` | Settings invalides → reset defaults sûrs | `settings` `storage` | prefs | `L2` | `C2` | exception parse | reset contrôlé | `SettingsDefault` | log reset + métrique | `PH3-TST-020` |
| `PH3-INV-029` | `PH3-FLOW-008` | Options sécurité/safety = fail-safe/closed | `settings` | sécurité | `L1` | `C1` | comportement dangereux sans config | désactiver option | defaults sûrs | logs décision | `TBD` |
| `PH3-INV-030` | `PH3-FLOW-008` | Changement settings observable sans PII | `settings` `logging` | none | `L2` | `C2` | changement non loggé | logging on minimal | audit trail | logs `settings_changed` | `PH3-TST-021` |
| `PH3-INV-031` | `PH3-FLOW-009` | Aucun secret/token/PII dans report/log | `reporting` `logging` | secrets/PII | `L1` | `C1` | test redaction/scan échoue | report minimal | pas d’envoi | logs redact + scan | `PH3-TST-022` |
| `PH3-INV-032` | `PH3-FLOW-009` | Reporting ne bloque pas flux critiques | `reporting` | none | `L2` | `C2` | UI bloquée | queue/offline | navigation ok | métrique submit | `PH3-TST-023` |
| `PH3-INV-033` | `PH3-FLOW-009` | reportId + operationId si présent | `reporting` | none | `L2` | `C2` | report sans IDs | report sans corrélation (interdit si possible) | report traçable | logs submit | `PH3-TST-024` |
| `PH3-INV-034` | `PH3-FLOW-009` | Erreurs submit actionnables | `reporting` | none | `L2` | `C2` | submit KO sans feedback | queue + retry | `Queued`/`SubmitFailed` explicite | logs + UX | `TBD` |


# Threat Model — Phase 1 (menaces sécurité / données)

## Statut et conformité
- **Lot** : `PH1-LOT-002` (sécurité/données) + liens vers `PH1-LOT-001` (risques)
- **Référentiel** : `docs/rules_nasa.md` (§8, §12, §13, §25, §27)
- **But** : formaliser les menaces majeures, la surface exposée, les contrôles, et la détectabilité.

## Surface exposée (périmètre Phase 1)
- **Config / secrets** : `.env`, `--dart-define`, CI, variables d’environnement.
- **Réseau** : Supabase, TMDB, IPTV endpoints (utilisateur), proxy.
- **Stockage** : préférences, cache, historique (à qualifier), secure storage.
- **Logs/traces** : logs structurés, Sentry (si activé).

## Menaces clés (conservateur)

| Threat ID | Catégorie | Menace | Impact | Contrôles attendus | Détectabilité | Risque lié |
|---|---|---|---|---|---|---|
| `THR-SEC-001` | Secrets | Secret/token versionné (repo) | compromission / abus API | retirer du repo, rotation, secret store CI | scan repo + revue | `SYS-P1-STO-001` + inventaire secrets |
| `THR-AUTH-001` | AuthZ | Fail-open auth/premium/parental | accès non autorisé / safety | fail-closed, invariants, tests négatifs | logs “gate decision” | `SYS-P1-AUTH-001`, `SYS-P1-PAR-001` |
| `THR-DATA-001` | Données | PII dans logs/Sentry | fuite confidentialité | redaction + `sendDefaultPii=false` | audit logs + config Sentry | `SYS-P1-STO-001` |
| `THR-NET-001` | Réseau | MITM via proxy / endpoints non fiables | interception / altération | TLS, validation stricte, timeouts | erreurs réseau corrélées | `SYS-P1-NET-001` |

## Exigences de détectabilité (minimum)
- Aucun log ne doit exposer : token, mot de passe, secret, PII en clair.
- Les décisions critiques doivent être observables : auth gate, parental gate, safe mode startup.

## Preuves attendues (à indexer)
- Snapshot daté de ce document + entrée `PH1-EVD-XXX` dans `docs/quality/validation_evidence_index.md`.
- Entrée logbook associée : `PH1-LOT-002` (sécurité/données) dans `docs/traceability/change_logbook.md`.


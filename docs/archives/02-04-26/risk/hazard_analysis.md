# Hazard Analysis — Phase 1 (sûreté / sécurité / données)

## Statut et conformité
- **Lot** : `PH1-LOT-005`
- **Référentiel** : `docs/rules_nasa.md` (§8, §9, §11, §12, §13, §25, §27)
- **But** : identifier les dangers redoutés, conditions d’activation, barrières, et **états sûrs** attendus (incluant échec partiel).

## Conventions
- **Danger** : dommage sécurité/safety/confidentialité/intégrité/indisponibilité majeure.
- **Barrière** : contrôle logique, opérationnel ou architectural réduisant probabilité/impact.
- **État sûr** : état du système si le danger ne peut pas être exclu (souvent **fail-closed** pour L1).
- **Liens** : relier aux risques `docs/risk/system_risk_register.md` et aux modes d’échec `docs/risk/failure_modes.md`.

## Tableau des hazards (conservateur — Phase 1)

| Hazard ID | Domaine | Danger redouté | Conditions d’activation | Barrières minimales | État sûr attendu | Détectabilité minimale | Risque lié |
|---|---|---|---|---|---|---|---|
| `HZD-STARTUP-001` | Startup | Indisponibilité majeure (crash loop) | exception non gérée + retry infini | guards + timeouts + safe mode | écran safe mode + blocage features risquées | crash rate + logs startup + Sentry | `SYS-P1-STARTUP-001` |
| `HZD-AUTH-001` | Auth | Accès non autorisé (fail-open) | session indéterminée traitée comme OK | validation session + fail-closed + invalidation | utilisateur non-auth par défaut + blocage actions sensibles | logs “gate decision” | `SYS-P1-AUTH-001` |
| `HZD-STO-001` | Storage | Fuite secrets/PII (en clair) | persistance non sécurisée + logs non redacted | secure storage + redaction logs | désactiver persistance sensible | scans + tests + logs sanitizer | `SYS-P1-STO-001` |
| `HZD-PAR-001` | Parental | Exposition contenu restreint | classification inconnue/erreur -> autorisation | invariants “deny by default” | bloquer lecture / masquer contenu | logs décision + tests négatifs | `SYS-P1-PAR-001` |
| `HZD-NET-001` | Network | Comportement implicite non observé (timeouts) | appels sans timeout/retry | timeouts + retry contrôlé | dégradation UX offline | métriques latence/timeout | `SYS-P1-NET-001` |

## États sûrs attendus (règles)

### L1 (startup/auth/storage/parental)
- **Fail-closed par défaut** lorsque l’état de sécurité/safety ne peut pas être établi.
- **Aucun échec silencieux** sur un chemin critique.
- **Décision observable** : logs/événements doivent indiquer *pourquoi* l’accès est bloqué (sans exposer de secrets).

### L2 (network/player/IPTV)
- **Dégradation contrôlée** : fallback explicite (désactivation feature, messages actionnables), plutôt que comportement implicite.

## Preuves attendues (à indexer)
- Snapshot daté de ce document + entrée `PH1-EVD-XXX` dans `docs/quality/validation_evidence_index.md`.
- Entrée logbook associée : `PH1-LOT-005` dans `docs/traceability/change_logbook.md`.


# Matrice de vérification — Phase 3 (invariants → tests → preuves)

- **Document ID** : `TRACE-PH3-VERIF-001`
- **Version** : `v1`
- **Statut** : `draft`
- **Références** : `docs/rules_nasa.md` §6, §15, §25, §27 ; `movi_nasa_refactor_plan_v3.md` Phase 3.

## Objet
Ce document liera, pour la Phase 3, les **invariants** (`PH3-INV-*`) aux **vérifications** (`PH3-TST-*`) et aux **preuves attendues** (logs CI / artefacts), conformément à la traçabilité minimale (réf. §6) et aux quality gates (réf. §27).

## Conventions & IDs
Les conventions d’identifiants et le gabarit de “fiche flux” sont définis dans :
- `docs/traceability/requirements_traceability.md` (section “Conventions & IDs (Phase 3 — Jalon M1)”).

## Tableau (à remplir en Jalon M4)

| Invariant ID | Flux | Criticité (C) | Classe (L) | Vérification (PH3-TST) | Type | Preuve attendue | Statut |
|---|---|---|---|---|---|---|---|
| `PH3-INV-001` | `PH3-FLOW-001` | `C1` | `L1` | `PH3-TST-001` | `integration` | Log CI `flutter test` + preuve “pas de crash loop” (harness) | `draft` |
| `PH3-INV-002` | `PH3-FLOW-001` | `C1` | `L1` | `PH3-TST-002` | `integration` | Log CI `flutter test` : config invalide → `SafeMode` | `draft` |
| `PH3-INV-003` | `PH3-FLOW-001` | `C2` | `L1` | `PH3-TST-025` | `integration` | Log CI : route_decision émise + stable (même entrée → même sortie) | `draft` |
| `PH3-INV-004` | `PH3-FLOW-001` | `C1` | `L1` | `PH3-TST-003` | `integration` | Log CI : session inconnue/KO → non-auth (fail-closed) | `draft` |
| `PH3-INV-005` | `PH3-FLOW-002` | `C1` | `L1` | `PH3-TST-004` | `integration` | Log CI : validation impossible → non-auth (fail-closed) | `draft` |
| `PH3-INV-006` | `PH3-FLOW-002` | `C2` | `L1` | `PH3-TST-005` | `integration` | Log CI : token expiré → clear + login (pas de boucle) | `draft` |
| `PH3-INV-007` | `PH3-FLOW-002` | `C2` | `L1` | `PH3-TST-026` | `integration` | Log CI : timeout/offline → UI navigable (pas de spinner infini) | `draft` |
| `PH3-INV-008` | `PH3-FLOW-002` | `C1` | `L1` | `PH3-TST-006` | `integration` | Log CI : suite redaction logs (aucun token/PII) | `draft` |
| `PH3-INV-009` | `PH3-FLOW-003` | `C1` | `L1` | `PH3-TST-007` | `integration` | Log CI : état auth indéterminé → `LoggedOut` (fail-closed) | `draft` |
| `PH3-INV-010` | `PH3-FLOW-003` | `C1` | `L1` | `PH3-TST-008` | `integration` | Log CI : logout supprime tokens (audit storage) | `draft` |
| `PH3-INV-011` | `PH3-FLOW-003` | `C1` | `L1` | `PH3-TST-027` | `unit` | Log CI : erreurs auth redacted + reason code stable (pas de secrets) | `draft` |
| `PH3-INV-012` | `PH3-FLOW-003` | `C2` | `L1` | `PH3-TST-009` | `unit` | Log CI : policy retry max N (pas de brute force involontaire) | `draft` |
| `PH3-INV-013` | `PH3-FLOW-004` | `C2` | `L2` | `PH3-TST-028` | `integration` | Log CI : pas de `playback_start` sans `source_resolve_ok` | `draft` |
| `PH3-INV-014` | `PH3-FLOW-004` | `C2` | `L2` | `PH3-TST-011` | `integration` | Log CI : erreur source → message actionnable + retry | `draft` |
| `PH3-INV-015` | `PH3-FLOW-004` | `C2` | `L2` | `PH3-TST-010` | `integration` | Log CI : timeout → `PlaybackError` (pas de buffering infini) | `draft` |
| `PH3-INV-016` | `PH3-FLOW-004` | `C1` | `L1` | `PH3-TST-012` | `unit` | Log CI : redaction logs (pas d’URL signée/token) | `draft` |
| `PH3-INV-017` | `PH3-FLOW-005` | `C2` | `L2` | `PH3-TST-014` | `unit` | Log CI : mapping type stable pour un ID | `draft` |
| `PH3-INV-018` | `PH3-FLOW-005` | `C2` | `L2` | `PH3-TST-029` | `integration` | Log CI : 404/timeout → UI navigable + message actionnable | `draft` |
| `PH3-INV-019` | `PH3-FLOW-005` | `C2` | `L2` | `PH3-TST-013` | `integration` | Log CI : timeout → erreur actionnable (pas de spinner infini) | `draft` |
| `PH3-INV-020` | `PH3-FLOW-006` | `C1` | `L1` | `PH3-TST-015` | `integration` | Log CI : policy inconnue → deny (fail-closed) | `draft` |
| `PH3-INV-021` | `PH3-FLOW-006` | `C2` | `L1` | `PH3-TST-017` | `unit` | Log CI : reason codes parentaux stables + log décision | `draft` |
| `PH3-INV-022` | `PH3-FLOW-006` | `C1` | `L1` | `PH3-TST-016` | `integration` | Log CI : deep-link/autoplay ne bypass pas contrôle parental | `draft` |
| `PH3-INV-023` | `PH3-FLOW-006` | `C1` | `L1` | `PH3-TST-030` | `unit` | Log CI : redaction logs parentaux (pas de PII) + scan patterns | `draft` |
| `PH3-INV-024` | `PH3-FLOW-007` | `C2` | `L2` | `PH3-TST-031` | `integration` | Log CI : sync ne bloque pas UI (local-first) | `draft` |
| `PH3-INV-025` | `PH3-FLOW-007` | `C2` | `L2` | `PH3-TST-018` | `integration` | Log CI : retry n’entraîne pas de doublons (idempotence) | `draft` |
| `PH3-INV-026` | `PH3-FLOW-007` | `C1` | `L1` | `PH3-TST-032` | `unit` | Log CI : validation payload sync (pas de secrets/PII) | `draft` |
| `PH3-INV-027` | `PH3-FLOW-007` | `C2` | `L2` | `PH3-TST-019` | `unit` | Log CI : résolution conflit déterministe | `draft` |
| `PH3-INV-028` | `PH3-FLOW-008` | `C2` | `L2` | `PH3-TST-020` | `unit` | Log CI : prefs corrompues → defaults sûrs | `draft` |
| `PH3-INV-029` | `PH3-FLOW-008` | `C1` | `L1` | `PH3-TST-033` | `unit` | Log CI : settings sécurité fail-safe (comportement dangereux interdit) | `draft` |
| `PH3-INV-030` | `PH3-FLOW-008` | `C2` | `L2` | `PH3-TST-021` | `integration` | Log CI : audit log sur changement settings (sans PII) | `draft` |
| `PH3-INV-031` | `PH3-FLOW-009` | `C1` | `L1` | `PH3-TST-022` | `unit` | Log CI : redaction report (pas de token/PII) + corpus patterns | `draft` |
| `PH3-INV-032` | `PH3-FLOW-009` | `C2` | `L2` | `PH3-TST-023` | `integration` | Log CI : submit KO n’empêche pas navigation (reporting optionnel) | `draft` |
| `PH3-INV-033` | `PH3-FLOW-009` | `C2` | `L2` | `PH3-TST-024` | `integration` | Log CI : reportId + operationId présents | `draft` |
| `PH3-INV-034` | `PH3-FLOW-009` | `C2` | `L2` | `PH3-TST-034` | `integration` | Log CI : submit KO → feedback actionnable + queue (si offline) | `draft` |

## Scénarios négatifs obligatoires (L1/C1) — rappel
- **Auth/session (fail-closed)** : `PH3-TST-003`, `PH3-TST-004`, `PH3-TST-007` (l’état inconnu ne doit jamais devenir “OK”).
- **Parental (fail-closed)** : `PH3-TST-015`, `PH3-TST-016`.
- **Aucun secret / PII en preuves** : `PH3-TST-006`, `PH3-TST-012`, `PH3-TST-022`, `PH3-TST-030`, `PH3-TST-032`.


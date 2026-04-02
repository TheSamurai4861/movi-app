# Traçabilité des exigences — Phase 3 (flux critiques & invariants)

- **Document ID** : `TRACE-PH3-REQ-001`
- **Version** : `v1`
- **Statut** : `draft`
- **Références** : `docs/rules_nasa.md` §6 (traçabilité), §15 (tests), §25 (preuves), §27 (quality gates) ; `movi_nasa_refactor_plan_v3.md` Phase 3.

## Objet
Ce document formalise la **traçabilité** de la Phase 3 : *exigences ↔ flux ↔ invariants ↔ vérifications*.

Objectif principal : **aucun lot critique (Phase 4+) ne démarre** sans invariants formalisés et scénarios de non-régression associés.

## Matrice des invariants (source de vérité C/L)
La classification **C/L**, les données concernées, la détectabilité et les modes dégradés sont consolidés dans :
- `docs/traceability/invariant_matrix.md`

## Catalogue des exigences — Phase 3 (Jalon M5)

Ces exigences sont formulées pour être **assertables** et traçables vers des invariants et des scénarios `PH3-TST-*`.

| PH3-REQ | Titre | Description (assertable) | C/L (cible) | Rationale | Hazards / risques Phase 1 |
|---|---|---|---|---|---|
| `PH3-REQ-001` | Startup sans crash loop | Au démarrage, l’application ne doit jamais entrer en crash loop; en cas d’échec bootstrap, elle doit atteindre un état sûr actionnable. | `C1/L1` | Disponibilité + sûreté L1 | `HZD-STARTUP-001` ; `SYS-P1-STARTUP-001` |
| `PH3-REQ-002` | Auth fail-closed | Si l’état d’auth/session ne peut pas être établi, le système doit **refuser** l’accès (non-auth) et rendre la décision observable. | `C1/L1` | Empêcher fail-open | `HZD-AUTH-001` ; `SYS-P1-AUTH-001` |
| `PH3-REQ-003` | Session restore déterministe | La restauration de session ne doit pas bloquer indéfiniment et doit être déterministe (pas de boucles/redirections). | `C2/L1` | Robustesse session | `SYS-P1-AUTH-001` |
| `PH3-REQ-004` | Parental fail-closed | Si policy/classification est inconnue ou indisponible, la décision doit être deny-by-default et observable. | `C1/L1` | Safety contenu restreint | `HZD-PAR-001` ; `SYS-P1-PAR-001` |
| `PH3-REQ-005` | Zéro secret/PII dans preuves | Aucun secret/token/PII ne doit apparaître dans logs, rapports, ou preuves CI liées aux flux critiques. | `C1/L1` | Confidentialité & audit | `HZD-STO-001` ; `SYS-P1-STO-001` |
| `PH3-REQ-006` | Playback contrôlé | La lecture vidéo doit gérer timeouts/erreurs de façon actionnable sans bloquer l’app (pas de buffering infini). | `C2/L2` | UX + disponibilité | `SYS-P1-PLY-001` |
| `PH3-REQ-007` | Résolution movie/tv robuste | La résolution movie/tv doit être déterministe; les erreurs doivent être actionnables et non bloquantes. | `C2/L2` | Navigation stable | `SYS-P1-NET-001` |
| `PH3-REQ-008` | Sync non bloquante | La synchronisation cloud ne doit pas bloquer le runtime; les conflits sont résolus de façon explicite et observable. | `C2/L2` | Intégrité + dispo | `SYS-P1-NET-001` |
| `PH3-REQ-009` | Settings sûrs | Des settings invalides ne doivent pas crasher; les options sécurité/safety doivent être fail-safe/fail-closed et auditables. | `C1/L1` | Defaults sûrs | `HZD-NET-001` |
| `PH3-REQ-010` | Reporting optionnel & redacted | Le reporting doit être optionnel, non bloquant, et toujours redacted (zéro secret/PII), avec IDs corrélables. | `C1/L1` | Diagnostic sans fuite | `HZD-STO-001` |

## Table de traçabilité — Phase 3 (Jalon M5) — source de vérité

| PH3-REQ | PH3-FLOW | PH3-INV | PH3-TST | Preuve attendue (résumé) | Docs Phase 1 (liens) | Statut |
|---|---|---|---|---|---|---|
| `PH3-REQ-001` | `PH3-FLOW-001` | `PH3-INV-001` | `PH3-TST-001` | `flutter test` + preuve “pas de crash loop” | `docs/risk/hazard_analysis.md` (`HZD-STARTUP-001`) ; `docs/risk/failure_modes.md` (Startup) | `draft` |
| `PH3-REQ-001` | `PH3-FLOW-001` | `PH3-INV-002` | `PH3-TST-002` | config invalide → `SafeMode` | `docs/risk/failure_modes.md` (Startup) | `draft` |
| `PH3-REQ-001` | `PH3-FLOW-001` | `PH3-INV-003` | `PH3-TST-025` | route_decision stable (log CI) | `docs/risk/hazard_analysis.md` (`HZD-STARTUP-001`) | `draft` |
| `PH3-REQ-002` | `PH3-FLOW-001` | `PH3-INV-004` | `PH3-TST-003` | session inconnue → non-auth (fail-closed) | `docs/risk/hazard_analysis.md` (`HZD-AUTH-001`) ; `docs/risk/failure_modes.md` (Auth/session) | `draft` |
| `PH3-REQ-002` | `PH3-FLOW-002` | `PH3-INV-005` | `PH3-TST-004` | validation impossible → non-auth | `docs/risk/failure_modes.md` (Auth/session) | `draft` |
| `PH3-REQ-003` | `PH3-FLOW-002` | `PH3-INV-006` | `PH3-TST-005` | token expiré → clear + login (pas de boucle) | `docs/risk/failure_modes.md` (Auth/session) | `draft` |
| `PH3-REQ-003` | `PH3-FLOW-002` | `PH3-INV-007` | `PH3-TST-026` | offline/timeout → pas de spinner infini | `docs/risk/failure_modes.md` (Network/Auth) | `draft` |
| `PH3-REQ-005` | `PH3-FLOW-002` | `PH3-INV-008` | `PH3-TST-006` | suite redaction logs session (CI) | `docs/risk/hazard_analysis.md` (`HZD-STO-001`) | `draft` |
| `PH3-REQ-002` | `PH3-FLOW-003` | `PH3-INV-009` | `PH3-TST-007` | auth indéterminée → `LoggedOut` | `docs/risk/hazard_analysis.md` (`HZD-AUTH-001`) | `draft` |
| `PH3-REQ-005` | `PH3-FLOW-003` | `PH3-INV-010` | `PH3-TST-008` | logout supprime tokens (audit) | `docs/risk/hazard_analysis.md` (`HZD-AUTH-001`) | `draft` |
| `PH3-REQ-005` | `PH3-FLOW-003` | `PH3-INV-011` | `PH3-TST-027` | erreurs auth redacted (unit) | `docs/risk/hazard_analysis.md` (`HZD-AUTH-001`) | `draft` |
| `PH3-REQ-003` | `PH3-FLOW-003` | `PH3-INV-012` | `PH3-TST-009` | retry max N (unit) | `docs/risk/failure_modes.md` (Auth/session) | `draft` |
| `PH3-REQ-006` | `PH3-FLOW-004` | `PH3-INV-013` | `PH3-TST-028` | pas de playback sans source_resolve_ok | `docs/risk/failure_modes.md` (Player) | `draft` |
| `PH3-REQ-006` | `PH3-FLOW-004` | `PH3-INV-014` | `PH3-TST-011` | erreur playback actionnable | `docs/risk/failure_modes.md` (Player) | `draft` |
| `PH3-REQ-006` | `PH3-FLOW-004` | `PH3-INV-015` | `PH3-TST-010` | pas de buffering infini | `docs/risk/failure_modes.md` (Player/Network) | `draft` |
| `PH3-REQ-005` | `PH3-FLOW-004` | `PH3-INV-016` | `PH3-TST-012` | redaction logs URL/token (unit) | `docs/risk/hazard_analysis.md` (`HZD-STO-001`) | `draft` |
| `PH3-REQ-007` | `PH3-FLOW-005` | `PH3-INV-017` | `PH3-TST-014` | résolution déterministe (unit) | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-007` | `PH3-FLOW-005` | `PH3-INV-018` | `PH3-TST-029` | 404/timeout → UI actionnable | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-007` | `PH3-FLOW-005` | `PH3-INV-019` | `PH3-TST-013` | pas de spinner infini | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-004` | `PH3-FLOW-006` | `PH3-INV-020` | `PH3-TST-015` | policy inconnue → deny | `docs/risk/hazard_analysis.md` (`HZD-PAR-001`) ; `docs/risk/failure_modes.md` (Parental) | `draft` |
| `PH3-REQ-004` | `PH3-FLOW-006` | `PH3-INV-021` | `PH3-TST-017` | reason code stable + log | `docs/risk/failure_modes.md` (Parental) | `draft` |
| `PH3-REQ-004` | `PH3-FLOW-006` | `PH3-INV-022` | `PH3-TST-016` | pas de bypass deep-link/autoplay | `docs/risk/failure_modes.md` (Parental) | `draft` |
| `PH3-REQ-005` | `PH3-FLOW-006` | `PH3-INV-023` | `PH3-TST-030` | redaction logs parentaux (pas PII) | `docs/risk/hazard_analysis.md` (`HZD-STO-001`) | `draft` |
| `PH3-REQ-008` | `PH3-FLOW-007` | `PH3-INV-024` | `PH3-TST-031` | sync non bloquante | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-008` | `PH3-FLOW-007` | `PH3-INV-025` | `PH3-TST-018` | idempotence (no duplicates) | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-005` | `PH3-FLOW-007` | `PH3-INV-026` | `PH3-TST-032` | validation payload (pas secrets/PII) | `docs/risk/hazard_analysis.md` (`HZD-STO-001`) | `draft` |
| `PH3-REQ-008` | `PH3-FLOW-007` | `PH3-INV-027` | `PH3-TST-019` | conflits déterministes | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-009` | `PH3-FLOW-008` | `PH3-INV-028` | `PH3-TST-020` | prefs corrompues → defaults | `docs/risk/hazard_analysis.md` (`HZD-NET-001`) | `draft` |
| `PH3-REQ-009` | `PH3-FLOW-008` | `PH3-INV-029` | `PH3-TST-033` | settings sécurité fail-safe | `docs/risk/hazard_analysis.md` (`HZD-NET-001`) | `draft` |
| `PH3-REQ-009` | `PH3-FLOW-008` | `PH3-INV-030` | `PH3-TST-021` | audit log settings (sans PII) | `docs/risk/hazard_analysis.md` (`HZD-NET-001`) | `draft` |
| `PH3-REQ-010` | `PH3-FLOW-009` | `PH3-INV-031` | `PH3-TST-022` | redaction report (no secrets/PII) | `docs/risk/hazard_analysis.md` (`HZD-STO-001`) | `draft` |
| `PH3-REQ-010` | `PH3-FLOW-009` | `PH3-INV-032` | `PH3-TST-023` | reporting optionnel non bloquant | `docs/risk/failure_modes.md` (Network) | `draft` |
| `PH3-REQ-010` | `PH3-FLOW-009` | `PH3-INV-033` | `PH3-TST-024` | reportId + operationId | `docs/risk/failure_modes.md` (Startup/Observabilité) | `draft` |
| `PH3-REQ-010` | `PH3-FLOW-009` | `PH3-INV-034` | `PH3-TST-034` | feedback actionnable + queue | `docs/risk/failure_modes.md` (Network) | `draft` |

## Revue indépendante (préparation) — Phase 3 (Jalon M5)

- **Statut global** : `draft` (prêt pour revue par pair ; viser contrôle renforcé si L1/C1 modifiés).
- **Points d’attention** :
  - Les scénarios `PH3-TST-*` sont **définis** (preuves attendues) mais pas encore implémentés en tests automatisés (travail Phase 3 M4→Phase 4).
  - Tous les invariants `C1/C2` ont une chaîne `REQ→FLOW→INV→TST`; aucun invariant critique n’est orphelin.
  - Les preuves attendues doivent rester **sans secrets/PII** (réf. `PH3-REQ-005`), et les tests de redaction sont prioritaires.

## Conventions & IDs (Phase 3 — Jalon M1)

### Schéma d’identifiants
- **Flux** : `PH3-FLOW-###`
- **Exigences** : `PH3-REQ-###`
- **Invariants** : `PH3-INV-###`
- **Scénarios de test** : `PH3-TST-###`

### Règles de nommage et d’usage
- Les IDs sont **immutables** une fois publiés (ne pas renuméroter).
- Format : 3 chiffres, zéros à gauche (`001..999`).
- Chaque fiche flux a un **owner** (peut être `TBD` au départ) et un **statut** (`draft|review|approved`).
- **Lien minimal obligatoire** (réf. §6) : pour tout invariant critique, disposer de la chaîne :
  - `PH3-REQ-*` → `PH3-FLOW-*` → `PH3-INV-*` → `PH3-TST-*`.

## Réservation des flux minimaux (Phase 3 — périmètre plan)

| Flow ID | Nom | Owner | Statut |
|---|---|---|---|
| `PH3-FLOW-001` | Démarrage applicatif | `TBD` | `draft` |
| `PH3-FLOW-002` | Restauration de session | `TBD` | `draft` |
| `PH3-FLOW-003` | Authentification / déconnexion | `TBD` | `draft` |
| `PH3-FLOW-004` | Sélection et lecture d’une source vidéo | `TBD` | `draft` |
| `PH3-FLOW-005` | Résolution movie/tv | `TBD` | `draft` |
| `PH3-FLOW-006` | Profils et restrictions parentales | `TBD` | `draft` |
| `PH3-FLOW-007` | Synchronisation locale/cloud | `TBD` | `draft` |
| `PH3-FLOW-008` | Settings impactant le runtime | `TBD` | `draft` |
| `PH3-FLOW-009` | Diagnostics et remontée de problèmes | `TBD` | `draft` |

## Gabarit standard — Fiche “flux critique” (Phase 3 — Jalon M1)

Copier-coller ce gabarit pour chaque `PH3-FLOW-###` (remplissage prévu en Jalon M2).

### Fiche flux — `PH3-FLOW-___` — `<Nom>`

#### 1) Identité
- **Flow ID** : `PH3-FLOW-___`
- **Nom** : `<à compléter>`
- **Owner** : `<à compléter>`
- **Classe** : `L1|L2|L3|L4` (si inconnue : `TBD`)
- **Criticité attendue** : `C1|C2|C3|C4` (si inconnue : `TBD`)
- **Statut** : `draft|review|approved`

#### 2) Préconditions
- `<liste>`

#### 3) États & transitions
- **États** : `<liste stable>`
- **Transitions** : `<table ou diagramme>` (déclencheur → état suivant)

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-___` : `<énoncé>` — **Justification** : `<pourquoi non négociable>` — **Signal de rupture** : `<comment détecter>`

#### 5) Effets de bord
- **Réseau** : `<oui/non + endpoints/dépendances>`
- **Storage** : `<oui/non + données>`
- **Auth/session** : `<oui/non>`
- **Analytics/telemetry** : `<oui/non>`
- **Autres** : `<liste>`

#### 6) Erreurs (nominales et anormales)
Pour chaque erreur : **catégorie** (§11), **symptôme**, **impact**, **action** (retry contrôlé / fallback / blocage), **diagnostic**.
- `<liste>`

#### 7) État sûr & modes dégradés
- **État sûr attendu** : `<à compléter>`
- **Échec partiel** : `<comportement attendu>` (fail-closed si L1/sécurité/données)

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `<événements clés + corrélation>`
- **Métriques** : `<min requis>`
- **Events** : `<si applicable>`

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-___` : `<type unit/widget/integration/E2E>` — **Couvre** : `PH3-INV-___` — **Preuve attendue** : `<artefact/log CI>`

#### 10) Rollback possible
- **Rollback** : `<possible / limité / non>`
- **Mécanisme** : `<kill switch / feature flag / N-1 / procédure>`
- **Contraintes** : `<à compléter>`

## Règle de revue & checklist de cohérence (Phase 3 — Jalon M1)

### Revue minimale (réf. `docs/rules_nasa.md` §16)
- **Par défaut** : 1 reviewer minimum.
- **Renforcée** : 2 reviewers minimum (dont 1 indépendant) si le flux ou ses invariants sont classés **L1** et/ou **C1**.

### Checklist M1 (cohérence)
- [ ] Les 9 flux minimaux ont un `PH3-FLOW-###` réservé.
- [ ] Le schéma `PH3-REQ/FLOW/INV/TST` est documenté et stable.
- [ ] Le gabarit “fiche flux” est unique et complet.
- [ ] Les champs `Owner` et `Statut` existent (même si `TBD` / `draft`).

---

## Fiches flux critiques — Phase 3 (Jalon M2)

> Remplissage du gabarit M1 pour `PH3-FLOW-001..009`. Les invariants et tests listés ci-dessous sont **des exigences de non-régression** (les tests seront planifiés/implémentés en M4+).

### Fiche flux — `PH3-FLOW-001` — Démarrage applicatif (startup / bootstrap)

#### 1) Identité
- **Flow ID** : `PH3-FLOW-001`
- **Nom** : Démarrage applicatif (startup / bootstrap)
- **Owner** : `TBD`
- **Classe** : `L1`
- **Criticité attendue** : `C1`
- **Statut** : `draft`

#### 2) Préconditions
- Binaire installé, environnement runtime valide.
- Accès à la configuration (fichiers/variables) **sans secrets exposés** dans les logs.
- Accès storage (au moins lecture des préférences) — sinon mode dégradé.
- Réseau **non requis** pour atteindre un état sûr (startup doit pouvoir échouer proprement).

#### 3) États & transitions
- **États** : `AppLaunch` → `BootstrapStart` → `ConfigLoad` → `DepsInit` → `SessionProbe` → `RouteDecision` → `Ready` | `SafeMode` | `FatalError`.
- **Transitions** :
  - `AppLaunch` --(process start)--> `BootstrapStart`
  - `BootstrapStart` --(init ok)--> `ConfigLoad`
  - `ConfigLoad` --(config valide)--> `DepsInit`
  - `ConfigLoad` --(config invalide)--> `SafeMode`
  - `DepsInit` --(deps ok)--> `SessionProbe`
  - `DepsInit` --(dep critique KO)--> `SafeMode`
  - `SessionProbe` --(session inconnue/KO)--> `RouteDecision` (fail-closed)
  - `RouteDecision` --(décision)--> `Ready`
  - *Any state* --(exception non gérée)--> `FatalError` (à éviter via guards)

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-001` : Aucun crash loop de bootstrap (>N redémarrages/secondes) — **Justification** : indisponibilité majeure — **Signal de rupture** : crash rate + logs startup + Sentry (`HZD-STARTUP-001`).
- `PH3-INV-002` : Toute exception de bootstrap est **capturée** et mène à `SafeMode` ou erreur actionnable — **Justification** : pas d’échec silencieux sur chemin critique — **Signal de rupture** : logs “bootstrap_failed” (sans secrets) + absence de “Ready”.
- `PH3-INV-003` : La décision de route initiale (login/home/safe mode) est **observée** et déterministe — **Justification** : éviter comportement implicite/non observé — **Signal de rupture** : log “route_decision” manquant/incohérent.
- `PH3-INV-004` : En cas d’incertitude sécurité (session/permissions), startup **fail-closed** (non-auth) — **Justification** : empêcher fail-open — **Signal de rupture** : accès à écran/authz sans preuve de session valide (`HZD-AUTH-001`).

#### 5) Effets de bord
- **Réseau** : optionnel (ping/refresh session éventuel), doit être time-outé.
- **Storage** : lecture prefs, cache minimal, clés de session.
- **Auth/session** : probing état session / token.
- **Analytics/telemetry** : événements startup (sans PII), crash reporting.
- **Autres** : init DI, init SDKs (doit être résilient).

#### 6) Erreurs (nominales et anormales)
- Config invalide (technique) : fallback `SafeMode`, message actionnable, log catégorie “config”.
- Dépendance init KO (intégration) : `SafeMode`, désactivation features risquées, log “dep_init_failed”.
- Boucle de bootstrap (technique) : watchdog → `SafeMode` (réf. `docs/risk/failure_modes.md` §1).
- Storage indispo/erreur parse (données) : reset contrôlé ou démarrage sans prefs.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : `SafeMode` (app démarre, navigation limitée, features à risque désactivées).
- **Échec partiel** : sans réseau / sans SDK externe → démarrer quand même + UX dégradée contrôlée.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `startup_begin`, `config_loaded`, `dep_init`, `session_probe`, `route_decision`, `safe_mode_entered` (corrélation `operationId` si dispo).
- **Métriques** : taux crash startup, temps bootstrap (p50/p95), erreurs config.
- **Events** : Sentry crash/exception bootstrap (sans secrets).

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-001` : integration — **Couvre** : `PH3-INV-001` — **Preuve attendue** : log CI + absence crash loop (test harness).
- `PH3-TST-002` : integration — **Couvre** : `PH3-INV-002` — **Preuve attendue** : scénario “config invalide” → `SafeMode`.
- `PH3-TST-003` : integration — **Couvre** : `PH3-INV-004` — **Preuve attendue** : session inconnue → route non-auth (fail-closed).
- `PH3-TST-025` : integration — **Couvre** : `PH3-INV-003` — **Preuve attendue** : log CI : route_decision émise + stable (mêmes entrées → mêmes sorties).

#### 10) Rollback possible
- **Rollback** : possible (release N-1).
- **Mécanisme** : `safe_mode_startup` / désactivation config risquée (voir Phase 1 M6) + rollback release.
- **Contraintes** : nécessite artefacts release traçables (réf. CI §20/§25).

### Fiche flux — `PH3-FLOW-002` — Restauration de session

#### 1) Identité
- **Flow ID** : `PH3-FLOW-002`
- **Nom** : Restauration de session
- **Owner** : `TBD`
- **Classe** : `L1`
- **Criticité attendue** : `C1`
- **Statut** : `draft`

#### 2) Préconditions
- Stockage local accessible (lecture clés session) OU capacité de démarrer “sans session”.
- Réseau potentiellement indisponible (offline) : la restauration ne doit pas bloquer indéfiniment.
- Politique auth : **fail-closed** si session indéterminée (réf. `docs/risk/failure_modes.md` §2).

#### 3) États & transitions
- **États** : `SessionNone` | `SessionLoad` | `SessionLoaded` | `SessionValidate` | `SessionValid` | `SessionInvalid` | `SessionUnknown` | `SessionCleared`.
- **Transitions** :
  - `SessionNone` --(startup)--> `SessionLoad`
  - `SessionLoad` --(clé absente)--> `SessionNone`
  - `SessionLoad` --(clé lue)--> `SessionLoaded`
  - `SessionLoaded` --(réseau dispo)--> `SessionValidate`
  - `SessionValidate` --(OK)--> `SessionValid`
  - `SessionValidate` --(KO/expired)--> `SessionInvalid`
  - `SessionValidate` --(timeout/indispo)--> `SessionUnknown`
  - `SessionInvalid|SessionUnknown` --(clear)--> `SessionCleared` → `SessionNone`

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-005` : Pas de “session OK” si validation impossible (fail-open interdit) — **Justification** : sécurité/confidentialité — **Signal de rupture** : accès zone auth sans log “session_validated=true” (`HZD-AUTH-001`).
- `PH3-INV-006` : Token/session expiré entraîne invalidation + retour login (sans boucle) — **Justification** : éviter redirections erratiques — **Signal de rupture** : >N redirects auth en <T secondes + logs auth.
- `PH3-INV-007` : Offline/timeout ne bloque pas la navigation : état `SessionUnknown` conduit à non-auth par défaut — **Justification** : disponibilité + sécurité — **Signal de rupture** : spinner infini “restoring session”.
- `PH3-INV-008` : Aucune donnée sensible (token/PII) n’est loggée en restauration — **Justification** : confidentialité (§12/§13) — **Signal de rupture** : scan logs/CI détecte motifs secrets.

#### 5) Effets de bord
- **Réseau** : refresh token / “me” endpoint (timeouts obligatoires).
- **Storage** : lecture/écriture état session, invalidation.
- **Auth/session** : rotation/expiration.
- **Analytics/telemetry** : évènement “session_restore_result” (sans PII).

#### 6) Erreurs (nominales et anormales)
- Token expiré (métier/sécurité) : clear + login, message actionnable.
- Timeout validation (technique) : `SessionUnknown`, non-auth par défaut, proposer retry explicite.
- Storage read error (données) : démarrer sans session, log “session_storage_error”.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : utilisateur **non-auth** par défaut si doute, et accès sensibles bloqués.
- **Échec partiel** : réseau KO → navigation possible en mode non-auth/offline.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `session_restore_begin`, `session_load_result`, `session_validate_result` (sans token), `session_cleared_reason`.
- **Métriques** : taux `SessionInvalid`, taux `SessionUnknown`, latence validation.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-004` : integration — **Couvre** : `PH3-INV-005` — **Preuve attendue** : timeout validation → non-auth (fail-closed).
- `PH3-TST-005` : integration — **Couvre** : `PH3-INV-006` — **Preuve attendue** : token expiré → clear + login (pas de boucle).
- `PH3-TST-006` : integration — **Couvre** : `PH3-INV-008` — **Preuve attendue** : test “log redaction” sur événements session.
- `PH3-TST-026` : integration — **Couvre** : `PH3-INV-007` — **Preuve attendue** : log CI : offline/timeout ne bloque pas la navigation (pas de spinner infini).

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : `auth_gate_strict` (flag) + rollback release.
- **Contraintes** : dépendent de la persistance (migrations de session à gérer).

### Fiche flux — `PH3-FLOW-003` — Authentification / déconnexion

#### 1) Identité
- **Flow ID** : `PH3-FLOW-003`
- **Nom** : Authentification / déconnexion
- **Owner** : `TBD`
- **Classe** : `L1`
- **Criticité attendue** : `C1`
- **Statut** : `draft`

#### 2) Préconditions
- Réseau (si auth distante) avec timeouts + retries contrôlés.
- Stockage sécurisé pour tokens (si persistés).
- Par défaut, aucune action sensible sans état auth **établi**.

#### 3) États & transitions
- **États** : `LoggedOut` | `AuthStart` | `AuthChallenge` | `AuthSuccess` | `AuthFailed` | `LoggedIn` | `LogoutStart` | `LogoutDone`.
- **Transitions** :
  - `LoggedOut` --(login demandé)--> `AuthStart`
  - `AuthStart` --(challenge ok)--> `AuthChallenge`
  - `AuthChallenge` --(succès)--> `AuthSuccess` → `LoggedIn`
  - `AuthChallenge` --(erreur)--> `AuthFailed` → `LoggedOut`
  - `LoggedIn` --(logout demandé)--> `LogoutStart` → `LogoutDone` → `LoggedOut`

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-009` : Auth ne peut jamais être “OK” sans preuve explicite (fail-open interdit) — **Justification** : sécurité — **Signal de rupture** : incohérence `isAuthenticated=true` sans `AuthSuccess` observé (`HZD-AUTH-001`).
- `PH3-INV-010` : Déconnexion invalide la session localement (et remote si applicable) — **Justification** : confidentialité — **Signal de rupture** : tokens encore présents après logout (audit storage).
- `PH3-INV-011` : Erreur auth est actionnable et ne divulgue aucun secret — **Justification** : sécurité + UX — **Signal de rupture** : logs contenant tokens / messages serveur bruts sensibles.
- `PH3-INV-012` : Limiter retries auth (pas de brute force involontaire) — **Justification** : sécurité + stabilité — **Signal de rupture** : >N tentatives auto / minute.

#### 5) Effets de bord
- **Réseau** : endpoints auth, refresh, revoke.
- **Storage** : tokens, flags “loggedIn”, profil courant.
- **Auth/session** : création/rotation, invalidation.
- **Analytics/telemetry** : événements login/logout (sans identifiants sensibles).

#### 6) Erreurs (nominales et anormales)
- Identifiants invalides (métier) : `AuthFailed`, message clair.
- Timeout/auth down (intégration) : `AuthFailed`, proposer retry, backoff.
- Storage secure KO (données/sécurité) : fail-closed, ne pas persister, forcer login à chaque session ou refuser.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : `LoggedOut` par défaut ; blocage actions sensibles.
- **Échec partiel** : réseau KO → rester `LoggedOut`, permettre navigation non-auth.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `auth_begin`, `auth_result`, `logout_begin`, `logout_done`, `auth_gate_decision` (sans secrets).
- **Métriques** : taux échec auth, latence auth, taux logout.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-007` : integration — **Couvre** : `PH3-INV-009` — **Preuve attendue** : session indéterminée → non-auth (fail-closed).
- `PH3-TST-008` : integration — **Couvre** : `PH3-INV-010` — **Preuve attendue** : logout supprime tokens (storage).
- `PH3-TST-009` : unit — **Couvre** : `PH3-INV-012` — **Preuve attendue** : policy retry max N.
- `PH3-TST-027` : unit — **Couvre** : `PH3-INV-011` — **Preuve attendue** : erreurs auth redacted + reason code stable (pas de secrets/PII).

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : `auth_gate_strict` + rollback release.
- **Contraintes** : selon fournisseur auth, revoke remote peut être non-idempotent.

### Fiche flux — `PH3-FLOW-004` — Sélection et lecture d’une source vidéo (playback)

#### 1) Identité
- **Flow ID** : `PH3-FLOW-004`
- **Nom** : Sélection et lecture d’une source vidéo (playback)
- **Owner** : `TBD`
- **Classe** : `L2` (peut devenir `L1` si parental/entitlements en ligne de mire)
- **Criticité attendue** : `C2`
- **Statut** : `draft`

#### 2) Préconditions
- Catalogue/metadata disponibles (cache ou réseau).
- Connectivité réseau optionnelle selon source (offline possible si supporté).
- Player initialisable sans crash ; timeouts réseau configurés.

#### 3) États & transitions
- **États** : `ContentSelected` → `SourceResolve` → `SourceReady` → `PlayerInit` → `Buffering` → `Playing` | `Paused` | `Ended` | `PlaybackError`.
- **Transitions** :
  - `ContentSelected` --(user play)--> `SourceResolve`
  - `SourceResolve` --(source ok)--> `SourceReady`
  - `SourceResolve` --(source KO/timeout)--> `PlaybackError`
  - `SourceReady` --(init player ok)--> `PlayerInit` → `Buffering`
  - `Buffering` --(ready)--> `Playing`
  - `Playing` --(error)--> `PlaybackError`

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-013` : Pas de tentative de lecture sans “source résolue” valide — **Justification** : éviter crash/état incohérent — **Signal de rupture** : log `playback_start` sans `source_resolve_ok`.
- `PH3-INV-014` : Toute erreur playback est actionnable (retry, changer source) — **Justification** : UX + support — **Signal de rupture** : `PlaybackError` sans message utilisateur + sans log diagnostic.
- `PH3-INV-015` : Timeouts/rétries réseau sont bornés (pas de buffering infini) — **Justification** : éviter blocage — **Signal de rupture** : `Buffering` > T secondes sans transition + logs watchdog.
- `PH3-INV-016` : Aucune URL/token sensible n’est loggée en clair — **Justification** : confidentialité — **Signal de rupture** : scan logs/CI détecte URL signées/tokens.

#### 5) Effets de bord
- **Réseau** : résolution source, playlists, DRM/keys si applicable (timeouts obligatoires).
- **Storage** : cache de metadata, dernier contenu, progression (si activée).
- **Auth/session** : vérification éventuelle d’accès premium/entitlement.
- **Analytics/telemetry** : événements `play_attempt`, `play_start`, `play_error` (sans PII).

#### 6) Erreurs (nominales et anormales)
- Source invalide/manquante (métier/intégration) : fallback variante ; sinon `PlaybackError`.
- Crash player SDK (technique) : capturer + `PlaybackError` + mode dégradé (voir Phase 1 failure modes player).
- Réseau lent/timeout (technique) : retry contrôlé + option offline si possible.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : `PlaybackError` avec message actionnable + navigation possible (ne pas bloquer l’app).
- **Échec partiel** : désactiver options avancées (tracks, qualité auto) et proposer une source simple.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `source_resolve_begin/result`, `player_init`, `buffering_start/duration`, `play_start`, `play_error` (codes catégorisés).
- **Métriques** : taux d’échec playback, latence résolution source, durée buffering, crash rate player.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-010` : integration — **Couvre** : `PH3-INV-015` — **Preuve attendue** : scénario timeout → `PlaybackError` (pas de buffering infini).
- `PH3-TST-011` : integration — **Couvre** : `PH3-INV-014` — **Preuve attendue** : erreur source → message + action retry.
- `PH3-TST-012` : unit — **Couvre** : `PH3-INV-016` — **Preuve attendue** : redaction des logs (pas d’URL signée).
- `PH3-TST-028` : integration — **Couvre** : `PH3-INV-013` — **Preuve attendue** : log CI : pas de démarrage playback sans `source_resolve_ok`.

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : `disable_advanced_tracks` (flag) + rollback release.
- **Contraintes** : dépend du SDK player et du format des sources.

### Fiche flux — `PH3-FLOW-005` — Résolution movie/tv (lookup & navigation vers détail)

#### 1) Identité
- **Flow ID** : `PH3-FLOW-005`
- **Nom** : Résolution movie/tv (lookup & navigation vers détail)
- **Owner** : `TBD`
- **Classe** : `L2`
- **Criticité attendue** : `C2`
- **Statut** : `draft`

#### 2) Préconditions
- Identifiant (movie/tv) ou requête disponible.
- Accès API/DB/cache (selon archi) avec timeouts.

#### 3) États & transitions
- **États** : `QueryStart` → `ResolveType` → `FetchDetails` → `DetailsReady` | `ResolveError`.
- **Transitions** :
  - `QueryStart` --(id/search)--> `ResolveType`
  - `ResolveType` --(movie/tv identifié)--> `FetchDetails`
  - `FetchDetails` --(ok)--> `DetailsReady`
  - `FetchDetails` --(timeout/404)--> `ResolveError`

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-017` : La résolution type (movie vs tv) est déterministe pour un ID donné — **Justification** : éviter navigation incohérente — **Signal de rupture** : résultats différents sans changement d’entrée.
- `PH3-INV-018` : En cas de 404/timeout, l’UI reste navigable et affiche un message actionnable — **Justification** : pas de blocage — **Signal de rupture** : écran figé / absence d’erreur utilisateur.
- `PH3-INV-019` : Les appels réseau ont timeout + retry contrôlé (pas de spinner infini) — **Justification** : résilience (§11) — **Signal de rupture** : requête >T sans issue.

#### 5) Effets de bord
- **Réseau** : fetch détails, images, recommendations (si activé).
- **Storage** : cache détails, historique.
- **Analytics** : `details_view`, `resolve_error`.

#### 6) Erreurs (nominales et anormales)
- ID inconnu (métier) : `ResolveError`, proposer recherche.
- Timeout réseau (technique) : fallback cache, sinon erreur.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : `ResolveError` + retour arrière possible + option retry.
- **Échec partiel** : afficher cache partiel, désactiver sections secondaires.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `resolve_type_result`, `fetch_details_result`, `resolve_error_reason`.
- **Métriques** : taux `ResolveError`, latence fetch détails.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-013` : integration — **Couvre** : `PH3-INV-019` — **Preuve attendue** : timeout → erreur actionnable (pas de spinner infini).
- `PH3-TST-014` : unit — **Couvre** : `PH3-INV-017` — **Preuve attendue** : mapping type stable pour un ID.
- `PH3-TST-029` : integration — **Couvre** : `PH3-INV-018` — **Preuve attendue** : log CI : 404/timeout → UI navigable + message actionnable.

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : désactivation feature secondaire + rollback release.
- **Contraintes** : dépend des contrats API/caching.

### Fiche flux — `PH3-FLOW-006` — Profils et restrictions parentales

#### 1) Identité
- **Flow ID** : `PH3-FLOW-006`
- **Nom** : Profils et restrictions parentales (contrôle d’accès contenu)
- **Owner** : `TBD`
- **Classe** : `L1`
- **Criticité attendue** : `C1`
- **Statut** : `draft`

#### 2) Préconditions
- Profil courant sélectionné OU profil par défaut défini.
- Règles parentales disponibles (local ou remote) ; si inconnues, appliquer deny-by-default.
- Toute décision doit être observable sans exposer de PII (réf. `HZD-PAR-001`, `docs/risk/failure_modes.md` §7).

#### 3) États & transitions
- **États** : `ProfileNone` | `ProfileSelect` | `ProfileActive` | `PolicyLoad` | `PolicyKnown` | `PolicyUnknown` | `DecisionAllow` | `DecisionDeny`.
- **Transitions** :
  - `ProfileNone` --(startup/user select)--> `ProfileSelect` → `ProfileActive`
  - `ProfileActive` --(load policy)--> `PolicyLoad`
  - `PolicyLoad` --(ok)--> `PolicyKnown`
  - `PolicyLoad` --(KO/timeout)--> `PolicyUnknown`
  - `PolicyKnown` --(evaluate)--> `DecisionAllow|DecisionDeny`
  - `PolicyUnknown` --(evaluate)--> `DecisionDeny` (fail-closed)

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-020` : Si classification/policy inconnue, décision = **deny** (fail-closed) — **Justification** : safety (`C1`) — **Signal de rupture** : contenu restreint visible alors que `PolicyUnknown` (`HZD-PAR-001`).
- `PH3-INV-021` : Toute décision parentale est observable (allow/deny + reason code) — **Justification** : audit/support — **Signal de rupture** : absence de log `parental_decision` sur tentative lecture.
- `PH3-INV-022` : Aucun contournement “indirect” (deep-link / auto-play) ne bypass la décision — **Justification** : sécurité/safety — **Signal de rupture** : playback démarre sans décision préalable.
- `PH3-INV-023` : Les règles parentales ne loggent jamais d’info sensible (profil, âge exact, etc.) — **Justification** : confidentialité — **Signal de rupture** : logs contenant PII.

#### 5) Effets de bord
- **Réseau** : fetch policy (si remote), vérification classification.
- **Storage** : profil courant, préférences parentales, PIN (si applicable; jamais en clair).
- **Auth/session** : dépend si profils liés à un compte.
- **Analytics** : événements agrégés (ex: `parental_deny_count`) sans identifiants.

#### 6) Erreurs (nominales et anormales)
- Policy indisponible/timeout (technique) : fail-closed + message “contenu indisponible” (ne pas révéler le rating).
- Corruption prefs (données) : reset contrôlé, profil par défaut, deny-by-default.
- Mauvaise classification (intégration) : deny, log reason code.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : contenu restreint **masqué/bloqué** par défaut.
- **Échec partiel** : désactiver lecture et affichage de sections si policy indisponible.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `profile_selected`, `policy_load_result`, `parental_decision` (allow/deny + reason code).
- **Métriques** : taux `PolicyUnknown`, taux `DecisionDeny`, tentatives bypass.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-015` : integration — **Couvre** : `PH3-INV-020` — **Preuve attendue** : policy inconnue → deny (fail-closed).
- `PH3-TST-016` : integration — **Couvre** : `PH3-INV-022` — **Preuve attendue** : deep-link/autoplay ne bypass pas la décision.
- `PH3-TST-017` : unit — **Couvre** : `PH3-INV-021` — **Preuve attendue** : reason codes stables et loggés.
- `PH3-TST-030` : unit — **Couvre** : `PH3-INV-023` — **Preuve attendue** : redaction logs parentaux (pas de PII) + scan patterns.

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : `parental_strict_mode` (flag) + rollback release.
- **Contraintes** : si règles migrées, prévoir compat rétro (sinon reset contrôlé).

### Fiche flux — `PH3-FLOW-007` — Synchronisation locale/cloud

#### 1) Identité
- **Flow ID** : `PH3-FLOW-007`
- **Nom** : Synchronisation locale/cloud (prefs, profil, historique, etc.)
- **Owner** : `TBD`
- **Classe** : `L2` (peut toucher `L1` si données sensibles)
- **Criticité attendue** : `C2`
- **Statut** : `draft`

#### 2) Préconditions
- Identité utilisateur connue (sinon sync désactivée).
- Réseau disponible OU stratégie offline (queue/retry contrôlé).
- Conflits possibles (multi-device) définis (last-write-wins vs merge).

#### 3) États & transitions
- **États** : `SyncDisabled` | `SyncIdle` | `SyncPlan` | `SyncUpload` | `SyncDownload` | `SyncMerge` | `SyncDone` | `SyncError`.
- **Transitions** :
  - `SyncIdle` --(trigger)--> `SyncPlan`
  - `SyncPlan` --(need upload)--> `SyncUpload`
  - `SyncPlan` --(need download)--> `SyncDownload`
  - `SyncUpload|SyncDownload` --(ok)--> `SyncMerge` → `SyncDone`
  - `SyncUpload|SyncDownload` --(timeout/KO)--> `SyncError` → `SyncIdle` (retry borné)

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-024` : Sync ne doit pas bloquer le runtime (UI utilisable) — **Justification** : dispo — **Signal de rupture** : opérations UI dépendantes bloquées par sync.
- `PH3-INV-025` : Toute écriture cloud est idempotente ou protégée contre doublons — **Justification** : intégrité données — **Signal de rupture** : doublons répétés après retry.
- `PH3-INV-026` : Données sensibles ne sortent jamais sans protection (transit + minimisation) — **Justification** : confidentialité — **Signal de rupture** : payload contient secrets/PII inutile.
- `PH3-INV-027` : Conflit est résolu selon une règle explicite et observable — **Justification** : déterminisme — **Signal de rupture** : divergence sans log “conflict_resolution”.

#### 5) Effets de bord
- **Réseau** : upload/download, latence, erreurs.
- **Storage** : journaling local, marquage “dirty”, cache.
- **Auth/session** : tokens nécessaires pour sync.
- **Analytics** : métriques sync (sans payload).

#### 6) Erreurs (nominales et anormales)
- Offline/timeout (technique) : backoff, retry contrôlé, mode offline.
- Conflits (données) : appliquer policy, log reason.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : sync désactivée / différée ; données locales restent cohérentes.
- **Échec partiel** : features cloud masquées, local-first.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `sync_trigger`, `sync_phase`, `sync_error`, `conflict_resolution`.
- **Métriques** : taux succès/échec, latence sync, retries.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-018` : integration — **Couvre** : `PH3-INV-025` — **Preuve attendue** : retry ne duplique pas les écritures.
- `PH3-TST-019` : unit — **Couvre** : `PH3-INV-027` — **Preuve attendue** : résolution conflit déterministe.
- `PH3-TST-031` : integration — **Couvre** : `PH3-INV-024` — **Preuve attendue** : log CI : sync ne bloque pas l’UI (local-first, sync différée).
- `PH3-TST-032` : unit — **Couvre** : `PH3-INV-026` — **Preuve attendue** : validation payload sync : pas de secrets/PII (minimisation + redaction).

#### 10) Rollback possible
- **Rollback** : possible, mais attention aux migrations de schéma.
- **Mécanisme** : feature flag “cloud_sync_off” (à introduire si absent) + rollback release.
- **Contraintes** : migrations doivent être backward compatible ou accompagnées d’un reset contrôlé.

### Fiche flux — `PH3-FLOW-008` — Settings impactant le runtime

#### 1) Identité
- **Flow ID** : `PH3-FLOW-008`
- **Nom** : Settings impactant le runtime (features, réseau, player, logs)
- **Owner** : `TBD`
- **Classe** : `L2` (peut toucher `L1` si sécurité)
- **Criticité attendue** : `C2`
- **Statut** : `draft`

#### 2) Préconditions
- Settings persistables et lisibles (sinon defaults sûrs).
- Toute option risquée a une valeur par défaut sûre (réf. §19).

#### 3) États & transitions
- **États** : `SettingsDefault` | `SettingsLoad` | `SettingsApplied` | `SettingsInvalid` | `SettingsReset`.
- **Transitions** :
  - `SettingsLoad` --(ok)--> `SettingsApplied`
  - `SettingsLoad` --(parse error)--> `SettingsInvalid` → `SettingsReset` → `SettingsDefault`

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-028` : Settings invalides ne crashent pas : reset contrôlé vers defaults sûrs — **Justification** : stabilité — **Signal de rupture** : crash/exception parse settings.
- `PH3-INV-029` : Toute option modifiant sécurité/safety est fail-safe/fail-closed (pas de valeur implicite dangereuse) — **Justification** : sécurité — **Signal de rupture** : comportement “dangereux” sans config explicite.
- `PH3-INV-030` : Changement de settings est observable (qui/quoi/quand) sans PII — **Justification** : audit — **Signal de rupture** : settings change non loggé.

#### 5) Effets de bord
- **Réseau** : proxy on/off, timeouts.
- **Storage** : prefs, caches.
- **Player** : options avancées.
- **Observabilité** : niveau de logs, telemetry.

#### 6) Erreurs (nominales et anormales)
- Corruption prefs (données) : reset contrôlé.
- Option incompatible (technique) : ignorer + log “setting_ignored”.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : defaults sûrs ; features risquées désactivées si doute.
- **Échec partiel** : appliquer partiellement, isoler option fautive.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `settings_load_result`, `settings_reset`, `settings_changed` (sans valeurs sensibles).
- **Métriques** : taux reset settings, taux invalid settings.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-020` : unit — **Couvre** : `PH3-INV-028` — **Preuve attendue** : prefs corrompues → defaults sûrs.
- `PH3-TST-021` : integration — **Couvre** : `PH3-INV-030` — **Preuve attendue** : audit log sur changement settings.
- `PH3-TST-033` : unit — **Couvre** : `PH3-INV-029` — **Preuve attendue** : settings sécurité fail-safe/fail-closed (valeurs implicites dangereuses interdites).

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : reset defaults + rollback release.
- **Contraintes** : compat des prefs entre versions.

### Fiche flux — `PH3-FLOW-009` — Diagnostics et remontée de problèmes (reporting)

#### 1) Identité
- **Flow ID** : `PH3-FLOW-009`
- **Nom** : Diagnostics et remontée de problèmes (reporting)
- **Owner** : `TBD`
- **Classe** : `L2` (peut toucher `L1` si fuite données)
- **Criticité attendue** : `C2` (devient `C1` si exposition PII/secrets)
- **Statut** : `draft`

#### 2) Préconditions
- Un identifiant d’opération/corrélation (`operationId`) est disponible si possible.
- Les logs/diagnostics sont **redactés** (pas de token/secret/PII en clair), conforme §12/§13.
- Réseau optionnel : la remontée peut être différée si offline.

#### 3) États & transitions
- **États** : `IssueStart` → `CollectContext` → `Redact` → `ComposeReport` → `Submit` → `Submitted` | `SubmitFailed` | `Queued`.
- **Transitions** :
  - `CollectContext` --(ok)--> `Redact`
  - `Redact` --(ok)--> `ComposeReport`
  - `Submit` --(ok)--> `Submitted`
  - `Submit` --(offline/timeout)--> `Queued` (retry contrôlé) ou `SubmitFailed`

#### 4) Invariants (`PH3-INV-*`)
- `PH3-INV-031` : Aucun secret/token/PII ne sort dans un rapport ou log associé — **Justification** : sécurité/confidentialité — **Signal de rupture** : test de redaction échoue / scan log détecte motifs.
- `PH3-INV-032` : Le reporting est optionnel et ne doit pas bloquer les flux critiques — **Justification** : disponibilité — **Signal de rupture** : UI bloquée en collecte/submit.
- `PH3-INV-033` : Chaque report a un identifiant traçable (reportId) et corrélable à `operationId` si présent — **Justification** : diagnostic — **Signal de rupture** : report sans IDs.
- `PH3-INV-034` : Les erreurs de submit sont actionnables (retry, copie locale) — **Justification** : UX/support — **Signal de rupture** : submit échoue sans feedback.

#### 5) Effets de bord
- **Réseau** : submit report (Sentry / Supabase / endpoint interne).
- **Storage** : queue locale si offline, stockage temporaire (avec limite/TTL).
- **Auth/session** : si report lié à un compte, ne pas exposer l’ID utilisateur en clair.
- **Analytics** : compteur reports (agrégé).

#### 6) Erreurs (nominales et anormales)
- Offline/timeout (technique) : `Queued`, retry contrôlé, pas de perte silencieuse.
- Redaction KO (sécurité) : refuser d’envoyer, proposer report minimal sans logs.
- Endpoint down (intégration) : message actionnable, conserver local si autorisé.

#### 7) État sûr & modes dégradés
- **État sûr attendu** : aucun envoi si redaction non garantie ; report minimal possible.
- **Échec partiel** : désactiver pièces jointes/logs, n’envoyer que le résumé.

#### 8) Observabilité minimale (réf. §14)
- **Logs** : `report_collect_begin/end`, `report_redact_result`, `report_submit_result` (sans payload sensible).
- **Métriques** : taux submit success/fail, taille payload (bornée), queue length.

#### 9) Tests requis (`PH3-TST-*`)
- `PH3-TST-022` : unit — **Couvre** : `PH3-INV-031` — **Preuve attendue** : redaction supprime tokens/PII (corpus de patterns).
- `PH3-TST-023` : integration — **Couvre** : `PH3-INV-032` — **Preuve attendue** : submit KO n’empêche pas navigation.
- `PH3-TST-024` : integration — **Couvre** : `PH3-INV-033` — **Preuve attendue** : reportId + operationId présents dans l’événement.
- `PH3-TST-034` : integration — **Couvre** : `PH3-INV-034` — **Preuve attendue** : submit KO → feedback actionnable + queue/retry contrôlé.

#### 10) Rollback possible
- **Rollback** : possible.
- **Mécanisme** : feature flag `reporting_off` / désactivation uploads + rollback release.
- **Contraintes** : purger queue locale si format change.


---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/implementation-readiness-report-2026-04-02.md
  - docs/archives/02-04-26/architecture/current_state.md
  - docs/archives/02-04-26/architecture/dependency_rules.md
  - docs/archives/02-04-26/roadmap/phase_4_media_resume_robuste.md
  - docs/archives/02-04-26/roadmap/phase_4_refondation_noyau_critique.md
  - docs/archives/02-04-26/adr/ADR-PH4-001_media_resume_orchestrators.md
  - docs/archives/02-04-26/traceability/requirements_traceability.md
  - docs/archives/02-04-26/traceability/verification_matrix.md
  - docs/archives/02-04-26/traceability/change_logbook.md
  - docs/archives/02-04-26/risk/hazard_analysis.md
  - docs/archives/02-04-26/risk/failure_modes.md
  - docs/archives/02-04-26/security/threat_model.md
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-04-02'
project_name: 'movi'
user_name: 'Matteo'
date: '2026-04-02T21:25:54.3490892+02:00'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
Le PRD courant porte 40 exigences fonctionnelles, organisees en domaines clairs :
- acces et gestion de session
- decouverte et navigation de contenu
- playback et reprise de lecture
- profils, parental controls et preferences
- abonnement et entitlement
- notifications et re-engagement
- experience degradee, sync cross-device et supportability

Architecturally, this implies a modular client architecture with distinct responsibility boundaries for startup, auth/session, content discovery, playback/resume, sync/storage, entitlement/subscription, settings/profiles, and diagnostics/observability.

The existing epics provide a partial architectural starting point around startup/auth safety, playback/resume, and sync/diagnostics, but they do not yet cover the full PRD scope for discovery, TV interaction, entitlement, or notifications.

**Non-Functional Requirements:**
The PRD defines 35 non-functional requirements that strongly constrain the architecture:
- strict performance budgets for cold start, warm start, navigation, and playback start
- fail-closed or fail-safe behavior for auth, parental control, entitlement, and sensitive settings
- zero secrets or PII in logs, traces, reports, and validation evidence
- explicit observability with `operationId`, `reasonCode`, and diagnosable safe/degraded/recovered states
- bounded timeouts, retries, and fallback behavior on all critical flows
- TV-grade interaction requirements: directional navigation, focus stability, 10-foot readability
- cross-device consistency and eventual sync without blocking the local experience
- evidence-based release gates tied to critical flows and traceability artifacts

### Scale & Complexity

This project is a brownfield, cross-platform mobile media application with high architectural complexity.

- Primary domain: mobile / TV media application
- Complexity level: high
- Estimated architectural components: 12

The complexity comes less from business regulation and more from the combination of:
- strict runtime reliability on critical flows
- multi-surface support (`Android` and `Android TV` first)
- cross-device synchronization and resume continuity
- entitlement and parental safety constraints
- strong observability and proof requirements
- an existing codebase with partial refactors already in progress

### Technical Constraints & Dependencies

Known architectural constraints and dependencies identified from the loaded documents:
- Flutter brownfield codebase with mixed dependency injection patterns (`Riverpod` and `GetIt`)
- existing structural hot spots and oversized files in startup, player, TV detail, movie detail, and search
- explicit architecture enforcement rules `ARCH-R1..R5` already defined and intended to be blocking
- Phase 4 execution order already suggested for critical core domains: startup, auth, storage, network, parental, profile
- accepted ADR for media resume orchestrators and stabilized reason codes
- target launch platforms are `Android` and `Android TV`; `iOS` and `Windows` are future-compatible targets
- external integration surface includes content resolution, session/auth, sync/cloud, subscription/entitlement, diagnostics, and network services
- offline support is partial and local-first; full offline playback is not part of MVP

### Cross-Cutting Concerns Identified

The following concerns will affect multiple architectural components:
- fail-safe and fail-closed decision policies
- structured observability and redaction-by-default
- contract-first boundaries with ports/adapters around side effects
- cross-device state consistency and reconciliation
- degraded-mode behavior for network, storage, auth, and playback
- TV-specific navigation, focus management, and accessibility
- traceability and validation evidence from requirement to test proof
- rollback and containment readiness for critical changes

## Starter Template Evaluation

### Primary Technology Domain

Application mobile Flutter / TV brownfield, orientee media playback, sync cross-device, entitlement et observabilite forte.

### Starter Options Considered

**1. Official Flutter CLI**
- Source officielle et la moins opinionnee
- Commande de base maintenue : `flutter create`
- Permet de bootstrap une application Flutter standard ou de regenerer proprement un squelette de plateforme
- Avantage principal pour `movi` : compatible avec un depot brownfield deja initialise, sans imposer une seconde architecture de projet

**2. Very Good CLI (`very_good_cli` 1.1.1)**
- Starter maintenu et actif pour projets Flutter
- Commande officielle de creation : `very_good create flutter_app <project-name>`
- Interessant pour un greenfield qui veut une base opinionnee et normalisee
- Moins adapte ici, car `movi` existe deja avec ses propres conventions, ses contraintes brownfield, et une stack reelle (`Riverpod`, `GetIt`, `go_router`, `Supabase`) qu’il faudrait preserver plutot que re-squelettiser

**3. Antigravity (workflow agentique documente par Flutter)**
- Pertinent comme environnement de generation assistee
- Pas un starter structurel de reference pour un depot brownfield existant
- Utile pour accelerer certaines taches, mais ne doit pas etre confondu avec la fondation architecturale du projet

### Selected Starter: Official Flutter CLI Baseline

**Rationale for Selection:**
Le projet est un brownfield Flutter deja en production de travail, avec des lots Phase 4 deja traces dans le logbook. Repartir d’un starter opinionne introduirait un conflit de conventions plus qu’un gain architectural.

Le choix le plus robuste est donc de retenir la baseline officielle Flutter comme reference de scaffolding, tout en conservant le depot existant comme base reelle du projet. Cela minimise le risque de divergence entre la fondation technique et l’architecture cible que nous allons documenter ensuite.

**Initialization Command:**

```bash
flutter create --platforms=android,ios,windows movi
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
- Projet `Dart` / `Flutter` standard, aligne sur l’outillage officiel
- Squelette de projet multiplateforme maintenu par l’ecosysteme Flutter

**Styling Solution:**
- Aucun systeme de design ou solution de styling opinionnee imposee
- Laisse l’architecture UI libre pour respecter les besoins TV, premium UX et brownfield constraints du projet

**Build Tooling:**
- Outillage de build Flutter officiel
- Generation standard des plateformes et configuration de base du projet

**Testing Framework:**
- Base de test Flutter standard
- Pas de conventions de test additionnelles imposees par le starter

**Code Organization:**
- Structure Flutter standard minimale
- La vraie organisation applicative sera definie par notre architecture cible, pas par le starter

**Development Experience:**
- Compatible avec les workflows Flutter officiels
- Le plus faible risque de friction avec le depot existant et ses scripts/outils

**Brownfield Note:**
Pour `movi`, cette commande doit etre traitee comme une reference de bootstrap, pas comme une instruction a rejouer aveuglement sur le depot courant. Le premier travail d’implementation ne doit pas recreer le projet, mais consolider le squelette existant et aligner les modules avec l’architecture cible.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Retenir une architecture brownfield Flutter modulaire, organisee par domaines fonctionnels, avec frontieres explicites entre `presentation`, `application`, `domain`, `data` et `core`
- Conserver `Supabase` comme backend principal pour auth et services cloud existants
- Conserver une strategie `local-first` avec persistance locale explicite, sync bornee et etats degrades visibles
- Formaliser un modele de securite `fail-closed` pour `auth`, `parental`, `entitlement` et decisions sensibles
- Retenir `Riverpod` comme mecanisme principal de state management UI et limiter `GetIt` au composition root / module wiring
- Retenir une observabilite structuree avec `operationId`, `reasonCode`, redaction par defaut et preuves tracables

**Important Decisions (Shape Architecture):**
- Conserver `go_router` comme systeme de navigation declarative
- Isoler `Supabase`, `Dio`, `sqflite`, `secure storage`, `Sentry` et autres SDK derriere des ports/adapters
- Traiter `Android` et `Android TV` comme cibles de premier ordre, avec contraintes TV explicites dans les composants UI
- Introduire une strategie claire de feature flags / kill switches sur les flux critiques
- Garder les upgrades de packages hors du flux d’architecture de reference, sauf besoin critique

**Deferred Decisions (Post-MVP):**
- Extension cible `iOS`
- Extension cible `Windows` au-dela de la compatibilite structurelle
- Recommandations IA et surfaces produit plus contextuelles
- Raffinements de personnalisation et re-engagement avance

### Data Architecture

**Primary Data Model**
- Architecture `local-first` avec source locale explicite et synchronisation cloud bornee
- Le modele de donnees doit separer :
  - etat local critique runtime
  - preferences utilisateur
  - historique playback / continue watching
  - etat de sync et conflict resolution
  - etat entitlement / abonnement

**Local Storage Decisions**
- Base locale principale : `sqflite`
- Donnees sensibles / secrets / materiel de session : `flutter_secure_storage`
- Les acces storage passent par des repositories et services de domaine, jamais par l’UI directement
- Toute lecture corrompue ou invalide doit produire soit une erreur typee, soit un fallback sur explicite

**Validation & Migration**
- Validation systematique en read-path et write-path
- Migrations SQLite testees sur fixtures representatives
- Aucun flux critique ne peut “ignorer” silencieusement une corruption locale
- Les migrations doivent avoir une strategie de containment ou rollback documentee

**Caching & Sync**
- Strategie `local-first, sync-later`
- Sync cloud non bloquante pour l’UI
- Retry, timeout, idempotence et reconciliation explicites
- Etats `pending`, `degraded`, `recovered`, `failed` visibles dans l’observabilite et, quand necessaire, dans l’UX

### Authentication & Security

**Authentication Method**
- Auth principale conservee via `Supabase Auth`
- L’etat auth ne doit jamais etre deduit implicitement : il passe par une orchestration explicite et observable

**Authorization & Sensitive Decisions**
- `auth`, `parental`, `entitlement` et `premium access` sont traites en `fail-closed`
- En cas d’incertitude, l’utilisateur reste dans un etat sur et non premium tant que la preuve d’acces n’est pas etablie

**Secrets & Data Protection**
- Aucun secret ou PII dans logs, traces, rapports ou preuves CI
- Configuration sensible injectee via mecanismes approuves CI / runtime, pas via fichiers versionnes
- Les payloads et diagnostics doivent etre redacted by default

**Security Architecture Pattern**
- Ports/adapters pour auth, storage sensible, diagnostics et services reseau
- Failure codes stables et reason codes exploitables
- Les policies sensibles vivent en domaine/application, pas dans l’UI

### API & Communication Patterns

**Communication Model**
- Pas de redecoupage vers GraphQL ou autre paradigme a ce stade
- Communication orientee services existants via `Supabase` et clients HTTP adaptes
- Les contrats applicatifs doivent etre modeles par ports, DTOs/adapters et failures typees

**Error Handling Standard**
- Taxonomie d’erreurs explicite : timeout, offline, unauthorized, conflict, invalid data, unknown
- Aucun spinner infini ou erreur silencieuse sur flux critique
- Toute erreur critique doit mener a un etat actionnable ou sur

**Rate Limiting / Retry / Timeout**
- Timeouts explicites sur appels critiques
- Retries bornes et jamais implicites a l’infini
- Idempotence requise sur sync, reprise et ecritures sensibles

### Frontend Architecture

**State Management**
- `flutter_riverpod` devient le mecanisme principal pour l’etat presentationnel et orchestration UI
- `GetIt` reste autorise pour le wiring et le bootstrap module, mais pas comme acces direct depuis l’UI
- L’architecture cible doit reduire progressivement les usages UI directs du locator conformement a `ARCH-R5`

**Routing**
- `go_router` conserve comme routeur declaratif principal
- Les redirections critiques doivent etre observables, deterministes et coherentes avec l’etat auth/launch
- Les parcours TV et mobile doivent partager les memes invariants, avec adaptation d’interaction par surface

**Feature Structure**
- Organisation par domaines / features
- Chaque feature expose des contrats stables vers l’exterieur
- Pas de dependance `feature -> feature` hors contrats explicitement approuves
- Pas d’imports `presentation -> data`
- Pas d’imports `domain -> data`

**UI / TV Constraints**
- Les composants doivent expliciter les comportements tactile vs telecommande
- Focus management, navigation directionnelle et lisibilite `10-foot UI` doivent etre traites comme exigences d’architecture, pas comme polish tardif
- Les etats degrade/pending/resume/blocked/premium doivent etre modeles comme etats UX explicites

### Infrastructure & Deployment

**Build & Delivery**
- Baseline outillage Flutter officielle
- Pipeline CI/CD alignee sur les preuves deja presentes dans le corpus (`Codemagic`, rapports d’architecture, evidence index, change logbook)
- No evidence, no merge sur les lots critiques

**Monitoring & Logging**
- `sentry_flutter` conserve pour crash/error monitoring
- Logs structures et rediges, correlables via `operationId`
- Les reason codes et safe states doivent etre visibles sans exposer de donnees sensibles

**Environment Configuration**
- Configuration runtime via `--dart-define` / CI secret store / mecanismes approuves
- Aucun secret versionne
- Les variables d’environnement doivent avoir des valeurs par defaut sures ou des modes degrades explicites

**Scaling Strategy**
- L’architecture doit privilegier :
  - performance percue
  - resilience locale
  - sync eventual consistency
  - diagnosabilite
- Le scale server-side n’est pas la contrainte dominante immediate; la priorite est la stabilite deterministe des flux critiques

### Decision Impact Analysis

**Implementation Sequence:**
1. Consolider les frontieres `startup`, `auth`, `storage`, `network`, `parental`, `profile`
2. Unifier la politique `ports/adapters + typed failures + fail-closed`
3. Aligner presentation state sur `Riverpod` et reduire les acces directs du locator en UI
4. Etendre proprement aux domaines encore sous-couverts par les epics : discovery, TV UX, entitlement, notifications
5. Completer les preuves et gates `REQ -> FLOW -> INV -> TST -> EVD`

**Cross-Component Dependencies:**
- Les choix storage, sync, auth et entitlement s’influencent mutuellement
- La navigation depend des decisions startup/auth/parental/entitlement
- L’observabilite traverse tous les composants critiques
- Les contraintes TV influencent routing, UI state, playback entry points et UX degradee

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:**
10 areas where AI agents could make different choices and create integration conflicts

### Naming Patterns

**Database Naming Conventions:**
- Tables use `snake_case` and plural names: `playback_history`, `user_profiles`, `subscription_events`
- Columns use `snake_case`: `user_id`, `updated_at`, `reason_code`
- Foreign keys use `<entity>_id`: `profile_id`, `session_id`
- Timestamps use `created_at`, `updated_at`, `synced_at`
- Boolean columns use positive names: `is_active`, `is_restricted`, `is_synced`

**API Naming Conventions:**
- External/persisted payload fields use `snake_case`
- Route paths use lowercase resource names
- Route parameters use semantic names: `:movieId`, `:episodeId`, `:profileId`
- Query parameters use `camelCase` in Dart call sites, but adapters map to external contract format when needed
- Error codes and machine-readable reason fields use stable `snake_case`

**Code Naming Conventions:**
- Dart files use `snake_case.dart`
- Classes, enums, typedefs use `PascalCase`
- Methods, variables and parameters use `camelCase`
- Providers end with `Provider`
- Controllers/orchestrators/services use explicit suffixes:
  - `...Controller`
  - `...Orchestrator`
  - `...Service`
  - `...Repository`
  - `...Adapter`
- Failure types use explicit names:
  - `AuthFailure`
  - `StorageFailure`
  - `ResumeFailure`
- Reason codes use domain-specific enums or constants, never ad-hoc strings spread across files

### Structure Patterns

**Project Organization:**
- Code remains organized by domain/feature first, not by technical layer alone
- Shared cross-cutting code goes into `lib/src/core/...`
- Feature-specific code stays inside `lib/src/features/<feature>/...`
- Do not create generic dumping grounds like `utils/`, `helpers/`, or `misc/` without a bounded purpose
- Each feature should separate responsibilities into:
  - `presentation`
  - `application` when orchestration/use-case logic exists
  - `domain`
  - `data` where adapters/repositories/datasources live

**File Structure Patterns:**
- Tests live under `test/`, mirroring `lib/src/...` paths as closely as possible
- ADRs, reports and traceability artifacts stay under `docs/...`
- Platform configuration remains in Flutter platform folders, not duplicated into feature code
- Static assets remain categorized by purpose, not by screen implementation details

### Format Patterns

**API Response Formats:**
- Domain/application layers consume typed results, not raw JSON maps
- Adapters are responsible for mapping external payloads into internal models
- Error outputs must include:
  - stable machine-readable code
  - human-readable message only at the edge
  - optional `operationId` when available
- Critical flows must preserve explicit state outcomes:
  - `success`
  - `degraded`
  - `failed`
  - `blocked`

**Data Exchange Formats:**
- Internal Dart models use `camelCase`
- External storage/network formats use `snake_case`
- Mapping between the two must happen only in adapters/DTOs
- Dates/timestamps should be normalized explicitly at boundaries
- Nullability must be intentional and modeled, not inferred implicitly from dynamic payloads

### Communication Patterns

**Event System Patterns:**
- Structured telemetry/event names use stable, domain-oriented strings such as:
  - `startup_begin`
  - `auth_gate_decision`
  - `player_resume_apply`
  - `sync_conflict_resolved`
- Event payloads must be minimal and redacted by default
- Correlation fields use:
  - `operationId`
  - `reasonCode`
- New event families must follow existing domain prefixes rather than inventing parallel vocabularies

**State Management Patterns:**
- `flutter_riverpod` is the primary UI state mechanism
- `GetIt` is restricted to dependency wiring / composition root concerns
- UI code must not resolve business dependencies directly from the locator
- Critical state should prefer explicit state models over loose booleans
- Recommended critical flow states:
  - `idle`
  - `loading`
  - `ready`
  - `degraded`
  - `blocked`
  - `error`
- State transitions for critical flows must be explicit and observable

### Process Patterns

**Error Handling Patterns:**
- Domain and application layers return typed failures/results
- Presentation maps typed failures into user-facing states/messages
- No silent catch-and-ignore on critical paths
- No infinite retry loops
- If a critical decision cannot be established, the system must choose the documented safe state

**Loading State Patterns:**
- Avoid raw `isLoading` booleans for critical workflows
- Use explicit state objects or enums for startup, auth, playback, sync and entitlement flows
- Loading must always have an exit condition:
  - success
  - degraded fallback
  - explicit failure
  - cancellation/timeout
- Infinite spinner states are forbidden on critical flows

### Enforcement Guidelines

**All AI Agents MUST:**
- Respect `ARCH-R1..R5` and avoid forbidden dependency directions
- Keep external SDKs and IO behind adapters/repositories, never in `presentation` or pure `domain`
- Use `camelCase` internally and map to external `snake_case` only at boundaries
- Mirror tests under `test/` for each critical domain or component introduced
- Emit stable `reasonCode` and `operationId` where the flow is critical or diagnosable
- Prefer explicit typed failures and state models over stringly-typed control flow
- Preserve `fail-closed` behavior for auth, parental, entitlement and other sensitive gates

**Pattern Enforcement:**
- Architectural violations are checked through the existing architecture wall rules and reports
- Pattern violations should be corrected in the same change whenever possible
- If a pattern must be broken, the exception must be documented via ADR or traceability/logbook entry
- New shared conventions should be added here before being repeated across multiple features

### Pattern Examples

**Good Examples:**
- `lib/src/features/player/application/services/player_resume_orchestrator.dart`
- `test/features/player/application/services/player_resume_orchestrator_test.dart`
- `PlaybackHistoryDto` maps `snake_case` payloads to a `PlaybackHistory` domain model
- `AuthFailureCode.sessionUnknown` is mapped to a fail-closed UI state with a stable `reasonCode`
- `libraryCloudSyncProvider` exposes UI-safe state while sync adapters encapsulate Supabase/network details

**Anti-Patterns:**
- A widget calling `sl<SomeRepository>()` directly
- A `presentation` file importing a `data` repository implementation
- JSON/network/storage maps passed raw through multiple layers
- Generic files like `helpers.dart` or `utils.dart` accumulating unrelated logic
- New critical flows represented only by `isLoading` and `hasError`
- Free-form error strings used as machine-readable decisions
- Logs or telemetry containing DSNs, tokens, email addresses, raw URLs or payload dumps

## Project Structure & Boundaries

### Complete Project Directory Structure

```text
movi/
|-- pubspec.yaml
|-- pubspec.lock
|-- analysis_options.yaml
|-- codemagic.yaml
|-- l10n.yaml
|-- .env
|-- .env.example
|-- android/
|-- ios/
|-- windows/
|-- assets/
|-- docs/
|   |-- archives/
|   |-- operations/
|   |-- quality/
|   |-- risk/
|   `-- traceability/
|-- supabase/
|   |-- functions/
|   |   `-- verify_subscription/
|   `-- migrations/
|-- tool/
|   |-- arch_lint.dart
|   |-- analyze_run_log.dart
|   |-- gen_l10n.dart
|   `-- arch_lint_canary/
|-- lib/
|   |-- main.dart
|   `-- src/
|       |-- core/                         # transversal only
|       |   |-- auth/
|       |   |-- config/
|       |   |-- di/                       # composition root, wiring, GetIt only here
|       |   |-- diagnostics/
|       |   |-- error/
|       |   |-- logging/
|       |   |-- network/
|       |   |-- notifications/            # target: push permissions, token/device, delivery adapters
|       |   |-- observability/
|       |   |-- parental/
|       |   |-- performance/
|       |   |-- playback/
|       |   |-- preferences/
|       |   |-- profile/
|       |   |-- reporting/
|       |   |-- responsive/
|       |   |-- router/
|       |   |-- security/
|       |   |-- shared/                   # temporary legacy zone to reduce over time
|       |   |-- startup/
|       |   |-- state/                    # rare app-global state only
|       |   |-- storage/
|       |   |-- subscription/             # entitlement/billing/premium authority
|       |   |   |-- application/
|       |   |   |-- domain/
|       |   |   |-- data/
|       |   |   `-- adapters/
|       |   |-- supabase/
|       |   |-- theme/
|       |   |-- utils/                    # frozen: no new generic logic
|       |   `-- widgets/                  # frozen: shared primitives only
|       |-- features/                     # product domains / user journeys
|       |   |-- auth/
|       |   |-- category_browser/
|       |   |-- home/
|       |   |-- iptv/
|       |   |-- library/
|       |   |-- movie/
|       |   |-- notifications/            # target: consent, inbox, re-engagement preferences
|       |   |-- person/
|       |   |-- player/
|       |   |-- playlist/
|       |   |-- saga/
|       |   |-- search/
|       |   |-- settings/
|       |   |-- shell/
|       |   |-- subscription/             # target: paywall, restore, plans, account status
|       |   |-- tv/
|       |   `-- welcome/
|       `-- shared/                       # canonical non-system shared code
|           |-- data/
|           |-- domain/
|           `-- presentation/
|-- test/                                 # canonical test tree
|   |-- core/
|   |-- features/
|   |   |-- home/
|   |   |-- iptv/
|   |   |-- library/
|   |   |-- movie/
|   |   |-- notifications/
|   |   |-- player/
|   |   |-- settings/
|   |   |-- subscription/
|   |   |-- tv/
|   |   `-- welcome/
|   |-- shared/
|   |-- src/
|   `-- support/
|-- tests/                                # legacy debt, no new tests here
|-- _bmad/
`-- _bmad-output/
```

### Architectural Boundaries

**API Boundaries:**
- All network, Supabase, external storage, or third-party SDK access goes through `lib/src/core/network/`, `lib/src/core/supabase/`, `lib/src/core/storage/`, or feature `data/` adapters
- `supabase/functions/` and `supabase/migrations/` own server logic and schema evolution; the client does not duplicate these decisions
- `lib/src/core/subscription/` is the source of truth for `entitlement`, premium access verification, and fail-closed policy
- `lib/src/core/notifications/` is the single entry point for push permissions, token registration, and delivery providers; user-facing screens live in `lib/src/features/notifications/`
- No widget, UI provider, or route guard talks directly to `Supabase`, `Dio`, `sqflite`, `flutter_secure_storage`, `media_kit`, or `Sentry`

**Component Boundaries:**
- `lib/src/features/*` contains user journeys and product-facing business logic
- `lib/src/core/*` contains cross-cutting capabilities, sensitive policies, runtime services, and system integrations
- `lib/src/shared/*` is the canonical location for shared non-system business code
- `lib/src/core/shared/` is treated as a temporary legacy zone; new shared business logic should not land there by default
- A feature may depend on `core/*` and `shared/*`, but not on another feature's internal implementation details
- Within a domain, the target direction remains `presentation -> application -> domain -> data`
- `Riverpod` carries UI state and presentation flow; `GetIt` stays limited to `lib/src/core/di/` and bootstrap wiring

**Service Boundaries:**
- `lib/src/core/startup/` orchestrates launch -> auth gate -> parental gate -> profile restore -> entitlement gate
- `lib/src/features/player/` owns the user playback experience; `lib/src/core/playback/` owns engines, resume policies, and technical coordination
- `lib/src/features/subscription/` owns premium user surfaces; `lib/src/core/subscription/` owns access decisions and billing/backend adapters
- `lib/src/features/notifications/` owns preferences, inbox, and consent; `lib/src/core/notifications/` owns permissions, tokens, scheduling, and delivery adapters
- `lib/src/core/observability/`, `lib/src/core/diagnostics/`, and `lib/src/core/reporting/` remain cross-cutting and are not reimplemented per feature

**Data Boundaries:**
- External `snake_case` models are confined to DTOs and `data/` adapters
- Internal Dart models remain typed and use `camelCase`
- `lib/src/core/storage/` owns local persistence abstractions; features do not touch `sqflite` or secure storage directly
- Sync, resume, entitlement, and preferences state remain persisted but are exposed through repositories and services, never through raw UI reads
- Sensitive decisions for `auth`, `parental`, and `entitlement` remain fail-closed even in degraded mode

### Requirements to Structure Mapping

**Feature/Epic Mapping:**
- Access, session, and safe launch -> `lib/src/core/startup/`, `lib/src/core/auth/`, `lib/src/core/security/`, `lib/src/features/auth/`, `lib/src/features/welcome/`, `test/core/`, `test/features/auth/`, `test/features/welcome/`
- Discovery and content navigation -> `lib/src/features/home/`, `lib/src/features/library/`, `lib/src/features/search/`, `lib/src/features/movie/`, `lib/src/features/tv/`, `lib/src/features/person/`, `lib/src/features/saga/`, `lib/src/features/category_browser/`, `lib/src/features/playlist/`, `lib/src/features/shell/`
- Playback and resume -> `lib/src/features/player/`, `lib/src/core/playback/`, `lib/src/core/storage/`, `lib/src/core/network/`, `test/features/player/`
- Profiles, parental controls, and preferences -> `lib/src/core/profile/`, `lib/src/core/parental/`, `lib/src/core/preferences/`, `lib/src/features/settings/`
- Subscription and entitlement -> `lib/src/core/subscription/`, `lib/src/core/supabase/`, `supabase/functions/verify_subscription/`, `supabase/migrations/`, `lib/src/features/subscription/`, `test/features/subscription/`
- Notifications and re-engagement -> `lib/src/core/notifications/`, `lib/src/features/notifications/`, `android/` for native integrations when needed, `test/features/notifications/`
- Observability, supportability, and evidence -> `lib/src/core/observability/`, `lib/src/core/diagnostics/`, `lib/src/core/reporting/`, `tool/`, `docs/traceability/`, `docs/quality/`, `_bmad-output/planning-artifacts/`

**Cross-Cutting Concerns:**
- Routing and app shell -> `lib/src/core/router/`, `lib/src/features/shell/`
- Theme, responsiveness, and TV readability -> `lib/src/core/theme/`, `lib/src/core/responsive/`, related feature UI
- DI and bootstrap -> `lib/src/core/di/`
- Logging, redaction, and reason codes -> `lib/src/core/logging/`, `lib/src/core/observability/`, `lib/src/core/error/`
- Architecture enforcement -> `tool/arch_lint.dart`, `analysis_options.yaml`, architecture tests, and CI review
- Shared code conventions -> new reusable business code goes to `lib/src/shared/`; `lib/src/core/utils/` and `lib/src/core/widgets/` do not receive open-ended new logic

### Integration Points

**Internal Communication:**
- Widget/Screen -> Riverpod Provider/Controller -> Application Service/Orchestrator -> Repository -> Adapter -> SDK/API/DB
- Critical transitions expose explicit states like `ready`, `degraded`, `blocked`, and `error` rather than raw booleans
- Cross-feature interaction goes through the router, `core/*` services, or explicit contracts, not direct imports of internal implementations
- Shell and startup own global decisions; features remain focused on their user domain

**External Integrations:**
- `Supabase Auth` and cloud services via `lib/src/core/supabase/`
- Subscription verification via `supabase/functions/verify_subscription/` and `lib/src/core/subscription/`
- Local persistence via `lib/src/core/storage/`
- Third-party HTTP/network via `lib/src/core/network/`
- Monitoring via `lib/src/core/observability/` and `sentry_flutter`
- Playback engine via `lib/src/core/playback/` and `lib/src/features/player/`
- Native billing or purchase restore flows via `lib/src/core/subscription/` and platform integrations when required

**Data Flow:**
- External input -> Adapter/DTO -> Repository -> Domain/Application -> Provider/Controller -> UI
- User event -> Provider/Controller -> Use Case/Service -> Repository -> Local store, then bounded sync when needed
- Critical startup -> startup orchestration -> auth decision -> parental/profile decision -> entitlement decision -> navigation
- Playback resume -> storage/sync read -> playback policy -> player controller -> observable UI state

### File Organization Patterns

**Configuration Files:**
- Root files like `pubspec.yaml`, `analysis_options.yaml`, `codemagic.yaml`, `l10n.yaml`, and `.env.example` remain at repository root
- Secrets are never versioned; runtime injection uses `--dart-define` and the CI secret store
- Architecture and quality rules are centralized at root or under `tool/`, not scattered per feature

**Source Organization:**
- New product code belongs in `lib/src/features/<domain>/{presentation,application,domain,data}` when the domain warrants those layers
- New cross-cutting code belongs in `lib/src/core/<capability>/...`
- New shared business code belongs in `lib/src/shared/...`
- `lib/src/core/utils/` and `lib/src/core/widgets/` are closed by default; touch them for extraction or debt reduction, not for new opportunistic behavior
- `lib/src/core/state/` is reserved for rare global app state; feature state stays within the feature

**Test Organization:**
- `test/` is the only canonical test tree
- Every addition in `lib/src/features/<domain>/` should be mirrored under `test/features/<domain>/`
- Every critical addition in `lib/src/core/<capability>/` should be covered under `test/core/<capability>/`
- `tests/` is explicitly obsolete and must not receive new files

**Asset Organization:**
- `assets/` stays organized by asset type rather than by screen
- Playback, branding, or theme-specific assets are referenced from features or theme code without platform duplication
- Any TV-specific or premium-specific resource should be named by business intent, not by page implementation

### Development Workflow Integration

**Development Server Structure:**
- The entry point remains `lib/main.dart`; daily implementation work happens by domain under `lib/src/`
- Feature changes stay contained to their domain plus legitimate `core/*` dependencies
- Wiring changes happen in `lib/src/core/di/`, not in widgets
- Any new PRD feature starts by creating its explicit target location rather than appending logic opportunistically into a neighboring folder

**Build Process Structure:**
- Flutter build uses root configuration and standard platform directories `android/`, `ios/`, and `windows/`
- Verification and enforcement scripts live under `tool/`
- Supabase migrations and edge functions are versioned separately under `supabase/`
- CI should verify tests, lint, the architecture wall, and evidence tied to critical flows

**Deployment Structure:**
- `codemagic.yaml` remains the main CI/CD control point
- Readiness, architecture, and evidence artifacts live in `_bmad-output/planning-artifacts/` and `docs/archives/...`
- The structure supports incremental migration: harden boundaries first, then progressively move legacy code out of `core/shared`, `core/utils`, and `core/widgets`
- This structure is intentionally stricter than the current repo, but it remains compatible with brownfield migration instead of demanding a full re-scaffold

## Architecture Validation Results

### Coherence Validation

**Decision Compatibility:**
The main choices are compatible with each other and do not create any obvious structural contradiction.

- The combination `Flutter + Riverpod + go_router + Supabase + sqflite + secure storage + Sentry` is coherent for a brownfield media application
- The `Riverpod` / `GetIt` coexistence remains acceptable because it is now explicitly bounded: `Riverpod` for UI state, `GetIt` for composition root and wiring only
- The decisions around `local-first`, `fail-closed`, `ports/adapters`, `typed failures`, and observable critical flows reinforce each other
- The `Android` + `Android TV` constraints are accounted for without blocking future evolution toward `iOS` and `Windows`
- No architecture choice requires a greenfield re-scaffold that would conflict with the current repository

**Pattern Consistency:**
The documented patterns support the architecture correctly.

- Naming conventions are precise enough to reduce implementation divergence between agents
- Structure and communication patterns align with `Riverpod`, adapters, repositories, and orchestrators
- Error handling, loading states, and `reasonCode` rules are coherent with the PRD's safety and observability requirements
- The anti-pattern list covers the most likely brownfield failure modes: locator in UI, forbidden imports, raw maps, and generic dumping grounds
- The examples are sufficient to guide the first implementation batches without major ambiguity

**Structure Alignment:**
The target structure supports the architecture decisions with enough precision for brownfield execution.

- The split between `core/`, `features/`, and `shared/` is now more defensible
- Missing PRD domains now have explicit target locations: `notifications` and `subscription`
- `test/` is defined as canonical and `tests/` as legacy debt
- `core/utils/` and `core/widgets/` are explicitly frozen to avoid drift into generic dumping grounds
- Structural debt still exists around `core/shared/` and some historical zones, but it is now treated as controlled migration rather than design ambiguity

### Requirements Coverage Validation

**Epic/Feature Coverage:**
The architecture covers the PRD domains more broadly than `epics.md`.

- `auth`, `startup`, `playback`, `resume`, `sync`, `parental`, `subscription`, `notifications`, `diagnostics`, and `TV` all have architectural support
- The architecture closes gaps left by the current plan by reserving explicit boundaries for `subscription/entitlement` and `notifications`
- The main remaining gap is in `epics.md`, which is still based on an older requirements inventory; this is now a planning gap, not an architecture gap

**Functional Requirements Coverage:**
The FR categories `FR1-FR40` are supported at the architecture level.

- `FR1-FR4` are covered through `startup`, `auth`, `router`, and `security`
- `FR5-FR10` are covered through discovery/navigation features and documented TV constraints
- `FR11-FR17` are covered through `player`, `playback`, `storage`, `network`, and sync-related boundaries
- `FR18-FR23` are covered through `profile`, `parental`, `preferences`, and `settings`
- `FR24-FR28` are covered through `core/subscription`, `features/subscription`, `supabase/functions`, and `supabase/migrations`
- `FR29-FR31` are covered through `core/notifications` and `features/notifications`
- `FR32-FR40` are covered through the `local-first` model, degraded states, observability, reporting, and traceability boundaries

**Non-Functional Requirements Coverage:**
The critical NFRs are addressed by the decisions and patterns.

- Performance is addressed through explicit budgets, bounded transitions, and priority on perceived performance
- Security and privacy are addressed through redaction by default, zero secrets/PII, and fail-closed sensitive decisions
- Reliability is addressed through timeouts, bounded retries, idempotence, and explicit `safe/degraded/recovered/failed` states
- TV and accessibility are addressed through visible focus, directional navigation, `10-foot UI` readability, and critical-path parity
- Evolvability is addressed through future compatibility with `iOS` and `Windows` without redefining the core contract
- Supportability is addressed through `operationId`, `reasonCode`, diagnostics, and evidence-based release gates

### Implementation Readiness Validation

**Decision Completeness:**
The critical decisions needed to avoid major implementation divergence are documented.

- The structuring choices for stack, state management, navigation, backend, persistence, and observability are explicit
- Fail-closed rules for `auth`, `parental`, and `entitlement` are clear enough to guide implementation
- Ports/adapters boundaries and import rules are concrete enough for implementation agents
- Recent version checks were performed for starters and major packages, without forcing unnecessary upgrades

**Structure Completeness:**
The structure is specific enough to guide implementation.

- The real repository layout was used as the basis, not a theoretical tree
- Missing target locations were defined without demanding a disruptive refactor
- Internal and external integration points are identified
- Test, tooling, Supabase, and CI/CD boundaries are documented

**Pattern Completeness:**
The patterns are complete enough to limit implementation conflicts, with some future refinements still useful.

- Naming and mapping conventions are sufficient
- Communication and state management patterns are complete for critical flows
- Process patterns cover errors, loading states, and architecture violations
- A future migration guide for `core/shared`, `core/utils`, and UI locator usage would still improve execution discipline

### Gap Analysis Results

**Critical Gaps:**
No critical internal architecture gap remains that would block creation of coherent technical work batches.

**Important Gaps:**
- No formal UX document exists yet to translate states, journeys, and mobile/TV differences into implementation-ready interaction rules
- `epics.md` still lags behind the current PRD and this architecture; story-to-FR traceability remains incomplete
- Brownfield migration for some legacy zones is not yet decomposed into a detailed execution plan
- The `notifications` and `subscription` domains are now placed correctly, but are not yet reflected in stories or detailed UX conventions

**Nice-to-Have Gaps:**
- A short ADR on the final `Riverpod vs GetIt` policy would help future reviews
- A guide to migrate legacy `tests/` material toward `test/` would be useful
- An index of legacy folders to reduce progressively would help future work batches

### Validation Issues Addressed

- Reduced ambiguity between `core/` and `features/` by defining their responsibilities more strictly
- Reduced ambiguity around `subscription` / `entitlement` by making `core/subscription/` the authority and `features/subscription/` the user-facing surface
- Added an explicit target for `notifications` on both system and product sides
- Reduced the risk of drift in `core/utils/` and `core/widgets/` through an explicit freeze
- Reduced test organization drift by declaring `test/` canonical and `tests/` obsolete
- Reduced DI inconsistency risk by limiting `GetIt` to `core/di/`

### Architecture Completeness Checklist

**Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**Implementation Patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR ARCHITECTURE HANDOFF, CONDITIONAL FOR FULL PRD IMPLEMENTATION

**Confidence Level:** medium

**Key Strengths:**
- Much clearer technical boundaries for a brownfield codebase
- Strong compatibility with the real repository and the existing Phase 4 work
- Good coverage of critical invariants: fail-closed behavior, observability, degraded states, and TV constraints
- Enough structure to prevent the most common implementation conflicts between agents
- Explicit target locations for PRD domains that were previously missing

**Areas for Future Enhancement:**
- Produce an implementation-ready mobile/TV UX specification
- Regenerate `epics.md` from the current PRD and this architecture
- Continue progressive cleanup of `core/shared`, `core/utils`, and `core/widgets`
- Reduce remaining historical UI locator usage
- Formalize a small brownfield migration plan for the most coupled legacy zones

### Implementation Handoff

**AI Agent Guidelines:**

- Follow all architecture decisions exactly as documented
- Use `Riverpod` for UI state and keep `GetIt` inside `core/di/`
- Respect `presentation -> application -> domain -> data` and `ARCH-R1..R5`
- Put new shared business code in `lib/src/shared/`, not in generic legacy folders
- Mirror every critical implementation under `test/`
- Preserve fail-closed behavior for `auth`, `parental`, and `entitlement`
- Keep all external IO behind adapters, repositories, or service boundaries

**First Implementation Priority:**
Consolidate the critical boundaries `core/startup`, `core/auth`, `core/storage`, `core/network`, `core/parental`, and `core/profile`, then open the target locations `core/subscription`, `features/subscription`, `core/notifications`, and `features/notifications` cleanly before extending the story set.

## Addendum 2026-04-03 - Entry Flow Runtime Contract

The approved course correction introduces a sharper runtime contract for app entry.

Architecture clarifications:
- split `startup readiness` from `entry decision`
- split `first useful state` from `background hydration`
- stop using `fully hydrated home` as the sole condition for entering the shell
- keep routing deterministic while allowing `home lite` when a safe useful state already exists

Approved target contract:
- `startup ready`: platform and app dependencies are initialized enough to render entry UX
- `entry decision`: auth, profile, source, and recovery destination are resolved
- `home lite ready`: a safe shell/home surface can render with local or partial data
- `home hydrated`: secondary rails, freshness checks, and library hydration are complete enough to remove degraded/pending states when applicable

Implications for architecture and implementation:
- `core/startup/` owns the state machine and timing checkpoints for `entry_flow`
- `core/router/` redirects according to explicit user-facing destination classes, not only technical preload phases
- `features/welcome/` owns entry surfaces as product states, not as thin wrappers around technical routes
- `features/home/` must support progressive hydration from `home lite` to hydrated home without forcing a second bootstrap corridor
- entry diagnostics must correlate `entry_flow_started`, `entry_destination_resolved`, `first_useful_state_visible`, and `home_hydrated`

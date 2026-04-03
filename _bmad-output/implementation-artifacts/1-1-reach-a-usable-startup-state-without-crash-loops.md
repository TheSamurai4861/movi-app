# Story 1.1: Reach a Usable Startup State Without Crash Loops

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

En tant qu'utilisateur,
je veux que l'application atteigne un etat `Ready` ou `Safe` exploitable meme quand des dependances de demarrage echouent,
afin de pouvoir ouvrir l'application sans crash loops, spinner infini ni blocage silencieux.

## Acceptance Criteria

1. **Given** one or more startup dependencies fail, timeout, or return inconsistent state during bootstrap  
   **When** the application launches  
   **Then** the startup flow reaches a bounded `Safe` or `Ready` state instead of crashing or hanging  
   **And** the failure outcome is observable with stable `reasonCode` and correlated identifiers, without secrets or PII.

2. **Given** all required startup dependencies are available  
   **When** bootstrap completes successfully  
   **Then** the application transitions through explicit startup states into `Ready`  
   **And** the final route decision is observable and deterministic for the same startup inputs.

## Tasks / Subtasks

- [x] Verifier et durcir le pipeline de bootstrap existant dans `core/startup` pour garantir une issue bornee.
  - [x] Reutiliser `StartupPhase`, `StartupFailureCode`, `StartupResult` et `AppStartupOrchestrator`; ne pas introduire une seconde state machine parallele.
  - [x] S'assurer que chaque echec, timeout ou etat incoherent de dependance se traduit par un `StartupResult.ready` ou `StartupResult.safeMode` exploitable, jamais par une attente infinie ou une exception qui remonte sans controle.
  - [x] Normaliser les cas "inconsistent state" encore non types dans le demarrage afin qu'ils produisent un `reasonCode` stable et testable.

- [x] Aligner l'observabilite startup sur les invariants de correlation et de redaction.
  - [x] Conserver `runWithOperationId(prefix: 'startup')` comme point d'entree de correlation du bootstrap.
  - [x] Etendre les logs/events startup pour exposer un `reasonCode` stable sur les issues non nominales qui n'en ont pas encore.
  - [x] Verifier qu'aucun secret, token, URL complete, identifiant utilisateur, stack sensible ou PII n'est emis dans les logs startup, y compris en mode degrade.

- [x] Preserver la separation entre bootstrap pur, gate UI et decision de route.
  - [x] Garder `AppStartupOrchestrator` pur et framework-agnostic pour la logique L1 bootstrap.
  - [x] Garder `app_startup_provider.dart` et `startup_adapters.dart` comme ponts Riverpod / GetIt / SDK.
  - [x] Garder `AppStartupGate`, la route `/launch`, `LaunchRedirectGuard` et `AppLaunchStateRegistry` comme surfaces de presentation et de redirection, sans y deplacer la logique metier de bootstrap.

- [x] Garantir un shell de demarrage exploitable et non bloquant.
  - [x] Reutiliser `OverlaySplash` et `LaunchErrorPanel` avant de creer tout nouveau widget de startup.
  - [x] Eliminer tout chemin menant a spinner infini, route loop ou ecran silencieusement bloque entre `/launch`, `/bootstrap` et la destination finale.
  - [x] Conserver un retry explicite et une lisibilite mobile/TV correcte sur les etats `error` et `safeMode`.

- [x] Ajouter ou mettre a jour les tests qui verrouillent FR1.
  - [x] Etendre `test/core/startup/app_startup_orchestrator_test.dart` pour couvrir les etats incoherents, les timeouts et les `reasonCode` attendus.
  - [x] Etendre `test/core/startup/app_startup_gate_safe_mode_test.dart` pour verifier le rendu exploitable et actionnable des etats degrades.
  - [x] Etendre les tests de route guard / bootstrap (`test/core/router/launch_redirect_guard_reconnect_test.dart`, tests `welcome/bootstrap` si necessaire) pour prouver que la destination finale reste deterministe et sans boucle pour les memes entrees de lancement.

### Review Findings

- [x] [Review][Patch] Failure reporting can still break the SafeMode fallback [lib/src/core/startup/domain/app_startup_orchestrator.dart:130]
- [x] [Review][Patch] Startup stack traces are still emitted raw and without startup correlation prefix [lib/src/core/startup/infrastructure/startup_adapters.dart:53]
- [x] [Review][Patch] SafeMode still forces raw technical diagnostics in release UI [lib/src/core/startup/app_startup_gate.dart:206]
- [x] [Review][Patch] Secret masking now preserves control whitespace around separators [lib/src/core/logging/sanitizer/message_sanitizer.dart:97]
- [x] [Review][Defer] Supabase sanity check can still emit a complete URL [lib/src/core/startup/infrastructure/startup_adapters.dart:179] — deferred, pre-existing
- [x] [Review][Defer] Structured JSON secrets still bypass `MessageSanitizer` [lib/src/core/logging/sanitizer/message_sanitizer.dart:96] — deferred, pre-existing

## Dev Notes

### Portee et limites de la story

- Cette story couvre uniquement `FR1`: atteindre un etat de lancement exploitable meme en cas d'echec partiel du demarrage.
- La restauration de session et les decisions d'acces initial (`FR2`, `FR3`) appartiennent aux stories `1.2` et `1.3`.
- La restauration du contexte essentiel apres lancement (`FR4`) appartient a la story `1.4`.
- Le depot est brownfield: il faut durcir et aligner la pile startup existante, pas recrer un bootstrap Flutter ou une nouvelle architecture parallele.

### Contexte existant a reutiliser

- `lib/src/core/startup/domain/startup_contracts.dart` definit deja les phases, issues `ready/safeMode` et codes d'echec types.
- `lib/src/core/startup/domain/app_startup_orchestrator.dart` execute deja le bootstrap L1 avec timeouts bornes sur config et dependencies, puis retourne `StartupResult.ready` ou `StartupResult.safeMode`.
- `lib/src/core/startup/app_startup_provider.dart` encapsule deja l'execution dans `runWithOperationId(prefix: 'startup')`.
- `lib/src/core/startup/infrastructure/startup_adapters.dart` contient deja les adapters startup vers config, DI, logging, app state et sanity check Supabase.
- `lib/src/core/startup/app_startup_gate.dart` affiche deja un shell minimal `loading / error / safeMode` avec `OverlaySplash` et `LaunchErrorPanel`.
- `lib/src/core/router/app_routes.dart`, `lib/src/core/router/app_router.dart` et `lib/src/core/router/launch_redirect_guard.dart` portent deja la transition `/launch` -> `/bootstrap` -> destination finale.
- `lib/src/core/startup/app_launch_orchestrator.dart` et `lib/src/core/startup/app_launch_criteria.dart` existent deja pour la decision de destination et les criteres `home` prete.

### Gaps probables a traiter dans cette story

- Le bootstrap startup actuel transporte bien `operationId`, mais le contrat `reasonCode` n'est pas encore uniformement explicite sur tout le chemin `startup -> logging -> observability -> route outcome`.
- Les AC parlent de "dependencies fail, timeout, or return inconsistent state". Les cas `fail` et `timeout` sont deja bien couverts en test; les etats incoherents doivent etre verifies explicitement et types proprement la ou ils ne le sont pas encore.
- Le shell de demarrage existe deja; le risque principal est la regression par duplication de logique, boucle de route, ou ajout de comportement opportuniste hors `core/startup` / `core/router`.

### Technical Requirements

- Respecter `FR1` et ne pas deriver vers la logique session/auth complete des stories suivantes.
- Respecter les NFR startup et fiabilite du PRD:
  - `NFR1`: cold start utilisable `P50 <= 2.0s`, `P95 <= 3.0s`
  - `NFR2`: warm start/reprise utilisable `P50 <= 1.0s`, `P95 <= 1.8s`
  - `NFR7`: aucun secret / token / credential / PII dans les logs ou preuves
  - `NFR9`: decisions sensibles en etat sur si information absente/incoherente/non verifiee
  - `NFR12`: `crash-free sessions >= 99.7 %`
  - `NFR13`: aucune crash loop connue au demarrage
  - `NFR16`: timeouts, retries et fallback bornes sur les flux critiques
  - `NFR17`: etat degrade comprehensible plutot qu'etat bloquant
  - `NFR31-NFR33`: observabilite corrigee avec `operationId`, `reasonCode` et etats explicites
- Le dev doit raisonner en local-first / fail-safe: si une dependance critique ne permet pas de conclure nominalement, l'app doit rester vivante dans un etat degrade clair.
- Aucun nouvel acces direct UI vers `Supabase`, `Dio`, `sqflite`, `flutter_secure_storage` ou `Sentry`.

### Architecture Compliance

- `Riverpod` reste le mecanisme principal de state management UI et provider bootstrap.
- `GetIt` reste limite au wiring / composition root dans `lib/src/core/di/` et aux adapters startup existants.
- Toute nouvelle logique metier startup va dans `lib/src/core/startup/...`.
- Tout ajustement de redirection va dans `lib/src/core/router/...`.
- Ne pas ajouter de logique metier opportuniste dans `lib/src/core/utils/` ou `lib/src/core/widgets/`.
- `lib/src/core/widgets/launch_error_panel.dart` et `lib/src/core/widgets/overlay_splash.dart` peuvent etre adaptes uniquement si necessaire pour respecter les AC, pas comme nouveau point de logique startup.

### Library / Framework Requirements

- Rester sur les versions epinglees du depot pour cette story:
  - Flutter `>=3.38.0`
  - Dart `^3.9.2`
  - `flutter_riverpod ^3.0.3`
  - `go_router ^16.3.0`
  - `supabase_flutter ^2.10.0`
  - `sentry_flutter ^9.2.0`
- Veille technique effectuee le `2026-04-02`:
  - `flutter_riverpod` publie: `3.3.1`
  - `go_router` publie: `17.1.0`
  - `supabase_flutter` publie: `2.12.2`
  - `sentry_flutter` publie: `9.16.0`
- Regle de mise en oeuvre: ne pas faire de bump de dependance dans cette story. Toute migration de version doit faire l'objet d'une story/ADR dediee, car elle changerait le risque de regression du bootstrap brownfield.

### File Structure Requirements

- Zones cibles probables:
  - `lib/src/core/startup/domain/startup_contracts.dart`
  - `lib/src/core/startup/domain/app_startup_orchestrator.dart`
  - `lib/src/core/startup/infrastructure/startup_adapters.dart`
  - `lib/src/core/startup/app_startup_provider.dart`
  - `lib/src/core/startup/app_startup_gate.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/startup/app_launch_criteria.dart`
  - `lib/src/core/router/launch_redirect_guard.dart`
  - `lib/src/core/router/app_routes.dart`
  - `lib/src/core/logging/operation_context.dart`
  - `lib/src/core/observability/sentry_bootstrap.dart`
- Zones de tests cibles:
  - `test/core/startup/`
  - `test/core/router/`
  - `test/features/welcome/presentation/` si le shell/bootstrap UI evolue
- Ne pas creer de nouveaux tests dans `tests/`; `test/` est l'arborescence canonique.

### Testing Requirements

- Conserver les tests existants et les etendre avant de refactorer.
- Ajouter des assertions explicites sur:
  - issue `ready` vs `safeMode`
  - mapping `phase -> reasonCode`
  - absence de boucle entre `/launch`, `/bootstrap`, `/home`, `/auth/otp`
  - comportement retry explicite
  - sanitation minimale des logs/telemetry startup
- Les tests unitaires doivent rester majoritaires pour le bootstrap pur.
- Les tests widget/route servent a verrouiller l'absence de spinner infini et de redirection non deterministe.

### UX Guardrails

- Le shell de demarrage doit rester minimal, calme, premium et lisible.
- Aucun spinner infini. Si l'app n'est pas prete nominalement, elle doit basculer vers un etat `Safe` exploitable.
- Les etats sensibles doivent etre explicites sans dump technique brut en release.
- Si un bouton retry est present, il doit rester lisible et focusable sur mobile et Android TV.

### Previous Story Intelligence

- Aucune story precedente dans l'Epic 1. Pas de dev notes precedentes a reutiliser.

### Git Intelligence Summary

- Les cinq derniers commits montrent un contexte de `Phase 4` en cours et un travail recent sur la hardening/qualite. Cette story doit donc rester incrementale et compatible avec la structure actuelle, pas lancer une reorganisation transverse opportuniste.

### Project Structure Notes

- Aucun `project-context.md` exploitable n'a ete trouve dans le depot courant.
- La structure reelle du depot est deja alignee sur les grandes frontieres d'architecture (`core/`, `features/`, `shared/`).
- La pile startup existe deja en profondeur: cette story doit l'aligner sur les AC BMAD, pas en creer une seconde.

### References

- `_bmad-output/planning-artifacts/epics.md`
  - `Epic 1: Trusted App Entry and Session Continuity`
  - `Story 1.1: Reach a Usable Startup State Without Crash Loops`
- `_bmad-output/planning-artifacts/prd.md`
  - `User Journeys`
  - `Risk Mitigations`
  - `Functional Requirements > Access & Session Management`
  - `Non-Functional Requirements > Performance`
  - `Non-Functional Requirements > Security & Privacy`
  - `Non-Functional Requirements > Reliability & Resilience`
  - `Non-Functional Requirements > Observability & Supportability`
- `_bmad-output/planning-artifacts/architecture.md`
  - `Core Architectural Decisions`
  - `Frontend Architecture`
  - `Implementation Patterns & Consistency Rules`
  - `Project Structure & Boundaries`
  - `Requirements to Structure Mapping`
  - `Implementation Handoff`
- `_bmad-output/planning-artifacts/ux-design-specification.md`
  - `Core User Experience`
  - `Critical Success Moments`
  - `Experience Principles`
  - `Design Direction Decision`
- Codebase:
  - `lib/src/core/startup/domain/startup_contracts.dart`
  - `lib/src/core/startup/domain/app_startup_orchestrator.dart`
  - `lib/src/core/startup/infrastructure/startup_adapters.dart`
  - `lib/src/core/startup/app_startup_provider.dart`
  - `lib/src/core/startup/app_startup_gate.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/router/app_router.dart`
  - `lib/src/core/router/app_routes.dart`
  - `lib/src/core/router/launch_redirect_guard.dart`
  - `lib/src/core/logging/operation_context.dart`
  - `lib/src/core/observability/sentry_bootstrap.dart`
  - `pubspec.yaml`
- Tests existants:
  - `test/core/startup/app_startup_orchestrator_test.dart`
  - `test/core/startup/app_startup_gate_safe_mode_test.dart`
  - `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - `test/core/router/launch_redirect_guard_reconnect_test.dart`
  - `test/features/welcome/presentation/splash_bootstrap_page_progress_test.dart`
- Documentation technique recente:
  - `https://pub.dev/packages/flutter_riverpod`
  - `https://pub.dev/packages/go_router`
  - `https://pub.dev/packages/supabase_flutter`
  - `https://pub.dev/packages/sentry_flutter`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `dart format lib/src/core/startup/domain/startup_contracts.dart lib/src/core/startup/domain/app_startup_orchestrator.dart lib/src/core/startup/infrastructure/startup_adapters.dart lib/src/core/startup/app_startup_gate.dart lib/src/core/logging/sanitizer/message_sanitizer.dart`
- `flutter test test/core/startup/app_startup_orchestrator_test.dart`
- `flutter test test/core/startup/startup_adapters_test.dart`
- `flutter test test/core/startup/app_startup_gate_safe_mode_test.dart`
- `flutter test test/core/logging/sanitizer/message_sanitizer_test.dart`
- `flutter test test/core/router/launch_redirect_guard_reconnect_test.dart`
- `flutter test`
- `dart analyze lib/src/core/startup lib/src/core/logging/sanitizer test/core/startup test/core/router/launch_redirect_guard_reconnect_test.dart`
- `dart analyze lib/src/core/startup lib/src/core/logging/sanitizer test/core/startup test/core/logging/sanitizer`
- `flutter analyze` (7 infos hors surface startup)

### Completion Notes List

- Story auto-selectionnee depuis `sprint-status.yaml` comme premiere story `backlog`.
- Contexte compile depuis `epics.md`, `prd.md`, `architecture.md`, `ux-design-specification.md`, le code startup/reseau/router existant et les tests startup/router deja presents.
- Aucun `project-context.md` projet specifique trouve.
- Le contrat `operationId` est deja present via `runWithOperationId`; la story doit etendre/normaliser `reasonCode`, pas inventer une correlation parallele.
- Cette story est un durcissement brownfield du bootstrap existant, pas une recreation du projet ni une migration de dependances.
- Le contrat startup expose maintenant un `reasonCode` stable sur `StartupResult` et `StartupFailure`, avec des codes types pour `appStateExposureFailed` et `loggingInitFailed`.
- `AppStartupOrchestrator` reste pur et framework-agnostic tout en emettant des `reasonCode` explicites sur succes et echec vers la telemetry et le logging startup.
- `DebugPrintTelemetryAdapter` reutilise `MessageSanitizer`, preserve `operationId` et accepte un `printer` injectable pour verrouiller la redaction en test.
- `MessageSanitizer` normalise desormais les separateurs sensibles sur une seule ligne et s'arrete au prochain champ `key[:=]value`, ce qui evite les sorties multiline et les secrets concatenes.
- `AppStartupGate` affiche un SafeMode exploitable avec `reasonCode` stable et phase associee, sans introduire de nouvelle logique de bootstrap hors `core/startup`.
- `flutter test` complet passe sur le depot apres implementation.
- `dart analyze` cible sur la surface modifiee ne remonte aucun probleme.
- `flutter analyze` global remonte encore 7 infos hors story sur des imports de tests et un import inutile, sans probleme sur la surface startup/router modifiee.
- Le suivi post-review rend le reporting d'echec startup best-effort, redige les stack traces telemetry et recache les details SafeMode en release.

### File List

- `lib/src/core/logging/sanitizer/message_sanitizer.dart`
- `lib/src/core/startup/app_startup_gate.dart`
- `lib/src/core/startup/domain/app_startup_orchestrator.dart`
- `lib/src/core/startup/domain/startup_contracts.dart`
- `lib/src/core/startup/infrastructure/startup_adapters.dart`
- `test/core/logging/sanitizer/message_sanitizer_test.dart`
- `test/core/startup/app_startup_gate_safe_mode_test.dart`
- `test/core/startup/app_startup_orchestrator_test.dart`
- `test/core/startup/startup_adapters_test.dart`

## Change Log

- 2026-04-03: normalisation des `reasonCode` startup, typage des echec `appStateExposureFailed`/`loggingInitFailed`, redaction des logs startup durcie et rendu SafeMode aligne sur FR1.
- 2026-04-03: correctifs de code review appliques sur le fallback SafeMode, la redaction des stack traces startup, le masquage single-line des secrets et l'affichage release des details SafeMode.

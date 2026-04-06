# Sprint Change Proposal - Entry Flow Reframe

**Project:** movi  
**Date:** 2026-04-03  
**Mode:** Incremental  
**Change scope:** Moderate  
**Recommended path:** Hybrid of Option 1 (direct adjustment) + selective epic resequencing, without rollback of completed work

## 1. Issue Summary

### Trigger

Inference from current sprint context: the recadrage is triggered by Epic 1 implementation, especially Story 1.3 review, plus a broader realization that the current welcome / auth / sources / entry flow no longer matches the product ambition stated in the PRD, UX spec, and architecture.

### Core Problem Statement

The current entry system is technically more robust than before, but it remains organized around technical routes and preload constraints rather than around a single user-facing "first useful state" contract.

This creates four product-level problems:

1. The launch flow is split across multiple technical surfaces (`AppStartupGate`, `/launch`, `/bootstrap`, `/welcome/*`, `/auth/otp`) with overlapping loading/error roles.
2. The runtime definition of "home ready" is too strict for perceived performance because it blocks on IPTV catalog readiness, home preload, and library preload before allowing home.
3. Auth recovery, source recovery, and degraded/offline behavior are present in code but not surfaced as a coherent screen-by-screen UX system.
4. Android TV is treated as first-class in the shell, but the entry flow screens are still largely mobile-form surfaces with limited TV-specific focus and navigation treatment.

### Evidence

- Startup already has a dedicated loading / error / safe-mode gate before the main app renders: [lib/src/core/startup/app_startup_gate.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_startup_gate.dart#L26), [lib/src/core/startup/app_startup_gate.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_startup_gate.dart#L51), [lib/src/core/startup/app_startup_gate.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_startup_gate.dart#L78).
- Bootstrap adds a second loading/error surface on top of that: [lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart#L18), [lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart#L39).
- Router redirection is centered on technical launch routes and keeps `/home` inside critical routing: [lib/src/core/router/route_catalog.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/route_catalog.dart#L4), [lib/src/core/router/launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart#L81), [lib/src/core/router/launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart#L127).
- The guard treats auth as unresolved for up to 4 seconds, then falls back to auth-state routing: [lib/src/core/router/launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart#L66), [lib/src/core/router/launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart#L209).
- The launch orchestrator blocks home behind profile resolution, source resolution, IPTV preload, home preload, and library preload: [lib/src/core/startup/app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart#L566), [lib/src/core/startup/app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart#L675), [lib/src/core/startup/app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart#L777), [lib/src/core/startup/app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart#L839), [lib/src/core/startup/app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart#L892).
- `isHomeReady` requires `selectedProfile + selectedSource + iptvCatalogReady + homePreloaded + libraryReady`, which is too strict for first useful paint: [lib/src/core/startup/app_launch_criteria.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_criteria.dart#L18).
- `WelcomeUserPage` silently auto-pushes OTP when unauthenticated instead of making auth state an explicit first-class decision screen: [lib/src/features/welcome/presentation/pages/welcome_user_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_user_page.dart#L116).
- `WelcomeSourceLoadingPage` duplicates catalog loading and home warmup outside the main launch orchestration, then allows "Continue anyway": [lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart#L54), [lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart#L159), [lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart#L199).
- Entry screens are mostly narrow form layouts, while TV-specific navigation discipline is primarily in the shell: [lib/src/features/auth/presentation/auth_otp_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/auth/presentation/auth_otp_page.dart#L87), [lib/src/features/welcome/presentation/pages/welcome_user_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_user_page.dart#L141), [lib/src/features/shell/presentation/pages/app_shell_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/shell/presentation/pages/app_shell_page.dart#L135).

## 2. Checklist Status

- [x] 1.1 Trigger identified: Story 1.3 implementation/review exposed broader entry-flow debt.
- [x] 1.2 Core problem defined: failed approach at UX orchestration level, not at low-level reliability primitives.
- [x] 1.3 Evidence gathered from code, PRD, UX, architecture, epics, and sprint status.
- [x] 2.1 Epic 1 remains viable but its scope is currently too narrow around session continuity.
- [x] 2.2 Epic-level changes needed: expand Epic 1, pull selected concerns from Epic 2/7/8 earlier.
- [x] 2.3 Future epics affected: Epic 2, Epic 7, Epic 8.
- [x] 2.4 No existing epic becomes obsolete; no full replan required.
- [x] 2.5 Priority/order should change: entry-home, degraded states, and observability must move earlier.
- [x] 3.1 PRD impacted.
- [x] 3.2 Architecture impacted.
- [x] 3.3 UX spec impacted.
- [x] 3.4 Secondary artifacts impacted: sprint plan, test strategy, observability evidence, performance evidence.
- [x] 4.1 Direct adjustment viable with targeted story additions and resequencing.
- [ ] 4.2 Rollback not recommended.
- [ ] 4.3 MVP reduction not required.
- [x] 4.4 Recommended path selected.
- [x] 5.1-5.5 Proposal components drafted below.
- [x] 6.1-6.2 Proposal reviewed for consistency.
- [!] 6.3 Explicit approval pending.
- [N/A] 6.4 `sprint-status.yaml` not updated yet; should happen only after approval.
- [!] 6.5 Handoff confirmed in proposal, pending approval.

## 3. Impact Analysis

### Epic Impact

#### Epic 1

Epic 1 should evolve from "trusted app entry and session continuity" to "trusted app entry, access recovery, and first useful state".

Reason:
- It already owns startup, auth, session restore, and initial context.
- The real gap is not only session correctness; it is the contract between correctness and the first useful surface shown to the user.

#### Epic 2

Epic 2 is directly impacted because the first useful surface after launch is functionally the discovery home, not a separate concern. Story 2.1 cannot stay fully downstream if entry-home behavior is a top priority.

#### Epic 7

Epic 7 concerns must move earlier because degraded/offline entry behavior is part of the launch path, not an afterthought. The app currently has some degraded logic but not a unified degraded UX contract.

#### Epic 8

Epic 8 concerns must move earlier because performance measurement, reason codes, and explicit safe/degraded/recovered classifications are required to validate the new entry flow.

### Story / Sprint Impact

Current sprint status suggests:
- `1-1` and `1-2` remain valid and should be preserved.
- `1-3` remains valid but should be widened into a user-facing recovery model, not just a session-state edge case.
- `1-4` should be rewritten before implementation because "restore essential context" must now include first useful state targeting.

### Artifact Conflicts

#### PRD conflict

The PRD promises "ouvrir l'app et atteindre un ecran utile presque immediatement" and emphasizes safe/degraded states and deterministic runtime. The current runtime definition of home readiness is stricter than that promise because it blocks on full preload before the main surface is reachable.

#### Architecture conflict

The architecture says routing must be observable, deterministic, and coherent with startup/auth. That is true at the decision level, but the current orchestration still conflates:
- route resolution
- full data warmup
- first useful state

Those need to become distinct contracts.

#### UX conflict

The UX spec emphasizes calm trust, explicit sensitive states, TV-first clarity, and quick arrival at a useful screen. The implemented entry flow still shows mostly technical progress surfaces and form-heavy pages rather than a unified entry UX system.

### Secondary Artifact Impact

- `epics.md`: story scope and sequencing updates.
- `sprint-status.yaml`: likely add new ready/backlog story IDs after approval.
- test strategy: new widget/integration/perf suites for entry flow.
- evidence artifacts: add performance and observability traces for startup/auth/source/home.

## 4. Option Evaluation

### Option 1 - Direct Adjustment

Viability: Yes  
Effort: Medium  
Risk: Medium

Why it works:
- Stories 1.1 and 1.2 already created useful primitives.
- The main need is to flatten orchestration and refactor UX contracts, not to delete the current reliability work.

### Option 2 - Potential Rollback

Viability: No  
Effort: High  
Risk: High

Why not:
- Existing startup/auth hardening is useful and aligned with the PRD.
- Rollback would remove runtime safety without solving the real UX and contract problem.

### Option 3 - PRD MVP Review

Viability: Not required  
Effort: Medium  
Risk: Medium

Why not:
- The MVP remains achievable.
- The issue is sequencing and UX/runtime contract clarity, not excessive scope.

### Recommended Path

Hybrid:
- Keep Epic 1 implementation momentum.
- Expand Epic 1 scope.
- Pull a minimal subset of Epic 2, Epic 7, and Epic 8 concerns into the entry-flow track now.
- Do not rewrite the app from scratch.

## 5. Recommended UX Target Order

### Target Principle

The system should resolve to a single user-facing contract:

`App opened -> first useful state resolved -> secondary hydration continues in background or via explicit bounded recovery`

The product should stop treating "full home preload complete" as the only valid definition of usable entry.

### Target Order, Screen by Screen

#### 1. Native Splash

Keep platform splash minimal and short.

Purpose:
- OS handoff only.

#### 2. Entry Bootstrap Surface

Replace the current perception of separate `startup` and `bootstrap` screens with one branded entry surface.

Shown while:
- app dependencies initialize
- launch state machine resolves auth/profile/source/home-lite destination

Rules:
- no technical route exposure to the user
- message stays simple
- after bounded wait, show explicit next state, not silent continuation

#### 3. Auth Recovery / Sign-In Decision

This becomes a full screen in the entry system, not an automatic push from Welcome User.

Shown when:
- session expired
- session invalid
- cloud auth required
- reauth explicitly needed

Must show:
- current status
- why user is here
- primary action
- alternate safe path if degraded local continuation is allowed

#### 4. Profile Decision Screen

This screen should handle:
- no profile yet
- choose profile
- recover stale profile

It should not double as hidden auth redirection logic.

#### 5. Source Hub

Unify current source-add and source-recovery states into a single source hub.

It should support:
- no source yet
- one source restorable
- multiple sources, choose active
- degraded source verification
- add or repair source

#### 6. Source Warmup / Catalog Recovery

Keep a source-loading step only when needed, and reframe it as bounded warmup rather than a mandatory blocking corridor.

Rules:
- if local snapshot exists, continue to home-lite and keep sync in background
- if no usable local snapshot exists, keep warmup screen with bounded retry and explicit fallback
- no hidden duplication with launch orchestration

#### 7. Home Lite

This should be the first useful post-session surface.

Home Lite contains:
- shell already mounted
- active profile and active source visible
- continue-watching / resume priority slot
- local snapshot sections and skeletons
- clear degraded / offline / pending-sync banner when needed

Home Lite does not wait for:
- full IPTV refresh
- full library readiness
- full secondary rails hydration

#### 8. Home Hydrated

Secondary data arrives progressively:
- richer rails
- library state
- remote freshness confirmation
- contextual promotions

The user should remain in the same shell/context while hydration completes.

### Screen-by-Screen UI Refactor Guidance

#### `AppStartupGate` + `SplashBootstrapPage`

Current:
- two technical loading/error surfaces.

Target:
- one entry surface pattern with clear stage model and a single UX vocabulary.

#### `AuthOtpPage`

Current:
- good functional OTP flow, but visually still a narrow form page.

Target:
- explicit entry-auth screen with recovery banner, state explanation, and TV-safe focus path.

#### `WelcomeUserPage`

Current:
- mixed responsibility: profile bootstrap + hidden auth detour.

Target:
- pure profile decision/create screen.

#### `WelcomeSourcePage`

Current:
- primarily add/connect form.

Target:
- source hub with distinct states: add, repair, restore, choose, continue degraded.

#### `WelcomeSourceSelectPage`

Current:
- useful source choice step.

Target:
- keep it, but enrich with active-state explanation, last-used/freshness, and TV-first focus order.

#### `WelcomeSourceLoadingPage`

Current:
- duplicate preload corridor.

Target:
- bounded warmup/recovery step only when truly required, or fold into Home Lite background hydration.

#### `Home`

Current:
- mounted only when strict preload criteria are met.

Target:
- becomes the first useful state quickly, with progressive hydration.

## 6. Detailed Change Proposals

### PRD Changes

#### PRD Section: Technical Success / Measurable Outcomes / Offline Mode

OLD:
- fast launch to usable screen
- degraded mode expectations
- evidence-based validation on startup/auth/playback/sync

NEW:
- add a distinct contract for `first useful state`
- separate `first useful state` from `fully hydrated home`
- require entry-flow degraded states to be explicit for `expired`, `offline`, `timeout`, `blocked`, `pending-sync`, `recovered`
- add Android TV-specific validation for the entry flow itself, not only discovery/detail

Rationale:
- The current PRD intention is right; it needs sharper runtime language and measurable checkpoints.

#### PRD Section: MVP Scope

OLD:
- startup, auth, session restore, navigation, playback, sync

NEW:
- explicitly include `first useful home`, `entry-state UX`, and `degraded entry recovery` in MVP quality gates

Rationale:
- These are now product-critical, not polish.

### UX Specification Changes

#### UX Section: Core User Experience / Critical Success Moments

OLD:
- opening should reach useful screen rapidly

NEW:
- define a canonical entry-flow sequence and state vocabulary
- specify screen-level contracts for:
  - startup
  - auth recovery
  - profile decision
  - source hub
  - source warmup
  - home lite
  - home hydrated

Rationale:
- The UX spec currently states principles well but does not fully specify the entry flow as a designed system.

#### UX Section: Android TV

OLD:
- TV treated as first-class on discovery/detail

NEW:
- extend TV-first requirements to auth, profile, source, error, timeout, offline, and recovery states

Rationale:
- Entry flow is still a mobile-first interaction zone.

### Architecture Changes

#### Architecture Section: Routing / Startup / Component Boundaries

OLD:
- startup orchestrates launch -> auth gate -> parental gate -> profile restore -> entitlement gate

NEW:
- split architecture into:
  - `startup readiness`
  - `entry decision`
  - `first useful state`
  - `background hydration`
- redefine home readiness contract into:
  - `homeLiteReady`
  - `homeHydrated`
- keep route redirection deterministic, but stop using full warmup completion as the sole gateway to home

Rationale:
- This resolves the current coupling between correctness and perceived performance.

### Epic Changes

#### Epic 1

OLD:
- Trusted App Entry and Session Continuity

NEW:
- Trusted App Entry, Access Recovery, and First Useful State

Rationale:
- better matches actual product need

#### Story 1.3

OLD:
- recover from expired/offline/timeout session states

NEW:
- recover from expired/offline/timeout session states with explicit user-facing recovery states and bounded re-entry paths

Rationale:
- turns a technical recovery story into a UX/runtime contract story

#### Story 1.4

OLD:
- restore essential context after launch

NEW:
- restore essential context into the correct first useful state, then hydrate secondary context in background without bypassing safety gates

Rationale:
- aligns context restore with perceived performance and determinism

#### Proposed New Story 1.5

Title:
- Resolve the Entry Flow Into a Single First Useful State Contract

Scope:
- unify launch decision model
- remove duplicate blocking corridors
- introduce `homeLiteReady`

#### Proposed New Story 1.6

Title:
- Surface Explicit Entry States for Empty, Loading, Error, Timeout, Offline, Expired, and Recovered Conditions

Scope:
- screen states and transitions
- shared state vocabulary
- user-facing next actions

#### Proposed New Story 1.7

Title:
- Make Entry Flow Fully Usable on Android TV

Scope:
- focus order
- remote navigation
- 10-foot readability
- parity for startup/auth/source/error screens

#### Epic 2 Adjustment

Modify Story 2.1:
- discovery home must support `home lite` and progressive hydration from entry flow

#### Epic 7 Adjustment

Pull forward part of Story 7.1 and 7.2:
- degraded entry states become entry-flow acceptance criteria, not only sync/story concerns

#### Epic 8 Adjustment

Pull forward part of Story 8.1:
- entry flow must emit one correlated operation scope with explicit outcome classification and measurement timestamps

## 7. Implementation Plan by Lots

### Lot 0 - Audit and Contract Freeze

Deliverables:
- entry-flow state map
- old-to-new route/state mapping
- event taxonomy for entry outcomes
- baseline performance measurements

Goal:
- freeze contracts before refactor

### Lot 1 - Runtime Contract Refactor

Scope:
- separate `startup ready` from `entry decision`
- introduce `first useful state` contract
- split `homeLiteReady` from `homeHydrated`
- remove duplicate responsibility between launch orchestrator and source-loading screen

Primary files likely touched:
- `lib/src/core/startup/*`
- `lib/src/core/router/*`
- `lib/src/features/welcome/presentation/providers/*`

### Lot 2 - Entry UX Refactor

Scope:
- redesign startup/auth/profile/source screens as a single entry system
- make recovery states explicit
- remove hidden auth detours

Primary files likely touched:
- `lib/src/features/auth/presentation/*`
- `lib/src/features/welcome/presentation/pages/*`
- `lib/src/features/welcome/presentation/widgets/*`

### Lot 3 - Home Lite and Progressive Hydration

Scope:
- mount shell/home earlier
- show local snapshot + skeletons
- hydrate secondary content in background
- attach degraded banners without blocking the shell

Primary files likely touched:
- `lib/src/features/home/*`
- `lib/src/features/shell/*`
- `lib/src/core/startup/*`

### Lot 4 - Android TV Entry Hardening

Scope:
- focus choreography for auth/profile/source/recovery surfaces
- remote-safe primary actions
- readability and spacing adjustments

Primary files likely touched:
- entry screens
- reusable focus/navigation widgets

### Lot 5 - Observability, Perf, and Release Gates

Scope:
- entry-flow performance spans
- stable reason codes and outcome classes
- evidence artifacts for Android low/mid/TV devices

## 8. Performance and Measurement Strategy

### Performance Budgets

Retain PRD budgets, but add entry-flow checkpoints:

- cold start -> first useful state visible:
  - P50 <= 2.0s
  - P95 <= 3.0s
- warm start -> first useful state visible:
  - P50 <= 1.0s
  - P95 <= 1.8s
- first useful state -> home hydrated:
  - P50 <= 1.5s additional on stable network
  - P95 <= 3.0s additional on stable network
- auth recovery decision visible after unresolved auth:
  - <= 1.5s target
  - hard bounded fallback before 4.0s
- source selection -> source warmup result or home-lite fallback:
  - P50 <= 2.5s
  - P95 <= 5.0s

### Measurement Points

Instrument at least:

- `entry_flow_started`
- `startup_ready`
- `auth_resolution_started`
- `auth_resolution_finished`
- `entry_destination_resolved`
- `first_useful_state_visible`
- `home_lite_visible`
- `home_hydrated`
- `source_warmup_started`
- `source_warmup_finished`
- `entry_recovery_action_selected`

### Device Matrix

Validate on:
- Android low-end reference
- Android mid-range reference
- Android TV reference

## 9. Observability Strategy

### Required Runtime Model

Every launch flow should carry:
- `entryFlowOperationId`
- `reasonCode`
- `outcomeClass`
- `safeStateClass`
- timing checkpoints

### Outcome Classes

Use explicit classes:
- `ready`
- `ready_degraded`
- `blocked_reauth`
- `blocked_source_setup`
- `failed_retryable`
- `failed_support_required`

### Minimum Diagnostics

For each transition, emit:
- previous state
- next state
- trigger
- elapsedMs
- safe/degraded/recovered/failed classification

No secrets, tokens, URLs with credentials, or PII.

## 10. Validation and Test Strategy

### Unit Tests

- state machine transition tests for entry decision
- mapping tests from auth/profile/source inputs to destination
- timeout and retry policy tests
- outcome classification tests

### Widget Tests

- startup surface states
- auth recovery screen states
- profile decision states
- source hub empty/loading/error/multiple states
- home-lite degraded banners
- Android TV focus traversal on entry screens

### Integration Tests

- cold start with valid session -> home lite -> home hydrated
- expired session -> auth recovery -> resume entry flow
- offline session restore -> degraded home lite
- no profile -> profile create/select
- no source -> source hub
- multiple sources without valid selection -> source choose
- source warmup failure -> bounded retry/fallback
- Android TV remote path from launch to first playable home state

### Performance Tests

- launch traces on low/mid/TV devices
- first useful state timings
- progressive hydration timings
- retry/timeout path timings

### Manual Exploratory Checks

- airplane mode at launch
- backend timeout during auth restore
- stale profile ID
- stale source ID
- source exists but catalog empty
- auth recovered while entry screen is visible
- TV focus after retry banners and dialogs

## 11. Handoff Plan

### Scope Classification

Moderate

Reason:
- multiple artifacts impacted
- no fundamental PRD reset required
- brownfield-preserving targeted reframe is feasible

### Handoff Recipients

- Product / Scrum: update epic scope, sequencing, and story breakdown
- UX: define canonical entry-flow screens and state vocabulary
- Architecture: formalize `homeLiteReady` vs `homeHydrated`, routing contract, and observability contract
- Development: implement lots 1-5 incrementally
- QA: build verification matrix for launch/auth/source/home entry states across Android and Android TV

### Success Criteria for Implementation

- one coherent entry-flow UX system
- no duplicate blocking preload corridor
- first useful state visible within budget
- degraded/offline/expired/timeout states explicit and recoverable
- Android TV entry flow fully navigable by remote
- release evidence available for startup/auth/source/home entry flow

## 12. Proposed Next Story/Backlog Changes

Recommended immediate backlog order after approval:

1. Rewrite Story 1.4 before implementation.
2. Add Story 1.5 and Story 1.6.
3. Add Story 1.7 if Android TV entry parity is not already fully covered elsewhere.
4. Update Story 2.1 to support `home lite`.
5. Pull part of Story 7.1, 7.2, and 8.1 into the same implementation track.

## 13. Final Recommendation

Do not restart from zero.

Preserve:
- startup hardening
- auth restoration hardening
- current route/state machinery as raw material

Change now:
- the contract of "usable state"
- the entry UX order
- the blocking preload model
- the visibility of degraded and recovery states
- the Android TV treatment of entry screens

This is the smallest change that materially improves UX clarity, runtime determinism, and perceived performance while staying coherent with the brownfield architecture.


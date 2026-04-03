# Story 1.2: Restore Session and Initial Access Deterministically

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

En tant qu'utilisateur de retour,
je veux que l'application restaure ma session et me route vers le bon niveau d'acces,
afin de comprendre immediatement si je suis connecte, deconnecte, ou dans un etat sur limite.

## Acceptance Criteria

1. **Given** a previously stored session is valid and successfully revalidated  
   **When** initial access is resolved  
   **Then** the application routes to the authenticated experience  
   **And** the resulting access decision is consistent for the same validated session state.

2. **Given** the session state is unknown, invalid, expired, or cannot be verified  
   **When** the initial route decision is made  
   **Then** the application defaults to a signed-out or otherwise safe non-authenticated path  
   **And** no protected route is exposed by mistake.

## Tasks / Subtasks

- [x] Formaliser une resolution de session L1 explicite et verifiee.
  - [x] Reutiliser `AuthOrchestrator.bootstrapSession()` comme point d'entree de validation initiale, ou centraliser l'equivalent dans `core/auth`, sans reintroduire une seconde politique de refresh dans `core/router`.
  - [x] Supprimer toute decision d'acces initial fondee uniquement sur `currentSession != null` dans les chemins critiques de lancement.
  - [x] Garantir un resultat borne et deterministe pour les memes entrees de session validee, invalide ou unverifiable.

- [x] Aligner l'orchestration `launch -> bootstrap -> destination` sur l'etat auth verifie.
  - [x] Garder `AppLaunchOrchestrator`, `BootstrapDestination`, `AppLaunchCriteria` et `LaunchRedirectGuard` comme surfaces uniques de decision initiale.
  - [x] Conserver `/launch` et `/bootstrap` comme surfaces d'orchestration; ne pas deplacer la logique de routage initial dans `AuthGate` ou des widgets `welcome`.
  - [x] Verifier que le chemin "experience authentifiee" signifie ici "continuer en toute securite vers la suite du bootstrap existant (`welcomeUser`, `welcomeSources`, `chooseSource`, `home` selon le contexte)", pas "forcer directement `/home`".

- [x] Preserver la logique `local-first` et le parcours de bienvenue existants.
  - [x] Si `Supabase` n'est pas configure, conserver le mode local existant sans regressions.
  - [x] Si `Supabase` est configure mais que la session est invalide, expiree ou non verifiable, router vers un chemin non authentifie actionnable (`auth` ou `welcomeUser` selon le contexte), sans jamais exposer une route protegee par erreur.
  - [x] Ne pas casser la restauration de profil, de source et de preload appliquee apres resolution auth; ces etapes restent du ressort du bootstrap existant et des stories suivantes.

- [x] Aligner l'observabilite auth/session sur les contrats existants.
  - [x] Reutiliser `AuthFailureCode`, `operationId` existant cote lancement et les journaux/telemetry deja presents; ne pas inventer une taxonomie parallele.
  - [x] Rendre explicites et testables les outcomes `authenticated`, `unauthenticated` et les causes `invalidSession`, `refreshFailed`, `timeout` et autre cause typed si necessaire.
  - [x] Verifier qu'aucun secret, token, email complet, URL sensible ou PII n'apparait dans les traces de restauration de session.

- [x] Ajouter ou mettre a jour les tests qui verrouillent FR2/FR3.
  - [x] Etendre `test/core/auth/auth_orchestrator_test.dart` si les outcomes ou la telemetry de bootstrap auth evoluent.
  - [x] Etendre `test/core/startup/app_launch_orchestrator_local_mode_test.dart` pour couvrir session validee, session invalide, refresh timeout/echec et stabilite de la destination pour les memes entrees.
  - [x] Etendre `test/core/router/launch_redirect_guard_reconnect_test.dart` ou ajouter un test voisin pour prouver qu'aucune route critique/protegee n'est exposee quand l'auth n'est pas verifiee.
  - [x] Etendre `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart` pour verrouiller les chemins `Supabase configure + signed-out` vs `Supabase indisponible/local mode`.

### Review Findings

- [x] [Review][Patch] LaunchRedirectGuard laisse encore passer les routes non critiques et deep links quand la resolution finit sur `BootstrapDestination.auth` [lib/src/core/router/launch_redirect_guard.dart:109]
- [x] [Review][Patch] Le lancement authentifie effectue maintenant deux `bootstrapSession()` successifs entre le bootstrap app et `AuthController`, avec risque de divergence d'etat et de refresh inutile [lib/src/core/auth/presentation/providers/auth_providers.dart:117]

## Dev Notes

### Portee et limites de la story

- Cette story couvre uniquement `FR2` et `FR3`: restauration de session et decision d'acces initiale deterministe.
- Le comportement de recuperation riche pour session expiree, offline ou timeout appartient surtout a la story `1.3`; ici, l'exigence minimale est de retomber sur un chemin non authentifie et sur, sans exposition accidentelle de routes protegees.
- La restauration du contexte apres lancement (`FR4`) appartient a la story `1.4`.
- Le depot est brownfield: il faut durcir et aligner la pile `core/auth + core/startup + core/router` deja presente, pas recreer un systeme d'authentification ou une navigation parallele.

### Contexte existant a reutiliser

- `lib/src/core/auth/domain/repositories/auth_repository.dart` expose deja `currentSession`, `refreshSession()` et `onAuthStateChange` avec une politique documentee `fail-safe`/`fail-closed` pour le L1.
- `lib/src/core/auth/application/auth_orchestrator.dart` definit deja `bootstrapSession()`:
  - `currentSession == null` -> `unauthenticated`
  - `refreshSession()` reussi -> `authenticated`
  - timeout / erreur / refresh impossible -> `unauthenticated`
- `lib/src/core/auth/data/repositories/supabase_auth_repository.dart` encapsule deja l'API `Supabase Auth`, avec timeouts bornes pour `refreshSession`, `signInWithOtp`, `verifyOtp` et `signOut`.
- `lib/src/core/startup/app_launch_orchestrator.dart` est deja la state machine L1/L2 du lancement applicatif, mais elle lit actuellement `_authRepository.currentSession` de facon brute avant `profiles -> sources -> preload`.
- `lib/src/core/router/launch_redirect_guard.dart` initialise actuellement `_isAuthenticated` a partir de `currentSession` et peut considerer l'auth comme resolue avant verification explicite; c'est l'un des points de risque principaux pour cette story.
- `lib/src/core/startup/app_launch_criteria.dart` et `lib/src/features/welcome/domain/enum.dart` definissent deja les criteres de readiness et les destinations bootstrap canoniques; ils doivent rester la source de verite du routage initial.
- `lib/src/core/auth/presentation/widgets/auth_gate.dart` n'est volontairement pas un garde "bloquant" sur `unauthenticated`; il laisse les flux `local-first` continuer. Cette story ne doit pas "corriger" le probleme en deplacant toute la politique d'acces ici.
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` priorise deja OTP quand `Supabase` est disponible et `unauthenticated`, tout en gardant un mode local si `Supabase` est indisponible.
- `lib/src/core/profile/presentation/providers/profile_auth_providers.dart` expose deja un etat auth `Supabase` minimal cote app; utile comme signal UI, mais ce provider ne doit pas devenir la nouvelle source de verite globale de la decision de lancement.

### Gaps probables a traiter dans cette story

- La restauration auth L1 existe deja dans `AuthOrchestrator`, mais n'est pas encore utilisee comme autorite unique dans l'orchestration de lancement.
- La simple presence d'une session locale peut actuellement etre interpretee trop tot comme "authentifie", sans revalidation explicite.
- Le risque principal n'est pas le crash mais l'exposition incorrecte d'une route critique via un etat auth stale, invalide ou non verifiable.
- L'UX demande un statut d'acces lisible; la story doit donc produire des outcomes clairs et repetables, pas juste "ca finit par marcher".
- Le produit est `local-first`: l'absence de session verifiee ne doit pas bloquer l'app dans un spinner ou un dead-end, mais il ne faut pas non plus ouvrir la voie protegee par erreur.

### Technical Requirements

- Respecter `FR2` et `FR3` sans deriver vers les comportements complets de reauth/recovery de `1.3`.
- Traiter toute incertitude auth comme `fail-closed` pour l'acces sensible:
  - session validee -> bootstrap authentifie
  - session inconnue/invalide/expiree/non verifiable -> chemin signe-out ou autre chemin non authentifie et sur
- Garder les transitions bornees et explicites:
  - pas d'attente infinie
  - pas de boucle `/launch -> /bootstrap -> /launch`
  - pas de route critique exposee avant verification
  - la route de reconnexion explicite `/auth/otp?return_to=previous` doit rester atteignable quand elle est demandee volontairement
- Conserver l'objectif de performance percue des stories de lancement:
  - decision auth bornee
  - pas de nouvel enchainement reseau non borne sur le chemin critique
- Conserver l'hygiene de securite/observabilite deja imposee par le PRD et l'architecture:
  - zero secret / token / PII dans logs, traces, rapports
  - `reasonCode` etats d'erreur et outcomes explicites
  - comportements recuperables/actionnables plutot qu'ambigus
- Si une session validee existe, "experience authentifiee" ne veut pas dire contourner le bootstrap existant: la destination finale peut encore etre `welcomeUser`, `welcomeSources`, `chooseSource` ou `home` selon profil/source/preload.

### Architecture Compliance

- `Riverpod` reste le mecanisme principal pour l'etat UI; `GetIt` reste borne au wiring/composition root dans `lib/src/core/di/`.
- La politique auth/session vit dans `lib/src/core/auth/` et l'orchestration de lancement dans `lib/src/core/startup/`; ne pas deplacer cette logique dans des widgets ou dans `features/welcome/`.
- `go_router` reste le routeur declaratif principal; la redirection critique doit rester observable et coherente avec `AppLaunchState`.
- Les decisions sensibles `auth`, `parental`, `entitlement` restent `fail-closed`; cette story touche `auth` uniquement.
- Aucun acces direct UI vers `Supabase`, `Dio`, `sqflite`, `flutter_secure_storage` ou `Sentry`.
- Les acces SDK / reseau / stockage sensible restent derriere repositories, adapters ou services deja en place.
- Ne pas ajouter de nouvelle logique opportuniste dans `lib/src/core/utils/` ou `lib/src/core/widgets/`.
- `test/` reste l'arborescence canonique; ne pas ajouter de nouveaux tests dans `tests/`.

### Library / Framework Requirements

- Rester sur les versions epinglees du depot pour cette story:
  - Flutter `>=3.38.0`
  - Dart `^3.9.2`
  - `flutter_riverpod ^3.0.3`
  - `go_router ^16.3.0`
  - `supabase_flutter ^2.10.0`
  - `sentry_flutter ^9.2.0`
- Veille technique verifiee le `2026-04-03` via sources officielles:
  - `flutter_riverpod` publie: `3.3.1`
  - `go_router` publie: `17.2.0`
  - `supabase_flutter` publie: `2.12.2`
  - `sentry_flutter` publie: `9.16.0`
- Information technique utile pour la story:
  - la documentation `supabase_flutter` officielle montre bien `auth.onAuthStateChange.listen(...)` comme surface de synchronisation auth cote app
  - la documentation officielle Supabase rappelle qu'une session repose sur un access token court et un refresh token, et que certaines politiques de session sont effectivement constatees au moment du refresh; cela renforce l'usage de `refreshSession()` pour la decision d'acces initiale
  - `go_router` documente explicitement le support des redirections basees sur l'etat applicatif; il faut donc renforcer le garde existant, pas contourner le routeur par des navigations opportunistes
- Regle de mise en oeuvre: ne pas faire de bump de dependance dans cette story. Toute migration de version doit faire l'objet d'une story/ADR dediee, car elle changerait le risque de regression auth/router.

### File Structure Requirements

- Zones cibles probables:
  - `lib/src/core/auth/application/auth_orchestrator.dart`
  - `lib/src/core/auth/data/repositories/supabase_auth_repository.dart`
  - `lib/src/core/auth/domain/entities/auth_failures.dart`
  - `lib/src/core/auth/presentation/providers/auth_providers.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/startup/app_launch_criteria.dart`
  - `lib/src/core/router/launch_redirect_guard.dart`
  - `lib/src/core/router/app_routes.dart`
  - `lib/src/core/auth/presentation/widgets/auth_gate.dart` uniquement si indispensable et sans casser `local-first`
  - `lib/src/core/profile/presentation/providers/profile_auth_providers.dart` uniquement si le contrat de signal UI doit etre aligne
  - `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` uniquement pour rester coherent avec la priorisation OTP / local mode deja en place
- Zones de tests cibles:
  - `test/core/auth/auth_orchestrator_test.dart`
  - `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - `test/core/router/launch_redirect_guard_reconnect_test.dart`
  - `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
- Eviter d'elargir la surface:
  - pas de nouveau systeme d'etat auth en doublon
  - pas de nouveau routeur
  - pas de nouveau "session manager" hors `core/auth`

### Testing Requirements

- Conserver les tests existants et les etendre avant de refactorer les decisions critiques.
- Ajouter des assertions explicites sur:
  - usage de session verifiee vs session simplement presente
  - timeout / echec / invalidation du refresh -> chemin non authentifie et sur
  - absence d'exposition accidentelle de `/` ou d'autres routes critiques quand l'auth n'est pas resolue
  - stabilite de la destination pour les memes entrees (decision deterministe)
  - preservation du mode local quand `Supabase` n'est pas configure
  - priorisation OTP quand `Supabase` est configure et l'utilisateur est `unauthenticated`
  - absence de fuite d'informations sensibles dans la telemetry auth/session
- Les tests unitaires doivent rester majoritaires pour la politique auth.
- Les tests widget/router servent a verrouiller l'absence de loop et de route critique exposee.

### UX Guardrails

- L'utilisateur doit comprendre tres vite son niveau d'acces:
  - connecte et en route vers l'experience authentifiee
  - signe-out et oriente vers le bon parcours non authentifie
  - etat sur limite si la verification ne peut pas conclure
- Aucun spinner infini ni transition opaque entre `/launch`, `/bootstrap`, OTP et la destination finale.
- Les etats sensibles auth doivent rester calmes, premiums et actionnables; ne pas afficher des diagnostics bruts ou des erreurs techniques cote utilisateur.
- Si une action de reauth est necessaire, elle doit etre explicite et coherente avec le pattern OTP deja present.
- Mobile et TV partagent le meme invariant produit: pas d'ambiguite sur "puis-je acceder a la zone protegee maintenant ?".

### Previous Story Intelligence

- La story `1.1` a deja durci le bootstrap L1 pour garantir un etat `Ready` ou `Safe` exploitable, avec `reasonCode` stables et redaction renforcee.
- `AppStartupOrchestrator` doit rester pur et framework-agnostic; ne pas lui deplacer la logique de session/auth applicative de cette story.
- Le contrat `operationId` existe deja via `runWithOperationId(prefix: 'startup')`; il faut prolonger la coherence d'observabilite auth/session, pas inventer une seconde correlation parallele.
- Le shell `OverlaySplash` / `LaunchErrorPanel` et la logique `/launch` -> `/bootstrap` sont deja en place; le risque principal est la regression par duplication de logique auth dans l'UI ou le routeur.
- Deux dettes pre-existantes de redaction ont ete differees apres review `1.1` (`Supabase` sanity check et JSON secrets dans `MessageSanitizer`); elles ne doivent pas elargir inutilement le scope de cette story.

### Git Intelligence Summary

- Les commits recents montrent un pattern `Phase 4` centre sur le durcissement des flux critiques plutot que sur des refontes transverses.
- Le commit `b79fc42` a introduit ou renforce les briques cle de cette story:
  - `core/auth/application/auth_orchestrator.dart`
  - `core/auth/data/repositories/supabase_auth_repository.dart`
  - `core/auth/presentation/providers/auth_providers.dart`
  - `core/startup/domain/app_startup_orchestrator.dart`
  - tests auth/startup/router associes
- Le commit `86c8255` touche uniquement la surface player; cette story doit garder ses changements isoles a `auth/startup/router/welcome`.
- Le pattern recent du depot est:
  - typed failures / reason codes
  - timeouts bornes
  - tests unitaires explicites
  - corrections incrementales sur surfaces critiques

### Latest Technical Intelligence

- `supabase_flutter` officiel documente `auth.onAuthStateChange.listen(...)` et confirme que le flux Flutter doit ecouter les changements de session au niveau client; le repository existant est donc le bon point d'integration.
- La documentation officielle Supabase sur les sessions precise qu'une session est composee d'un access token et d'un refresh token, que le refresh token n'est utilisable qu'une fois, et que certaines restrictions de session ne sont constatees qu'au prochain refresh. Pour cette story, cela signifie qu'une decision d'acces initiale basee uniquement sur `currentSession` est insuffisante.
- `go_router` officiel reste "feature complete" avec support explicite des redirections par etat applicatif; il faut donc renforcer le `LaunchRedirectGuard` existant et garder la logique de redirect dans le routeur.
- `flutter_riverpod` officiel insiste sur la testabilite et la gestion explicite des etats asynchrones; cela confirme le choix de conserver des `NotifierProvider`/states explicites plutot qu'un state auth implicite ou disperse.

### Project Structure Notes

- Aucun `project-context.md` exploitable n'a ete trouve dans le depot courant.
- La structure reelle du depot confirme les zones canoniques pour cette story:
  - `core/auth` pour la politique auth/session
  - `core/startup` pour l'orchestration de lancement
  - `core/router` pour la redirection initiale
  - `features/welcome` pour les surfaces de bienvenue/OTP
- La story doit rester compatible avec l'architecture cible documentee, sans lancer une reorganisation de `core/shared`, `core/utils` ou `core/widgets`.

### References

- `_bmad-output/planning-artifacts/epics.md`
  - `Epic 1: Trusted App Entry and Session Continuity`
  - `Story 1.2: Restore Session and Initial Access Deterministically`
  - `Story 1.3: Recover Cleanly From Expired, Offline, and Timeout Session States`
- `_bmad-output/planning-artifacts/prd.md`
  - `Functional Requirements > Access & Session Management`
  - `Risk Mitigations`
  - `Non-Functional Requirements > Security & Privacy`
  - `Non-Functional Requirements > Reliability & Resilience`
- `_bmad-output/planning-artifacts/architecture.md`
  - `Authentication & Security`
  - `Frontend Architecture > Routing`
  - `Service Boundaries`
  - `Requirements to Structure Mapping`
  - `Implementation Handoff`
- `_bmad-output/planning-artifacts/ux-design-specification.md`
  - `Experience Principles`
  - `Transferable UX Patterns`
  - `Anti-Patterns to Avoid`
  - `Accessibility Considerations`
- `_bmad-output/implementation-artifacts/1-1-reach-a-usable-startup-state-without-crash-loops.md`
- Codebase:
  - `lib/src/core/auth/application/auth_orchestrator.dart`
  - `lib/src/core/auth/data/repositories/supabase_auth_repository.dart`
  - `lib/src/core/auth/domain/entities/auth_failures.dart`
  - `lib/src/core/auth/domain/entities/auth_models.dart`
  - `lib/src/core/auth/domain/repositories/auth_repository.dart`
  - `lib/src/core/auth/presentation/providers/auth_providers.dart`
  - `lib/src/core/auth/presentation/widgets/auth_gate.dart`
  - `lib/src/core/router/app_route_paths.dart`
  - `lib/src/core/router/app_routes.dart`
  - `lib/src/core/router/launch_redirect_guard.dart`
  - `lib/src/core/startup/app_launch_criteria.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
  - `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
  - `lib/src/core/profile/presentation/providers/profile_auth_providers.dart`
- Tests existants:
  - `test/core/auth/auth_orchestrator_test.dart`
  - `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - `test/core/router/launch_redirect_guard_reconnect_test.dart`
  - `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
- Documentation officielle verifiee le `2026-04-03`:
  - `https://pub.dev/packages/flutter_riverpod`
  - `https://pub.dev/packages/go_router`
  - `https://pub.dev/packages/supabase_flutter`
  - `https://pub.dev/packages/sentry_flutter`
  - `https://supabase.com/docs/guides/auth/sessions`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `git log -5 --oneline`
- `git show --stat --oneline -1 86c8255`
- `git show --stat --oneline -1 b79fc42`
- `Get-Content _bmad-output/planning-artifacts/epics.md`
- `Get-Content _bmad-output/planning-artifacts/prd.md`
- `Get-Content _bmad-output/planning-artifacts/architecture.md`
- `Get-Content _bmad-output/planning-artifacts/ux-design-specification.md`
- `Get-Content _bmad-output/implementation-artifacts/1-1-reach-a-usable-startup-state-without-crash-loops.md`
- `Get-Content lib/src/core/auth/application/auth_orchestrator.dart`
- `Get-Content lib/src/core/startup/app_launch_orchestrator.dart`
- `Get-Content lib/src/core/router/launch_redirect_guard.dart`
- `flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart test/core/router/launch_redirect_guard_reconnect_test.dart test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
- `flutter test`
- `flutter analyze`

### Completion Notes List

- Story selection resolved from user input `1.2` to `1-2-restore-session-and-initial-access-deterministically`.
- Contexte compile depuis `epics.md`, `prd.md`, `architecture.md`, `ux-design-specification.md`, la story `1.1`, les surfaces `core/auth`, `core/startup`, `core/router`, `features/welcome` et les tests existants.
- `AppLaunchOrchestrator` valide maintenant la session initiale via `AuthOrchestrator.bootstrapSession()` avant toute decision d'acces sensible.
- Si l'auth cloud est active mais qu'aucune session n'est validee, la destination initiale bascule en fail-closed vers `BootstrapDestination.auth`; en mode local sans Supabase, le bootstrap existant est preserve.
- Les tests startup, router et welcome couvrent desormais session validee, session stale/non verifiable, echec de refresh et non-exposition de route protegee.
- `flutter test` passe integralement le `2026-04-03`.
- `flutter analyze` ne remonte plus de warning lie a cette story; il reste 7 infos pre-existantes dans des tests hors scope.
- La revue de code a ajoute un verrouillage des routes non-startup vers la destination de bootstrap resolue et evite un second `bootstrapSession()` quand le launch a deja tranche l'etat auth.

### File List

- `_bmad-output/implementation-artifacts/1-2-restore-session-and-initial-access-deterministically.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/router/launch_redirect_guard.dart`
- `lib/src/core/auth/presentation/providers/auth_providers.dart`
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `test/core/router/launch_redirect_guard_reconnect_test.dart`
- `test/core/auth/presentation/providers/auth_providers_test.dart`
- `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`

### Change Log

- `2026-04-03`: implementation de la story 1.2, ajout des tests FR2/FR3, validation par `flutter test`, passage du statut a `review`.
- `2026-04-03`: correction des findings de review, ajout des tests `LaunchRedirectGuard`/`AuthController`, validation par `flutter test`, passage du statut a `done`.

# Story 1.3: Recover Cleanly From Expired, Offline, and Timeout Session States

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

En tant qu'utilisateur de retour,
je veux qu'une restauration de session expiree, offline ou timeoutee me laisse dans un etat de recuperation clair,
afin de pouvoir continuer en securite ou me reauthentifier sans boucle de redirection ni navigation bloquee.

## Acceptance Criteria

1. **Given** a stored session is expired or no longer valid  
   **When** session restoration runs  
   **Then** invalid sensitive state is cleared as required  
   **And** the user is shown a clear reauthentication or recovery path without redirect loops.

2. **Given** session restoration is blocked by offline conditions, timeout, or backend unavailability  
   **When** the maximum bounded wait is reached  
   **Then** the application remains navigable in a safe degraded state  
   **And** retries stay explicit, bounded, and observable.

## Tasks / Subtasks

- [x] Formaliser des outcomes de recovery auth/session L1 explicites et types.
  - [x] Etendre `AuthOrchestrator.bootstrapSession()` ou son contrat adjacent pour distinguer au minimum `invalidSession`, `offline`, `timeout` et `refreshFailed`, sans reintroduire une seconde politique de refresh ailleurs dans l'app.
  - [x] Garantir un resultat borne et deterministe pour les memes entrees auth, y compris quand le backend est indisponible ou lent.
  - [x] Ne jamais baser la decision de recovery sur `currentSession != null` seul quand la revalidation a deja echoue ou timeoute.

- [x] Nettoyer l'etat sensible requis quand la session est expiree/invalide.
  - [x] Identifier la surface minimale a nettoyer pour respecter le `fail-closed` sur l'acces sensible, sans effacer agressivement le contexte `local-first` encore valable.
  - [x] Reutiliser les ports / services de cleanup deja presents dans `core/auth` au lieu d'inventer une nouvelle logique opportuniste dans `core/router` ou l'UI.
  - [x] Verifier que la sortie "session invalide" conduit vers un chemin de reauthentification clair et non boucle.

- [x] Aligner `launch -> bootstrap -> destination` sur des etats de recovery actionnables.
  - [x] Garder `AppLaunchOrchestrator`, `BootstrapDestination`, `AppLaunchCriteria`, `LaunchRedirectGuard` et `SplashBootstrapPage` comme surfaces uniques de decision et de presentation de recovery.
  - [x] Router les cas `invalidSession` vers une reauth explicite (`auth` / OTP) sans exposer de route protegee.
  - [x] Router les cas `offline`, `timeout` ou backend indisponible vers un etat degrade navigable avec retry explicite et borne, sans spinner infini ni loop `/launch -> /bootstrap -> /auth`.

- [x] Preserver la logique `local-first` et les parcours deja durcis par 1.1/1.2.
  - [x] Si `Supabase` n'est pas configure, conserver le comportement local existant sans regressions.
  - [x] Ne pas casser `WelcomeUserPage`, `AuthOtpPage`, `SplashBootstrapPage` ni la route `/auth/otp?return_to=previous`.
  - [x] Ne pas effacer les profils, sources locales ou preloads qui restent valides localement quand seule la restauration cloud est en echec degrade.

- [x] Aligner l'observabilite et la UX de recovery sur les contrats existants.
  - [x] Reutiliser `AuthFailureCode`, `operationId`, `reasonCode`, `recoveryMessage` et les journaux/telemetry deja en place; ne pas inventer une taxonomie parallele.
  - [x] Rendre explicites et testables les outcomes `reauth-required`, `degraded-retryable` et `authenticated`, avec causes `invalidSession`, `offline`, `timeout`, `refreshFailed` et autre cause typed si necessaire.
  - [x] Verifier qu'aucun secret, token, email complet, URL sensible ou PII n'apparait dans les traces ou messages de recovery.

- [x] Ajouter ou mettre a jour les tests qui verrouillent FR2/FR3 pour les cas de recovery.
  - [x] Etendre `test/core/auth/auth_orchestrator_test.dart` pour couvrir invalidation, offline, timeout et cleanup associe.
  - [x] Etendre `test/core/startup/app_launch_orchestrator_local_mode_test.dart` pour couvrir les chemins `invalidSession -> auth` et `offline/timeout -> degraded retryable`.
  - [x] Etendre `test/core/router/launch_redirect_guard_reconnect_test.dart` pour prouver l'absence de redirect loop et la non-exposition de routes critiques pendant la recovery.
  - [x] Etendre `test/features/welcome/presentation/splash_bootstrap_page_progress_test.dart` ou un test voisin pour verrouiller le message de recovery et le retry explicite.

### Review Findings

- [ ] [Review][Decision] Definir la politique quand `Supabase` est configure mais qu'aucune session locale n'existe [lib/src/core/auth/application/auth_orchestrator.dart:41] — le diff traite `currentSession == null` comme `invalidSession` puis force `BootstrapDestination.auth`, ce qui change le comportement pour les fresh installs, les sign-outs volontaires et certains parcours `local-first`. La correction depend du contrat produit souhaite entre `reauth` immediate et entree non authentifiee actionnable.
- [ ] [Review][Decision] Definir le scope du cleanup `invalidSession` pour les sources IPTV hydratees depuis le cloud [lib/src/core/auth/application/services/local_data_cleanup_service.dart:45] — le cleanup sensible preserve les comptes IPTV locaux et le vault, alors que le bootstrap hydrate des sources Supabase dans ce stockage local. Corriger le bleed inter-compte impose de choisir entre purge ciblée des donnees hydratees, isolation par compte, ou purge plus large des actifs IPTV.
- [ ] [Review][Decision] Confirmer si la recovery retryable doit rester visible hors `SplashBootstrapPage` [lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart:3] — la story borne la presentation de recovery a `SplashBootstrapPage`, mais le diff ajoute `LaunchRecoveryBanner` dans le shell et plusieurs ecrans welcome. Le bon correctif depend de l'intention UX finale.
- [ ] [Review][Patch] Les erreurs d'invalidation de session levees pendant `refreshSession()` sont degradees en `refreshFailed` retryable au lieu de forcer une reauth fail-closed [lib/src/core/auth/application/auth_orchestrator.dart:142]
- [ ] [Review][Patch] La recovery `invalidSession` peut retourner vers la reauth avec une session stale toujours en memoire quand `signOut()` echoue [lib/src/core/auth/application/auth_orchestrator.dart:200]
- [ ] [Review][Patch] Le chemin `currentSession == null` marque `invalidSession` sans lancer le cleanup sensible requis [lib/src/core/auth/application/auth_orchestrator.dart:41]
- [ ] [Review][Patch] La recovery auth retryable continue quand meme vers `getProfiles()` et peut rebloquer le lancement sur un second aller-retour cloud [lib/src/core/startup/app_launch_orchestrator.dart:568]
- [ ] [Review][Patch] `WelcomeSourcePage` relance automatiquement `Supabase` au montage pendant une recovery degradee alors que le retry doit rester explicite [lib/src/features/welcome/presentation/pages/welcome_source_page.dart:70]
- [ ] [Review][Patch] La telemetry `sensitive_cleanup=success` peut etre emise alors que des suppressions partielles ont deja echoue en interne [lib/src/core/auth/application/services/local_data_cleanup_service.dart:160]
- [ ] [Review][Patch] Les messages de recovery et le CTA `Reessayer` contournent la couche de localisation et figent du texte francais dans le domaine/UI [lib/src/core/auth/application/auth_orchestrator.dart:179]

## Dev Notes

### Portee et limites de la story

- Cette story couvre la seconde moitie de `FR2`/`FR3`: recuperation propre quand la restauration de session ne peut pas conclure nominalement.
- La determination de base `session validee -> experience authentifiee` a deja ete traitee par la story `1.2`.
- La restauration du contexte essentiel apres lancement (`FR4`) appartient toujours a la story `1.4`.
- Le depot est brownfield: il faut durcir et completer `core/auth + core/startup + core/router + welcome` existants, pas recreer un nouveau gestionnaire de session ou une nouvelle navigation parallele.

### Contexte existant a reutiliser

- `lib/src/core/auth/application/auth_orchestrator.dart` fait deja le bootstrap L1 auth en `fail-closed`, avec telemetry `bootstrap_session` et `refresh_session`.
- `lib/src/core/auth/domain/entities/auth_failures.dart` expose deja `AuthFailureCode.timeout`, `offline`, `invalidSession`, `refreshFailed`, `notConfigured`, etc., mais tous ne sont pas encore propages jusqu'a la decision UX de recovery.
- `lib/src/core/auth/data/repositories/supabase_auth_repository.dart` borne deja `refreshSession()` avec timeout et peut servir de point central pour distinguer timeout/indisponibilite backend.
- `lib/src/core/auth/presentation/providers/auth_providers.dart` evite maintenant un second `bootstrapSession()` quand `AppLaunchState` a deja tranche l'etat auth.
- `lib/src/core/startup/app_launch_orchestrator.dart` route actuellement toute session cloud non validee vers `BootstrapDestination.auth`; cela couvre le `fail-closed`, mais ne distingue pas encore les cas `reauth-required` vs `degraded-retryable`.
- `lib/src/core/router/launch_redirect_guard.dart` redirige deja les routes critiques et non-startup vers la destination de bootstrap resolue; c'est la bonne surface pour eviter les loops et l'exposition accidentelle de routes protegees.
- `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart` sait deja afficher un `recoveryMessage` et un retry explicite via `LaunchErrorPanel`.
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` priorise deja OTP quand `Supabase` est disponible et l'utilisateur `unauthenticated`, sans casser le mode local quand `Supabase` est indisponible.
- `lib/src/features/auth/presentation/auth_otp_controller.dart` et `auth_otp_page.dart` constituent deja le chemin de reauth explicite; cette story doit s'y raccorder, pas le contourner.

### Gaps probables a traiter dans cette story

- `AuthOrchestrator` sait aujourd'hui echouer en `unauthenticated`, mais n'expose pas encore assez d'information structuree pour que le launch distingue session invalide vs indisponibilite temporaire.
- `AppLaunchOrchestrator` traite actuellement les cas `invalidSession`, `timeout`, `offline` et backend indisponible de la meme facon (`BootstrapDestination.auth`), ce qui ne satisfait pas encore l'AC 2 sur l'etat degrade navigable avec retry explicite.
- Le code de cleanup existe cote auth, mais il faut cadrer precisement ce qui doit etre nettoye pour une session invalide sans detruire le contexte `local-first` encore utile.
- Le shell de recovery existe deja (`SplashBootstrapPage` + `LaunchErrorPanel`), mais il n'est pas encore branche sur des outcomes auth/session plus fins.
- Le risque principal n'est pas le crash: c'est soit une boucle de redirection, soit un dead-end OTP alors que le probleme est simplement transitoire (`offline` / `timeout`).

### Technical Requirements

- Respecter `FR2` et `FR3` sans deriver vers la restauration de contexte complet de `1.4`.
- Traiter `invalidSession` et etat sensible incoherent en `fail-closed`:
  - access path protege ferme
  - route de reauth explicite
  - nettoyage des elements sensibles requis
- Traiter `offline`, `timeout` et backend indisponible comme etats recuperables bornes:
  - pas de spinner infini
  - pas de retries implicites non bornes
  - etat degrade lisible, actionnable, retry explicite
- Conserver le mode `local-first`:
  - ne pas effacer les donnees locales encore valides sans raison
  - ne pas casser les chemins de bienvenue locale quand `Supabase` est absent
- Reutiliser les contrats de correlation/observabilite deja poses:
  - `operationId`
  - `AuthFailureCode`
  - `reasonCode`
  - `recoveryMessage`
- Aucun secret, token, credential ou PII dans les logs, messages de recovery, crash reports ou preuves.

### Architecture Compliance

- `Riverpod` reste le mecanisme principal de state management UI; `GetIt` reste borne au wiring/composition root.
- La politique auth/session vit dans `lib/src/core/auth/`; l'orchestration de lancement vit dans `lib/src/core/startup/`; la redirection reste dans `lib/src/core/router/`.
- `go_router` reste la source de verite pour la redirection critique; ne pas contourner les loops par des navigations ad hoc dans les widgets.
- `AuthGate` doit rester passif pour `local-first`; cette story ne doit pas deplacer tout le policy handling dedans.
- Les acces `Supabase`, stockage et IO externe restent encapsules derriere des repositories / adapters / services.
- Ne pas ajouter de nouvelle logique opportuniste dans `lib/src/core/utils/` ou `lib/src/core/widgets/`.

### Library / Framework Requirements

- Rester sur les versions epinglees du depot pour cette story:
  - Flutter `>=3.38.0`
  - Dart `^3.9.2`
  - `flutter_riverpod ^3.0.3`
  - `go_router ^16.3.0`
  - `supabase_flutter ^2.10.0`
  - `sentry_flutter ^9.2.0`
- Veille technique officielle reverifiee le `2026-04-03`:
  - `flutter_riverpod` publie: `3.3.1`
  - `go_router` publie: `17.2.0`
  - `supabase_flutter` publie: `2.12.2`
  - `sentry_flutter` publie: `9.16.0`
- Information utile pour cette story:
  - `supabase_flutter` continue de documenter `auth.onAuthStateChange.listen(...)` comme surface de synchronisation cote app
  - la documentation Supabase sur les sessions confirme que certaines invalidations/restrictions sont constatees au refresh, ce qui renforce la distinction entre `session locale presente` et `session effectivement restauree`
  - `go_router` documente les redirections basees sur l'etat applicatif; la solution doit donc rester dans `LaunchRedirectGuard` / `AppLaunchState`
- Regle de mise en oeuvre: aucun bump de dependance dans cette story.

### File Structure Requirements

- Zones cibles probables:
  - `lib/src/core/auth/application/auth_orchestrator.dart`
  - `lib/src/core/auth/domain/entities/auth_failures.dart`
  - `lib/src/core/auth/domain/entities/auth_models.dart`
  - `lib/src/core/auth/presentation/providers/auth_providers.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/router/launch_redirect_guard.dart`
  - `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
  - `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
  - `lib/src/features/auth/presentation/auth_otp_controller.dart` uniquement si necessaire pour garder la recovery explicite et bornee
- Zones de tests cibles:
  - `test/core/auth/`
  - `test/core/startup/`
  - `test/core/router/`
  - `test/features/welcome/presentation/`
- Eviter d'elargir la surface:
  - pas de nouveau gestionnaire global de session
  - pas de nouveau routeur
  - pas de nouvelle state machine auth parallele

### Testing Requirements

- Conserver les tests existants et les etendre avant de refactorer les chemins critiques.
- Ajouter des assertions explicites sur:
  - `invalidSession` -> chemin reauth clair, sans loop
  - `offline` / `timeout` / backend indisponible -> etat degrade navigable + retry explicite
  - absence d'exposition accidentelle de `/`, `/player`, deep links ou autres routes critiques pendant la recovery
  - stabilite de la destination et du message de recovery pour les memes entrees
  - preservation du mode local quand `Supabase` n'est pas configure
  - absence de fuite d'informations sensibles dans telemetry/logs/messages
- Les tests unitaires doivent rester majoritaires pour la politique auth/recovery.
- Les tests widget/router servent a verrouiller l'absence de loop et le retry UX explicite.

### UX Guardrails

- L'utilisateur doit comprendre rapidement s'il doit:
  - se reconnecter
  - patienter/reessayer
  - continuer dans un etat degrade mais navigable
- Aucun spinner infini ni transition opaque entre `/launch`, `/bootstrap`, OTP et la destination finale.
- Un cas transitoire (`offline`, `timeout`, backend indisponible) ne doit pas ressembler a une session definitivement invalide.
- Un cas definitivement invalide ne doit pas laisser croire que l'acces protege peut encore etre utilise.
- Les messages de recovery doivent rester calmes, premium, actionnables et coherents sur mobile comme sur TV.

### Previous Story Intelligence

- La story `1.1` a deja durci le bootstrap startup, introduit un shell Safe/Ready exploitable, et pose les invariants `operationId` / `reasonCode`.
- La story `1.2` a deja remplace la decision brute sur `currentSession` par `AuthOrchestrator.bootstrapSession()` et ferme l'exposition de routes non critiques pendant la resolution auth.
- La review de `1.2` a ajoute deux garde-fous importants pour `1.3`:
  - `LaunchRedirectGuard` redirige maintenant aussi les routes non-startup vers la destination de bootstrap resolue
  - `AuthController` ne refait plus un `bootstrapSession()` quand le launch a deja tranche l'etat auth
- `1.3` doit donc completer les outcomes de recovery, pas remettre en cause la structure de decision deja durcie.

### Git Intelligence Summary

- Les commits recents montrent un pattern `Phase 4` centre sur le hardening progressif des flux critiques, sans refonte transverse brutale.
- Le commit `b79fc42` a renforce la pile `core/auth` / `core/startup` qui sert de base a cette story.
- Le commit `86c8255` reste hors scope (surface player).
- Le pattern recent du depot est:
  - typed failures / reason codes
  - timeouts bornes
  - retries explicites
  - tests unitaires et widget de verrouillage sur surfaces critiques

### Latest Technical Intelligence

- `supabase_flutter` officiel documente toujours `auth.onAuthStateChange.listen(...)` comme point d'integration auth cote Flutter.
- La documentation Supabase sur les sessions rappelle qu'une session n'est pas seulement un snapshot local, mais un etat qui peut etre invalide au prochain refresh; cela justifie la distinction `invalidSession` vs indisponibilite temporaire.
- `go_router` reste "feature complete" avec redirections par etat applicatif, ce qui conforte l'usage du garde de route existant pour prevenir les loops.
- `flutter_riverpod` continue de mettre en avant les etats asynchrones explicites et testables; cette story doit conserver des outcomes auth/recovery lisibles plutot qu'un etat implicite disperse.

### Project Structure Notes

- Aucun `project-context.md` exploitable n'a ete trouve dans le depot courant.
- La structure reelle du depot confirme les zones canoniques pour cette story:
  - `core/auth` pour la politique session/recovery
  - `core/startup` pour l'orchestration de lancement
  - `core/router` pour la redirection initiale
  - `features/welcome` / `features/auth` pour la presentation de la recovery et de la reauth
- La story doit rester compatible avec l'architecture cible documentee, sans lancer une reorganisation de `core/shared`, `core/utils` ou `core/widgets`.

### References

- `_bmad-output/planning-artifacts/epics.md`
  - `Epic 1: Trusted App Entry and Session Continuity`
  - `Story 1.3: Recover Cleanly From Expired, Offline, and Timeout Session States`
  - `Story 1.4: Restore Essential Context After Launch Without Breaking Safety Rules`
- `_bmad-output/planning-artifacts/prd.md`
  - `Functional Requirements > Access & Session Management`
  - `Risk Mitigations`
  - `Non-Functional Requirements > Security & Privacy`
  - `Non-Functional Requirements > Reliability & Resilience`
  - `User Journeys`
- `_bmad-output/planning-artifacts/architecture.md`
  - `Authentication & Security`
  - `Frontend Architecture > Routing`
  - `Data Architecture`
  - `Implementation Handoff`
- `_bmad-output/planning-artifacts/ux-design-specification.md`
  - `Experience Principles`
  - `Critical Success Moments`
  - `Design Direction Decision`
  - `Accessibility Considerations`
- `_bmad-output/implementation-artifacts/1-1-reach-a-usable-startup-state-without-crash-loops.md`
- `_bmad-output/implementation-artifacts/1-2-restore-session-and-initial-access-deterministically.md`
- Codebase:
  - `lib/src/core/auth/application/auth_orchestrator.dart`
  - `lib/src/core/auth/domain/entities/auth_failures.dart`
  - `lib/src/core/auth/domain/entities/auth_models.dart`
  - `lib/src/core/auth/presentation/providers/auth_providers.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/router/launch_redirect_guard.dart`
  - `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
  - `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
  - `lib/src/features/auth/presentation/auth_otp_controller.dart`
  - `lib/src/features/auth/presentation/auth_otp_page.dart`
- Tests existants:
  - `test/core/auth/auth_orchestrator_test.dart`
  - `test/core/auth/presentation/providers/auth_providers_test.dart`
  - `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - `test/core/router/launch_redirect_guard_reconnect_test.dart`
  - `test/features/welcome/presentation/splash_bootstrap_page_progress_test.dart`
  - `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
  - `test/features/settings/presentation/reconnect_validation_test.dart`
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
- `Get-Content _bmad-output/planning-artifacts/epics.md`
- `Get-Content _bmad-output/planning-artifacts/prd.md`
- `Get-Content _bmad-output/planning-artifacts/architecture.md`
- `Get-Content _bmad-output/planning-artifacts/ux-design-specification.md`
- `Get-Content _bmad-output/implementation-artifacts/1-1-reach-a-usable-startup-state-without-crash-loops.md`
- `Get-Content _bmad-output/implementation-artifacts/1-2-restore-session-and-initial-access-deterministically.md`
- `Get-Content lib/src/core/auth/application/auth_orchestrator.dart`
- `Get-Content lib/src/core/startup/app_launch_orchestrator.dart`
- `Get-Content lib/src/core/router/launch_redirect_guard.dart`
- `Get-Content lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
- `dart format lib/src/core/auth/application/auth_orchestrator.dart lib/src/core/auth/application/services/local_data_cleanup_service.dart lib/src/core/auth/application/ports/local_cleanup_port.dart lib/src/core/auth/domain/entities/auth_models.dart lib/src/core/auth/presentation/providers/auth_providers.dart lib/src/core/startup/app_launch_orchestrator.dart lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart lib/src/features/shell/presentation/pages/app_shell_page.dart lib/src/features/welcome/presentation/pages/welcome_user_page.dart lib/src/features/welcome/presentation/pages/welcome_source_page.dart lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart test/core/auth/auth_orchestrator_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart test/core/router/launch_redirect_guard_reconnect_test.dart test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
- `flutter test test/core/auth/auth_orchestrator_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart test/core/router/launch_redirect_guard_reconnect_test.dart test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`

### Completion Notes List

- `AuthOrchestrator` expose maintenant un `AuthBootstrapResult` type avec outcomes `authenticated`, `reauthRequired` et `degradedRetryable`, ainsi que des causes `invalidSession`, `offline`, `timeout` et `refreshFailed`.
- La sortie `invalidSession` applique un cleanup cible via `clearSensitiveSessionState()` pour fermer l'acces sensible tout en preservant les donnees `local-first` encore valides.
- `AppLaunchOrchestrator` propage des recoveries actionnables jusqu'a la destination de bootstrap, route `invalidSession` vers `auth` et laisse les erreurs transitoires navigables en mode degrade avec retry explicite.
- Une `LaunchRecoveryBanner` reutilisable affiche le message et l'action `Reessayer` sur le shell et les ecrans welcome, en supprimant l'auto-redirection OTP quand la recovery est retryable.
- Les tests couvrent maintenant invalidation, offline, timeout, reachability home en degrade et UX de retry sur `WelcomeUserPage`.
- Validation executee avec succes via `flutter test test/core/auth/auth_orchestrator_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart test/core/router/launch_redirect_guard_reconnect_test.dart test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`.

### File List

- `lib/src/core/auth/application/auth_orchestrator.dart`
- `lib/src/core/auth/application/ports/local_cleanup_port.dart`
- `lib/src/core/auth/application/services/local_data_cleanup_service.dart`
- `lib/src/core/auth/domain/entities/auth_models.dart`
- `lib/src/core/auth/presentation/providers/auth_providers.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart`
- `lib/src/features/shell/presentation/pages/app_shell_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_source_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
- `test/core/auth/auth_orchestrator_test.dart`
- `test/core/router/launch_redirect_guard_reconnect_test.dart`
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/1-3-recover-cleanly-from-expired-offline-and-timeout-session-states.md`

### Change Log

- `2026-04-03`: creation de la story 1.3 avec contexte brownfield complet, garde-fous auth/startup/router et strategie de recovery explicite.
- `2026-04-03`: implementation des outcomes auth/session types, du cleanup sensible cible et de la propagation `AppLaunchRecovery` jusqu'aux destinations de bootstrap.
- `2026-04-03`: ajout d'une UX de retry explicite sur shell/welcome et couverture de tests pour invalidSession, offline, timeout et navigation degradee.

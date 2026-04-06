---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
workflowType: 'epics-and-stories'
project_name: 'movi'
user_name: 'Matteo'
date: '2026-04-02'
---

# movi - Epic Breakdown

## Overview

Ce document fournit la decomposition epics/stories officielle de `movi` a partir du PRD, de l'architecture et de la specification UX courants.

## Requirements Inventory

### Functional Requirements

FR1: Les utilisateurs peuvent lancer l'application et atteindre un etat exploitable meme si certaines dependances de demarrage echouent.

FR2: Les utilisateurs peuvent etablir, restaurer et terminer une session de maniere coherente sur les appareils supportes.

FR3: Les utilisateurs peuvent comprendre s'ils ont acces ou non a une zone authentifiee lorsque l'etat de session change.

FR4: Les utilisateurs peuvent reprendre l'usage de l'application apres interruption sans perdre leur contexte essentiel.

FR5: Les utilisateurs peuvent parcourir les contenus movie et TV disponibles dans une interface dediee a la decouverte.

FR6: Les utilisateurs peuvent acceder aux details d'un contenu avant de decider de le lancer.

FR7: Les utilisateurs peuvent retrouver un contenu pertinent a partir de l'etat actuel de l'application.

FR8: Les utilisateurs peuvent identifier ce qu'ils regardent, ce qu'ils ont deja commence et ce qu'ils peuvent reprendre.

FR9: Les utilisateurs peuvent naviguer entre les parcours cles sans perdre le sens de leur progression dans l'application.

FR10: Les utilisateurs peuvent utiliser les parcours critiques sur mobile et sur TV avec des interactions adaptees au contexte d'usage.

FR11: Les utilisateurs peuvent lancer la lecture d'un contenu eligible depuis les surfaces principales de l'application.

FR12: Les utilisateurs peuvent interrompre puis reprendre un contenu sans devoir reconstruire manuellement leur progression.

FR13: Les utilisateurs peuvent retrouver leur progression de lecture sur un autre appareil supporte.

FR14: Les utilisateurs peuvent comprendre quand une lecture, une reprise ou une restauration de progression n'a pas pu aboutir.

FR15: Les utilisateurs peuvent recuperer d'un echec de playback ou de reprise sans rester dans un etat bloquant ou ambigu.

FR16: Les utilisateurs peuvent conserver une continuite d'usage meme quand la synchronisation n'est pas immediate.

FR17: Les utilisateurs peuvent beneficier d'une experience de reprise coherente entre films, episodes et contenus deja entames.

FR18: Les utilisateurs peuvent utiliser des profils distincts avec un contexte d'usage separe.

FR19: Les titulaires de compte peuvent definir et modifier des restrictions parentales applicables aux profils concernes.

FR20: Les titulaires de compte peuvent comprendre l'effet des restrictions et des parametres sensibles qu'ils appliquent.

FR21: Les utilisateurs peuvent consulter et modifier leurs preferences d'application prises en charge.

FR22: Les utilisateurs peuvent retrouver leurs preferences essentielles apres redemarrage ou changement d'appareil lorsque le produit les supporte.

FR23: Les utilisateurs peuvent continuer a utiliser l'application dans un etat sur lorsque certaines preferences, regles ou politiques ne peuvent pas etre resolues.

FR24: Les utilisateurs peuvent connaitre leur statut d'abonnement et leur niveau d'acces actuel.

FR25: Les utilisateurs peuvent acceder aux fonctionnalites premium uniquement lorsqu'ils disposent des droits correspondants.

FR26: Les utilisateurs peuvent retrouver leurs droits apres restauration de session, changement d'appareil ou revalidation du compte.

FR27: Les utilisateurs peuvent comprendre pourquoi un acces premium est disponible, indisponible ou en attente de confirmation.

FR28: Les titulaires de compte peuvent utiliser un parcours d'abonnement coherent avec les plateformes de distribution supportees.

FR29: Les utilisateurs peuvent choisir s'ils souhaitent recevoir des notifications liees au contenu suivi.

FR30: Les utilisateurs peuvent etre informes lorsqu'un nouvel episode ou un evenement pertinent concerne leur contenu suivi.

FR31: Les utilisateurs peuvent controler les preferences de notifications prises en charge par le produit.

FR32: Les utilisateurs peuvent retrouver un etat utile minimal meme lorsque le reseau est indisponible ou degrade.

FR33: Les utilisateurs peuvent comprendre que certaines donnees ou actions sont en attente de synchronisation.

FR34: Les utilisateurs peuvent reprendre un usage normal apres retour du reseau sans devoir reparer manuellement leur etat.

FR35: Les utilisateurs peuvent conserver une experience coherente entre appareils supportes meme lorsque certains evenements arrivent hors sequence.

FR36: Le support et les operations peuvent diagnostiquer les incidents critiques de demarrage, session, lecture, reprise et synchronisation.

FR37: Le support et les operations peuvent correler les evenements pertinents d'un parcours critique sans exposer de donnees sensibles.

FR38: Le support et les operations peuvent distinguer un etat recuperable d'un etat necessitant une action corrective.

FR39: Le produit peut exposer des informations de diagnostic suffisantes pour expliquer les echecs visibles par l'utilisateur.

FR40: Le produit peut signaler les situations ou il fonctionne en etat degrade ou en etat sur.

### NonFunctional Requirements

NFR1: L'application doit atteindre un ecran utilisable en `P50 <= 2,0 s` et `P95 <= 3,0 s` au cold start sur appareil de reference.

NFR2: L'application doit revenir a un ecran utilisable en `P50 <= 1,0 s` et `P95 <= 1,8 s` en warm start ou reprise.

NFR3: Les navigations critiques doivent devenir interactives en `P95 <= 300 ms` sur appareils supportes de reference.

NFR4: Le lancement de lecture doit aboutir en `P50 <= 2,5 s` et `P95 <= 5,0 s` sur reseau stable.

NFR5: Les transitions critiques doivent rester fluides, avec au moins `95 %` des frames dans le budget de rendu sur les appareils cibles de reference.

NFR6: Les budgets de performance doivent etre verifies sur au moins une classe d'appareil faible, une classe moyenne et une classe TV avant release.

NFR7: Aucun secret, token, credential ou PII ne doit apparaitre dans les logs, traces, crash reports ou artefacts de preuve.

NFR8: Les donnees sensibles doivent etre protegees en transit et au repos selon les capacites des plateformes supportees.

NFR9: Les decisions d'acces sensibles doivent echouer en etat sur lorsque les informations necessaires sont absentes, incoherentes ou non verifiees.

NFR10: Les permissions appareil doivent etre limitees a `internet`, `notifications` et stockage local strictement necessaire au fonctionnement declare.

NFR11: Les parcours d'abonnement, de session et de diagnostic doivent respecter les regles de distribution et de transparence des stores cibles.

NFR12: Le produit doit maintenir un taux de `crash-free sessions >= 99,7 %` sur les versions candidates a la release.

NFR13: Aucun crash loop connu au demarrage ne doit etre accepte en release.

NFR14: Aucun fail-open connu sur auth, parental control ou entitlement ne doit etre accepte en release.

NFR15: Aucun cas connu de boucle de media resume ne doit etre accepte en release.

NFR16: Les flux `startup`, `auth`, `playback`, `resume`, `sync` et `subscription` doivent disposer de timeouts, retries et fallback bornes.

NFR17: En condition de reseau degrade ou d'integration indisponible, l'application doit atteindre un etat degrade comprehensible plutot qu'un etat bloquant ou ambigu.

NFR18: Le produit doit supporter les objectifs cibles de `1 000` utilisateurs actifs mensuels a `3 mois` et `10 000` utilisateurs actifs mensuels a `12 mois` sans degradation majeure des parcours critiques.

NFR19: La croissance x10 entre les objectifs `3 mois` et `12 mois` ne doit pas introduire plus de `10 %` de degradation sur les budgets de performance critiques valides.

NFR20: Les mecanismes de synchronisation et de diagnostic doivent rester exploitables sous croissance du volume d'evenements utilisateur.

NFR21: Les limites connues de capacite doivent etre surveillees et rendues visibles avant qu'elles ne degradent silencieusement l'experience.

NFR22: Les parcours critiques mobiles doivent respecter les attentes d'accessibilite de base des plateformes supportees pour lecture d'ecran, contraste, taille de texte supportee et navigation claire.

NFR23: Les parcours critiques TV doivent etre entierement utilisables via telecommande ou controle directionnel, avec focus visible, stable et previsible.

NFR24: Les ecrans cles doivent conserver une lisibilite adequate sur interface TV de type `10-foot UI`.

NFR25: Les etats d'erreur, de chargement, de blocage et d'etat degrade doivent etre communiques de facon perceptible et non ambigue.

NFR26: Les integrations critiques de contenu, session, synchronisation et entitlement doivent exposer des contrats stables et des comportements de fallback definis.

NFR27: Le produit doit maintenir la parite fonctionnelle des parcours critiques entre `Android` et `Android TV` au lancement.

NFR28: Les differences de surface d'usage entre tactile et telecommande doivent etre traitees sans regression fonctionnelle sur les parcours critiques.

NFR29: Le produit doit pouvoir evoluer vers `iOS` puis `Windows` sans redefinition du contrat fonctionnel coeur.

NFR30: Toute dependance externe critique doit avoir une strategie de degradation maitrisee en cas d'indisponibilite ou de reponse incoherente.

NFR31: Tous les flux critiques doivent etre traces avec `operationId`, `reasonCode` et contexte suffisant pour diagnostic.

NFR32: Les artefacts de diagnostic doivent permettre de relier un echec visible utilisateur a un evenement systeme sans exposer de donnees sensibles.

NFR33: Les etats `safe`, `degrade`, `recovered` ou `failed` doivent etre explicitement discernables dans l'observabilite.

NFR34: Aucune release critique ne doit etre autorisee si les preuves attendues sur `startup / auth / parental / playback / resume / sync / subscription / TV` sont absentes ou au rouge.

NFR35: Les preuves de verification doivent rester indexables et tracables de `REQ -> FLOW -> INV -> TST -> EVD`.

### Additional Requirements

- Utiliser [prd.md](C:/Users/berny/DEV/Flutter/movi/_bmad-output/planning-artifacts/prd.md) comme source fonctionnelle officielle et [architecture.md](C:/Users/berny/DEV/Flutter/movi/_bmad-output/planning-artifacts/architecture.md) comme source technique officielle pour la decomposition epics/stories.
- Retenir une architecture brownfield Flutter modulaire organisee par domaines fonctionnels, avec frontieres `presentation -> application -> domain -> data`.
- Conserver `Riverpod` comme mecanisme principal de state management UI et limiter `GetIt` a `lib/src/core/di/` et au composition root.
- Conserver `go_router` comme routeur declaratif principal, avec redirections critiques observables, deterministes et coherentes avec l'etat `startup/auth`.
- Conserver `Supabase` comme backend principal pour auth et services cloud existants, derriere des ports, repositories et adapters.
- Appliquer une strategie `local-first` avec sync bornee, etats `pending/degraded/recovered/failed` explicites et aucune UI bloquee par la sync cloud.
- Traiter `auth`, `parental`, `entitlement` et les decisions sensibles en `fail-closed` ou `fail-safe` selon le cas, jamais en etat ambigu.
- Encapsuler tout IO externe (`Supabase`, `Dio`, `sqflite`, `flutter_secure_storage`, `media_kit`, `Sentry`) derriere `core/*` ou `data/` adapters, jamais depuis l'UI.
- Ouvrir explicitement les domaines cibles `lib/src/core/subscription/`, `lib/src/features/subscription/`, `lib/src/core/notifications/` et `lib/src/features/notifications/` pour couvrir le PRD complet.
- Respecter les contraintes `Android` et `Android TV` comme cibles de lancement de premier ordre, avec focus visible, navigation directionnelle stable et lisibilite `10-foot UI`.
- Garder `test/` comme arborescence canonique de tests et considerer `tests/` comme dette legacy, sans nouveau fichier dedans.
- Geler `lib/src/core/utils/` et `lib/src/core/widgets/` comme zones legacy par defaut pour eviter d'y ajouter de nouveaux comportements opportunistes.
- Prioriser la migration brownfield sur `startup`, `auth`, `storage`, `network`, `parental`, `profile`, puis etendre proprement vers `subscription` et `notifications`.
- Appliquer `contracts first`: stabiliser ports, DTOs, failures typees, `reasonCode` et invariants avant tout deplacement majeur de code.
- Exiger une observabilite structuree avec `operationId`, `reasonCode`, redaction par defaut, preuves indexees, et aucune fuite de secret ou PII.

### UX Design Requirements

UX-DR1: La home de discovery doit prioriser `continue watching / resume` et un hero compact utile avant les rails secondaires.

UX-DR2: Les surfaces browse doivent limiter la densite visible, conserver une action principale evidente et eviter les homes surchargees.

UX-DR3: Les pages detail movie/TV doivent exposer une action primaire dominante et un retour contextuel coherent vers la surface d'origine.

UX-DR4: Les etats critiques `blocked`, `premium`, `pending-sync` et `degraded` doivent etre explicites dans le flux de navigation et de lecture.

UX-DR5: Les parcours `browse -> detail -> playback -> retour` doivent rester courts, predictibles et coherents entre mobile et TV.

UX-DR6: Les surfaces TV doivent garantir focus visible et stable, navigation directionnelle previsible, cibles genereuses et lisibilite `10-foot UI`.

### FR Coverage Map

FR1: Epic 1 - Entree fiable dans l'application meme quand le demarrage est degrade.

FR2: Epic 1 - Session et acces initial geres de facon coherente.

FR3: Epic 1 - Lisibilite du statut d'acces quand l'etat de session change.

FR4: Epic 1 - Reprise d'usage apres interruption sans perte de contexte essentiel.

FR5: Epic 2 - Parcours de decouverte de contenus movie et TV.

FR6: Epic 2 - Acces aux details d'un contenu avant lancement.

FR7: Epic 2 - Recuperation rapide d'un contenu pertinent depuis l'etat courant.

FR8: Epic 2 - Visibilite de l'etat "deja vu / en cours / reprenable".

FR9: Epic 2 - Navigation claire entre les parcours cles sans perte de progression mentale.

FR10: Epic 2 - Parcours critiques adaptes au mobile et a la TV.

FR11: Epic 3 - Lancement de lecture depuis les surfaces principales.

FR12: Epic 3 - Interruption et reprise sans reconstruction manuelle.

FR13: Epic 3 - Recuperation de progression sur un autre appareil supporte.

FR14: Epic 3 - Comprehension des echecs de lecture, reprise ou restauration.

FR15: Epic 3 - Recuperation apres echec de playback ou de resume.

FR16: Epic 3 - Continuite d'usage meme quand la sync n'est pas immediate.

FR17: Epic 3 - Reprise coherente entre films, episodes et contenus entames.

FR18: Epic 4 - Utilisation de profils distincts avec contexte separe.

FR19: Epic 4 - Definition et modification de restrictions parentales.

FR20: Epic 4 - Lisibilite de l'effet des restrictions et parametres sensibles.

FR21: Epic 4 - Consultation et modification des preferences supportees.

FR22: Epic 4 - Retrouver les preferences essentielles apres redemarrage ou changement d'appareil.

FR23: Epic 4 - Maintien d'un etat sur si certaines preferences ou politiques ne peuvent pas etre resolues.

FR24: Epic 5 - Comprehension du statut d'abonnement et du niveau d'acces.

FR25: Epic 5 - Acces aux fonctionnalites premium uniquement avec les droits correspondants.

FR26: Epic 5 - Restauration des droits apres session, appareil ou revalidation.

FR27: Epic 5 - Lisibilite d'un acces premium disponible, indisponible ou en attente.

FR28: Epic 5 - Parcours d'abonnement coherent avec les plateformes supportees.

FR29: Epic 6 - Choix utilisateur sur les notifications liees au contenu suivi.

FR30: Epic 6 - Information utile lors d'un nouvel episode ou evenement pertinent.

FR31: Epic 6 - Controle des preferences de notifications.

FR32: Epic 7 - Retrouver un etat utile minimal meme en reseau degrade.

FR33: Epic 7 - Comprendre les donnees ou actions en attente de synchronisation.

FR34: Epic 7 - Retour a un usage normal apres retour reseau sans reparation manuelle.

FR35: Epic 7 - Experience coherente entre appareils meme si certains evenements arrivent hors sequence.

FR36: Epic 8 - Diagnostic des incidents critiques par le support et les operations.

FR37: Epic 8 - Correlation des evenements critiques sans fuite de donnees sensibles.

FR38: Epic 8 - Distinction entre etat recuperable et action corrective necessaire.

FR39: Epic 8 - Informations de diagnostic suffisantes pour expliquer les echecs visibles.

FR40: Epic 8 - Signalement des situations en etat degrade ou en etat sur.

## Epic List

### Epic 1: Trusted App Entry, Access Recovery, and First Useful State
Les utilisateurs peuvent ouvrir l'application, retrouver une session coherente, recuperer d'un acces degrade, puis atteindre rapidement un premier etat utile sans boucle, sans spinner infini et sans confusion sur leur niveau d'acces.
**FRs covered:** FR1, FR2, FR3, FR4

### Epic 2: Discover and Navigate Content Across Mobile and TV
Les utilisateurs peuvent parcourir le catalogue, comprendre ou ils sont, retrouver un contenu pertinent et naviguer de facon lisible sur mobile comme sur TV.
**FRs covered:** FR5, FR6, FR7, FR8, FR9, FR10

### Epic 3: Launch, Recover and Resume Playback Reliably
Les utilisateurs peuvent lancer une lecture, reprendre un contenu, comprendre les echecs de playback ou de resume, et recuperer sans etat bloquant ni progression corrompue.
**FRs covered:** FR11, FR12, FR13, FR14, FR15, FR16, FR17

### Epic 4: Manage Profiles, Parental Rules and Preferences Safely
Les utilisateurs et titulaires de compte peuvent utiliser des profils, appliquer des restrictions parentales et gerer les preferences sensibles avec des comportements clairs, surs et predictibles.
**FRs covered:** FR18, FR19, FR20, FR21, FR22, FR23

### Epic 5: Understand, Restore and Use Premium Access
Les utilisateurs peuvent comprendre leur statut premium, acceder uniquement aux fonctionnalites autorisees, restaurer leurs droits et suivre un parcours d'abonnement coherent.
**FRs covered:** FR24, FR25, FR26, FR27, FR28

### Epic 6: Stay Informed Through Useful Re-engagement
Les utilisateurs peuvent choisir, recevoir et controler des notifications utiles liees au contenu suivi sans dependance critique du produit a ces messages.
**FRs covered:** FR29, FR30, FR31

### Epic 7: Preserve a Coherent Experience Across Sync and Degraded States
Les utilisateurs peuvent continuer a utiliser `movi` quand le reseau est degrade, comprendre les etats pending-sync et retrouver un usage normal sans reparer manuellement leur contexte.
**FRs covered:** FR32, FR33, FR34, FR35

### Epic 8: Diagnose Critical Incidents Without Exposing Sensitive Data
Le support et les operations peuvent diagnostiquer les incidents critiques, distinguer les etats recuperables, expliquer les echecs visibles et confirmer les etats surs sans fuite de donnees sensibles.
**FRs covered:** FR36, FR37, FR38, FR39, FR40

## Epic 1: Trusted App Entry, Access Recovery, and First Useful State

Les utilisateurs peuvent ouvrir l'application, retrouver une session coherente, recuperer d'un acces degrade, puis atteindre rapidement un premier etat utile sans boucle, sans spinner infini et sans confusion sur leur niveau d'acces.

### Story 1.1: Reach a Usable Startup State Without Crash Loops

As a user,
I want the application to reach a usable `Ready` or `Safe` state even when startup dependencies fail,
So that I can open the app without repeated crashes, infinite spinners, or silent hangs.

**FRs implemented:** FR1

**Acceptance Criteria:**

**Given** one or more startup dependencies fail, timeout, or return inconsistent state during bootstrap
**When** the application launches
**Then** the startup flow reaches a bounded `Safe` or `Ready` state instead of crashing or hanging
**And** the failure outcome is observable with stable `reasonCode` and correlated identifiers, without secrets or PII.

**Given** all required startup dependencies are available
**When** bootstrap completes successfully
**Then** the application transitions through explicit startup states into `Ready`
**And** the final route decision is observable and deterministic for the same startup inputs.

### Story 1.2: Restore Session and Initial Access Deterministically

As a returning user,
I want the application to restore my session and route me to the correct access level,
So that I immediately understand whether I am signed in, signed out, or in a limited safe state.

**FRs implemented:** FR2, FR3

**Acceptance Criteria:**

**Given** a previously stored session is valid and successfully revalidated
**When** initial access is resolved
**Then** the application routes to the authenticated experience
**And** the resulting access decision is consistent for the same validated session state.

**Given** the session state is unknown, invalid, expired, or cannot be verified
**When** the initial route decision is made
**Then** the application defaults to a signed-out or otherwise safe non-authenticated path
**And** no protected route is exposed by mistake.

### Story 1.3: Recover Cleanly From Expired, Offline, and Timeout Session States With Explicit Recovery UX

As a returning user,
I want interrupted or degraded session restoration to end in a clear visible recovery state,
So that I can continue safely or reauthenticate without redirect loops or blocked navigation.

**FRs implemented:** FR2, FR3

**Acceptance Criteria:**

**Given** a stored session is expired or no longer valid
**When** session restoration runs
**Then** invalid sensitive state is cleared as required
**And** the user is shown a clear reauthentication or recovery path without redirect loops.

**Given** session restoration is blocked by offline conditions, timeout, or backend unavailability
**When** the maximum bounded wait is reached
**Then** the application remains navigable in a safe degraded state
**And** retries stay explicit, bounded, and observable.

**Given** the user lands in an expired, offline, timeout, or revalidated degraded path
**When** the recovery state is shown
**Then** the screen explains the current access state, the primary next action, and any allowed degraded continuation path
**And** the user never has to infer whether the app is blocked, retrying, or safe to continue.

### Story 1.4: Restore Essential Context Into the Correct First Useful State

As a returning user,
I want the app to restore my essential context into the correct first useful state after interruption,
So that I can continue from a useful place without losing my orientation or bypassing safety gates.

**FRs implemented:** FR4

**Acceptance Criteria:**

**Given** startup and access resolution complete successfully
**When** the application restores essential context
**Then** the user lands on the last safe relevant screen, `home lite`, or an equivalent useful entry point
**And** the restored context does not bypass auth, parental, or entitlement gates.

**Given** the previously stored context is invalid, stale, or no longer safe to restore
**When** context restoration is attempted
**Then** the application falls back to a safe default entry point
**And** the user is not left in an ambiguous or broken navigation state.

**Given** secondary data such as full catalog freshness or library hydration is not yet complete
**When** the first useful state becomes visible
**Then** the application may continue hydrating in the background
**And** the user is not blocked behind a full preload corridor when a safe useful state already exists.

### Story 1.5: Resolve the Entry Flow Into a Single First Useful State Contract

As a user opening the app,
I want the entry flow to resolve into one coherent first useful state contract,
So that launch logic feels fast, predictable, and understandable instead of fragmented across technical screens.

**FRs implemented:** FR1, FR3, FR4

**Acceptance Criteria:**

**Given** startup, auth, profile, and source decisions are being evaluated
**When** the application resolves the entry flow
**Then** it produces one explicit user-facing destination contract such as `auth recovery`, `profile decision`, `source hub`, `source warmup`, or `home lite`
**And** route orchestration does not expose redundant technical corridors as separate product states.

**Given** the app can reach a safe useful state before full hydration completes
**When** first useful state is available
**Then** the shell or equivalent useful surface becomes visible within the defined launch budget
**And** non-critical warmup continues progressively in the background.

### Story 1.6: Surface Explicit Entry States for Empty, Loading, Error, Timeout, Offline, Expired, and Recovered Conditions

As a user entering the app,
I want every critical entry condition to be represented by a clear state,
So that I always understand what is happening, what is safe, and what to do next.

**FRs implemented:** FR1, FR2, FR3, FR32, FR33

**Acceptance Criteria:**

**Given** the entry flow encounters `empty`, `loading`, `error`, `timeout`, `offline`, `expired`, or `recovered` conditions
**When** the relevant screen is rendered
**Then** the application shows a distinct state with the correct explanation and next action
**And** the state is distinguishable from normal, blocked, and pending-sync outcomes.

**Given** the underlying condition changes because retry, reconnect, revalidation, or recovery succeeds
**When** the entry UI refreshes
**Then** the visible state updates coherently without contradictory banners, stale labels, or hidden redirects
**And** the user remains on a deterministic path.

### Story 1.7: Make the Entry Flow Fully Usable on Android TV

As a user on Android TV,
I want the entry flow to work naturally with directional navigation,
So that auth, profile, source, and recovery states remain clear and controllable on TV.

**FRs implemented:** FR10

**Acceptance Criteria:**

**Given** the user navigates startup, auth, profile, source, or recovery screens with a remote
**When** focus moves across primary and secondary actions
**Then** focus remains visible, deterministic, and spatially coherent
**And** no focus trap, hidden action, or ambiguous next move occurs.

**Given** the same entry path is used on mobile and Android TV
**When** the UI renders on TV
**Then** the same core states and actions remain available with adapted spacing, readability, and target sizing
**And** the presentation satisfies `10-foot UI` clarity before the user reaches discovery or playback.

## Epic 2: Discover and Navigate Content Across Mobile and TV

Les utilisateurs peuvent parcourir le catalogue, comprendre ou ils sont, retrouver un contenu pertinent et naviguer de facon lisible sur mobile comme sur TV.

### Story 2.1: Present a Dedicated Discovery Home With Prioritized Content Paths

As a media user,
I want a dedicated discovery home with clear content priorities,
So that I can start browsing useful movie and TV options immediately.

**FRs implemented:** FR5

**Acceptance Criteria:**

**Given** primary app state and a safe local or remote content snapshot are available
**When** the discovery home renders as the first useful post-entry surface
**Then** the user sees a dedicated browse surface with a compact hero, a visible primary action, and structured movie/TV rails
**And** the main browse path is reachable without navigating through secondary screens first.

**Given** one or more secondary discovery feeds fail, timeout, or return empty data
**When** the home surface is shown
**Then** the application keeps the discovery home usable with partial content or explicit empty states
**And** the failure is communicated without blocking navigation to available content.

**Given** the app has reached `home lite` before full hydration completes
**When** secondary rails, freshness checks, or library hydration finish later
**Then** the discovery home enriches progressively in place
**And** the user does not lose shell context or re-enter a blocking bootstrap screen.

### Story 2.2: Resolve Movie and TV Content Into a Usable Detail State

As a media user,
I want to open a movie or TV detail page that is immediately usable,
So that I can understand the content and decide whether to launch it.

**FRs implemented:** FR6

**Acceptance Criteria:**

**Given** the user selects a movie or TV item from discovery, continue watching, or another supported entry point
**When** the detail route resolves
**Then** the application shows the correct identity, key metadata, and dominant primary action for that item
**And** the user can decide to play, resume, or back out without ambiguity.

**Given** content resolution is unavailable, inconsistent, blocked, or timed out
**When** the detail route opens
**Then** the application shows a clear degraded or blocked state with a safe next action
**And** no silent failure or unintended playback attempt occurs.

### Story 2.3: Surface Relevant Content From the User's Current Context

As a returning media user,
I want the app to surface relevant content from my current context,
So that I can quickly continue from what matters now instead of starting discovery from scratch.

**FRs implemented:** FR7

**Acceptance Criteria:**

**Given** the user has recent, in-progress, or contextually related items
**When** the discovery home or equivalent entry surface opens
**Then** the application prioritizes those items ahead of generic browse content
**And** the promoted entry points align with the user's last safe known context.

**Given** the user's recent context is unavailable, stale, or incompatible with the active profile or access state
**When** the entry surface renders
**Then** the application falls back to neutral discovery content
**And** no misleading recommendation or stale shortcut is shown as current.

### Story 2.4: Expose In-Progress and Resume Signals Without Ambiguity

As a user who has already started content,
I want clear in-progress and resume signals across discovery surfaces,
So that I can tell what I was watching and what can be resumed.

**FRs implemented:** FR8

**Acceptance Criteria:**

**Given** progress or started-state data exists for a visible item
**When** that item appears on home, rails, or detail surfaces
**Then** the UI displays explicit progress or resume status for the item
**And** the primary action reflects whether the next step is `Resume`, `Continue`, or `Play`.

**Given** progress data is missing, stale, or not safe to trust
**When** the item is rendered
**Then** the UI does not expose a false resume affordance
**And** the user is shown a neutral, non-ambiguous content state instead.

### Story 2.5: Preserve Navigation Context Across Browse, Detail, and Return Flows

As a media user,
I want navigation between browse, detail, playback entry points, and return flows to preserve my place,
So that I do not lose orientation while moving through the app.

**FRs implemented:** FR9

**Acceptance Criteria:**

**Given** the user enters detail from a specific rail, grid, or prioritized entry
**When** the user navigates back from detail
**Then** the originating surface restores the relevant scroll, selection, or focus context
**And** the user returns to the last meaningful safe position instead of an unrelated top-level state.

**Given** the user exits a blocked, degraded, or pre-playback state
**When** the application routes them back into discovery
**Then** the return path preserves enough context for the next action to remain obvious
**And** the user does not need to reconstruct the journey manually.

### Story 2.6: Adapt Discovery and Detail Interactions for Android TV

As a user on Android TV,
I want discovery and detail surfaces to work naturally with remote control navigation,
So that browsing and selection remain clear, stable, and comfortable on TV.

**FRs implemented:** FR10

**Acceptance Criteria:**

**Given** the user navigates discovery or detail surfaces with directional input on Android TV
**When** focus moves across hero, rails, grids, and primary actions
**Then** focus remains visible, deterministic, and spatially coherent
**And** no focus trap, hidden target, or ambiguous next move occurs.

**Given** the same critical discovery/detail path is used on mobile and TV
**When** the surfaces render on TV
**Then** the same core actions and user states remain available with adapted spacing, readability, and target sizing
**And** the TV presentation satisfies `10-foot UI` legibility and primary-action clarity.

## Epic 3: Launch, Recover and Resume Playback Reliably

Les utilisateurs peuvent lancer une lecture, reprendre un contenu, comprendre les echecs de playback ou de resume, et recuperer sans etat bloquant ni progression corrompue.

### Story 3.1: Launch Eligible Playback From Primary Content Surfaces

As a media user,
I want to launch playback from the main content surfaces,
So that I can start watching without extra navigation or ambiguity.

**FRs implemented:** FR11

**Acceptance Criteria:**

**Given** eligible content is visible from discovery, detail, or continue-watching entry points
**When** the user activates the primary play or resume action
**Then** the application routes into the correct playback entry flow for that content and current access state
**And** the same business action remains available on mobile and TV with surface-appropriate interaction.

**Given** the selected content is blocked, unavailable, or not currently eligible for playback
**When** the user triggers the primary playback action
**Then** the application prevents an unsafe launch and shows a clear blocked or degraded state with a next action
**And** no silent failure, no-op, or opaque spinner is left on screen.

### Story 3.2: Reach a Playable State With Bounded Startup and Observable Outcomes

As a media user,
I want playback startup to either begin quickly or fail explicitly,
So that I know whether my content is actually starting.

**FRs implemented:** FR11, FR14

**Acceptance Criteria:**

**Given** content resolution and playback dependencies succeed
**When** playback startup executes
**Then** the application reaches a playable state through explicit loading states and bounded waits
**And** the startup outcome is observable with stable `reasonCode` and correlated identifiers.

**Given** source resolution, buffering, or engine initialization fails, times out, or returns inconsistent state
**When** the maximum bounded startup policy is reached
**Then** the application ends in an explicit failed or degraded state instead of hanging indefinitely
**And** the user is given a safe recovery option.

### Story 3.3: Restore Local Playback Progress After Interruption

As a returning viewer,
I want interrupted content to resume from safe local progress,
So that I do not have to reconstruct my last position manually.

**FRs implemented:** FR12

**Acceptance Criteria:**

**Given** valid local progress exists for previously started content
**When** the user returns via continue watching, detail, or another supported playback entry
**Then** the application restores the last safe local checkpoint and relevant playback context
**And** the resume flow avoids duplicate progress application or resume loops.

**Given** locally stored progress is stale, invalid, or no longer safe to apply
**When** local resume is attempted
**Then** the application falls back to a neutral validated action such as `Play`, `Restart`, or another safe checkpoint
**And** corrupted or ambiguous progress is not applied.

### Story 3.4: Reconcile Cross-Device Progress Without Blocking Local Use

As a multi-device user,
I want my playback progress to reconcile across devices without blocking local use,
So that I can continue watching even when synchronization is delayed.

**FRs implemented:** FR13, FR16

**Acceptance Criteria:**

**Given** local and cloud progress differ or arrive out of sequence
**When** reconciliation executes on a supported device
**Then** the application applies a deterministic resume policy to select the effective progress state
**And** the user-facing experience remains usable while synchronization completes in the background.

**Given** the network is unavailable, slow, or temporarily inconsistent
**When** the user opens started content on another device
**Then** the application exposes the best safe local state plus an explicit `pending-sync` or degraded status when necessary
**And** retries remain bounded and recover cleanly when connectivity returns.

### Story 3.5: Explain Playback and Resume Failures With Actionable Recovery

As a media user,
I want playback and resume failures to be explained clearly,
So that I can recover without being left in a blocked or ambiguous state.

**FRs implemented:** FR14, FR15

**Acceptance Criteria:**

**Given** playback start, resume, or progress restoration cannot succeed
**When** the failure state is reached
**Then** the UI shows a clear failure state with a meaningful next action such as retry, restart, or return to details
**And** the failure is distinguishable from loading, pending, or blocked access states.

**Given** the user chooses a recovery action from a playback or resume failure
**When** the fallback path executes
**Then** the application returns to a safe deterministic state without redirect loops, stuck overlays, or corrupted progress
**And** diagnostics capture a stable `reasonCode` without exposing sensitive data.

### Story 3.6: Apply Resume Policies Consistently Across Movies, Episodes, and Started Content

As a viewer of mixed movie and TV content,
I want resume behavior to stay consistent across content types,
So that I can trust what `Resume` means everywhere in the app.

**FRs implemented:** FR17

**Acceptance Criteria:**

**Given** the content is a movie, an episode, or another previously started item with valid progress
**When** the application resolves the primary playback action
**Then** it applies a consistent policy for checkpoint selection, `Resume` labeling, and play-versus-resume semantics
**And** discovery, detail, and player entry points interpret the same content state coherently.

**Given** episode boundaries, completed content, or stale progress make resume inappropriate
**When** the action state is resolved
**Then** the application falls back to the correct next action such as `Play`, `Restart`, or `Next Episode`
**And** the user is not shown contradictory or misleading resume affordances.

## Epic 4: Manage Profiles, Parental Rules and Preferences Safely

Les utilisateurs et titulaires de compte peuvent utiliser des profils, appliquer des restrictions parentales et gerer les preferences sensibles avec des comportements clairs, surs et predictibles.

### Story 4.1: Restore and Switch Profiles With Isolated Usage Context

As a household user,
I want to restore or switch to the correct profile with isolated context,
So that my usage state stays separate from other users.

**FRs implemented:** FR18

**Acceptance Criteria:**

**Given** one or more profiles are available to the active account
**When** the user restores or selects a profile
**Then** the application applies the chosen profile as the active context for discovery, playback, resume, and settings
**And** data or shortcuts from another profile are not surfaced as if they belonged to the current user.

**Given** a stored profile reference is stale, unavailable, or no longer authorized
**When** profile restoration is attempted
**Then** the application falls back to a safe profile selection or neutral state
**And** no protected or mismatched profile context is silently reused.

### Story 4.2: Create and Update Profile-Level Parental Restrictions

As an account holder or parent,
I want to define and modify parental restrictions for a target profile,
So that sensitive content stays inaccessible according to the rules I set.

**FRs implemented:** FR19

**Acceptance Criteria:**

**Given** the active user is allowed to manage parental controls
**When** they create or update restrictions for a profile
**Then** the application persists the new restriction policy with explicit confirmation
**And** the resulting policy is tied to the intended profile only.

**Given** the requested parental change is invalid, incomplete, or cannot be saved safely
**When** the update is submitted
**Then** the application rejects the unsafe change with a clear explanation
**And** the previous effective restriction policy remains in force.

### Story 4.3: Enforce Parental Decisions on Discovery, Details, and Playback Entry

As a protected-profile user,
I want parental rules to be enforced consistently across content entry points,
So that blocked content cannot be reached accidentally or by shortcut.

**FRs implemented:** FR19, FR23

**Acceptance Criteria:**

**Given** content violates the active profile's parental restrictions
**When** the user encounters it in discovery, detail, deep-link-equivalent entry, or playback launch
**Then** the application blocks the sensitive action using the same effective rule set
**And** the user is not allowed to bypass the restriction through an alternate entry path.

**Given** restriction data is missing, stale, or cannot be verified safely
**When** a sensitive content decision must be made
**Then** the application chooses the documented safe blocked state
**And** no fail-open behavior exposes content that should remain restricted.

### Story 4.4: Show the Effect of Sensitive Rules and Settings in Context

As an account holder or parent,
I want to understand the effect of the restrictions and sensitive settings I apply,
So that I can trust what the app is allowing, blocking, or deferring.

**FRs implemented:** FR20

**Acceptance Criteria:**

**Given** a parental rule or other sensitive setting affects what the user can do
**When** that effect matters in discovery, details, settings, or playback entry
**Then** the application shows a clear in-context explanation of the resulting state
**And** the explanation distinguishes blocked access, pending resolution, and normal availability without ambiguity.

**Given** a sensitive state changes because of profile switch, policy update, or validation result
**When** the UI refreshes
**Then** the visible messaging updates coherently with the new effective rule
**And** stale or contradictory status labels are removed.

### Story 4.5: View and Update Supported Application Preferences Safely

As a user,
I want to view and change supported application preferences,
So that the app reflects my intended runtime behavior.

**FRs implemented:** FR21

**Acceptance Criteria:**

**Given** supported preferences are available for the active profile or account scope
**When** the user opens the relevant settings surface
**Then** the application displays the current effective preference values with clear editability
**And** the user can update supported preferences without navigating through opaque system states.

**Given** a preference update is invalid, conflicts with a higher-priority rule, or cannot be applied safely
**When** the user saves the change
**Then** the application preserves the last safe effective value
**And** the user is shown what failed and what remains active.

### Story 4.6: Restore Essential Preferences Across Restart and Device Changes With Safe Fallbacks

As a returning user,
I want essential preferences to be restored across restarts and supported device changes,
So that my app experience remains coherent without compromising safety.

**FRs implemented:** FR22, FR23

**Acceptance Criteria:**

**Given** essential preference state was previously saved for the active user or profile
**When** the application restarts or the user resumes on another supported device
**Then** the application restores the effective preferences that are valid for the current context
**And** the restored values remain consistent with the active profile and sensitive policy state.

**Given** a preference, rule, or policy cannot be resolved because data is missing, stale, or inconsistent
**When** the application computes the effective settings state
**Then** it falls back to a documented safe state instead of exposing ambiguous behavior
**And** the unresolved condition is visible enough for the user to understand what remains active.

## Epic 5: Understand, Restore and Use Premium Access

Les utilisateurs peuvent comprendre leur statut premium, acceder uniquement aux fonctionnalites autorisees, restaurer leurs droits et suivre un parcours d'abonnement coherent.

### Story 5.1: Surface the Current Subscription and Entitlement Status Clearly

As a user,
I want to see my current subscription and access status clearly,
So that I understand what premium rights are active right now.

**FRs implemented:** FR24

**Acceptance Criteria:**

**Given** the application has a verified entitlement or subscription state for the active account
**When** the user opens the relevant premium or account surface
**Then** the application shows the current access level and premium status in a clear, non-ambiguous way
**And** the displayed state matches the effective rights currently enforced by the system.

**Given** the entitlement state is still pending verification or temporarily degraded
**When** the premium status surface renders
**Then** the application shows an explicit pending or degraded state instead of implying confirmed premium access
**And** the user is not misled into believing rights are active before verification completes.

### Story 5.2: Gate Premium Capabilities With Fail-Closed Access Decisions

As a premium or non-premium user,
I want premium capabilities to be exposed only when my rights are verified,
So that access stays safe and consistent.

**FRs implemented:** FR25

**Acceptance Criteria:**

**Given** a user attempts to enter a premium-only capability or feature path
**When** the access decision is evaluated
**Then** the application allows the action only if the effective entitlement is verified for the active account
**And** the same decision is enforced consistently across all supported entry points.

**Given** the entitlement information is missing, stale, inconsistent, or cannot be verified safely
**When** a premium access decision must be made
**Then** the application chooses the documented non-premium or blocked state
**And** no fail-open behavior exposes premium capability by mistake.

### Story 5.3: Restore and Revalidate Premium Rights After Session or Device Changes

As a returning user,
I want my premium rights to be restored after session recovery, reconnection, or device change,
So that I do not lose access incorrectly when my account is still entitled.

**FRs implemented:** FR26

**Acceptance Criteria:**

**Given** the active account has previously established premium rights
**When** the application restores session state, reconnects, or resumes on another supported device
**Then** the entitlement state is revalidated through the supported authority and applied to the active account
**And** the resulting access state becomes consistent with the verified outcome.

**Given** entitlement restoration is delayed, fails, or returns conflicting information
**When** revalidation completes or times out
**Then** the application preserves a safe temporary access state until the conflict is resolved
**And** the user-facing status remains explicit rather than silently oscillating.

### Story 5.4: Explain Why Premium Access Is Available, Unavailable, or Pending

As a user,
I want the app to explain why premium access is available, unavailable, or pending,
So that I can understand what is happening and what to do next.

**FRs implemented:** FR27

**Acceptance Criteria:**

**Given** the premium state is active, blocked, expired, pending confirmation, or otherwise limited
**When** that state affects a visible user decision
**Then** the application shows a contextual explanation tied to the current status
**And** the explanation distinguishes entitlement state from unrelated failures such as playback or network issues.

**Given** the user can take a follow-up action such as retry verification, restore purchase, manage account, or continue in non-premium mode
**When** the status explanation is displayed
**Then** the relevant next action is presented clearly
**And** the user is not left with an opaque premium message and no recovery path.

### Story 5.5: Run a Store-Coherent Subscription Purchase Flow

As an account holder,
I want to subscribe through a coherent supported purchase flow,
So that premium access aligns with platform expectations and confirmed account rights.

**FRs implemented:** FR28

**Acceptance Criteria:**

**Given** the user enters the supported subscription purchase flow
**When** they review plans and start a purchase
**Then** the application follows the platform-appropriate purchase path with clear status transitions and user messaging
**And** the resulting entitlement state is synchronized back into the app without contradictory account status.

**Given** the purchase attempt is canceled, rejected, incomplete, or not confirmed by the supported authority
**When** the flow ends
**Then** the application leaves the account in the correct non-premium or pending state
**And** no screen claims premium success before entitlement verification is actually complete.

### Story 5.6: Run a Store-Coherent Restore Purchase Flow

As an account holder,
I want to restore prior purchases through a coherent supported flow,
So that previously valid rights can be recovered consistently on supported platforms.

**FRs implemented:** FR26, FR28

**Acceptance Criteria:**

**Given** the user enters the supported restore-purchase flow
**When** they trigger restore for an eligible account on a supported platform
**Then** the application follows the platform-appropriate restore path with clear status transitions and user messaging
**And** the resulting entitlement state is revalidated and synchronized back into the app without contradictory account status.

**Given** the restore attempt is canceled, rejected, incomplete, or not confirmed by the supported authority
**When** the flow ends
**Then** the application leaves the account in the correct non-premium or pending state
**And** no screen claims restored premium access before entitlement verification is actually complete.

## Epic 6: Stay Informed Through Useful Re-engagement

Les utilisateurs peuvent choisir, recevoir et controler des notifications utiles liees au contenu suivi sans dependance critique du produit a ces messages.

### Story 6.1: Let Users Opt In or Out of Followed-Content Notifications

As a user,
I want to choose whether I receive notifications related to followed content,
So that I stay informed only when I want to.

**FRs implemented:** FR29

**Acceptance Criteria:**

**Given** the user reaches a supported notification consent or settings surface
**When** they enable or disable followed-content notifications
**Then** the application records the resulting consent state for the active account or profile scope
**And** any required platform permission step is tied clearly to the user's choice.

**Given** notification permission is denied, unavailable, or revoked at the platform level
**When** the user attempts to enable followed-content notifications
**Then** the application shows the resulting disabled or limited state explicitly
**And** the core product remains usable without implying that notifications are active.

### Story 6.2: Deliver Useful Notifications for New Episodes and Relevant Followed-Content Events

As a user following content,
I want to receive useful alerts when a new episode or relevant event occurs,
So that I can re-engage with content that matters to me.

**FRs implemented:** FR30

**Acceptance Criteria:**

**Given** the user has opted in to supported followed-content notifications
**When** a new episode or another supported relevant event is detected for tracked content
**Then** the system produces a notification payload that matches the followed content and current preference state
**And** the message is useful, non-ambiguous, and does not depend on the user already having the app open.

**Given** the event is unsupported, duplicated, or no longer valid for the active preference state
**When** delivery is evaluated
**Then** the application or notification pipeline suppresses the notification safely
**And** no contradictory, stale, or noisy alert is sent to the user.

### Story 6.3: Let Users Control Supported Notification Preferences Clearly

As a user,
I want to view and update supported notification preferences clearly,
So that I can control which notification experiences the product uses.

**FRs implemented:** FR31

**Acceptance Criteria:**

**Given** supported notification options exist for the active user context
**When** the user opens the notifications preferences surface
**Then** the application shows the current effective notification settings with clear editability
**And** the user can distinguish global notification state from content-specific notification choices.

**Given** a notification preference cannot be applied because of missing permission, stale state, or delivery unavailability
**When** the user saves the preference change
**Then** the application preserves the last safe effective preference state
**And** the user is shown what changed, what did not, and why.

## Epic 7: Preserve a Coherent Experience Across Sync and Degraded States

Les utilisateurs peuvent continuer a utiliser `movi` quand le reseau est degrade, comprendre les etats pending-sync et retrouver un usage normal sans reparer manuellement leur contexte.

### Story 7.1: Reach a Minimal Useful State When Network Conditions Are Degraded

As a user in poor network conditions,
I want the app to remain minimally useful when connectivity is unavailable or degraded,
So that I am not blocked from understanding my current context.

**FRs implemented:** FR32

**Acceptance Criteria:**

**Given** the network is unavailable, slow, or unstable during a critical user path
**When** the application resolves the current screen state
**Then** it falls back to a minimal useful local state instead of an infinite wait or blocked screen
**And** the user can still understand the current safe context and available next actions.

**Given** required remote data cannot be fetched safely
**When** the fallback state is shown
**Then** the application makes the degraded condition explicit
**And** it avoids implying that missing remote data is already current or confirmed.

**Given** degraded connectivity occurs during the app entry flow
**When** a full warmup path cannot complete in time
**Then** the application prefers a safe minimal useful entry state over a blocked preload corridor
**And** the user can still identify active profile, source, and next safe action.

### Story 7.2: Surface Pending-Sync and Degraded States in Context

As a user,
I want pending-sync and degraded states to be visible in context,
So that I understand which data or actions are still catching up.

**FRs implemented:** FR33

**Acceptance Criteria:**

**Given** local changes, delayed updates, or deferred reconciliation exist
**When** the affected content or surface is rendered
**Then** the application shows an explicit in-context `pending-sync` or degraded status where the decision matters
**And** the status is distinguishable from normal, blocked, and failed states.

**Given** the sync state changes because reconciliation succeeds, fails, or remains delayed
**When** the UI refreshes
**Then** the visible status updates coherently without contradictory banners or stale indicators
**And** the user is not forced to infer the state from missing or inconsistent content.

**Given** entry, home-lite, or source warmup is still reconciling remote freshness
**When** the user reaches the first useful state
**Then** any `pending-sync` or degraded marker appears in the decision context that it affects
**And** the user is not left to guess whether content is current, local-only, or still recovering.

### Story 7.3: Recover to Normal Use Automatically When Connectivity Returns

As a user,
I want the app to recover automatically when network conditions improve,
So that I can resume normal use without manually repairing my state.

**FRs implemented:** FR34

**Acceptance Criteria:**

**Given** the user is in a degraded or pending-sync state caused by temporary network issues
**When** connectivity returns and required retries or reconciliation succeed
**Then** the application restores the normal effective state automatically
**And** the user does not need to restart the app or manually rebuild the previous context.

**Given** recovery cannot complete immediately after connectivity returns
**When** the application retries within bounded policy
**Then** it keeps the user in the clearest safe intermediate state
**And** it avoids oscillating between conflicting recovered and degraded states.

### Story 7.4: Reconcile Out-of-Sequence Cross-Device Events Deterministically

As a multi-device user,
I want cross-device updates to stay coherent even when events arrive out of sequence,
So that my app state remains trustworthy across supported devices.

**FRs implemented:** FR35

**Acceptance Criteria:**

**Given** local and remote events affecting progress, preferences, or other synchronized state arrive out of sequence
**When** reconciliation is performed
**Then** the application applies a deterministic conflict-resolution policy for the affected state
**And** the resulting user-visible state remains coherent across supported devices.

**Given** an out-of-sequence event cannot be resolved immediately or safely
**When** the conflict is detected
**Then** the application preserves the best safe state while surfacing the relevant pending or degraded status where needed
**And** no silent corruption or contradictory effective state is exposed to the user.

## Epic 8: Diagnose Critical Incidents Without Exposing Sensitive Data

Le support et les operations peuvent diagnostiquer les incidents critiques, distinguer les etats recuperables, expliquer les echecs visibles et confirmer les etats surs sans fuite de donnees sensibles.

### Story 8.1: Instrument Access and Session Critical Flows With Stable Diagnostic Identifiers

As a support or operations stakeholder,
I want access and session critical flows to emit stable diagnostic identifiers,
So that incidents in startup, auth, parental, and subscription gates can be traced consistently.

**FRs implemented:** FR36

**Acceptance Criteria:**

**Given** a critical startup, auth, parental, or subscription gate executes
**When** the system records diagnostic events for that flow
**Then** the emitted events include stable `operationId`, `reasonCode`, and enough contextual state to support diagnosis
**And** the same failure mode maps to the same diagnostic vocabulary across supported devices.

**Given** one of those access or session flows completes successfully or degrades safely
**When** observability data is emitted
**Then** the resulting events still identify the effective outcome explicitly
**And** support can distinguish safe, degraded, blocked, and failed access outcomes.

**Given** the application resolves an entry-flow destination such as `auth recovery`, `profile decision`, `source hub`, `source warmup`, `home lite`, or `home hydrated`
**When** diagnostics are recorded for that launch
**Then** all events for the same launch share a correlated entry-flow identifier and timing checkpoints
**And** support can distinguish `first useful state visible` from later background hydration completion.

### Story 8.2: Instrument Playback, Resume, and Sync Critical Flows With Stable Diagnostic Identifiers

As a support or operations stakeholder,
I want playback, resume, and sync critical flows to emit stable diagnostic identifiers,
So that media continuity incidents can be traced consistently.

**FRs implemented:** FR36

**Acceptance Criteria:**

**Given** a playback, resume, or synchronization critical flow executes
**When** the system records diagnostic events for that flow
**Then** the emitted events include stable `operationId`, `reasonCode`, and enough contextual state to support diagnosis
**And** support can connect the resulting event stream to the affected media continuity path.

**Given** one of those media continuity flows succeeds, degrades, or fails
**When** observability data is emitted
**Then** the resulting events preserve the effective outcome explicitly
**And** the diagnostic trail remains stable across retries, fallback paths, and later recovery.

### Story 8.3: Correlate Critical Events Across System Layers

As a support or operations stakeholder,
I want related critical events to be correlatable across system layers,
So that I can investigate incidents without reconstructing the flow manually.

**FRs implemented:** FR37

**Acceptance Criteria:**

**Given** multiple diagnostic events belong to the same critical user-facing flow
**When** they are collected across app, service, and adapter boundaries
**Then** support can correlate them through shared identifiers and stable metadata
**And** the related event chain remains understandable without depending on raw unstructured logs.

**Given** retries, fallbacks, or recovery paths produce additional events for the same incident
**When** diagnostics are reviewed
**Then** the correlated trail preserves the sequence and outcome of those events coherently
**And** support can follow the incident path without ambiguous branching.

### Story 8.4: Redact Diagnostic Payloads by Default While Preserving Investigation Value

As a support or operations stakeholder,
I want diagnostic payloads to be redacted by default,
So that incidents remain investigable without exposing secrets or PII.

**FRs implemented:** FR37

**Acceptance Criteria:**

**Given** a diagnostic payload includes fields that are too sensitive or too verbose for operational use
**When** the event is persisted or reported
**Then** the application redacts or suppresses the unsafe fields before emission
**And** no secrets, tokens, or PII are exposed in logs, reports, or evidence.

**Given** a payload is redacted for safety
**When** support reviews the resulting event
**Then** the retained diagnostic information remains sufficient for incident analysis
**And** redaction does not destroy the identifiers needed for safe correlation.

### Story 8.5: Distinguish Recoverable States From States Requiring Corrective Action

As a support or operations stakeholder,
I want the system to distinguish recoverable incidents from ones needing corrective action,
So that triage decisions are fast and consistent.

**FRs implemented:** FR38

**Acceptance Criteria:**

**Given** a critical flow ends in a non-nominal state
**When** the diagnostic outcome is classified
**Then** the system marks whether the state is recoverable, degraded-but-usable, blocked, or requires corrective action
**And** the classification is consistent with the user-visible next action and system state.

**Given** the system cannot establish a normal outcome with confidence
**When** the classification is emitted
**Then** it falls back to the documented safe diagnosis rather than under-reporting severity
**And** the resulting triage signal does not imply false recovery.

### Story 8.6: Link Visible User Failures to Actionable Diagnostic Context

As a support stakeholder,
I want visible user failures to map to actionable diagnostic context,
So that I can explain what happened without reverse-engineering the entire flow.

**FRs implemented:** FR39

**Acceptance Criteria:**

**Given** a user encounters a visible failure in a critical path
**When** the application shows the resulting error or degraded state
**Then** the underlying diagnostics preserve enough linked context to identify the relevant operation, reason, and affected flow
**And** support can relate the visible symptom to a concrete system event trail.

**Given** the visible failure is resolved through retry, fallback, or later recovery
**When** diagnostics are reviewed
**Then** the incident history still shows the original failure and the subsequent outcome coherently
**And** the final evidence does not erase the path that produced the user-visible problem.

### Story 8.7: Signal Safe, Degraded, Recovered, and Failed States Explicitly

As a user and support stakeholder,
I want system states such as `safe`, `degraded`, `recovered`, and `failed` to be explicit,
So that both the visible experience and operational diagnosis remain trustworthy.

**FRs implemented:** FR40

**Acceptance Criteria:**

**Given** a critical flow transitions between normal and non-normal states
**When** the effective state is resolved
**Then** the application and diagnostics expose an explicit state label that matches the actual outcome
**And** the state remains consistent between user-visible messaging and support-facing evidence.

**Given** the flow later recovers or stabilizes after degradation
**When** the final state is updated
**Then** the system marks the transition to `recovered` or the appropriate end state explicitly
**And** prior degraded or failed evidence remains traceable rather than silently overwritten.

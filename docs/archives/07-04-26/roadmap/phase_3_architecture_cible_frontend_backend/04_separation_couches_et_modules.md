# Sous-phase 3.3 - Separation des couches et modules

## Objectif

Fixer les frontieres entre presentation, application, domain et data pour le tunnel d'entree, puis mapper l'existant vers cette cible.

Cette sous-phase repond a deux questions:
- ou doit vivre chaque responsabilite du tunnel
- quels modules actuels doivent etre conserves, extraits, fusionnes, simplifies ou supprimes

## Principe directeur

Le tunnel d'entree doit etre organise en quatre couches nettes:

1. `presentation`
2. `application`
3. `domain`
4. `data / infrastructure`

Regle structurante:
- la presentation affiche et emet des intentions
- l'application orchestre la sequence
- le domain porte les regles et contrats metier
- le data/infrastructure parle aux SDK, preferences, stockage, cloud et reseau

## Schema de couches cible

## 1. Presentation

Responsabilites:
- pages du tunnel
- widgets et composants UI
- adapteurs focus TV
- binding de formulaire
- consommation de `TunnelState`
- emission d'intentions utilisateur

Exemples cibles:
- `Preparation systeme`
- `Auth`
- `Creation profil`
- `Choix profil`
- `Choix / ajout source`
- `Chargement medias`

La presentation ne doit pas:
- choisir le prochain ecran via logique metier
- parler directement aux repositories cloud
- piloter la sequence du tunnel

## 2. Application

Responsabilites:
- `EntryJourneyOrchestrator`
- calcul et publication du `TunnelState`
- coordination des use cases
- gestion des retries et restart journey
- derivation des reason codes de parcours

Exemples cibles:
- `EntryJourneyOrchestrator`
- use cases `restore session`, `resolve profile`, `resolve source`, `preload home`
- `TunnelStateStore`

L'application ne doit pas:
- connaitre les widgets
- connaitre `GoRouter`
- contenir du code SDK concret

## 3. Domain

Responsabilites:
- contrats metier et ports
- policies et gardes de parcours
- value objects et modeles du tunnel
- regles `must-have before home`

Exemples cibles:
- `TunnelState`
- `TunnelStage`
- `TunnelReasonCode`
- `TunnelCriteriaSnapshot`
- `EntryJourneyPolicy`
- ports auth, profiles, sources, preload

Le domain ne doit pas:
- importer Riverpod
- importer Flutter
- connaitre Supabase ou le stockage local concret

## 4. Data / Infrastructure

Responsabilites:
- adapters de repositories
- preferences persistantes
- SDK auth et cloud
- chiffrement credentials
- connectivite
- catalog refresh concret
- preload concret de `home`

Exemples:
- `SupabaseAuthRepository`
- `SupabaseProfileRepository`
- `SelectedProfilePreferences`
- `SelectedIptvSourcePreferences`
- `IptvCredentialsEdgeService`
- `RefreshXtreamCatalog`
- `RefreshStalkerCatalog`

Le data/infrastructure ne doit pas:
- calculer le parcours
- decider d'une surface UI
- vivre comme dependance directe du widget tree

## Regles de dependances autorisees

Matrice cible:

- `presentation -> application`
- `presentation -> domain` autorise pour types passifs
- `application -> domain`
- `application -> data` via ports ou adapters injectes
- `domain -> rien`
- `data -> domain`

Dependances interdites:

- `presentation -> data`
- `presentation -> router metier`
- `domain -> Flutter`
- `domain -> Riverpod`
- `domain -> SDK externes`
- `application -> widgets`
- `application -> GoRouter`

## Modules cibles recommandes

## A. Module `entry_journey`

Nouveau module transversal recommande.

Contenu cible:
- `domain`
  - `tunnel_state.dart`
  - `tunnel_reason_code.dart`
  - `tunnel_policy.dart`
  - ports `session`, `profiles`, `sources`, `preload`
- `application`
  - `entry_journey_orchestrator.dart`
  - use cases de progression
  - store / state publisher
- `presentation`
  - providers du tunnel
  - mapping `TunnelState -> target surface`

Role:
- devenir la colonne vertebrale du tunnel

## B. Module `startup`

Statut recommande:
- conserver
- recentrer sur le bootstrap technique systeme

Doit garder:
- initialisation technique
- exposition d'un resultat de startup minimal

Ne doit plus garder:
- la machine d'etat metier auth/profile/source

## C. Module `auth`

Statut recommande:
- conserver

Doit garder:
- contrats auth
- restore / refresh session
- ecran OTP
- telemetry auth

Ne doit plus garder:
- bootstrap croise de tunnel

## D. Module `profile`

Statut recommande:
- conserver

Doit garder:
- modeles et repository de profils
- use cases create / list / select

Doit evoluer:
- la selection persistante devient un adapter de persistence, pas la source de verite du tunnel

## E. Module `iptv / sources`

Statut recommande:
- conserver mais clarifier

Doit garder:
- inventaire de sources
- ajout / edition / validation
- refresh catalogue

Doit evoluer:
- separer clairement `source selection metier` et `settings CRUD`

## F. Module `home preload`

Statut recommande:
- extraire comme contrat d'application explicite

Doit exposer:
- readiness minimale avant `home`
- contenu vide vs contenu pret

Ne doit pas:
- etre pilote directement depuis la presentation du tunnel

## Mapping `existant -> cible`

## Orchestration et startup

| Existant | Cible | Decision |
| --- | --- | --- |
| [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart) | `entry_journey/application` | `extract + simplify` |
| [app_launch_criteria.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_criteria.dart) | `entry_journey/domain` | `evolve + move` |
| [startup_contracts.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/domain/startup_contracts.dart) | `core/startup/domain` | `keep` |
| [app_startup_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/domain/app_startup_orchestrator.dart) | `core/startup/domain` | `keep + clarify boundary` |
| [app_startup_provider.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_startup_provider.dart) | startup application binding | `keep temporary` |

## Routing

| Existant | Cible | Decision |
| --- | --- | --- |
| [launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart) | route guard de compatibilite | `simplify` |
| [app_routes.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_routes.dart) | catalogue de surfaces | `keep + reduce business logic` |
| [app_route_paths.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_route_paths.dart) | compat routing | `keep` |

## Etat global

| Existant | Cible | Decision |
| --- | --- | --- |
| [app_state_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_controller.dart) | store global applicatif hors tunnel strict | `simplify + decouple` |
| `AppLaunchStateRegistry` dans [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart) | exposition transitoire de `TunnelState` | `temporary bridge` |

## Presentation welcome / auth

| Existant | Cible | Decision |
| --- | --- | --- |
| [bootstrap_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart) | providers tunnel presentation | `refactor` |
| [welcome_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/providers/welcome_providers.dart) | providers surface-specific | `simplify` |
| [splash_bootstrap_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart) | `Preparation systeme` | `keep + refactor` |
| [welcome_user_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_user_page.dart) | `Creation profil` / bridge temporaire | `split or remove` |
| [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart) | `Choix / ajout source` | `keep + refactor` |
| [welcome_source_select_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart) | fusion dans hub source | `merge` |
| [welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart) | `Chargement medias` | `replace` |
| [auth_otp_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/auth/presentation/auth_otp_page.dart) | `Auth` | `keep + rebind` |
| [auth_otp_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/auth/presentation/auth_otp_controller.dart) | auth presentation logic | `keep + decouple from tunnel` |

## Profile et selection

| Existant | Cible | Decision |
| --- | --- | --- |
| [selected_profile_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_profile_preferences.dart) | persistence adapter | `keep + downgrade responsibility` |
| [selected_profile_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/profile/presentation/controllers/selected_profile_controller.dart) | provider presentation ou application adapter | `refactor` |
| [selected_profile_service.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/profile/application/services/selected_profile_service.dart) | port selection profil | `keep + clarify` |

## Sources et persistence

| Existant | Cible | Decision |
| --- | --- | --- |
| [selected_iptv_source_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_iptv_source_preferences.dart) | persistence adapter | `keep + downgrade responsibility` |
| [iptv_source_selection_list.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart) | composant UI source hub | `keep + reuse` |
| [supabase_iptv_sources_repository.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart) | data adapter | `keep` |
| [refresh_xtream_catalog.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/application/usecases/refresh_xtream_catalog.dart) | preload / validation dependency | `keep` |
| [refresh_stalker_catalog.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/application/usecases/refresh_stalker_catalog.dart) | preload / validation dependency | `keep` |

## Home preload et library

| Existant | Cible | Decision |
| --- | --- | --- |
| [home_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/home/presentation/providers/home_providers.dart) | `HomePreloadPort` adapter | `extract boundary` |
| [library_cloud_sync_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart) | library readiness adapter | `extract boundary` |

## Modules a extraire

Extraction recommandee:

1. `entry_journey/domain`
   - state model
   - policies
   - reason codes
   - criteria snapshot

2. `entry_journey/application`
   - orchestrator
   - progression use cases
   - tunnel state publisher

3. ports d'application explicites pour:
   - session snapshot
   - profiles inventory
   - source selection / validation
   - home preload readiness

## Modules a fusionner

Fusion recommandee:

1. `welcome_source_page` + `welcome_source_select_page`
   - un seul hub source

2. logique tunnel dispersee dans:
   - `bootstrap_providers`
   - `launch_redirect_guard`
   - `welcome_* pages`
   vers:
   - `entry_journey/application`

## Modules a simplifier

Simplification recommandee:

1. `LaunchRedirectGuard`
   - garde uniquement la protection de navigation et le mapping d'etat

2. `AppStateController`
   - sort des decisions strictes du tunnel
   - reste un store app-level transverse

3. preferences de selection
   - persistence uniquement
   - plus de calcul metier implicite

## Modules a supprimer a terme

Suppression cible a terme:

1. l'usage metier de `BootstrapDestination`
2. les redirections metier calculees dans le routeur
3. les pages hybrides qui portent encore navigation + side effects

## Decision log `extract / merge / simplify / remove`

1. Extraire un vrai module `entry_journey` transversal.
2. Garder `core/startup` pour le bootstrap technique, pas pour la machine d'etat metier du tunnel.
3. Garder `auth`, `profile` et `iptv` comme domaines sources, mais les faire parler a l'orchestrateur via ports.
4. Fusionner les surfaces source redondantes en un seul hub.
5. Ramener toute logique de sequence hors des pages `welcome`.
6. Ramener le routeur a un role de projection et de protection.
7. Reclasser les preferences de selection comme adapters de persistence.

## Risques d'architecture si on ne fait pas ce decoupage

- le routeur restera une seconde machine d'etat cachee
- la logique de retry restera dupliquee
- les pages welcome resteront hybrides et fragiles
- le preload `home` restera poreux et difficile a tester
- les regressions mobile / TV seront plus probables car le tunnel n'aura pas de source de verite unique

## Points deferes a 3.4 et 3.5

Cette sous-phase ne tranche pas encore:
- la forme exacte des contrats backend / infra
- le role final de `Riverpod` vs `GetIt`
- la composition root detaillee

Ces points seront traites dans:
- `3.4` pour les contrats
- `3.5` pour la composition et le state management

## Verdict de sortie de la sous-phase 3.3

Verdict:
- la sous-phase `3.3` est suffisamment stable pour lancer `3.4`

Pourquoi:
- les couches cibles sont explicites
- le mapping `existant -> cible` est assez concret pour guider les futurs refactors
- les decisions `extract / merge / simplify / remove` sont bornees

## Prochaine etape recommandee

La suite logique est:
1. definir les contrats backend et infra du tunnel
2. distinguer clairement ce qui doit etre pret avant `home`
3. typer les erreurs et reason codes des ports critiques

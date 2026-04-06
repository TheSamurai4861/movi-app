# Sous-phase 3.0 - Preparation et alignement architecture

## Objectif

Cadrer la phase architecture avant de figer la machine d'etat et l'orchestrateur cibles.

Cette sous-phase ne propose pas encore l'architecture finale. Elle fixe:
- les contraintes techniques non negociables
- les surfaces et etats UX que l'architecture devra servir
- les zones actuelles de couplage a traiter
- les questions techniques encore ouvertes avant la sous-phase `3.1`

## Base de travail confirmee

Les phases 1 et 2 ont deja stabilise:
- le parcours cible du tunnel
- les surfaces UI cibles
- la logique des etats inline
- la cible visuelle et le systeme de composants

L'architecture doit donc servir les surfaces suivantes:
- `Preparation systeme`
- `Auth`
- `Creation profil`
- `Choix profil`
- `Choix / ajout source`
- `Chargement medias`
- `Home vide`

Et les etats UX deja actes:
- progression nominale
- confirmation breve
- information
- recovery
- erreur bloquante

## Contraintes architecture non negociables

## Produit et parcours

- un seul tunnel d'entree logique jusqu'a `home`
- `Home` n'apparait qu'une fois l'etat juge necessaire pret
- le retour utilisateur sain doit tendre vers un tunnel quasi invisible
- le premier parcours reste guide et assume des etapes visibles
- les erreurs source, sync partielle et chargement long restent le plus possible inline

## Technique et execution

- architecture `local-first, cloud-safe`
- gestion explicite des etats de recovery
- support mobile + TV sans branches d'architecture paralleles
- preload avant `home` conserve comme contrainte metier
- migration realiste possible sans re-ecrire tout le tunnel en big bang obligatoire

## Couches et composition

- la UI ne doit pas orchestrer le tunnel
- le routeur ne doit pas porter une machine d'etat metier diffuse
- `Riverpod` et `GetIt` doivent avoir des responsabilites plus nettes
- les contrats doivent etre fixes avant les gros refactors

## Zones actuelles de couplage a traiter

## 1. Routeur <-> logique de tunnel

Couplage constate:
- [launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart) inspecte auth, `AppState`, et `AppLaunchStateRegistry`
- la redirection decide deja une partie du flux a partir de destinations bootstrap
- [app_routes.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_routes.dart) continue d'exposer des routes de tunnel tres explicites (`/welcome/*`, `/auth/otp`, `/bootstrap`)

Probleme:
- le routing reste un lieu de decision de flux
- la frontiere entre "navigation technique" et "etat metier du tunnel" n'est pas encore nette

## 2. Orchestrateur d'entree <-> trop de dependances directes

Couplage constate:
- [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart) importe auth, config, DI, preferences, `AppState`, home preload, library sync, IPTV, Supabase, etc.
- l'orchestrateur manipule a la fois:
  - auth
  - profils
  - sources
  - preload home
  - persistance de selections
  - recovery

Probleme:
- le point central existe deja, mais il est trop large et trop concret
- il melange orchestration, details infra, persistance locale et lecture de providers

## 3. Providers presentation <-> orchestration

Couplage constate:
- [bootstrap_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart) expose directement l'orchestrateur a la presentation
- [auth_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/auth/presentation/providers/auth_providers.dart) depend de l'orchestrateur auth, mais aussi du `AppLaunchStateRegistry`

Probleme:
- les providers presentation connaissent des details d'orchestration croisee
- le bootstrap auth et le bootstrap tunnel se croisent deja

## 4. `Riverpod` <-> `GetIt`

Couplage constate:
- [app_state_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_controller.dart) est un `Notifier` Riverpod qui lit des dependances via `GetIt`
- `slProvider` expose `GetIt` dans Riverpod
- plusieurs providers presentation construisent encore des services en lisant `GetIt`

Probleme:
- les frontieres `composition root / provider graph / service locator` ne sont pas nettes
- certains objets de couche presentation ou application peuvent etre crees via deux mecanismes differents

## 5. Preferences et selections <-> tunnel

Couplage constate:
- l'orchestrateur et `AppStateController` lisent `SelectedProfilePreferences` et `SelectedIptvSourcePreferences`
- le tunnel depend de preferences persistantes pour deduire profil courant, source courante et etat de reprise

Probleme:
- les preferences servent a la fois de persistence, de signal d'etat et de derive metier
- la source de verite du tunnel n'est pas encore clairement nommee

## 6. Preload `home` <-> tunnel d'entree

Couplage constate:
- `AppLaunchOrchestrator` attend / pilote du preload `home`
- `home_providers` expose une notion de `bootstrapPreloadInFlight`

Probleme:
- la frontiere entre "tunnel d'entree" et "mecanique interne de `home`" est poreuse
- l'architecture devra clarifier ce qui est `must-have before home` vs `can-load-after-home`

## 7. Welcome pages actuelles <-> logique de navigation

Couplage constate:
- les pages `welcome_user`, `welcome_source`, `welcome_source_select`, `welcome_source_loading` portent encore des bouts de logique de progression et de redirection
- elles interagissent avec providers, routeur et bootstrap de facon assez directe

Probleme:
- les surfaces UI actuelles ne sont pas encore de simples vues derivees d'etat
- elles restent partiellement hybrides

## Liste synthetique des couplages prioritaires

1. routeur <-> machine d'etat implicite
2. orchestrateur <-> details infra / providers / preload home
3. auth bootstrap <-> tunnel bootstrap
4. Riverpod <-> GetIt
5. preferences persistantes <-> source de verite metier
6. welcome pages <-> navigation et side effects

## Questions architecture deja deferrees par les phases precedentes

Issues de la phase 1:
- mapping exact entre routes actuelles et surfaces UX cibles
- definition de la machine d'etat du tunnel d'entree
- orchestration technique de `Preparation systeme`
- strategie de fallback local et de reprise cloud
- conditions exactes de `home ready`
- seuils techniques du `chargement long`
- regles d'auto-skip robustes
- traitement de la reprise apres interruption du tunnel
- preparation du futur flow TV par QR code

Issues de la phase 2:
- decomposition technique concrete des composants tunnel
- integration des etats inline dans les flux reels
- mapping architecturel exact des composants et routes

## Questions techniques encore ouvertes

## 1. Source de verite du tunnel

Question:
- l'etat canonique du tunnel vit-il dans un objet d'orchestration unique, ou reste-t-il derive de plusieurs stores et providers ?

## 2. Statut du routeur

Question:
- le routeur doit-il seulement afficher une surface correspondant a un etat deja calcule, ou continuer a porter une logique de redirection primaire ?

## 3. Statut de `AppLaunchOrchestrator`

Question:
- refactor profond de l'existant ou remplacement progressif par un orchestrateur plus propre au-dessus de ports ?

## 4. Place de l'auth bootstrap

Question:
- `AuthOrchestrator.bootstrapSession()` reste-t-il une brique autonome appelee par l'orchestrateur du tunnel, ou faut-il fusionner davantage la sequence ?

## 5. Place de `AppStateController`

Question:
- `AppStateController` reste-t-il un store global d'exposition applicative, ou doit-il etre sorti des decisions de tunnel strictes ?

## 6. Source de verite profil/source selectionnes

Question:
- les preferences de selection doivent-elles rester des caches de persistance, ou participent-elles encore a la resolution metier du tunnel ?

## 7. Frontiere avec `home`

Question:
- que doit exactement attendre l'orchestrateur avant d'autoriser l'entree `home` ?

## Ambiguities restantes a lever avant la sous-phase 3.1

Ces points ne bloquent pas `3.0`, mais doivent etre assumes explicitement au demarrage du modele d'etat.

1. Le modele d'etat canonique couvre-t-il uniquement le tunnel jusqu'a `home`, ou inclut-il aussi les signaux de preload `home` ?

2. Les routes actuelles du tunnel restent-elles une simple couche de compatibilite, ou certaines doivent-elles survivre comme surfaces structurelles de la cible ?

3. Le fallback local est-il un sous-etat de certains etats canoniques, ou un axe transversal annote par des reason codes ?

4. La selection profil/source doit-elle etre modelisee comme etat stable autonome, ou comme condition a satisfaire avant `ready_for_home` ?

5. Le registre `AppLaunchStateRegistry` reste-t-il un mecanisme transitoire, ou peut-il devenir la base d'exposition du futur modele d'etat ?

## Ce qui est fixe et ne doit plus etre re-ouvert en phase 3

- le parcours cible issu de la phase 1
- la cible UI issue de la phase 2
- le principe `one journey, one state model`
- la necessite d'un orchestrateur d'entree unique
- la distinction `must-have before home` vs travail differe apres `home`
- la priorite mobile + TV sur un seul tunnel, pas deux architectures separees

## Verdict de sortie de la sous-phase 3.0

Verdict:
- la sous-phase `3.0` est suffisamment cadree pour lancer `3.1`

Pourquoi:
- les contraintes non negociables sont explicites
- les couplages majeurs sont identifies
- les questions techniques encore ouvertes sont bornees
- les ambiguities restantes sont assez claires pour cadrer la machine d'etat

## Prochaine etape recommandee

La suite logique est:
1. definir le modele d'etat canonique du tunnel
2. separer etats stables, transitoires et de recovery
3. fixer les transitions avant de redefinir l'orchestrateur

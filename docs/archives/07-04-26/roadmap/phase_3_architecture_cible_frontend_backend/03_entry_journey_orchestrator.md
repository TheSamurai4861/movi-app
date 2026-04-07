# Sous-phase 3.2 - Entry journey orchestrator

## Objectif

Definir le `entry journey orchestrator` comme point central de decision du tunnel d'entree.

Cette sous-phase transforme le modele d'etat de [02_modele_etat_canonique_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/02_modele_etat_canonique_tunnel.md) en responsabilite applicative concrete.

Elle fixe:
- le role exact de l'orchestrateur
- ses entrees autorisees
- ses sorties attendues
- ses commandes publiques
- les dependances qu'il peut posseder
- les responsabilites qui doivent rester hors de lui

## Diagnostic de l'existant

L'orchestrateur actuel [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart) va deja dans la bonne direction, mais reste trop large.

Il concentre aujourd'hui:
- la lecture du contexte auth
- la resolution profils et sources
- la persistance de selections
- le fallback local
- le preload `home`
- la construction d'une destination de navigation
- des dependances concretes d'infra et de presentation

Conclusion:
- il faut **garder l'idee d'un orchestrateur unique**
- mais **refactorer sa forme** pour en faire une couche application propre, basee sur des ports

## Role cible de l'orchestrateur

Le `entry journey orchestrator` est responsable de:

1. observer le contexte utile au tunnel
2. evaluer les gardes du modele d'etat canonique
3. produire un `TunnelState` unique
4. emettre les commandes necessaires pour faire progresser le tunnel
5. exposer des intentions simples a la presentation et au routeur

En une phrase:
- l'orchestrateur **decide du parcours**
- il ne **rendra pas l'UI**
- il ne **portera pas les details d'infra**

## Responsabilites autorisees

## 1. Resoudre le contexte initial

Il peut:
- lancer l'evaluation initiale du tunnel a l'ouverture de l'app
- demander un bootstrap technique minimal
- collecter les signaux auth, profils, sources, preload et connectivite

Il ne doit pas:
- faire lui-meme l'initialisation globale des SDK
- contenir la logique detaillee de chaque integration

## 2. Calculer l'etat canonique

Il peut:
- lire un ensemble de snapshots et resultats de use cases
- appliquer les gardes de `3.1`
- choisir le `stage`, les qualifiers et les reason codes

Il ne doit pas:
- exposer seulement une `destination`
- laisser le routeur recalculer la logique metier

## 3. Coordonner la progression du tunnel

Il peut:
- lancer la resolution suivante quand le state model l'autorise
- declencher auth restore, load profiles, load sources, validate source, preload home
- gerer retry, restart journey et reprise de progression

Il ne doit pas:
- declencher des side effects presentation
- ecrire directement dans des widgets ou `BuildContext`

## 4. Exposer un contrat stable vers le reste de l'app

Il peut:
- publier un flux ou store de `TunnelState`
- publier des commandes d'interaction simples
- publier des telemetry events lies au tunnel

Il ne doit pas:
- imposer la structure exacte des ecrans
- melanger `UI copy`, `route strings` et logique metier

## Contrat cible recommande

## Forme du composant

Recommandation:
- un composant application unique nomme `EntryJourneyOrchestrator`
- framework-aware uniquement a son bord exterieur
- coeur pilote par des ports metier et infra

Pseudo-contrat recommande:

```text
interface EntryJourneyOrchestrator {
  TunnelState get currentState
  Stream<TunnelState> observe()

  Future<void> start()
  Future<void> retry()
  Future<void> restartJourney()

  Future<void> submitAuthSuccess()
  Future<void> submitProfileSelection(ProfileSelection selection)
  Future<void> submitSourceSelection(SourceSelection selection)
}
```

Le detail exact `Notifier`, `StateNotifier` ou autre sera tranche en `3.5`.

## Entrees autorisees

L'orchestrateur peut dependre d'entrees de quatre categories.

## 1. Etat systeme et execution

- `StartupStatusPort`
- `ConnectivityPort`
- `ClockPort`
- `TelemetryPort`

Role:
- savoir si le systeme est pret
- savoir si le reseau est disponible
- mesurer timeout, slow loading et durees
- tracer les transitions

## 2. Auth et identite

- `SessionSnapshotPort`
- `AuthRestorePort`
- `AuthRefreshPort`

Role:
- savoir si une session existe
- tenter une restauration
- detecter les cas de re-auth

## 3. Profils et sources

- `ProfilesInventoryPort`
- `SelectedProfilePort`
- `SourcesInventoryPort`
- `SelectedSourcePort`
- `SourceValidationPort`

Role:
- charger les profils
- lire ou resoudre le profil courant
- charger les sources
- lire ou resoudre la source courante
- verifier qu'une source selectionnee est encore exploitable

## 4. Pre-home readiness

- `CatalogReadinessPort`
- `LibraryReadinessPort`
- `HomePreloadPort`

Role:
- savoir ce qui est `must-have before home`
- lancer et suivre le preload minimal
- distinguer `content ready` et `content empty`

## Sorties attendues

## 1. Etat principal publie

Sortie obligatoire:
- `TunnelState`

Ce state doit deja contenir:
- `stage`
- `executionMode`
- `continuityMode`
- `contentState`
- `loadingState`
- `reasons`
- `criteria`

## 2. Commandes derivees pour le shell applicatif

Sorties derivees autorisees:
- `targetSurface`
- `canRetry`
- `canRestart`
- `requiresBlockingAttention`

Important:
- ces sorties sont derivees du `TunnelState`
- elles ne constituent pas une seconde machine d'etat

## 3. Telemetry

Sorties attendues:
- transition state-to-state
- reason codes actifs
- duree par stage
- retry count
- fallback local active

## Commandes publiques de l'orchestrateur

L'API publique doit rester courte.

Commandes recommandees:
- `start()`
- `retry()`
- `restartJourney()`
- `acknowledgeBlockingMessage()`
- `submitAuthCompleted()`
- `submitProfileChosen(profileId)`
- `submitProfileCreated(profileId)`
- `submitSourceChosen(sourceId)`
- `submitSourceCreated(sourceId)`

Commandes a eviter:
- `goToAuth()`
- `navigateToSource()`
- `showLoadingScreen()`

Raison:
- ces commandes coderaient l'UI ou le routing au lieu d'exprimer des intentions metier

## Politique de dependances

## Dependances autorisees

L'orchestrateur peut parler a:
- des ports application / domain
- un store d'etat local du tunnel
- un journal de telemetry

Il peut aussi coordonner:
- des use cases de lecture
- des use cases de validation
- des use cases de preload

## Dependances interdites

L'orchestrateur ne doit pas dependre directement de:
- widgets
- `BuildContext`
- `GoRouter`
- chemins de routes
- providers presentation UI
- repositories data concretes si un port applicatif existe
- services `Supabase`, `GetIt`, `Riverpod Ref` au coeur de sa logique

## Regle pratique

Le coeur de l'orchestrateur doit pouvoir etre teste:
- sans Flutter
- sans router
- sans widget tree
- sans SDK externe reel

## Effets et orchestration

## Ce que l'orchestrateur declenche directement

Il peut coordonner:
- bootstrap minimal
- restauration session
- chargement profils
- chargement sources
- validation source
- preload pre-home

## Ce qu'il doit demander a d'autres briques

Il doit deleguer:
- la lecture/criture de preferences
- la synchronisation cloud detaillee
- le chiffrement credentials
- les details IPTV provider-specific
- le rendu des erreurs et messages

## Strategie de calcul recommandee

Le comportement recommande est une boucle courte:

1. lire le snapshot du contexte
2. calculer `TunnelState`
3. publier l'etat
4. si l'etat autorise un effet automatique, declencher cet effet
5. relire le snapshot
6. recalculer l'etat

Cette approche est preferable a:
- des transitions poussees depuis chaque widget
- des redirections routeur multi-sources
- des `if` croises entre providers presentation

## Relation avec le routeur

Decision recommandee:
- le routeur observe l'etat de l'orchestrateur
- il mappe `TunnelState.stage` vers une surface
- il n'invente pas de logique metier supplementaire

Le routeur garde seulement:
- les regles de securite de navigation globales
- la compatibilite des URLs
- la protection contre des ouvertures manuelles incoherentes

Le routeur ne garde plus:
- le calcul `auth -> profile -> source -> preload -> home`

## Relation avec la presentation

Decision recommandee:
- les ecrans du tunnel consomment un state et emettent des intentions
- ils n'appellent ni repository ni navigation metier directe

Exemples:
- `Auth` emet `submitAuthCompleted()`
- `Choix profil` emet `submitProfileChosen(profileId)`
- `Choix / ajout source` emet `retry()` ou `submitSourceChosen(sourceId)`

## Relation avec l'existant

## Sort de `AppLaunchOrchestrator`

Recommendation:
- evolution progressive plutot que remplacement brutal

Strategie:
1. conserver le point d'entree existant
2. introduire le nouveau contrat `TunnelState`
3. reduire graduellement les dependances concretes
4. basculer `destination` en simple derive de compatibilite

## Sort de `AppLaunchStateRegistry`

Recommendation:
- peut survivre temporairement comme mecanisme d'exposition
- ne doit pas etre la definition metier du tunnel

La source de verite doit devenir:
- l'etat publie par le futur orchestrateur

## Sort de `BootstrapDestination`

Recommendation:
- conserver temporairement pour compatibilite routeur
- ne plus l'utiliser comme modele metier primaire

## Boundaries explicites

## Ce qui doit rester hors orchestrateur

- la composition root finale
- la construction des providers UI
- les details de routing
- les adapters data concrets
- les widgets
- les copy texts

## Ce qui doit rester dans l'orchestrateur

- la sequence metier du tunnel
- les gardes de progression
- les effets automatiques du tunnel
- le calcul de l'etat canonique
- les reason codes de parcours

## Decision log

1. Le tunnel aura un orchestrateur unique.
2. Cet orchestrateur publiera un `TunnelState`, pas seulement une `destination`.
3. Le routeur devient un consommateur de l'etat, pas le moteur du parcours.
4. Les widgets emettent des intentions metier, pas des decisions de navigation.
5. Les details d'infra doivent passer par des ports ou use cases, pas par des dependances concretes au coeur.
6. La migration recommandee est progressive au-dessus de l'existant.

## Points deferes a 3.3 et 3.5

Cette sous-phase ne tranche pas encore:
- la liste exacte des modules a extraire
- la place definitive de `Riverpod` et `GetIt`
- la forme du composition root
- la repartition exacte entre use cases, services et repositories

Ces points seront traites dans:
- `3.3` pour les couches et modules
- `3.5` pour composition root, routing et state management

## Verdict de sortie de la sous-phase 3.2

Verdict:
- la sous-phase `3.2` est suffisamment stable pour lancer `3.3`

Pourquoi:
- la responsabilite de l'orchestrateur est maintenant nette
- ses entrees et sorties sont bornees
- le routeur et la presentation ont un role clarifie
- la trajectoire de migration depuis l'existant est compatible avec une evolution progressive

## Prochaine etape recommandee

La suite logique est:
1. fixer la separation des couches et modules
2. mapper l'existant vers la cible
3. identifier ce qui doit etre extrait, fusionne ou supprime

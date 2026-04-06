# Sous-phase 3.6 - Strategie de migration, feature flags et rollout

## Objectif

Rendre la cible architecture de la phase 3 migrable sans casser l'existant.

Cette sous-phase fixe:
- la strategie de migration recommandee
- les zones de coexistence temporaires
- les feature flags utiles
- les points de rollback
- les preconditions de bascule des ecrans du tunnel

## Decision de migration recommandee

La strategie recommande est:
- **par paliers**
- avec **coexistence temporaire ancien tunnel / nouveau tunnel**
- et **bascule progressive par couches**

La strategie `big bang` n'est pas recommandee ici, car le tunnel actuel touche en meme temps:
- startup
- auth
- profils
- sources
- preload `home`
- routeur
- providers presentation

Une bascule brutale augmenterait fortement le risque de:
- regressions de navigation
- etats de blocage non couverts
- incoherences mobile / TV
- retour difficile en arriere

## Principes directeurs de migration

1. migrer d'abord la **source de verite**
2. ensuite migrer la **projection routeur**
3. ensuite migrer les **surfaces UI**
4. enfin supprimer les anciens ponts de compatibilite

Autrement dit:
- d'abord `state model`
- puis `orchestrator`
- puis `routing`
- puis `pages`

## Strategie generale en 6 paliers

## Palier 1 - Introduire le nouveau modele sans changer l'UX visible

But:
- ajouter `TunnelState`, reason codes et derives sans casser le tunnel actuel

Travaux:
- introduire le modele d'etat canonique
- introduire les contracts / ports cibles
- faire produire un etat compatible depuis l'orchestrateur existant
- conserver `BootstrapDestination` comme derive de compatibilite

Livrable attendu:
- le nouveau coeur de lecture existe, mais l'UX publique ne change pas encore

Rollback:
- revenir au calcul historique `destination + phase + status`

## Palier 2 - Introduire le nouvel orchestrateur en mode bridge

But:
- faire porter la logique par `EntryJourneyOrchestrator` sans retirer encore les routes existantes

Travaux:
- brancher les ports `startup`, `session`, `profiles`, `sources`, `preload`
- faire publier `TunnelState`
- garder `AppLaunchStateRegistry` comme pont temporaire si necessaire

Livrable attendu:
- la source de verite du parcours devient le nouvel orchestrateur
- l'ancien routeur continue de fonctionner

Rollback:
- rebascule du routeur et des providers sur l'orchestrateur historique

## Palier 3 - Migrer le routeur vers `TunnelSurface`

But:
- sortir la logique metier du routeur

Travaux:
- introduire `tunnelSurfaceProvider`
- faire observer ce derive par `appRouterProvider`
- simplifier `LaunchRedirectGuard`
- conserver les anciens chemins comme compatibilite d'URL

Livrable attendu:
- le routeur ne recalcule plus auth/profile/source

Rollback:
- remettre `LaunchRedirectGuard` en lecture du registre historique

## Palier 4 - Migrer les ecrans du tunnel un par un

But:
- brancher chaque surface UI sur le nouveau contrat sans tout rebasculer d'un coup

Ordre recommande:
1. `Preparation systeme`
2. `Auth`
3. `Choix profil / Creation profil`
4. `Choix / ajout source`
5. `Chargement medias`

Pourquoi cet ordre:
- il suit la progression du tunnel
- il permet des validations incrementales plus simples
- il limite les regressions de navigation croisee

Rollback:
- chaque surface garde temporairement son binding historique tant que sa bascule n'est pas validee

## Palier 5 - Sortir les preferences et providers de leur role metier

But:
- reclasser les preferences en adapters de persistence

Travaux:
- faire sortir `SelectedProfilePreferences` et `SelectedIptvSourcePreferences` de la logique de decision
- simplifier les providers `welcome/*`
- sortir `AppStateController` du coeur du tunnel

Livrable attendu:
- plus de source de verite parallele pour le parcours

Rollback:
- rebrancher ponctuellement un adapter legacy si une surface depend encore d'un ancien flux

## Palier 6 - Supprimer les ponts legacy

But:
- retirer les couches de compatibilite une fois le nouveau tunnel stabilise

Travaux:
- retirer l'usage metier de `BootstrapDestination`
- retirer la logique de parcours restante du routeur
- supprimer les pages et providers hybrides devenus inutiles
- retirer `AppLaunchStateRegistry` si plus necessaire

Livrable attendu:
- tunnel cible propre, sans duplication systemique

Rollback:
- ce palier ne doit etre execute qu'apres une periode de stabilisation suffisante

## Strategie de coexistence recommandee

Pendant la migration, ces couples pourront coexister temporairement:

1. `BootstrapDestination` + `TunnelState`
2. `AppLaunchStateRegistry` + exposition Riverpod de `TunnelState`
3. `LaunchRedirectGuard` historique + derive `TunnelSurface`
4. pages `welcome/*` legacy + nouvelles surfaces branchees sur l'orchestrateur

Regle:
- coexistence temporaire oui
- double source de verite durable non

Chaque coexistence doit avoir:
- une duree cible
- un proprietaire
- un critere de suppression

## Feature flags recommandes

Le nombre de flags doit rester petit. Trop de flags rendraient le tunnel illisible.

Flags recommandes:

1. `entry_journey_state_model_v2`
   - active le nouveau `TunnelState`
   - sans changer encore toutes les surfaces

2. `entry_journey_routing_v2`
   - active la projection routeur via `TunnelSurface`

3. `entry_journey_ui_v2`
   - active les surfaces UI rebranchees au nouveau tunnel

4. `entry_journey_source_hub_v2`
   - active la fusion `welcome_source_page + welcome_source_select_page`

5. `entry_journey_prehome_v2`
   - active le nouveau `Chargement medias`

## Flags explicitement non recommandes

- un flag par ecran si ce n'est pas necessaire
- un flag par micro-etat du tunnel
- des flags metier caches dans les pages

## Strategie de rollout recommandee

## Etape 1 - Activation technique interne

But:
- valider que le nouvel etat et l'orchestrateur tournent correctement

Activation:
- dev
- QA
- builds internes

Mesures a suivre:
- coherence des transitions
- reason codes emis
- absence de blocages inattendus

## Etape 2 - Activation routeur

But:
- verifier que la projection `TunnelSurface -> routes` est stable

Mesures a suivre:
- loops de redirect
- routes interdites
- reprise apres relance app

## Etape 3 - Activation UI tunnel

But:
- brancher progressivement les surfaces refondues

Mesures a suivre:
- completion du premier parcours
- completion du retour utilisateur
- etats offline / recovery

## Etape 4 - Nettoyage des ponts legacy

But:
- enlever les couches anciennes une fois la nouvelle architecture stabilisee

Mesures a suivre:
- baisse de duplication
- baisse des redirections legacy
- stabilite des telemetry events

## Points de rollback recommandes

Chaque palier doit avoir un rollback simple.

Rollback 1:
- desactiver `entry_journey_ui_v2`
- revenir aux surfaces legacy

Rollback 2:
- desactiver `entry_journey_routing_v2`
- revenir au guard historique

Rollback 3:
- desactiver `entry_journey_state_model_v2`
- revenir a la source de verite historique

Regle:
- le rollback doit pouvoir se faire sans migration de donnees destructrice

## Preconditions de migration par surface UI

## `Preparation systeme`

Preconditions:
- `TunnelState.preparing_system` stable
- contrats `startup` et `connectivity` branches
- reason codes critiques exposes

## `Auth`

Preconditions:
- `SessionSnapshotPort` stable
- commande `submitAuthCompleted()` branchee
- cas `auth_missing / auth_expired` verifies

## `Creation profil / Choix profil`

Preconditions:
- `ProfilesInventoryPort` stable
- `SelectedProfilePort` stable
- derive `createProfile` vs `chooseProfile` fiabilise

## `Choix / ajout source`

Preconditions:
- `SourcesInventoryPort` stable
- `SelectedSourcePort` stable
- `SourceValidationPort` stable
- message source invalide et retry verifies

## `Chargement medias`

Preconditions:
- `HomePreloadPort` stable
- etat `preloading_home` stable
- gestion `preload_slow` et `catalog empty` verifyee

## Preconditions de suppression des ponts legacy

Avant suppression de `BootstrapDestination`, `AppLaunchStateRegistry` ou de la logique routeur legacy, il faut:
- 1 source de verite unique de parcours
- 0 dependance metier critique au guard legacy
- toutes les surfaces du tunnel branchees sur les nouveaux providers
- telemetry stable sur les transitions principales

## Decision log

1. La migration recommandee est par paliers, pas en big bang.
2. Le premier objet a migrer est la source de verite, pas l'ecran.
3. Le routeur doit etre migre avant la suppression des pages legacy.
4. Les feature flags doivent etre peu nombreux et porter des blocs coherents.
5. Les ponts legacy sont acceptables temporairement, mais doivent chacun avoir un critere de retrait.

## Risques principaux de migration

- coexistence trop longue entre deux sources de verite
- feature flags trop nombreux ou mal scopes
- suppression trop precoce du guard historique
- migration UI avant stabilisation du `TunnelState`
- couplages caches dans les pages `welcome/*`

## Points deferes a 3.7

Cette sous-phase ne tranche pas encore:
- le verdict final de stabilite de toute la phase 3
- la liste finale des risques residuels
- la synthese architecture globale

Ces points seront traites en `3.7`.

## Verdict de sortie de la sous-phase 3.6

Verdict:
- la sous-phase `3.6` est suffisamment stable pour lancer `3.7`

Pourquoi:
- la trajectoire de migration est realiste
- les flags utiles sont bornes
- les points de coexistence et de rollback sont explicites
- les preconditions de bascule par surface sont claires

## Prochaine etape recommandee

La suite logique est:
1. consolider tous les artefacts de la phase 3
2. verifier la coherence globale avec les phases 1 et 2
3. poser le verdict final de stabilite architecture

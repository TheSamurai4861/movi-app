# Sous-phase 5.3 - Feature flags, coexistence et strategie de bascule

## Objectif

Definir comment livrer les lots de la phase 5 par paliers, avec:
- un nombre borne de feature flags
- une coexistence temporaire ancien / nouveau tunnel explicite
- des points de rollback simples sur les lots critiques

Cette sous-phase ne redefinit ni le backlog, ni les dependances. Elle attache au plan de livraison un mecanisme d'activation et de retour arriere defendable.

## Principe directeur

La bascule doit rester:
- progressive
- observable
- reversible

Regle cle:
- peu de flags
- chacun porte un bloc coherent
- aucun flag ne doit cacher une demi-source de verite durable

## Doctrine de flags retenue

Les flags doivent porter des blocs de comportement, pas des micro-etats.

Regles:
- pas de flag par widget
- pas de flag par erreur
- pas de flag purement cosmetique
- un flag doit permettre soit:
  - d'activer une nouvelle couche
  - de basculer une famille de surfaces
  - de desactiver rapidement un comportement risque

## Liste des flags recommandes

### `entry_journey_telemetry_v2`

But:
- activer la telemetry cible du tunnel

Lots principalement couverts:
- `A1`
- `A2`

Nature:
- flag technique

Rollback:
- retour a la telemetry historique minimale

### `entry_journey_state_model_v2`

But:
- activer `TunnelState` et les derives du nouveau coeur

Lots principalement couverts:
- `B1`
- `B2`
- `B3`
- partiellement `B4`

Nature:
- flag coeur domaine

Rollback:
- retour a la lecture historique `destination + phase + status`

### `entry_journey_routing_v2`

But:
- activer la projection routeur par `TunnelSurface`

Lots principalement couverts:
- `D1`
- `D2`
- partiellement `D3`

Nature:
- flag navigation

Rollback:
- retour au guard historique et aux derives legacy

### `entry_journey_ui_v2`

But:
- activer les surfaces UI refondues du tunnel amont

Lots principalement couverts:
- `E1`
- `E2`
- `E3`
- `F1`
- `F2`
- `F3`
- `F4`

Nature:
- flag surfaces amont

Rollback:
- retour aux surfaces legacy equivalentes

### `entry_journey_source_hub_v2`

But:
- activer le hub source unifie et sa logique de recovery

Lots principalement couverts:
- `G1`
- `G2`
- `G3`

Nature:
- flag fonctionnel source

Rollback:
- retour a `welcome/sources` + `welcome/sources/select`

### `entry_journey_prehome_v2`

But:
- activer le nouveau `Chargement medias` et le pre-home borne

Lots principalement couverts:
- `C5`
- `H1`
- `H2`

Nature:
- flag pre-home

Rollback:
- retour au preloading historique, sous reserve d'accepter les limites connues

### `entry_journey_cleanup_v2`

But:
- autoriser la suppression finale des ponts legacy

Lots principalement couverts:
- `D3`
- `H3`
- `H4`

Nature:
- flag de fermeture de migration

Rollback:
- desactivation du nettoyage final tant que les ponts existent encore dans le code

## Mapping lots -> flags

| Lot | Flag principal | Flag secondaire eventuel | Strategie recommandee |
| --- | --- | --- | --- |
| `A1` | `entry_journey_telemetry_v2` | aucun | activation precoce |
| `A2` | `entry_journey_telemetry_v2` | aucun | activation precoce |
| `A3` | aucun | aucun | infrastructure always-on |
| `B1` | `entry_journey_state_model_v2` | aucun | activer en interne d'abord |
| `B2` | `entry_journey_state_model_v2` | aucun | bridge invisible |
| `B3` | `entry_journey_state_model_v2` | aucun | shadow mode avant bascule |
| `B4` | `entry_journey_state_model_v2` | `entry_journey_routing_v2` | bascule coordonnee |
| `C1` | `entry_journey_state_model_v2` | `entry_journey_ui_v2` | coeur puis surface |
| `C2` | `entry_journey_state_model_v2` | `entry_journey_ui_v2` | coeur puis surface |
| `C3` | `entry_journey_state_model_v2` | `entry_journey_source_hub_v2` | coeur puis surface source |
| `C4` | `entry_journey_source_hub_v2` | aucun | activer avec recovery source |
| `C5` | `entry_journey_prehome_v2` | aucun | activer apres validation source stable |
| `D1` | `entry_journey_routing_v2` | aucun | derive interne d'abord |
| `D2` | `entry_journey_routing_v2` | aucun | bascule routeur mesuree |
| `D3` | `entry_journey_cleanup_v2` | aucun | tardif |
| `E1` | `entry_journey_ui_v2` | aucun | peut etre merge avant activation |
| `E2` | `entry_journey_ui_v2` | `entry_journey_source_hub_v2` | selon surface |
| `E3` | `entry_journey_ui_v2` | `entry_journey_source_hub_v2` | selon surface |
| `F1` | `entry_journey_ui_v2` | `entry_journey_routing_v2` | depend de la projection routeur |
| `F2` | `entry_journey_ui_v2` | aucun | surface auth |
| `F3` | `entry_journey_ui_v2` | aucun | surface creation profil |
| `F4` | `entry_journey_ui_v2` | aucun | surface choix profil |
| `G1` | `entry_journey_source_hub_v2` | `entry_journey_ui_v2` | fusion source |
| `G2` | `entry_journey_source_hub_v2` | aucun | ajout + validation source |
| `G3` | `entry_journey_source_hub_v2` | aucun | recovery source |
| `H1` | `entry_journey_prehome_v2` | `entry_journey_ui_v2` | chargement medias |
| `H2` | `entry_journey_prehome_v2` | `entry_journey_telemetry_v2` | separation pre/post-home |
| `H3` | `entry_journey_cleanup_v2` | aucun | nettoyage metier tardif |
| `H4` | `entry_journey_cleanup_v2` | aucun | suppression finale |

## Zones de coexistence temporaires

Les zones de coexistence acceptees pendant la migration sont:

### 1. `BootstrapDestination` + `TunnelState`

Pourquoi:
- bridge temporaire pendant `B2-B4`

Doit disparaitre:
- apres stabilisation de `D2`

Proprietaire:
- coeur architecture tunnel

### 2. `AppLaunchStateRegistry` + exposition Riverpod du nouvel etat

Pourquoi:
- compatibilite transitoire pour routeur et surfaces non migrees

Doit disparaitre:
- avant ou pendant `D3`

Proprietaire:
- orchestration / routing

### 3. `LaunchRedirectGuard` historique + derive `TunnelSurface`

Pourquoi:
- transition progressive de la navigation

Doit disparaitre:
- apres validation de `D2`

Proprietaire:
- routing

### 4. Pages `welcome/*` legacy + nouvelles surfaces tunnel

Pourquoi:
- activation progressive des surfaces UI

Doit disparaitre:
- avant `H4`

Proprietaire:
- UI tunnel

### 5. Preferences de selection comme persistence + derives metier cibles

Pourquoi:
- migration progressive des choix profil/source

Doit disparaitre:
- pendant `H3`

Proprietaire:
- domaine profils / sources

## Zones ou la coexistence doit rester la plus courte possible

Les couples suivants doivent rester les plus courts possible:

### `TunnelState` + logique de decision legacy

Pourquoi:
- double source de verite

Risque:
- branches contradictoires

### `LaunchRedirectGuard` + projection routeur cible

Pourquoi:
- risque de redirections incoherentes

Risque:
- loops, mauvais ecrans, rollback flou

### Hub source nouveau + ancien flux source

Pourquoi:
- hotspot metier et UX

Risque:
- recovery source incoherente

## Strategie de bascule par vagues

## Vague 0 - Technique interne

Flags actifs:
- `entry_journey_telemetry_v2`
- infrastructure de flags

But:
- mesurer sans changer l'UX

Sortie attendue:
- telemetry fiable du tunnel historique

## Vague 1 - Coeur shadow

Flags actifs:
- `entry_journey_state_model_v2` en environnement interne ou shadow

But:
- faire tourner le nouveau coeur sans changer encore la projection publique partout

Sortie attendue:
- `TunnelState` fiable et comparable au legacy

## Vague 2 - Projection routeur

Flags actifs:
- `entry_journey_state_model_v2`
- `entry_journey_routing_v2`

But:
- faire porter le routing par l'etat cible

Sortie attendue:
- navigation stable sans recalcule metier historique

## Vague 3 - Surfaces amont

Flags actifs:
- `entry_journey_ui_v2`

But:
- migrer `Preparation systeme`, `Auth`, `Profil`

Sortie attendue:
- nouveau tunnel visible sur l'amont du parcours

## Vague 4 - Bloc source

Flags actifs:
- `entry_journey_source_hub_v2`

But:
- basculer le bloc source et sa recovery

Sortie attendue:
- une seule experience source cible

## Vague 5 - Pre-home final

Flags actifs:
- `entry_journey_prehome_v2`

But:
- activer `Chargement medias` et la separation `catalog minimal / catalog full`

Sortie attendue:
- `Home` n'attend plus le catalogue complet

## Vague 6 - Nettoyage

Flags actifs:
- `entry_journey_cleanup_v2`

But:
- supprimer les ponts legacy encore restants

Sortie attendue:
- tunnel cible propre

## Points de rollback recommandes

Chaque zone critique doit avoir un rollback simple.

### Rollback 1 - UI tunnel

Action:
- desactiver `entry_journey_ui_v2`

Effet:
- retour aux surfaces legacy

Quand l'utiliser:
- regression visible sur `Preparation systeme`, `Auth`, `Profil`

### Rollback 2 - Bloc source

Action:
- desactiver `entry_journey_source_hub_v2`

Effet:
- retour a l'ancien flux source

Quand l'utiliser:
- recovery source instable
- validation source incoherente

### Rollback 3 - Pre-home

Action:
- desactiver `entry_journey_prehome_v2`

Effet:
- retour au pre-home historique

Quand l'utiliser:
- blocage severe avant `Home`

### Rollback 4 - Routeur

Action:
- desactiver `entry_journey_routing_v2`

Effet:
- retour au comportement guard historique

Quand l'utiliser:
- loops de redirect
- projection de surface incorrecte

### Rollback 5 - Coeur state model

Action:
- desactiver `entry_journey_state_model_v2`

Effet:
- retour a la source de verite historique

Quand l'utiliser:
- incoherences majeures de parcours

## Preconditions de bascule recommandees

Avant d'activer un flag critique:

### Pour `entry_journey_state_model_v2`

- telemetry de base active
- comparaison legacy / nouveau coeur possible
- reason codes minimum disponibles

### Pour `entry_journey_routing_v2`

- `TunnelSurface` stable
- guard legacy encore present comme filet
- scenarios cold/warm verifies

### Pour `entry_journey_ui_v2`

- composants UI communs prets
- contrats session/profil stables
- offline et auth invalides verifies

### Pour `entry_journey_source_hub_v2`

- contrats sources stables
- validation source bornee
- recovery source verifiee

### Pour `entry_journey_prehome_v2`

- `catalog minimal ready` mesure
- separation `catalog full` effective
- `time_to_safe_state` mesurable

### Pour `entry_journey_cleanup_v2`

- flags precedents stabilises
- aucune dependance forte non migree
- checklist de suppression legacy validee

## Recommandations d'operabilite

- un seul changement de flag critique par vague de verification
- ne pas activer `routing`, `source hub` et `prehome` tous ensemble
- garder un proprietaire explicite pour chaque coexistence
- documenter une date cible de suppression pour chaque bridge legacy

## Verdict

La sous-phase `5.3` est suffisamment stable si l'on retient ces points:
- les flags utiles sont limites et coherents
- la coexistence temporaire est bornee
- les points de rollback sont explicites
- les bascules peuvent suivre les vagues du plan d'execution

La suite logique est la sous-phase `5.4`, pour preciser les migrations de composants, routes et branchements visibles dans le code.

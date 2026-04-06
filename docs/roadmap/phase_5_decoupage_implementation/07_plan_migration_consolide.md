# Sous-phase 5.6 - Plan de migration consolide

## Objectif

Assembler le backlog, les dependances, les flags, les migrations visibles et la definition of done dans un plan unique de livraison.

Cette sous-phase ne recree pas les analyses precedentes. Elle produit le plan consolide qui servira d'entree directe a l'execution.

## Principe directeur

Le plan de migration doit permettre de repondre clairement a ces questions:
- quel est le prochain lot a livrer
- quel flag porte sa bascule
- quelle est sa precondition
- quel signal prouve que le lot est stable
- quel rollback existe si la bascule se passe mal

## Backlog ordonne final

Le backlog ordonne final recommande est le suivant.

## Vague 0 - Fondations de mesure et d'infrastructure

### `A1` - Evenements telemetry du tunnel existant

Pourquoi ici:
- permet de mesurer avant toute bascule

Flag:
- `entry_journey_telemetry_v2`

Sortie attendue:
- telemetry stage/retry visible sur le tunnel historique

### `A2` - Reason codes et correlation IDs

Pourquoi ici:
- rend les mesures exploitables des le debut

Flag:
- `entry_journey_telemetry_v2`

Sortie attendue:
- `journey_run_id` et `reason_codes` normalises

### `A3` - Flags techniques de migration

Pourquoi ici:
- prepare les bascules sans changer encore le produit

Flag:
- aucun, infrastructure always-on

Sortie attendue:
- flags structurants disponibles

### `B1` - Modele `TunnelState` et reason codes du domaine

Pourquoi ici:
- fondation du nouveau coeur

Flag:
- `entry_journey_state_model_v2`

Sortie attendue:
- modele canonique compile et testable

### `E1` - Shells et layout tunnel

Pourquoi ici:
- peut avancer tot sans bloquer le coeur

Flag:
- `entry_journey_ui_v2`

Sortie attendue:
- briques de layout communes pretes

## Vague 1 - Coeur de tunnel

### `B2` - Bridge `legacy -> TunnelState`

Flag:
- `entry_journey_state_model_v2`

Precondition:
- `B1`

Sortie attendue:
- etat cible lisible sans casser l'existant

### `B3` - `EntryJourneyOrchestrator` en mode shadow

Flag:
- `entry_journey_state_model_v2`

Precondition:
- `B1`, `B2`

Sortie attendue:
- nouvel orchestrateur tournant en parallele controlee

### `C1` - Contrat session et auth

Flag:
- `entry_journey_state_model_v2`

Precondition:
- `B3`

Sortie attendue:
- `auth_required` fiable dans le nouveau coeur

### `C2` - Contrats profiles et selection

Flag:
- `entry_journey_state_model_v2`

Precondition:
- `B3`

Sortie attendue:
- `profile_required` fiable

### `C3` - Contrats sources et selection active

Flag:
- `entry_journey_state_model_v2`

Precondition:
- `B3`

Sortie attendue:
- `source_required` fiable

## Vague 2 - Bascule de source de verite et projection routeur

### `B4` - Bascule de la source de verite

Flag:
- `entry_journey_state_model_v2`

Precondition:
- `B3`, `C1`, `C2`, `C3`

Sortie attendue:
- nouveau coeur devenu source de verite du tunnel

### `D1` - Derive `TunnelSurface`

Flag:
- `entry_journey_routing_v2`

Precondition:
- `B4`

Sortie attendue:
- projection unique de surface disponible

### `D2` - Routeur branche sur `TunnelSurface`

Flag:
- `entry_journey_routing_v2`

Precondition:
- `D1`

Sortie attendue:
- routeur projete l'etat cible

## Vague 3 - Briques UI communes et surfaces amont

### `E2` - Composants de selection et feedback

Flag:
- `entry_journey_ui_v2`

Precondition:
- `E1`

Sortie attendue:
- galerie / messages / recovery communs

### `E3` - Focus TV et interactions communes

Flag:
- `entry_journey_ui_v2`

Precondition:
- `E1`, `E2`

Sortie attendue:
- focus TV stable pour les futures surfaces

### `F1` - Surface `Preparation systeme`

Flag:
- `entry_journey_ui_v2`

Precondition:
- `A1`, `B4`, `D2`, `E1`

Sortie attendue:
- `offline` et etat systeme servis sur la surface cible

### `F2` - Surface `Auth`

Flag:
- `entry_journey_ui_v2`

Precondition:
- `C1`, `E1`

Sortie attendue:
- auth cible branchee

### `F3` - Surface `Creation profil`

Flag:
- `entry_journey_ui_v2`

Precondition:
- `C2`, `E1`

Sortie attendue:
- creation profil sur contrat cible

### `F4` - Surface `Choix profil`

Flag:
- `entry_journey_ui_v2`

Precondition:
- `C2`, `E2`, `E3`

Sortie attendue:
- choix profil cible mobile / TV

## Vague 4 - Bloc source

### `C4` - Contrat validation source et recovery

Flag:
- `entry_journey_source_hub_v2`

Precondition:
- `C3`

Sortie attendue:
- validation source bornee

### `G1` - Hub source unifie

Flag:
- `entry_journey_source_hub_v2`

Precondition:
- `C3`, `E2`, `E3`

Sortie attendue:
- surface source unique

### `G2` - Ajout source et validation guidee

Flag:
- `entry_journey_source_hub_v2`

Precondition:
- `G1`, `C4`

Sortie attendue:
- ajout / validation cible

### `G3` - Recovery source

Flag:
- `entry_journey_source_hub_v2`

Precondition:
- `G2`

Sortie attendue:
- safe states source cibles

## Vague 5 - Pre-home borne

### `C5` - Contrat pre-home minimal

Flag:
- `entry_journey_prehome_v2`

Precondition:
- `C3`, `C4`

Sortie attendue:
- `catalog minimal ready` defini et mesure

### `H1` - Surface `Chargement medias`

Flag:
- `entry_journey_prehome_v2`

Precondition:
- `C5`, `E1`, `E2`

Sortie attendue:
- surface pre-home cible active

### `H2` - Separation `catalog minimal` / `catalog full`

Flag:
- `entry_journey_prehome_v2`

Precondition:
- `C5`, `H1`

Sortie attendue:
- `Home` n'attend plus le catalogue complet

## Vague 6 - Nettoyage et fermeture

### `D3` - Simplification des guards legacy

Flag:
- `entry_journey_cleanup_v2`

Precondition:
- `D2`, surfaces amont stables

Sortie attendue:
- moins de logique metier dans les guards

### `H3` - Preferences hors logique metier

Flag:
- `entry_journey_cleanup_v2`

Precondition:
- `B4`, `C2`, `C3`

Sortie attendue:
- preferences reduites a la persistence

### `H4` - Nettoyage final legacy

Flag:
- `entry_journey_cleanup_v2`

Precondition:
- `D3`, `F1-F4`, `G1-G3`, `H1-H3`

Sortie attendue:
- suppression des ponts et pages legacy devenus inutiles

## Jalons intermediaires recommandes

## Jalon 1 - Mesure et coeur lisible

Lots minimum:
- `A1`
- `A2`
- `A3`
- `B1`
- `B2`

Valeur:
- le tunnel commence a etre pilotable sans changement UX majeur

## Jalon 2 - Nouveau coeur actif

Lots minimum:
- `B3`
- `C1`
- `C2`
- `C3`

Valeur:
- les grandes decisions auth/profile/source existent deja dans le nouveau coeur

## Jalon 3 - Routing cible stable

Lots minimum:
- `B4`
- `D1`
- `D2`

Valeur:
- l'etat pilote le routeur

## Jalon 4 - Amont du tunnel migre

Lots minimum:
- `E2`
- `E3`
- `F1`
- `F2`
- `F3`
- `F4`

Valeur:
- l'utilisateur voit deja une partie substantielle du nouveau tunnel

## Jalon 5 - Bloc source cible

Lots minimum:
- `C4`
- `G1`
- `G2`
- `G3`

Valeur:
- le hotspot source est enfin aligne UX + architecture + resilience

## Jalon 6 - Pre-home borne

Lots minimum:
- `C5`
- `H1`
- `H2`

Valeur:
- la promesse phase 4 est tenue

## Jalon 7 - Tunnel cible propre

Lots minimum:
- `D3`
- `H3`
- `H4`

Valeur:
- plus de duplication systemique structurante

## Sorties d'etape partielles acceptables

Les sorties partielles suivantes sont acceptables:

- coeur shadow actif sans surfaces finales
- composants UI communs prets avant migration des pages
- surfaces amont migrees alors que le bloc source reste encore partiellement legacy
- nouveau `Chargement medias` actif avant nettoyage complet des ponts historiques

Les sorties partielles non recommandees sont:

- routeur cible actif sans telemetry exploitable
- hub source migre sans validation source bornee
- pre-home cible actif sans separation `catalog minimal / catalog full`
- nettoyage legacy lance avant stabilisation du routing et du bloc source

## Arbitrages encore ouverts

Les points suivants peuvent encore demander arbitrage pendant execution:

### 1. Sous-decoupage de `B4`

Si `B4` grossit trop:
- le couper en activation source de verite puis retrait du bridge legacy

### 2. Sous-decoupage de `G1`

Si la fusion source devient trop lourde:
- separer structure UI et logique de navigation / fusion

### 3. Timing exact de `D3`

Si la projection routeur reste sensible:
- repousser `D3` apres stabilisation plus longue des surfaces

## Regles de gouvernance d'execution

- ne pas faire monter un lot de vague suivante si une precondition critique manque
- ne pas activer simultanement `routing_v2`, `source_hub_v2` et `prehome_v2`
- garder une verification telemetry apres chaque jalon
- documenter explicitement toute coexistence prolongee au-dela du jalon prevu

## Resume executif

Le plan consolide recommande est:
- d'abord mesurer et stabiliser le coeur
- ensuite basculer le routeur
- ensuite migrer l'amont du tunnel
- ensuite fermer le bloc source
- ensuite finaliser le pre-home borne
- enfin nettoyer le legacy

## Verdict

La sous-phase `5.6` est suffisamment stable si l'on retient ces points:
- le backlog ordonne final est explicite
- les jalons intermediaires sont lisibles
- les sorties partielles acceptables sont bornees
- les derniers arbitrages sont identifies

La suite logique est la sous-phase `5.7`, pour clore la phase 5 avec une validation finale de stabilite.

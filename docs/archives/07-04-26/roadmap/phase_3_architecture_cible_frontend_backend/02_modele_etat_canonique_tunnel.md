# Sous-phase 3.1 - Modele d'etat canonique du tunnel

## Objectif

Definir un modele d'etat metier unique pour le tunnel d'entree, de l'ouverture de l'app jusqu'a l'autorisation d'entrer dans `home`.

Cette sous-phase ne redefinit pas l'UI. Elle fixe:
- les etats canoniques du tunnel
- les axes derives qui evitent de multiplier les faux etats
- les transitions autorisees
- les evenements utiles a l'orchestrateur
- les gardes et reason codes qui expliquent pourquoi le tunnel est dans un etat donne

## Decision de modelisation

Le tunnel cible n'est plus modelise comme une simple `destination` de route.

La cible retenue est:
- un **etat canonique principal** du tunnel
- enrichi par des **qualifiers** transverses
- et par un **snapshot de criteria** lisible par l'orchestrateur

Autrement dit:
- l'etat principal dit **ou en est le parcours**
- les qualifiers disent **dans quelle qualite d'execution**
- les criteria disent **quelles conditions sont deja satisfaites**

Cette forme est preferable a une enum geante, car elle:
- reste lisible
- couvre le nominal et le degrade sans explosion combinatoire
- aligne mieux UX, orchestration et telemetry

## Limites du modele actuel

Les objets existants sont utiles, mais insuffisants comme source de verite cible:

- [enum.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/domain/enum.dart)
  `BootstrapDestination` ne decrit qu'une destination de navigation.
- [app_launch_criteria.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_criteria.dart)
  `AppLaunchCriteria` capture quelques conditions utiles, mais pas:
  - la connectivite
  - la validite reelle de la source
  - le caractere degrade ou bloque
  - les reason codes
  - la distinction entre `catalogue pret` et `catalogue vide`
- [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart)
  `status`, `phase`, `destination` et `recoveryKind` decrivent une execution, mais pas encore un modele canonique defendable

Conclusion:
- `BootstrapDestination` devient une couche de compatibilite routeur
- `AppLaunchCriteria` doit evoluer vers un snapshot plus riche
- la source de verite cible est un **TunnelState** explicite

## Forme cible du modele

## 1. Etat principal

L'etat principal du tunnel doit etre un de ces noeuds:

1. `preparing_system`
2. `auth_required`
3. `profile_required`
4. `source_required`
5. `preloading_home`
6. `ready_for_home`

Ces noeuds suffisent pour representer le parcours cible valide en phase 1.

## 2. Qualifiers transverses

Les qualifiers evitent de creer des etats dupliques du type `source_required_but_offline_but_retryable`.

Qualifiers recommandes:
- `execution_mode`
  - `nominal`
  - `degraded`
  - `blocked`
- `continuity_mode`
  - `cloud`
  - `local_fallback`
- `content_state`
  - `unknown`
  - `ready`
  - `empty`
- `loading_state`
  - `normal`
  - `slow`

## 3. Snapshot de criteria

Le snapshot de criteria doit etre calcule par l'orchestrateur et expose au meme niveau que l'etat principal.

Criteria recommandes:
- `startupReady`
- `networkAvailable`
- `sessionResolved`
- `hasSession`
- `profilesResolved`
- `hasSelectedProfile`
- `sourcesResolved`
- `hasSelectedSource`
- `selectedSourceValid`
- `catalogReady`
- `catalogHasContent`
- `libraryReady`
- `homePreloaded`

## 4. Reason codes

Les reason codes sont obligatoires pour:
- expliquer un etat degrade ou bloque
- guider la microcopy
- tracer la telemetry
- eviter les branches opaques dans le code

Un etat peut porter zero, un ou plusieurs reason codes.

## Etat canonique recommande

En pseudo-modele:

```text
TunnelState {
  stage: TunnelStage
  executionMode: nominal | degraded | blocked
  continuityMode: cloud | local_fallback
  contentState: unknown | ready | empty
  loadingState: normal | slow
  reasons: Set<TunnelReasonCode>
  criteria: TunnelCriteriaSnapshot
}
```

## Etats canoniques du tunnel

## 1. `preparing_system`

Role:
- point d'entree systeme unique
- resolution du bootstrap technique
- evaluation initiale du contexte auth, profils, sources, preload

Nature:
- etat transitoire

Surface UX derivee:
- `Preparation systeme`

Ce qui peut y rester inline:
- progression
- message de sync cloud
- message de fallback local
- message de chargement long

## 2. `auth_required`

Role:
- le tunnel ne peut pas progresser sans authentification ou confirmation d'acces

Nature:
- etat stable de decision utilisateur

Surface UX derivee:
- `Auth`

Exemples de reasons:
- `auth_missing`
- `auth_expired`
- `auth_reconfirmation_required`

## 3. `profile_required`

Role:
- l'utilisateur doit creer ou choisir un profil avant de continuer

Nature:
- etat stable de decision utilisateur

Surface UX derivee:
- `Creation profil` ou `Choix profil` selon les criteria

Exemples de reasons:
- `profile_missing`
- `profile_selection_required`

## 4. `source_required`

Role:
- aucune source exploitable n'est selectionnee
- ou la source active est invalide et doit etre re-resolue

Nature:
- etat stable de decision utilisateur

Surface UX derivee:
- `Choix / ajout source`

Exemples de reasons:
- `source_missing`
- `source_selection_required`
- `source_invalid`
- `cloud_sync_partial`

## 5. `preloading_home`

Role:
- toutes les decisions utilisateur critiques sont prises
- le tunnel attend encore les preconditions minimales avant `home`

Nature:
- etat transitoire

Surface UX derivee:
- `Chargement medias`

Exemples de reasons:
- `catalog_loading`
- `library_loading`
- `home_preload_running`
- `preload_slow`

## 6. `ready_for_home`

Role:
- les preconditions minimales d'entree dans `home` sont satisfaites

Nature:
- etat terminal du tunnel

Surface UX derivee:
- sortie du tunnel vers `home`

Note:
- `Home vide` n'est pas un etat principal distinct du tunnel
- c'est `ready_for_home` avec `content_state = empty`

## Classification par categorie

## Etats stables

- `auth_required`
- `profile_required`
- `source_required`

## Etats transitoires

- `preparing_system`
- `preloading_home`

## Etats de recovery

Il n'y a pas d'etat principal supplementaire dedie au recovery.

Le recovery est exprime par:
- `execution_mode = degraded` ou `blocked`
- plus un ou plusieurs `reason codes`

Exemples:
- `preparing_system + degraded + local_fallback_active`
- `source_required + degraded + source_invalid`
- `preloading_home + blocked + network_unavailable`

## Etats terminaux

- `ready_for_home` avec `content_state = ready`
- `ready_for_home` avec `content_state = empty`

## Gardes critiques

Les gardes suivantes doivent gouverner les transitions:

## Gardes de progression

- `requiresAuth = !criteria.hasSession`
- `requiresProfile = !criteria.hasSelectedProfile`
- `requiresSource = !criteria.hasSelectedSource || !criteria.selectedSourceValid`
- `canStartPreload = criteria.hasSession && criteria.hasSelectedProfile && criteria.hasSelectedSource && criteria.selectedSourceValid`
- `canEnterHome = criteria.hasSelectedProfile && criteria.hasSelectedSource && criteria.selectedSourceValid && criteria.catalogReady && criteria.libraryReady && criteria.homePreloaded`

## Gardes de qualite d'execution

- `isBlockedByNetwork = !criteria.networkAvailable`
- `isCloudSyncDegraded = reasons contains cloud_sync_partial`
- `isUsingLocalFallback = continuityMode == local_fallback`
- `isContentEmpty = criteria.catalogReady && !criteria.catalogHasContent`
- `isLongLoading = loadingState == slow`

## Table de transitions coeur

| State | Event | Guard | Next state |
| --- | --- | --- | --- |
| `preparing_system` | `startup_completed` | `requiresAuth` | `auth_required` |
| `preparing_system` | `startup_completed` | `!requiresAuth && requiresProfile` | `profile_required` |
| `preparing_system` | `startup_completed` | `!requiresAuth && !requiresProfile && requiresSource` | `source_required` |
| `preparing_system` | `startup_completed` | `canStartPreload` | `preloading_home` |
| `preparing_system` | `startup_safe_mode_enabled` | `requiresProfile` | `profile_required` |
| `preparing_system` | `startup_safe_mode_enabled` | `requiresSource` | `source_required` |
| `auth_required` | `auth_succeeded` | `requiresProfile` | `profile_required` |
| `auth_required` | `auth_succeeded` | `!requiresProfile && requiresSource` | `source_required` |
| `auth_required` | `auth_succeeded` | `canStartPreload` | `preloading_home` |
| `profile_required` | `profile_created_or_selected` | `requiresSource` | `source_required` |
| `profile_required` | `profile_created_or_selected` | `canStartPreload` | `preloading_home` |
| `source_required` | `source_added_or_selected` | `criteria.selectedSourceValid` | `preloading_home` |
| `source_required` | `source_validation_failed` | `true` | `source_required` |
| `preloading_home` | `preload_completed` | `canEnterHome && !isContentEmpty` | `ready_for_home` |
| `preloading_home` | `preload_completed` | `canEnterHome && isContentEmpty` | `ready_for_home` |
| `preloading_home` | `preload_delayed` | `true` | `preloading_home` |
| `preloading_home` | `network_lost` | `isBlockedByNetwork` | `preloading_home` |
| `ready_for_home` | `enter_home_acknowledged` | `true` | exit tunnel |

## Evenements metier a reconnaitre

## Bootstrap et contexte

- `app_opened`
- `startup_completed`
- `startup_safe_mode_enabled`
- `network_lost`
- `network_restored`
- `retry_requested`
- `restart_journey_requested`

## Auth

- `session_detected`
- `session_missing`
- `auth_succeeded`
- `auth_failed`
- `auth_expired_detected`

## Profil

- `profiles_loaded`
- `profile_created`
- `profile_selected`

## Source

- `sources_loaded`
- `source_selected`
- `source_added`
- `source_validation_failed`
- `source_validated`

## Preload avant home

- `catalog_loaded`
- `catalog_empty_detected`
- `library_loaded`
- `home_preload_completed`
- `preload_delayed`

## Reason codes principaux recommandes

## Contexte systeme

- `startup_pending`
- `startup_safe_mode`
- `network_unavailable`
- `retry_available`
- `restart_required`

## Auth

- `auth_missing`
- `auth_expired`
- `auth_reconfirmation_required`

## Profil

- `profile_missing`
- `profile_selection_required`

## Source

- `source_missing`
- `source_selection_required`
- `source_invalid`
- `source_validation_failed`
- `source_catalog_empty`

## Cloud et fallback

- `cloud_sync_partial`
- `local_fallback_active`
- `cloud_resume_pending`

## Chargement et pre-home

- `catalog_loading`
- `library_loading`
- `home_preload_running`
- `preload_slow`

## Mapping etat -> surface UX cible

| Etat canonique | Surface cible | Notes |
| --- | --- | --- |
| `preparing_system` | `Preparation systeme` | Inclut bootstrap, sync initiale, fallback inline |
| `auth_required` | `Auth` | Pas de logique metier dans le widget |
| `profile_required` | `Creation profil` ou `Choix profil` | Surface derivee selon la presence de profils existants |
| `source_required` | `Choix / ajout source` | Source invalide et sync partielle restent inline |
| `preloading_home` | `Chargement medias` | Le chargement long reste inline dans cette surface |
| `ready_for_home` + `content_state = ready` | sortie vers `Home` | Tunnel termine |
| `ready_for_home` + `content_state = empty` | sortie vers `Home vide` | `Home vide` reste un mode de `home`, pas un ecran tunnel |

## Impacts directs sur l'architecture cible

## 1. Le routeur ne calcule plus le parcours

Le routeur doit:
- lire un etat canonique deja resolu
- mapper cet etat vers une surface
- rester une couche de compatibilite de navigation

Il ne doit plus:
- reconstituer les conditions profil/source
- porter sa propre machine d'etat implicite

## 2. L'orchestrateur produit un `TunnelState`

L'orchestrateur cible doit exposer:
- un etat principal
- des criteria
- des reason codes
- des commandes de retry / restart / continue

Il ne doit pas exposer uniquement:
- une `destination`
- une `phase`
- un `status`

## 3. `AppLaunchCriteria` doit etre etendu

Le snapshot futur doit depasser le modele actuel de [app_launch_criteria.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_criteria.dart) pour inclure:
- connectivite
- validite de la source
- resolution des profils et des sources
- etat du contenu

## 4. `Home vide` sort du tunnel

Le tunnel decide si `home` peut s'ouvrir.

Le rendu `Home vide`:
- n'est plus une etape de parcours
- devient un mode d'arrivee de `home`
- reste derive de `ready_for_home + content_state = empty`

## 5. Le fallback local reste un axe transverse

Decision recommandee:
- ne pas creer des etats du type `local_profile_required`
- annoter l'etat avec:
  - `continuity_mode = local_fallback`
  - `reasonCode = local_fallback_active`

Cette decision garde le modele compact et plus stable.

## Points volontairement deferes a 3.2

Cette sous-phase fixe le modele d'etat, mais ne tranche pas encore:
- l'API exacte de l'orchestrateur
- la forme concrete des commandes et effects
- le detail des ports utilises
- la repartition finale entre orchestrateur, services et adapters

Ces points seront traites en `3.2`.

## Verdict de sortie de la sous-phase 3.1

Verdict:
- la sous-phase `3.1` est suffisamment stable pour lancer `3.2`

Pourquoi:
- le tunnel a maintenant un etat principal unique
- le nominal, le degrade et le bloque sont modelises sans duplication
- les transitions critiques sont bornees
- le role futur du routeur et de l'orchestrateur est deja clarifie

## Prochaine etape recommandee

La suite logique est:
1. definir le `entry journey orchestrator` qui calcule et publie ce `TunnelState`
2. preciser ses entrees, sorties et commandes
3. fixer ce qui reste hors de l'orchestrateur

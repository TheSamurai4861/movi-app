# Sous-phase 4.2 - Politique timeout, retry, preload et fallback

## Objectif

Traduire les budgets de `4.1` en politiques concretes de:
- timeout
- retry
- preload borne
- fallback

Cette sous-phase fixe:
- les delais de patience par contrat critique
- le nombre maximal de retries
- les regles de backoff
- les conditions d'entree en `degraded` et `blocked`
- les conditions de fallback local et de reprise

## Principe directeur

Le tunnel ne doit jamais:
- attendre indefiniment
- retryer silencieusement sans borne
- lancer un preload sans limite claire
- cacher un blocage derriere un simple spinner

La regle retenue est:
- **patience courte**
- **retry borne**
- **safe state explicite**

## Taxonomie des comportements

Chaque contrat critique doit suivre cette logique:

1. une fenetre `nominal`
2. un seuil `slow`
3. une borne `timeout`
4. un nombre maximal de retries
5. une issue:
   - continuer
   - degrader
   - blocker
   - fallback local

## Politique globale de retry

Regle globale:
- pas de retry infini
- pas de retry cache au-dela de la premiere tentative automatique bornee

Politique par defaut:
- `1` tentative initiale
- `1` retry automatique maximum si le contrat est retryable
- `1` retry manuel utilisateur via action explicite

Backoff recommande:
- retry automatique: backoff fixe court `250 ms` a `500 ms`
- retry manuel: pas de backoff impose, mais protection anti-spam au niveau implementation

Exception:
- certains contrats purement locaux peuvent ne pas retryer du tout

## Politique globale de passage d'etat

Regle:
- `slow` ne signifie pas encore `blocked`
- `timeout` ne signifie pas automatiquement `blocked`

Decision:
- si une issue de repli defendable existe, on privilegie `degraded`
- si aucune progression sure n'est possible, on passe en `blocked`

## Matrice des contrats critiques

## 1. `StartupStatusPort`

Role:
- bootstrap systeme

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `startup_status` | `> 1200 ms` | `2500 ms` | `0` | `1` | `degraded` si `safeMode`, sinon `blocked` |

Decision:
- pas de retry automatique du bootstrap global
- si le startup est recuperable, bascule vers `safeMode`
- sinon blocage explicite

Reason codes cibles:
- `startup_pending`
- `startup_safe_mode`
- `startup_dependencies_failed`

## 2. `ConnectivityPort`

Role:
- evaluation reseau et internet reachable

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `connectivity_check` | `> 400 ms` | `1200 ms` | `0` | `illimite via retry utilisateur` | `blocked` ou `degraded` selon fallback |

Decision:
- pas de retry automatique
- si le flow requiert le reseau et qu'aucun fallback n'est possible: `blocked`
- si un mode local est autorise: `degraded + local_fallback`

Reason codes cibles:
- `network_unavailable`
- `internet_unreachable`
- `local_fallback_active`

## 3. `SessionSnapshotPort`

Role:
- restore / refresh session

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `session_resolve` | `> 800 ms` | `1800 ms` | `1` | `1` | `auth_required` ou `degraded` |

Decision:
- `1` retry automatique si timeout reseau court
- si la session ne peut pas etre prouvee:
  - `auth_required` si re-auth possible
  - `degraded` si fallback local explicitement autorise

Reason codes cibles:
- `auth_missing`
- `auth_expired`
- `auth_reconfirmation_required`
- `cloud_auth_unreachable`

## 4. `ProfilesInventoryPort`

Role:
- charger les profils

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `profiles_inventory` | `> 500 ms` | `1200 ms` | `1` | `1` | `profile_required` ou `degraded` |

Decision:
- `1` retry automatique acceptable si la lecture est distante
- si le cloud echoue mais qu'un profil local est exploitable: `degraded`
- si aucun profil exploitable n'est disponible: `profile_required`

Reason codes cibles:
- `profile_inventory_unavailable`
- `profile_missing`
- `local_profile_only`

## 5. `SelectedProfilePort`

Role:
- resoudre le profil courant

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `selected_profile_resolve` | `> 150 ms` | `400 ms` | `0` | `0` | `profile_required` |

Decision:
- pas de retry
- si non resolu, le tunnel passe simplement a `profile_required`

## 6. `SourcesInventoryPort`

Role:
- charger l'inventaire sources

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `sources_inventory` | `> 700 ms` | `1500 ms` | `1` | `1` | `source_required` ou `degraded` |

Decision:
- `1` retry automatique acceptable
- si inventaire cloud indisponible mais source locale exploitable: `degraded`
- sinon passage a `source_required`

Reason codes cibles:
- `sources_inventory_unavailable`
- `source_missing`
- `cloud_sync_partial`

## 7. `SelectedSourcePort`

Role:
- resoudre la source active

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `selected_source_resolve` | `> 150 ms` | `400 ms` | `0` | `0` | `source_required` |

Decision:
- pas de retry
- si non resolu, choix manuel impose

## 8. `SourceValidationPort`

Role:
- verifier que la source selectionnee est exploitable

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `source_validation` | `> 1200 ms` | `3000 ms` | `1` | `1` | `source_required` ou `degraded` |

Decision:
- `1` retry automatique seulement pour timeout court ou erreur reseau manifestement transitoire
- si validation echoue:
  - `source_required` avec message explicite
  - `degraded` seulement si une autre source deja validee peut reprendre le relai automatiquement

Reason codes cibles:
- `source_invalid`
- `source_validation_failed`
- `source_timeout`
- `source_auth_invalid`

## 9. `HomePreloadPort`

Role:
- amener `catalogReady`, `libraryReady` et `homePreloaded` au minimum requis

Politique retenue:

| Contrat | Slow | Timeout | Retry auto | Retry manuel | Issue |
| --- | --- | --- | --- | --- | --- |
| `catalog_ready` | `> 1800 ms` | `4000 ms` | `1` | `1` | `degraded` ou `blocked` |
| `library_ready` | `> 900 ms` | `2000 ms` | `1` | `1` | `degraded` |
| `home_preloaded` | `> 700 ms` | `1500 ms` | `0` | `1` | `degraded` |
| `preloading_home_global` | `> 2500 ms` | `5000 ms` | `0` | `1` | `degraded strong` ou `blocked` |

Decision:
- `catalog_ready` peut avoir `1` retry automatique
- `library_ready` peut avoir `1` retry automatique si cloud sync partielle
- `home_preloaded` ne retrye pas automatiquement
- au-dela du timeout global, le tunnel ne reste plus en attente implicite

Reason codes cibles:
- `catalog_loading`
- `library_loading`
- `home_preload_running`
- `preload_slow`
- `source_catalog_empty`

## Politique de preload borne

## Regle 1 - Le preload pre-home ne doit attendre que le `must-have`

Le preload doit s'arreter des que:
- `catalogReady`
- `libraryReady`
- `homePreloaded`
sont satisfaits au niveau minimal requis

Il ne doit pas attendre:
- enrichissements secondaires
- sync non critique
- donnees utiles seulement apres `home`
- chargement complet d'un catalogue volumineux si ce chargement peut legitiment prendre `10-15 s`

Decision explicite:
- `catalog_ready` ne veut pas dire `catalogue exhaustif entierement charge`
- `catalog_ready` veut dire `catalogue minimal exploitable pour entrer dans home`

## Regle 2 - Le preload a une borne globale dure

Borne retenue:
- `5000 ms` maximum pour `preloading_home` global

Au-dela:
- sortie du simple loading
- passage a `degraded strong` ou `blocked` selon le contrat manquant

Consequence architecturale:
- si le catalogue complet demande `10-15 s`, cette charge doit etre decoupee
- une partie minimale reste `must-have before home`
- le reste devient `can-load-after-home`

## Regle 3 - `catalog empty` n'est pas un echec de preload

Si:
- `catalogReady = true`
- `catalogHasContent = false`
- `libraryReady = true`
- `homePreloaded = true`

Alors:
- le preload est considere comme reussi
- `ready_for_home` est autorise
- `content_state = empty`

## Regle 4 - Le catalogue complet devient un chargement post-home

Si la volumetrie implique `10-15 s` de chargement normal:
- le tunnel attend seulement le seuil `catalog_ready` minimal
- le chargement complet continue apres l'entree dans `home`
- ce travail devra etre instrumente separement comme charge differee

## Politique de fallback local

Le fallback local n'est autorise que si:
- il existe une continuation sure et comprehensible
- le mode local ne contredit pas la promesse produit du moment

## Cas autorises

Fallback local acceptable pour:
- profils locaux disponibles
- sources locales deja connues
- contexte de reprise deja present

## Cas non autorises

Pas de fallback local si:
- aucune source exploitable n'existe
- la verification de session est strictement obligatoire pour continuer
- l'etat local est trop incomplet pour servir une progression sure

## Politique de passage `degraded` vs `blocked`

## Passage en `degraded`

On degrade si:
- l'utilisateur peut continuer dans un mode comprehensible
- un safe state stable existe
- l'action primaire reste claire

Exemples:
- cloud lent mais profils locaux disponibles
- source invalide mais choix manuel possible
- preload partiel mais `home` encore atteignable selon contrat

## Passage en `blocked`

On bloque si:
- aucune progression sure n'est possible
- aucune continuation ne respecte le contrat produit
- le risque de confusion ou de corruption est trop fort

Exemples:
- reseau obligatoire absent sans fallback
- startup critique echoue sans safe mode
- session doit etre reverifiee sans issue locale defendable

## Politique de reprise

## Retry automatique

Usage:
- une seule fois
- uniquement pour erreurs transitoires probables

## Retry manuel

Usage:
- toujours prefere au troisieme essai implicite
- doit etre visible et trace

## Restart journey

A utiliser si:
- l'etat courant est devenu incoherent
- plusieurs contrats critiques ont echoue
- un reset propre est plus fiable qu'une accumulation de retries

## Tableau de synthese

| Contrat | Timeout | Retry auto | Retry manuel | Issue par defaut |
| --- | --- | --- | --- | --- |
| `startup_status` | `2500 ms` | `0` | `1` | `degraded` ou `blocked` |
| `connectivity_check` | `1200 ms` | `0` | `1+` | `blocked` ou `local_fallback` |
| `session_resolve` | `1800 ms` | `1` | `1` | `auth_required` ou `degraded` |
| `profiles_inventory` | `1200 ms` | `1` | `1` | `profile_required` ou `degraded` |
| `selected_profile_resolve` | `400 ms` | `0` | `0` | `profile_required` |
| `sources_inventory` | `1500 ms` | `1` | `1` | `source_required` ou `degraded` |
| `selected_source_resolve` | `400 ms` | `0` | `0` | `source_required` |
| `source_validation` | `3000 ms` | `1` | `1` | `source_required` ou `degraded` |
| `catalog_ready` | `4000 ms` | `1` | `1` | `degraded` ou `blocked` |
| `library_ready` | `2000 ms` | `1` | `1` | `degraded` |
| `home_preloaded` | `1500 ms` | `0` | `1` | `degraded` |
| `preloading_home_global` | `5000 ms` | `0` | `1` | `degraded strong` ou `blocked` |

## Points encore ouverts apres 4.2

Ces points seront precises en `4.4` et `4.5`.

1. Quel event telemetry exact porte chaque timeout et retry.
2. Quelle microcopy apparait a chaque seuil `slow` et `blocked`.
3. Quels safe states visuels exacts correspondent a chaque issue `degraded`.

## Decision log

1. Aucun contrat critique ne retrye indefiniment.
2. Le preload pre-home a une borne globale dure de `5000 ms`.
3. `catalog empty` est un succes fonctionnel, pas un echec.
4. Le fallback local est un mode explicite et borne, pas une issue implicite.
5. `degraded` est prefere a `blocked` seulement si une continuation sure existe.

## Verdict de sortie de la sous-phase 4.2

Verdict:
- la sous-phase `4.2` est suffisamment stable pour lancer `4.3`

Pourquoi:
- les timeouts sont bornees par contrat
- les retries sont limites et coherents
- les regles de preload et fallback sont explicites
- les conditions de passage vers `degraded` et `blocked` sont bornees

## Prochaine etape recommandee

La suite logique est:
1. reprendre tous les chargements pre-home
2. separer strictement `must-have before home` et `can-load-after-home`
3. sortir du tunnel tout ce qui ne tient pas la promesse produit minimale

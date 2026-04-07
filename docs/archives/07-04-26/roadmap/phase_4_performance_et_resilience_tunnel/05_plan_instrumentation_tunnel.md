# Sous-phase 4.4 - Instrumentation, telemetry et reason codes de mesure

## Objectif

Rendre toutes les transitions critiques du tunnel observables, avec:
- des evenements de mesure stables
- des champs telemetry obligatoires
- des reason codes de performance et de resilience

Cette sous-phase ne decrit pas encore l'implementation code exacte. Elle fixe le contrat d'observabilite du tunnel.

## Principe directeur

Le tunnel doit pouvoir repondre sans ambiguite a ces questions:
- ou le temps est-il depense
- quel contrat est lent
- quel etat passe en `degraded` ou `blocked`
- combien de temps faut-il pour atteindre un safe state
- quelle part du travail a ete differee apres `home`

Sans cette instrumentation:
- les budgets de `4.1` ne sont pas pilotables
- la politique de `4.2` n'est pas verifiable
- la separation `pre-home / post-home` de `4.3` n'est pas mesurable

## Perimetre d'instrumentation

L'instrumentation de phase 4 doit couvrir:

1. transitions de `TunnelState`
2. resolutions de contrats critiques
3. retries et timeouts
4. entrees en `degraded`, `blocked`, `local_fallback`
5. separation entre charges pre-home et post-home
6. passage a `ready_for_home`
7. premiere peinture utile de `home`

## Taxonomie des evenements de mesure

## Famille A - Evenements de cycle de vie du tunnel

Ces evenements suivent la progression globale.

Evenements recommandes:
- `entry_journey_started`
- `entry_journey_stage_entered`
- `entry_journey_stage_completed`
- `entry_journey_stage_slow`
- `entry_journey_stage_blocked`
- `entry_journey_completed`

But:
- mesurer les temps par etape canonique
- piloter les budgets de `4.1`

## Famille B - Evenements de contrats critiques

Ces evenements suivent les 8 familles de contrats de phase 3.

Evenements recommandes:
- `startup_status_resolved`
- `connectivity_checked`
- `session_resolved`
- `profiles_inventory_loaded`
- `selected_profile_resolved`
- `sources_inventory_loaded`
- `selected_source_resolved`
- `source_validation_completed`
- `home_preload_completed`
- `continuity_mode_resolved`

But:
- localiser la lenteur au bon contrat
- distinguer la lenteur metier de la lenteur UI

## Famille C - Evenements de recoveries

Ces evenements suivent les sorties degradees.

Evenements recommandes:
- `entry_journey_retry_requested`
- `entry_journey_retry_executed`
- `entry_journey_fallback_local_entered`
- `entry_journey_blocked_entered`
- `entry_journey_safe_state_reached`
- `entry_journey_restarted`

But:
- mesurer le temps avant safe state
- quantifier la frequence des recoveries

## Famille D - Evenements de charges differees post-home

Ces evenements existent pour ne pas melanger le pre-home et le post-home.

Evenements recommandes:
- `catalog_minimal_ready`
- `catalog_full_load_started`
- `catalog_full_load_completed`
- `post_home_enrichment_started`
- `post_home_enrichment_completed`

But:
- proteger les KPI du tunnel
- suivre le cout reel du catalogue complet `10-15 s`

## Champs telemetry obligatoires

Chaque evenement critique du tunnel doit porter un noyau commun.

Champs communs recommandes:

| Champ | Obligation | Usage |
| --- | --- | --- |
| `event_name` | obligatoire | identification |
| `timestamp_ms` | obligatoire | ordering et duree |
| `session_id` | obligatoire | correlation d'une execution tunnel |
| `journey_run_id` | obligatoire | correlation d'une tentative |
| `stage` | obligatoire si pertinent | budget par etape |
| `execution_mode` | obligatoire | nominal / degraded / blocked |
| `continuity_mode` | obligatoire | cloud / local_fallback |
| `loading_state` | recommande | normal / slow |
| `reason_codes` | obligatoire si non vide | cause typ ee |
| `duration_ms` | obligatoire pour completed/slow/timeout | mesure |
| `device_class` | obligatoire | mobile / TV / autre |
| `app_start_kind` | obligatoire | cold / warm |
| `network_state` | obligatoire | online / offline / degraded |

## Champs additionnels par contrat

## Auth / session

- `has_session`
- `session_resolved`
- `auth_outcome`

## Profil

- `profiles_count`
- `selected_profile_present`
- `profile_resolution_source`

## Sources

- `sources_count`
- `selected_source_present`
- `selected_source_kind`
- `source_validation_outcome`

## Pre-home

- `catalog_ready`
- `catalog_has_content`
- `library_ready`
- `home_preloaded`
- `post_home_work_remaining`

## Evenements de mesure recommandes

## Evenements de stage

| Evenement | Quand | Champs minimum |
| --- | --- | --- |
| `entry_journey_started` | ouverture du tunnel | `session_id`, `journey_run_id`, `app_start_kind` |
| `entry_journey_stage_entered` | entree dans un stage | `stage`, `execution_mode`, `continuity_mode` |
| `entry_journey_stage_completed` | sortie nominale du stage | `stage`, `duration_ms` |
| `entry_journey_stage_slow` | seuil `slow` franchi | `stage`, `duration_ms`, `reason_codes` |
| `entry_journey_stage_blocked` | seuil `blocked` franchi | `stage`, `duration_ms`, `reason_codes` |
| `entry_journey_completed` | `ready_for_home` atteint | `duration_ms`, `content_state` |

## Evenements de contrats

| Evenement | Quand | Champs minimum |
| --- | --- | --- |
| `startup_status_resolved` | startup resolu | `duration_ms`, `reason_codes` |
| `connectivity_checked` | connectivite resolue | `duration_ms`, `network_state` |
| `session_resolved` | session resolue | `duration_ms`, `has_session`, `reason_codes` |
| `profiles_inventory_loaded` | profils charges | `duration_ms`, `profiles_count` |
| `selected_profile_resolved` | profil courant resolu | `duration_ms`, `selected_profile_present` |
| `sources_inventory_loaded` | sources chargees | `duration_ms`, `sources_count` |
| `selected_source_resolved` | source courante resolue | `duration_ms`, `selected_source_present` |
| `source_validation_completed` | validation source finie | `duration_ms`, `source_validation_outcome`, `reason_codes` |
| `home_preload_completed` | preload minimal fini | `duration_ms`, `catalog_ready`, `library_ready`, `home_preloaded` |

## Evenements de recoveries

| Evenement | Quand | Champs minimum |
| --- | --- | --- |
| `entry_journey_retry_requested` | action utilisateur | `stage`, `reason_codes` |
| `entry_journey_retry_executed` | retry lance | `stage`, `retry_index` |
| `entry_journey_fallback_local_entered` | bascule fallback | `stage`, `reason_codes` |
| `entry_journey_safe_state_reached` | safe state atteint | `stage`, `duration_ms`, `reason_codes` |
| `entry_journey_restarted` | reset de parcours | `reason_codes` |

## Evenements post-home

| Evenement | Quand | Champs minimum |
| --- | --- | --- |
| `catalog_minimal_ready` | seuil pre-home atteint | `duration_ms`, `catalog_has_content` |
| `catalog_full_load_started` | chargement exhaustif lance | `post_home_work_remaining` |
| `catalog_full_load_completed` | catalogue complet disponible | `duration_ms` |
| `post_home_enrichment_started` | enrichissement secondaire | `scope` |
| `post_home_enrichment_completed` | enrichissement fini | `scope`, `duration_ms` |

## Reason codes de performance et resilience

Les reason codes ci-dessous sont recommandes pour la mesure. Ils completent les reason codes metier de phase 3.

## Startup et systeme

- `startup_slow`
- `startup_timeout`
- `startup_safe_mode`

## Connectivite

- `network_unavailable`
- `internet_unreachable`
- `connectivity_timeout`

## Auth

- `session_resolve_slow`
- `session_resolve_timeout`
- `auth_missing`
- `auth_expired`
- `auth_reconfirmation_required`
- `cloud_auth_unreachable`

## Profils

- `profiles_inventory_slow`
- `profiles_inventory_timeout`
- `profile_missing`
- `profile_inventory_unavailable`

## Sources

- `sources_inventory_slow`
- `sources_inventory_timeout`
- `source_validation_slow`
- `source_validation_timeout`
- `source_invalid`
- `source_validation_failed`
- `source_timeout`

## Pre-home

- `catalog_minimal_slow`
- `catalog_minimal_timeout`
- `library_ready_slow`
- `library_ready_timeout`
- `home_preload_slow`
- `home_preload_timeout`
- `source_catalog_empty`

## Recovery / fallback

- `retry_triggered`
- `retry_exhausted`
- `local_fallback_active`
- `safe_state_reached`
- `blocked_state_entered`

## KPI recommandes de suivi

## KPI de performance

- `p50`, `p95` et `p99` de `entry_journey_completed`
- `p95` par `stage`
- `p95` par contrat critique
- temps median `ready_for_home -> first_home_paint_useful`

## KPI de resilience

- taux d'entree en `degraded`
- taux d'entree en `blocked`
- temps median vers `safe_state_reached`
- taux de retries automatiques
- taux de retries manuels
- taux de `local_fallback_active`

## KPI de separation pre-home / post-home

- temps median `catalog_minimal_ready`
- temps median `catalog_full_load_completed`
- proportion de travail differe apres `home`

## Regles de mise en oeuvre recommandees

## Regle 1 - Un evenement `completed` doit toujours avoir un `duration_ms`

Sans cela:
- impossible de piloter les budgets de `4.1`

## Regle 2 - Les reason codes doivent etre listes, pas remplaces par un message libre

Sans cela:
- analyse impossible a agreger

## Regle 3 - Pre-home et post-home doivent etre instrumentes separement

Sans cela:
- les KPI du tunnel deviennent inutilisables

## Regle 4 - Les retries doivent etre traces comme evenements propres

Sans cela:
- impossible de savoir si une bonne perf apparente masque plusieurs essais

## Regle 5 - Le stage et le contrat doivent etre correlables

Sans cela:
- on saura qu'un stage est lent, sans savoir quel contrat l'a cause

## Points encore ouverts apres 4.4

Ces points seront precises ensuite en implementation et en `4.5`.

1. Quel nommage exact sera retenu dans le code.
2. Quel adaptateur technique portera ces evenements.
3. Quels safe states exacts devront emettre quels evenements d'entree/sortie.

## Decision log

1. Le tunnel aura une telemetry de stage, de contrat, de recovery et de charges differees.
2. `catalog_minimal_ready` et `catalog_full_load_completed` doivent etre distincts.
3. Les retries sont des evenements de premier ordre.
4. Les reason codes de mesure completent les reason codes metier, ils ne les remplacent pas.
5. Les KPI de phase 4 doivent etre calculables sans interpretation manuelle.

## Verdict de sortie de la sous-phase 4.4

Verdict:
- la sous-phase `4.4` est suffisamment stable pour lancer `4.5`

Pourquoi:
- le plan d'instrumentation est structure
- les evenements critiques sont nommes
- les champs telemetry obligatoires sont explicites
- les reason codes de mesure sont cadres

## Prochaine etape recommandee

La suite logique est:
1. definir les safe states critiques
2. construire la matrice nominal / degrade / recovery
3. mapper etat detecte, surface, action et issue

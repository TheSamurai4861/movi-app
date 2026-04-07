# Environnements, dashboard minimal et traces de base

## Objectif

Definir le socle minimal d'execution et de verification necessaire avant de lancer les vagues critiques du tunnel.

## Environnements cibles

### `local`

But:
- developpement et verification rapide

Exigences minimales:
- flags pilotables localement
- logs structures lisibles
- fixtures ou mocks deterministes pour session, profils, sources, preload
- possibilite de forcer:
  - `offline`
  - `session_expired`
  - `source_invalid`
  - `catalog_empty`
  - `prehome_slow`

### `integration`

But:
- verifier les contrats inter-composants et les bascules sous flags

Exigences minimales:
- pipeline automatisee
- jeux de donnees reproductibles
- traces conservees pour les runs critiques
- verification `TunnelState -> TunnelSurface`

### `staging`

But:
- verifier le tunnel sur environnement proche du reel

Exigences minimales:
- configuration explicite
- flags pilotables
- telemetry exploitable
- dependances externes representatives
- au moins une source de test representative

### `production`

But:
- rollout progressif et comparaison avant/apres

Exigences minimales:
- dashboards temps reel
- kill switches disponibles
- tracing correlable
- suivi des reason codes critiques

## Dashboard minimal obligatoire

Le dashboard minimal doit afficher au moins:

### Vue funnel tunnel

- `entry_journey_started`
- `entry_journey_completed`
- abandon implicite si available
- repartition par `surface finale atteinte`

### Vue latence

- `preparing_system`
- `session_resolve`
- `profiles_inventory_loaded`
- `sources_inventory_loaded`
- `source_validation_completed`
- `catalog_minimal_ready`
- `catalog_full_load_completed`
- `time_to_safe_state`

Format recommande:
- `count`
- `failure_rate`
- `p50`
- `p95`
- `max`

### Vue errors et safe states

- `network_required_blocked`
- `auth_required_explicit`
- `profile_selection_required`
- `source_selection_required`
- `source_recovery_required`
- `local_fallback_entry`
- `prehome_partial_recovery`
- `ready_for_home_empty`

### Vue source

- taux de succes validation source
- taux d'echec validation source
- `reason_codes` principaux
- retries source

### Vue flags

- exposition par flag
- volume d'utilisateurs / runs affectes
- comparaison flag `off` vs `on`

## Traces minimales par run

Chaque run critique du tunnel doit pouvoir etre correle via:
- `journey_run_id`
- `user_session_kind`
- `surface`
- `stage`
- `reason_code`
- `result`
- `flag_set`
- `execution_mode`
- `continuity_mode`
- `source_state`

## Events minimaux obligatoires

Le socle vague 0 exige que le plan de suivi couvre:
- `entry_journey_started`
- `entry_journey_stage_entered`
- `entry_journey_stage_completed`
- `entry_journey_stage_slow`
- `entry_journey_stage_blocked`
- `entry_journey_safe_state_reached`
- `session_resolved`
- `source_validation_completed`
- `catalog_minimal_ready`
- `catalog_full_load_started`
- `catalog_full_load_completed`
- `entry_journey_completed`

## Scenarios a rendre observables des la vague 1

- cold start connecte
- warm start connecte
- session expiree
- offline
- aucune source
- source invalide
- catalogue vide
- preload lent

## Regles de confidentialite et hygiene

Conformement au referentiel:
- pas de secret dans logs et traces
- pas de PII inutile en clair
- pas de token
- correlation utile mais minimisee
- fields d'observabilite limites au diagnostic utile

## Outillage minimal a preparer

Avant les vagues critiques, l'equipe doit savoir ou regarder:
- les logs structures
- les traces par `journey_run_id`
- les dashboards de latence et safe states
- les activations de flags
- les tests d'integration et E2E associes

Cette vague n'impose pas un vendor unique.
Elle impose un resultat minimum observable.

## Verdict

Le dashboard minimal est considere `pret` si un reviewer independant peut:
- suivre un run de bout en bout
- comprendre pourquoi il a termine ou echoue
- distinguer `catalog minimal` et `catalog full`
- confirmer quel flag et quel safe state ont ete utilises

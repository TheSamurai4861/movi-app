# Schema de synthese - Performance et resilience du tunnel

## Vue d'ensemble

La phase 4 fixe un tunnel d'entree avec:
- un pre-home borne
- des contrats critiques limites par timeout et retry
- des safe states explicites
- une instrumentation de bout en bout
- un catalogue complet charge majoritairement apres `Home`

## Schema logique

```text
App start
  -> preparing_system
    -> connectivity
    -> session
    -> profiles
    -> sources
    -> source_validation
    -> preloading_home_minimal
    -> ready_for_home
    -> Home
    -> post_home_enrichment
```

## Separation pre-home / post-home

### Pre-home obligatoire

- `startupReady`
- `networkAvailable` quand requis
- `sessionResolved`
- `profilesResolved`
- `selectedProfileResolved`
- `sourcesResolved`
- `selectedSourceResolved`
- `selectedSourceValid`
- `catalogue minimal exploitable`
- `libraryReady` minimal
- `homePreloaded` minimal

### Post-home autorise

- catalogue complet exhaustif
- enrichissements bibliotheque non critiques
- sync cloud de confort
- sections secondaires de `Home`
- telemetry de confort

## Budgets de reference

| Zone | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `preparing_system` | `<= 1200 ms` | `<= 2500 ms` | `> 2500 ms` |
| `session_resolve` | `<= 800 ms` | `<= 1800 ms` | `> 1800 ms` |
| `profiles_inventory` | `<= 500 ms` | `<= 1200 ms` | `> 1200 ms` |
| `sources_inventory` | `<= 700 ms` | `<= 1500 ms` | `> 1500 ms` |
| `source_validation` | `<= 1200 ms` | `<= 3000 ms` | `> 3000 ms` |
| `preloading_home` global | `<= 2500 ms` | `<= 5000 ms` | `> 5000 ms` |
| `time_to_safe_state` | `<= 2500 ms` | `<= 4500 ms` | `> 4500 ms` |

## Safe states critiques

| Cas critique | Safe state cible | Surface |
| --- | --- | --- |
| `offline` | `network_required_blocked` | `Preparation systeme` |
| `session invalide` | `auth_required_explicit` | `Auth` |
| `profil manquant` | `profile_selection_required` | `Choix profil` |
| `source manquante` | `source_selection_required` | `Choix / ajout source` |
| `source invalide` | `source_recovery_required` | `Choix / ajout source` |
| `cloud partiel mais local possible` | `local_fallback_entry` | surface suivante autorisee |
| `pre-home partiel mais minimum atteint` | `prehome_partial_recovery` | `Chargement medias` puis `Home` |
| `catalogue vide` | `ready_for_home_empty` | `Home` avec empty state |

## Politique de comportement

### Nominal

- viser la progression la plus directe vers `ready_for_home`
- ne pas garder d'attente invisible apres les seuils `slow`

### Degraded

- si une continuation sure existe, la preferer a un blocage silencieux
- rendre la degradation visible avant que l'utilisateur ne perde le contexte

### Recovery

- renvoyer vers la surface metier pertinente
- ne pas inventer de pages techniques intermediaires

## Instrumentation minimale

Les evenements critiques a toujours avoir en release:
- `entry_journey_started`
- `entry_journey_stage_entered`
- `entry_journey_stage_completed`
- `entry_journey_stage_slow`
- `entry_journey_stage_blocked`
- `session_resolved`
- `profiles_inventory_loaded`
- `sources_inventory_loaded`
- `source_validation_completed`
- `catalog_minimal_ready`
- `catalog_full_load_started`
- `catalog_full_load_completed`
- `entry_journey_safe_state_reached`
- `entry_journey_completed`

## Noyau mandatory avant release

- sortir le catalogue complet du pre-home
- borner `preloading_home`
- borner tous les contrats critiques
- rendre `offline`, `session invalide` et `source invalide` explicitement recuperables
- instrumenter toutes les transitions critiques
- rendre mesurable `time_to_safe_state`

## Conclusion

La cible de phase 4 est un tunnel:
- rapide par contrat
- robuste par safe states
- observable par design
- compatible avec un catalogue complet lent charge apres `Home`

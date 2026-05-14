# Etape 6.3 - Contrat d'evenements logs

## Cible

Definir un contrat stable et explicite pour les evenements critiques du tunnel
boot, avec un schema commun lisible et exploitable en debug/runtime.

## Evenements structurels retenus

| Event | Quand | Source d'emission |
| --- | --- | --- |
| `boot_state_changed` | transition de phase/status boot | `AppLaunchOrchestrator._logPhase` |
| `boot_action_triggered` | action utilisateur sur CTA boot/home partial | `executeBootAction` |
| `catalog_preparation_started` | debut preparation catalogue bloquante | `AppLaunchOrchestrator._logCatalogTransition` |
| `catalog_preparation_completed` | preparation catalogue terminee | `AppLaunchOrchestrator._logCatalogTransition` |
| `catalog_preparation_failed` | preparation catalogue en echec | `AppLaunchOrchestrator._logCatalogTransition` |
| `boot_recovery_shown` | ecran/etat recovery expose (source ou technique) | `AppLaunchOrchestrator` |
| `home_partial_shown` | banniere Home partielle activee | `AppLaunchOrchestrator._setHomeDegradationNotice` |
| `entry_journey_completed` | fin de run boot (safe state atteinte) | `AppLaunchOrchestrator.completeSuccess` |

## Schema minimal commun

Tous les evenements ci-dessus utilisent le meme noyau:

- `event` (nom de l'evenement)
- `run_id` (id unique du run)
- `phase` (phase courante, si disponible)
- `reason_code` (cause/raison metier, si disponible)
- `duration_ms` (latence, si disponible)
- `destination` (destination resolue, si disponible)
- `action` (action utilisateur ou systeme, si disponible)

Champs optionnels supplementaires possibles via `fields` (ex:
`status`, `step`, `catalog_mode`, `source_key`, `execution_kind`, `route`,
`reason_codes`).

## Implementation technique

- Nouveau logger contrat: `lib/src/core/startup/boot_event_contract_logger.dart`
  - enum `BootContractEvent` (noms stables)
  - serialisation en `key=value`
  - categorie log dediee: `startup_contract`
- Compatibilite preservee: les logs legacy (`startup`, `entry_journey`) restent
  actifs en parallele pendant la migration.

## Verification

- `flutter analyze` sur les fichiers startup touches
- tests cibles:
  - `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - `test/core/startup/boot_action_handler_test.dart`

Ces verifications valident l'absence de regression sur le flux boot existant
apres l'introduction du contrat.

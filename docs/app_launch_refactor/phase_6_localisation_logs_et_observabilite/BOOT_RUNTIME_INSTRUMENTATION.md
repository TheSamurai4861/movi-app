# Etape 6.4 - Instrumentation runtime

## Cible

Brancher l'emission des evenements du contrat sur les transitions critiques du
tunnel boot, avec prevention des doublons par run, sans casser les logs legacy.

## Instrumentation appliquee

- `lib/src/core/startup/app_launch_orchestrator.dart`
  - ajout d'un helper central `_emitContractEvent(...)` ;
  - ajout d'une cle de deduplication `_contractEventKey(...)` ;
  - ajout d'un cache runtime `_emittedContractEventKeys` vide au demarrage d'un
    run et au `reset()`.

## Transitions critiques couvrees

- `boot_state_changed`
  - emis a chaque transition de phase via `_logPhase`.
- `catalog_preparation_started|completed|failed`
  - emis depuis `_logCatalogTransition`.
- `boot_recovery_shown`
  - emis sur recovery auth (`setRecovery`),
  - emis sur recovery source (catalogue),
  - emis sur echec technique (`completeFailure`).
- `home_partial_shown`
  - emis lors de la publication d'une degradation Home.
- `entry_journey_completed`
  - emis a la fin d'un run successful.
- `boot_action_triggered`
  - deja emis dans `executeBootAction` (conserve).

## Anti-doublon

- Deduplication activee (`dedupe: true`) sur les evenements de transition
  structurelle.
- La cle de dedupe inclut:
  - `event`, `run_id`, `phase`, `reason_code`, `duration_ms`,
    `destination`, `action`, et les champs additionnels tries.
- La dedupe est scopee au run (cache purge sur `run()` et `reset()`).

## Compatibilite

- Les logs existants (`startup`, `entry_journey`) sont conserves tels quels.
- Le contrat runtime est emet en parallele dans la categorie
  `startup_contract`.

## Verification

- `flutter analyze` (fichiers startup modifies)
- `flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `flutter test test/core/startup/boot_action_handler_test.dart`

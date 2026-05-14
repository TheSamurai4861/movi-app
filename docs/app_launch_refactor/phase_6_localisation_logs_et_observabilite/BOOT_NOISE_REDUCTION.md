# Etape 6.5 - Reduction du bruit

## Cible

Reduire les rafales de logs hors diagnostic boot critique, sans perdre les
traces necessaires a la lecture complete d'un run startup.

## Reductions appliquees

- `home_hero_debug`
  - sampling/rate-limit par categorie ajoute dans la configuration logging.
  - en staging/prod, categorie relevee a `warn` (les traces info sont coupees).
- `image_pipeline`
  - sampling/rate-limit par categorie ajoute dans la configuration logging.
  - en staging/prod, categorie relevee a `warn`.
  - les erreurs/fallback init du cache passent explicitement en `warn` pour
    rester visibles meme avec filtrage.
- logs focus recherche
  - traces `[SearchFocus][debug]` desactivees par defaut.
  - activation explicite possible via `--dart-define=SEARCH_FOCUS_DEBUG=true`.

## Parametrage introduit

Fichier: `lib/src/core/config/config_module.dart`

- dev:
  - `samplingByCategory`: home hero/image pipeline.
  - `rateLimitPerCategory`: home hero/image pipeline/startup contract.
- staging:
  - idem + `minLevelByCategory` a `warn` pour home hero/image pipeline.
- prod:
  - idem, avec filtrage plus strict.

## Compatibilite et garde-fous

- Les categories critiques boot (`startup`, `entry_journey`, `startup_contract`)
  restent actives.
- Les evenements de contrat startup conservent un debit autorise superieur pour
  garder la lisibilite run-to-run.

## Validation

- `flutter analyze` sur fichiers modifies.
- tests cibles:
  - `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - `test/core/startup/boot_action_handler_test.dart`

# Etape 7.4 - Validation runtime multi-scenarios

## Cible

Verifier le comportement runtime du tunnel boot sur les scenarios critiques,
avec preuves executees et points de validation manuelle restants.

## Commandes executees

- `flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `flutter test test/core/startup/boot_critical_screens_widget_test.dart`
- `flutter test test/core/router/launch_redirect_guard_boot_alignment_test.dart`

## Matrice de scenarios

| Scenario | Attendu | Evidence | Resultat |
| --- | --- | --- | --- |
| Run sans snapshot | `catalog_preparing` visible, refresh bloquant puis Home | tests orchestrateur locaux: cas `catalog_preparation_started/completed`, `complete preload done -> home` | Valide |
| Run avec snapshot | Home rapide sans refresh bloquant | tests orchestrateur locaux: cas snapshot exploitable + no extra blocking refresh | Valide |
| Run source timeout | ecran source timeout + action retry/change source | tests orchestrateur locaux: `catalog_sync_timeout` + tests widget recovery timeout | Valide |
| Run credentials invalides | ecran credentials invalides + action reconnect source | tests orchestrateur locaux: `catalog_credentials_invalid` + tests widget recovery credentials | Valide |
| Run catalogue vide | ecran catalogue vide + actions resync/choose source | tests widget critiques: cas `catalogue vide` + mapper recovery | Valide |
| Run Home partiel | Home accessible + banniere compacte + action ciblee | tests widget `home_error_banner` + guard alignment (`keeps Home partial on Home`) | Valide |
| Run Windows (desktop vs TV) | qualification surface + focus clavier | non automatisable de bout en bout via tests headless | A confirmer manuellement |

## Extraits de preuve (logs/tests)

- `catalog recovery required -> catalog_sync_timeout`
- `catalog recovery required -> catalog_credentials_invalid`
- `home preload done`
- `complete preload done -> home`
- `keeps Home partial on Home instead of redirecting to source recovery`

## Limites

- La qualification explicite Windows TV vs desktop reste manuelle.
- Les tests automatises couvrent les transitions et rendus critiques, mais pas
  l'observation interactive complete sur machine physique.

## Decision

- Validation runtime 7.4 acceptable pour la progression phase 7.
- Conserver un point de verification manuelle Windows dans la synthese 7.5.

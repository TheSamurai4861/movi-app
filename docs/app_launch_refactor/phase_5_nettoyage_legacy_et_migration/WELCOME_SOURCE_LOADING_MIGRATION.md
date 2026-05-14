# Etape 5.3 - WelcomeSourceLoadingPage

## Decision

`WelcomeSourceLoadingPage` ne porte plus la logique catalogue critique.

La page est reduite a un **bridge de transition**:

- affiche une surface minimale (`OverlaySplash`) ;
- relance le tunnel boot unifie via `/launch` ;
- garde un fallback utilisateur (`Réessayer`) ;
- conserve la route `/welcome/sources/loading` pour compatibilite temporaire.

## Avant / apres

### Avant

- page etatful volumineuse ;
- lecture/normalisation source selectionnee ;
- refresh Xtream/Stalker ;
- verification catalog ready ;
- prechargement Home + library via
  `completeManualSourceLoadingToHome(...)`.

### Apres

- plus de refresh source/catalgue dans le widget ;
- plus de prechargement Home depuis cette page ;
- handoff unique vers `AppRouteNames.launch` (orchestrateur source de verite).

## Raisons

- supprimer la duplication orchestrateur/UI ;
- eviter une deuxieme implementation du pipeline catalog/home ;
- preparer la suppression ou redirection complete de la route legacy en 5.4.

## Impacts connus

- `force_reload=1` reste accepté pour compatibilite de navigation, mais ne
  declenche plus de logique catalogue locale dans le widget ;
- les helpers purs de resolution/formatage sont conserves pour les tests
  existants et pourront etre deplaces/supprimes en nettoyage final.

## Fichiers touches

- `lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart`

## Verification

- `flutter analyze` sur la page et ses tests;
- `flutter test`:
  - `test/features/welcome/presentation/welcome_source_loading_page_test.dart`
  - `test/core/router/launch_redirect_guard_boot_alignment_test.dart`
  - `test/core/startup/boot_action_handler_test.dart`

Tous passent apres migration.

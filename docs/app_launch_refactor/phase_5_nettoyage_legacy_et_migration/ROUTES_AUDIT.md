# Etape 5.4 - Audit routes et navigation

## Regle appliquee

- Conserver les routes qui correspondent a une vraie page d'action.
- Rediriger les routes devenues legacy/pont vers le tunnel boot unifie.

## Tableau des routes (perimetre boot/welcome)

| Route | Statut 5.4 | Justification | Action |
| --- | --- | --- | --- |
| `/launch` (`AppRoutePaths.launch`) | **Conservee** | Entree canonique du tunnel boot. | Aucune. |
| `/bootstrap` | **Conservee** | Surface principale de rendu boot (`SplashBootstrapPage`). | Aucune. |
| `/welcome` | **Redirigee** | Route historique compat. | Redirection vers `/welcome/user` (deja en place). |
| `/welcome/user` | **Conservee** | Page d'action profile. | Aucune. |
| `/welcome/sources` | **Conservee** | Page d'action source. | Aucune. |
| `/welcome/sources/select` | **Conservee** | Page d'action choix source. | Aucune. |
| `/welcome/sources/loading` | **Redirigee** | N'est plus une destination boot finale ; widget reduit a bridge en 5.3. | Redirection explicite vers `/launch`. |

## Changements code effectues

- `app_routes.dart`
  - route `/welcome/sources/loading` redirigee vers `/launch`.
- `boot_action_handler.dart`
  - `BootActionIntent.resyncSource` route par defaut -> `/launch`
    (plus `/welcome/sources/loading`).
- `launch_redirect_guard.dart`
  - suppression de l'exception qui autorisait explicitement
    `/welcome/sources/loading` en succes.
- `route_catalog.dart`
  - retrait de `/welcome/sources/loading` des routes critiques.

## Non-regression navigation

Suites executees apres changement:

- `test/core/startup/boot_action_handler_test.dart`
- `test/core/router/launch_redirect_guard_boot_alignment_test.dart`
- `test/features/welcome/presentation/welcome_source_loading_page_test.dart`
- `test/core/startup/boot_screen_renderer_test.dart`

Toutes passent.

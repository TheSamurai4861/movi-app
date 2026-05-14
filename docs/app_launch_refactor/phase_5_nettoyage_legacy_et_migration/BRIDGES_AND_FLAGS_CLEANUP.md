# Etape 5.6 - Bridges, flags et dette technique

## Nettoyage applique

### Points d'entree legacy supprimes ou neutralises

- Le widget/page `WelcomeSourceLoadingPage` a ete retire du runtime.
- La route `/welcome/sources/loading` reste declaree **uniquement** comme
  redirection explicite vers `/launch` (compat URL).
- Le mapper de surface projetee (`TunnelSurfaceRouteMapper`) n'utilise plus
  `/welcome/sources/loading` comme surface canonique de chargement ; il renvoie
  `/bootstrap`.

### Redirections/actions alignees

- Les actions `resyncSource` ne pointent plus vers une page legacy :
  route planner par defaut -> `/launch`.
- Les boutons d'activation/selection source (`welcome_source_page`,
  `welcome_source_select_page`) n'envoient plus de `destinationOverride`
  `welcomeSourceLoading?force_reload=1`.

### Nettoyage de dette locale

- Suppression de `AppFocusRegionId.welcomeSourceLoadingPrimary` (region non
  referencee apres retrait de la page legacy).
- Extraction des helpers purs de resolution source dans
  `welcome_source_loading_resolution.dart` (conserves pour tests et reusabilite).

## Verification

- `flutter analyze` sur router/guard/welcome et tests ajustes.
- Tests executes:
  - `launch_redirect_guard_boot_alignment_test.dart`
  - `launch_redirect_guard_tunnel_surface_test.dart`
  - `new_user_auth_launch_flow_test.dart`
  - `welcome_source_loading_page_test.dart`

Tous passent.

## TODO explicites (report phase 6 / 7)

- **Phase 6 (localisation/logs)**
  - migrer les derniers messages statiques FR dans le mapper boot vers l10n.
  - harmoniser les logs de redirection startup (niveaux/structure).
- **Phase 7 (validation globale)**
  - etendre les scenarios E2E autour des redirections legacy -> `/launch`
    en environnement reel (deep links, retour background).

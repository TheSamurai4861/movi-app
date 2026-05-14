# Tests router et actions boot

## Couverture ajoutee ou confirmee

| test | scenario | entree runtime | action | destination attendue | assertion critique |
| --- | --- | --- | --- | --- | --- |
| `boot_action_handler_test.dart` | `retry` relance le tunnel | `BootActionIntent.retry` | `BootActionPlanner.plan` | `/launch` | kind `launchRun`, route `/launch`, run reason `boot_action_retry` |
| `boot_action_handler_test.dart` | actions pages metier | `login`, `createProfile`, `chooseProfile`, `addSource`, `reconnectSource`, `chooseSource` | `BootActionPlanner.plan` | `/auth/otp`, `/welcome/user`, `/welcome/sources`, `/welcome/sources/select` | chaque action produit une route stable |
| `boot_action_handler_test.dart` | actions source/Home deleguees | `resyncSource`, `retryHomeSections`, `retryLibrary` | `BootActionPlanner.plan` | `/welcome/sources/loading`, `/` | chaque action produit une commande controller et une route fallback |
| `boot_action_handler_test.dart` | ouverture Home | `openHome` | `BootActionPlanner.plan` | `/` | kind `navigation`, route Home |
| `boot_action_handler_test.dart` | export logs | `exportLogs` | `BootActionPlanner.plan` | aucune route | kind `diagnostic`, commande `exportLogs` |
| `boot_action_handler_test.dart` | exhaustivite actions | toutes les valeurs `BootActionIntent` | `BootActionPlanner.plan` | route ou commande selon intent | aucune action actionnable ne reste sans effet testable |
| `boot_action_handler_test.dart` | mapping recovery/action | toutes les valeurs `RecoveryAction` | `toBootActionIntent()` | intention boot cible | chaque action Phase 1 a une intention technique |
| `launch_redirect_guard_boot_alignment_test.dart` | route transitoire pendant run | `AppLaunchStatus.running`, phase `preloadCompleteHome`, route courante `/welcome/sources/loading` | `LaunchRedirectGuard.handle` | `/launch` | le guard renvoie vers la surface boot pendant un run actif |
| `launch_redirect_guard_boot_alignment_test.dart` | loading source legacy autorise | success + destination `chooseSource`, route courante `/welcome/sources/loading` | `LaunchRedirectGuard.handle` | `/welcome/sources/loading` | le fallback legacy reste accessible quand la destination source l'autorise |
| `launch_redirect_guard_boot_alignment_test.dart` | ouverture Home | success + destination `home` + criteria Home complete | `LaunchRedirectGuard.handle` | `/` | Home s'ouvre uniquement avec readiness complete |
| `launch_redirect_guard_boot_alignment_test.dart` | auth requise | success + destination `auth`, auth repo unauthenticated | `LaunchRedirectGuard.handle` | `/auth/otp` | Home est redirige vers auth |
| `launch_redirect_guard_boot_alignment_test.dart` | profil requis | success + destination `welcomeUser` | `LaunchRedirectGuard.handle` | `/welcome/user` | Home est redirige vers la page profil |
| `launch_redirect_guard_boot_alignment_test.dart` | source requise | success + destination `welcomeSources` | `LaunchRedirectGuard.handle` | `/welcome/sources` | Home est redirige vers la page source |
| `launch_redirect_guard_boot_alignment_test.dart` | selection source requise | success + destination `chooseSource` | `LaunchRedirectGuard.handle` | `/welcome/sources/select` | Home est redirige vers la selection source |
| `launch_redirect_guard_boot_alignment_test.dart` | Home partiel apres Home | success + destination `home` + criteria complete, route courante `/` | `LaunchRedirectGuard.handle` | `/` | Home partiel ne repart pas vers recovery source |
| `launch_redirect_guard_tunnel_surface_test.dart` | routing V2 auth | `TunnelStage.authRequired` + flags V2 actifs | `LaunchRedirectGuard.handle` | `/auth/otp` | projection V2 applique auth |
| `launch_redirect_guard_tunnel_surface_test.dart` | routing V2 Home pret | `TunnelStage.readyForHome` + route non startup | `LaunchRedirectGuard.handle` | route courante conservee | le guard ne chasse pas l'utilisateur d'une route non startup |
| `launch_redirect_guard_tunnel_surface_test.dart` | recovery auth interne | `TunnelStage.authRequired`, routes forgot/update password | `LaunchRedirectGuard.handle` | route auth recovery conservee | les pages auth internes restent accessibles |
| `launch_redirect_guard_tunnel_surface_test.dart` | routing V2 selection source | `TunnelStage.sourceRequired`, `legacyDestination=chooseSource` | `LaunchRedirectGuard.handle` | `/welcome/sources/select` | projection V2 applique selection source |
| `launch_redirect_guard_tunnel_surface_test.dart` | routing V2 loading source | `TunnelStage.preloadingHome`, route courante `/welcome/sources/loading` | `LaunchRedirectGuard.handle` | `/welcome/sources/loading` | le fallback loading reste stable pendant preloading |
| `boot_screen_mapper_test.dart` | etats non interactifs | idle, running, catalog loading, opening Home | `BootScreenMapper.fromLaunchState` | aucun focus/action | pas d'action focusable sur loading/opening |
| `boot_screen_mapper_test.dart` | etats interactifs | auth, profil, source, selection source, failure | `BootScreenMapper.fromLaunchState` | action principale + focus primaire | un ecran actionnable declare une action principale |
| `boot_screen_mapper_test.dart` | textes UI | etat selection source | `BootScreenMapper.fromLaunchState` | n/a | les textes visibles ne contiennent pas le reason code brut |
| `boot_screen_providers_test.dart` | provider projection UI | `AppLaunchState` override | `bootScreenModelProvider` | modele UI cible | provider sans effet de bord |

## Destinations critiques

| destination | couverture |
| --- | --- |
| `launch` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart` |
| `auth` / `/auth/otp` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart`, `launch_redirect_guard_tunnel_surface_test.dart` |
| `welcomeUser` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart` |
| `welcomeSources` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart` |
| `welcomeSourceSelect` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart`, `launch_redirect_guard_tunnel_surface_test.dart` |
| `welcomeSourceLoading` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart`, `launch_redirect_guard_tunnel_surface_test.dart` |
| `home` | `boot_action_handler_test.dart`, `launch_redirect_guard_boot_alignment_test.dart` |

## Limites restantes

- Les tests verrouillent les decisions router/actions et le modele UI, pas
  encore le rendu Figma final.
- Les actions `retryHomeSections` et `retryLibrary` restent mappees en contrat
  et fallback Home; le branchement controller reel sera a renforcer pendant le
  traitement Home partial.
- `WelcomeSourceLoadingPage` reste le fallback legacy catalogue jusqu'a la
  Phase 3.

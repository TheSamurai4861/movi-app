# Alignement LaunchRedirectGuard avec l'orchestrateur

## Decision

`LaunchRedirectGuard` doit appliquer les destinations du runtime sans recreer
les decisions metier.

Changement effectue :

```text
AppRouteCatalog.criticalRoutes inclut maintenant /welcome/sources/loading.
```

Raison :

- `/welcome/sources/loading` est une surface boot critique ;
- pendant `AppLaunchStatus.running` ou `idle`, elle doit revenir a `/launch`
  comme les autres routes boot ;
- quand une destination source l'autorise explicitement, le guard continue de
  la laisser ouverte via l'exception existante `allowsWelcomeSourceLoading`.

## Donnees lues par le guard

| donnee | source | usage |
| --- | --- | --- |
| `state.matchedLocation` | `GoRouterState` | Connaitre la route courante. |
| `state.uri.queryParameters` | `GoRouterState` | Laisser passer `auth?return_to=previous` et `force_reload` cote page. |
| `AuthRepository.currentSession` | Auth repository | Detecter auth resolue/stale auth destination. |
| `AuthRepository.onAuthStateChange` | Auth repository | Notifier le router apres changement auth. |
| `AppLaunchStateRegistry.state` | Orchestrateur legacy | Lire `status`, `destination`, `phase`, `criteria`, `recovery`. |
| `TunnelStateRegistry.state` | Projection V2 sous flags | Router via `TunnelSurfaceRouteMapper` quand V2 actif. |
| `AppRouteCatalog.criticalRoutes` | Catalogue router | Savoir quelles routes appartiennent au tunnel boot. |

Le guard ne lit pas les repositories profil/source/catalogue. Ces decisions
restent dans l'orchestrateur.

## Table runtime -> router

| etat runtime | destination cible | redirection guard | action utilisateur | fallback | test router |
| --- | --- | --- | --- | --- | --- |
| Auth non resolue | `/launch` | Routes non recovery auth -> `/launch`; `/launch` reste stable. | Aucune. | Timeout auth lit `currentSession`. | Couverture existante guard auth timeout/reconnect. |
| `AppLaunchStatus.idle` sur route boot critique | `/launch` | Route critique -> `/launch`. | Aucune. | `/launch` lance le runner legacy. | Tests existants launch flow. |
| `AppLaunchStatus.running` sur route boot critique | `/launch` | Route critique -> `/launch`, y compris `/welcome/sources/loading`. | Aucune. | `_LaunchGate`/renderer boot. | `redirects welcome source loading back to launch while orchestrator is running`. |
| `AppLaunchStatus.failure` sur route boot critique | `/bootstrap` | Route critique -> `/bootstrap`. | Retry/export logs via UI legacy ou futur handler. | `SplashBootstrapPage`/`LaunchErrorPanel`. | Tests existants failure/bootstrap. |
| `success + destination=auth` sans session | `/auth/otp` | Toute route concernee -> auth. | Login. | Auth recovery routes restent accessibles. | Tests existants auth redirect. |
| `success + destination=auth` avec session stale | `/launch` | Force relance via `/launch`. | Aucune. | Re-evaluation orchestrateur. | Test existant stale auth destination. |
| `success + destination=welcomeUser` | `/welcome/user` | Route boot/home -> page profil. | Creation/selection profil. | Page profil legacy. | Couverture a ajouter si changement futur. |
| `success + destination=welcomeSources` | `/welcome/sources` | Route boot/home -> page source. | Ajout/reconnexion source. | Page source legacy. | `redirects Home to source action page when recovery before Home is required`. |
| `success + destination=chooseSource` | `/welcome/sources/select` | Route boot/home -> selection source. | Selection source. | Page selection legacy. | Tests projected source selection + nouveau loading allowed. |
| `success + destination=welcomeSources/chooseSource` et route courante `/welcome/sources/loading` | `/welcome/sources/loading` autorisee temporairement | Pas de redirection pour conserver le fallback legacy de loading source. | Loading legacy ou futur `resyncSource`. | Exception `allowsWelcomeSourceLoading`. | `keeps welcome source loading reachable when source action destination allows it`. |
| `success + destination=home` + `criteria.isHomeReady=false` | `/bootstrap` | Route boot critique -> `/bootstrap`, avec log warning. | Aucune immediate. | Surface legacy Home non pret. | Test existant Home non pret. |
| `success + destination=home` + `criteria.isHomeReady=true` | `/` | Route boot critique -> Home. | Aucune. | Home partiel reste possible apres Home. | `opens Home when destination is home and readiness criteria are complete`. |
| Home partiel apres Home | `/` | Reste Home si destination Home et readiness complete. | Retry Home/library/source depuis notice Home. | Notice Home legacy/future. | `keeps Home partial on Home instead of redirecting to source recovery`. |
| Auth recovery routes | Route recovery auth | Pas de redirection. | Reset password/update password. | Pages auth existantes. | Tests existants auth recovery deep link. |
| Projected routing V2 | Surface route mappee | `TunnelSurfaceRouteMapper` applique la route si route critique. | Selon surface. | Flags V2 off par defaut. | Tests existants `launch_redirect_guard_tunnel_surface_test.dart`. |

## Non-redirections confirmees

| cas | decision |
| --- | --- |
| Route debug en `kDebugMode` | Le guard laisse passer. |
| Auth recovery routes | Le guard laisse passer quelle que soit la surface auth. |
| `/auth/otp?return_to=previous` | Le guard laisse passer pour les reconnects depuis settings/welcome. |
| Route non startup pendant projected ready Home | Le guard laisse passer, ex. player/deep link. |
| `/welcome/sources/loading` autorise par destination source legacy | Le guard laisse passer pour ne pas casser le fallback legacy. |

## Points volontairement non modifies

- Le guard ne branche pas encore `BootScreenModel`.
- Le guard ne remplace pas encore les navigations directes des widgets.
- Le guard ne lance pas de refresh catalogue.
- Le guard conserve `/bootstrap` comme fallback legacy tant que Phase 4/5 n'a
  pas remplace les surfaces UI.

## Definition de fini - etape 5

- Le guard applique les destinations boot sans lire repositories metier.
- `/welcome/sources/loading` est classee comme route boot critique.
- Les cas Home partiel restent sur Home.
- Les recoveries source avant Home redirigent vers les pages d'action source.
- Les pages auth/profil/source restent les surfaces de collecte utilisateur.

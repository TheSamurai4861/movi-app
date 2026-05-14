# Cartographie du routage boot

## Synthese

Le routage boot est controle par trois couches :

- `GoRouter` declare les routes dans `app_routes.dart`.
- `LaunchRedirectGuard` decide les redirections globales selon auth,
  `AppLaunchState`, `BootstrapDestination` ou `TunnelState`.
- Certains widgets welcome/auth/settings effectuent encore des navigations
  directes pour relancer le boot, revenir a une etape ou continuer le parcours.

Le chemin nominal actuel est :

```text
/launch
  -> _LaunchGate
  -> AppLaunchOrchestrator.run()
  -> LaunchRedirectGuard
  -> /auth/otp | /welcome/user | /welcome/sources | /welcome/sources/select | /bootstrap | /
```

`/bootstrap` reste une route importante meme si elle n'est pas une destination
metier de `BootstrapDestination`. Elle affiche `SplashBootstrapPage` et sert de
surface legacy pendant la preparation de Home ou en cas d'echec de lancement.

## Routes boot

| route | widget | declencheur | condition d'entree | condition de sortie | source de decision |
| --- | --- | --- | --- | --- | --- |
| `/launch` | `_LaunchGate` | Route initiale du `GoRouter` par defaut, ou navigation directe vers `AppRouteNames.launch`. | `GoRouter.initialLocation` vaut `AppRoutePaths.launch`, sauf override `MOVI_INITIAL_ROUTE`. Le guard y renvoie aussi quand `AppLaunchState` est `idle` ou `running` sur une route critique. | `_LaunchGate.initState()` lance `appLaunchRunnerProvider('startup')`. Le guard redirige ensuite selon `AppLaunchState` ou `TunnelState`. | Router + `_LaunchGate` + `AppLaunchOrchestrator`. |
| `/auth/otp` | `AuthPasswordPage` ou `AuthOtpPage` selon query `mode=otp`. | `LaunchRedirectGuard` mappe `BootstrapDestination.auth` vers cette route. Les pages auth peuvent aussi y revenir directement. | Auth non resolue ou auth requise. La route auth recovery reste accessible. `return_to=previous` court-circuite certains redirects. | Apres succes auth, `AuthPasswordPage` / `AuthOtpPage` naviguent vers `/launch`, sauf mode `return_to=previous`. | Orchestrateur pour la destination, guard pour la redirection, pages auth pour la sortie locale. |
| `/welcome/user` | `WelcomeUserPage` | `LaunchRedirectGuard` mappe `BootstrapDestination.welcomeUser` vers cette route. `/welcome` redirige aussi vers `/welcome/user`. | Profil requis ou selection profil requise selon l'etat de lancement. | Actions internes pouvant reset l'orchestrateur puis aller vers `/launch` ou `/bootstrap`. Certains flows ouvrent auth avec `return_to=previous`. | Orchestrateur pour l'entree, widget pour certaines sorties. |
| `/welcome/sources` | `WelcomeSourcePage` | `LaunchRedirectGuard` mappe `BootstrapDestination.welcomeSources` vers cette route. `WelcomeSourceSelectPage` peut y envoyer pour ajouter une source. | Source requise, ajout/reconnexion source, ou retour depuis selection source. | En activation source reussie, navigation nommee vers `/welcome/sources/loading?force_reload=1`. Back local vers `/welcome/user` si on est dans le welcome flow, sinon vers settings IPTV. | Orchestrateur/guard pour l'entree, widget pour activation et back. |
| `/welcome/sources/select` | `WelcomeSourceSelectPage` | `LaunchRedirectGuard` mappe `BootstrapDestination.chooseSource` vers cette route. `WelcomeSourceLoadingPage` peut y envoyer si plusieurs sources et selection invalide. | Plusieurs sources existent ou selection active invalide/manquante. | Selection d'une source puis navigation nommee vers `/welcome/sources/loading?force_reload=1`. Action ajouter source vers `/welcome/sources`. Retry recovery reset puis `/launch`. | Orchestrateur/guard pour l'entree, widget pour selection et retry. |
| `/welcome/sources/loading` | `WelcomeSourceLoadingPage` | `WelcomeSourcePage` et `WelcomeSourceSelectPage` y naviguent apres activation/selection source. `LaunchRedirectGuard` l'autorise specialement quand la destination est `welcomeSources` ou `chooseSource`. | Source selectionnee ou force reload apres ajout/selection. Query `force_reload=1` force le refresh catalogue. | Succes : `completeManualSourceLoadingToHome()` puis navigation directe vers `/`. Erreur : retry local ou choix source. Back : `/welcome/sources` ou `/welcome/sources/select`. | Widget principalement. Orchestrateur est notifie a la fin via `completeManualSourceLoadingToHome`. |
| `/bootstrap` | `SplashBootstrapPage` | `LaunchRedirectGuard` y renvoie apres `/launch` legacy, en cas d'echec `AppLaunchStatus.failure`, ou si destination `home` sans criteres Home ready. Des pages welcome/settings y renvoient aussi apres reset. | Preparation Home ou surface legacy de failure. | Si `launchState.error == null`, affiche `OverlaySplash`. Si erreur, affiche `LaunchErrorPanel`. Retry reset puis `appLaunchRunnerProvider('retry')`. Le guard sort vers destination finale quand `AppLaunchState.success`. | Guard + `SplashBootstrapPage` + orchestrateur. |
| `/` | `AuthGate(child: AppShellPage())` | `LaunchRedirectGuard` mappe `BootstrapDestination.home` vers cette route. `WelcomeSourceLoadingPage` y navigue directement apres chargement manuel. | `AppLaunchState.success` avec destination `home` et criteres `isHomeReady`, ou navigation directe apres `completeManualSourceLoadingToHome`. | Logout/reset depuis Shell peut reset l'orchestrateur et aller vers `/launch`. `AuthGate` protege encore la surface Home. | Orchestrateur/guard pour entree normale, widget source loading pour continuation manuelle. |

## Mapping destination -> route

Mapping legacy dans `LaunchRedirectGuard._mapDestination` :

| `BootstrapDestination` | route |
| --- | --- |
| `auth` | `/auth/otp` |
| `welcomeUser` | `/welcome/user` |
| `welcomeSources` | `/welcome/sources` |
| `chooseSource` | `/welcome/sources/select` |
| `home` | `/` |

Mapping depuis `EntryDecision` dans `AppLaunchOrchestrator` :

| `EntryDecision` | `BootstrapDestination` |
| --- | --- |
| `RequireAuth` | `auth` |
| `RequireProfile` | `welcomeUser` |
| `RequireSource` | `welcomeSources` |
| `RequireSourceSelection` | `chooseSource` |
| `OpenHome` | `home` |
| `TechnicalBootFailure` | `auth` |

Mapping routing V2 projete dans `TunnelSurfaceRouteMapper` :

| `TunnelSurface` | route |
| --- | --- |
| `preparingSystem` | `/launch` ou `/bootstrap` si `reasonCode == launch_failure` |
| `auth` | `/auth/otp` |
| `createProfile` | `/welcome/user` |
| `chooseProfile` | `/welcome/user` |
| `chooseSource` | `/welcome/sources` ou `/welcome/sources/select` selon `legacyDestination` |
| `loadingMedia` | `/welcome/sources/loading` dans les flows source, sinon `/bootstrap` |
| `home` | `/` |

## Guard global

`LaunchRedirectGuard` est branche comme `GoRouter.redirect` et
`refreshListenable`.

### Mode legacy

Le mode legacy est actif quand `enableEntryJourneyStateModelV2` ou
`enableEntryJourneyRoutingV2` est false.

Regles observees :

- Auth non resolue : rester sur `/launch` ou route auth recovery, sinon
  rediriger vers `/launch`.
- `return_to=previous` sur `/auth/otp` : pas de redirection.
- Routes auth recovery : pas de redirection.
- `AppLaunchStatus.running` sur route critique : rester sur `/launch` ou y
  retourner.
- `AppLaunchStatus.idle` sur route critique : rester sur `/launch` ou y
  retourner.
- `AppLaunchStatus.failure` sur route critique : rester sur `/bootstrap` ou y
  retourner.
- `AppLaunchStatus.success` : mapper `destination` vers la route cible.
- Destination `home` sans `criteria.isHomeReady` : rester sur `/bootstrap` ou y
  retourner.
- Apres `/launch`, si aucune autre regle ne s'applique, redirection vers
  `/bootstrap`.

### Mode projected routing

Le mode projete est actif uniquement si :

```text
enableEntryJourneyStateModelV2 == true
enableEntryJourneyRoutingV2 == true
```

Dans ce mode, le guard utilise `TunnelStateRegistry`, `TunnelSurfaceMapper` et
`TunnelSurfaceRouteMapper`.

## Routes critiques

`AppRouteCatalog.criticalRoutes` contient actuellement :

```text
/launch
/auth/otp
/bootstrap
/welcome/user
/welcome/sources
/welcome/sources/select
/
```

Observation : `/welcome/sources/loading` n'est pas dans `criticalRoutes`, mais
le guard contient une exception dediee via `onWelcomeSourceLoading`. Cette route
est donc bien dans le boot, mais traitee a part.

## Navigations directes observees

| fichier | navigation | role |
| --- | --- | --- |
| `AuthPasswordPage` | `context.go(AppRoutePaths.launch)` | Retour au tunnel apres succes auth, sauf `return_to=previous`. |
| `AuthOtpPage` | `context.go(AppRoutePaths.launch)` | Retour au tunnel apres succes auth, sauf `return_to=previous`. |
| `AuthPasswordPage` | `context.push(AppRoutePaths.authForgotPassword)` | Sous-flow auth, pas une destination boot principale. |
| `AuthOtpPage` / `AuthPasswordPage` | `context.pushReplacement(_authLocation(...))` | Bascule locale OTP/password sur la route auth. |
| `WelcomeUserPage` | `context.push('${AppRoutePaths.authOtp}?return_to=previous')` | Auth ponctuelle depuis le flow profil. |
| `WelcomeUserPage` | reset orchestrateur puis `context.go(AppRouteNames.launch)` | Relance du tunnel depuis une action recovery/profil. |
| `WelcomeUserPage` | reset orchestrateur puis `context.go/router.go(AppRouteNames.bootstrap)` | Retour legacy vers bootstrap apres certaines actions profil. |
| `WelcomeSourcePage` | `GoRouter.of(context).goNamed(AppRouteIds.welcomeSourceLoading, force_reload=1)` | Apres activation source, lancement du chargement catalogue. |
| `WelcomeSourcePage` | back vers `/welcome/user` ou settings IPTV | Retour selon contexte welcome ou settings. |
| `WelcomeSourcePage` | reset orchestrateur puis `context.go(AppRouteNames.launch)` | Retry recovery source. |
| `WelcomeSourceSelectPage` | reset orchestrateur puis `context.go(AppRouteNames.launch)` | Retry recovery depuis selection source. |
| `WelcomeSourceSelectPage` | `context.go(AppRouteNames.welcomeSources)` | Ajouter une source depuis la selection. |
| `WelcomeSourceSelectPage` | `context.goNamed(AppRouteIds.welcomeSourceLoading, force_reload=1)` | Apres selection source, lancement du chargement catalogue. |
| `WelcomeSourceLoadingPage` | `context.go(AppRouteNames.home)` | Sortie directe vers Home apres `completeManualSourceLoadingToHome`. |
| `WelcomeSourceLoadingPage` | back vers `/welcome/sources` ou `/welcome/sources/select` | Retour local pendant erreur ou back key. |
| `WelcomeSourceLoadingPage` | `context.go(AppRouteNames.welcomeSourceSelect)` | Selection requise apres refresh/selection invalide, ou action secondaire. |
| `AppShellPage` | reset orchestrateur puis `context.go(AppRouteNames.launch)` | Retour au tunnel depuis le shell, notamment reset/logout ou changement majeur. |
| `IptvConnectPage` | reset orchestrateur puis `context.go(AppRouteNames.bootstrap)` | Reconnexion source depuis settings vers pipeline strict bootstrap. |
| `IptvSourceAddPage` | reset orchestrateur puis `context.go(AppRouteNames.bootstrap)` | Ajout source depuis settings vers pipeline strict bootstrap. |

## Decisions router vs orchestrateur

| decision | couche responsable actuelle | notes |
| --- | --- | --- |
| Route initiale | Router | `MOVI_INITIAL_ROUTE` peut bypasser `/launch`. |
| Lancer le tunnel applicatif | `_LaunchGate` | Le widget declenche `appLaunchRunnerProvider('startup')`. |
| Determiner destination metier | `AppLaunchOrchestrator` | Produit `BootstrapDestination` dans `AppLaunchState`. |
| Appliquer destination metier | `LaunchRedirectGuard` | Mappe destination vers route. |
| Bloquer Home si criteres incomplets | `LaunchRedirectGuard` | Redirige vers `/bootstrap` si destination Home sans `isHomeReady`. |
| Charger manuellement catalogue apres ajout/selection source | `WelcomeSourceLoadingPage` | Le widget contient encore de la logique metier et navigue lui-meme vers Home. |
| Relancer apres auth | Pages auth | Naviguent vers `/launch`. |
| Relancer apres certaines actions source/profil/settings | Widgets | Reset orchestrateur puis navigation directe vers `/launch` ou `/bootstrap`. |

## Points d'attention pour le refactor

- `/bootstrap` est une surface legacy centrale et doit etre traitee dans le
  nettoyage, meme si elle n'est pas une destination metier.
- `/welcome/sources/loading` n'est pas dans `criticalRoutes`, mais elle fait
  partie du boot catalogue.
- Plusieurs widgets font encore des `context.go(...)` directs vers des routes
  boot. Ces sorties devront etre alignees avec un handler d'action boot.
- Le routage V2 existe mais est desactive dans les environnements actuels.
- `AppRouteNames` est une compat historique de paths ; les nouveaux ajouts
  devraient preferer `AppRoutePaths` pour les URLs et `AppRouteIds` pour
  `goNamed`.

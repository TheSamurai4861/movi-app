# Relecture cible du routage actuel

## Synthese

Le routage boot actuel est partage entre trois couches :

- `AppLaunchOrchestrator`, qui produit une `BootstrapDestination` dans
  `AppLaunchState`.
- `LaunchRedirectGuard`, qui applique cette destination au `GoRouter` en mode
  legacy, ou projette `TunnelState` vers une route si les flags V2 sont actifs.
- Des widgets welcome/auth/settings, qui effectuent encore des navigations
  directes pour retry, retour, source loading et sortie vers Home.

La source cible reste celle definie en Phase 2 :

- l'orchestrateur decide les transitions boot ;
- le router applique la destination ;
- les pages d'action collectent les donnees utilisateur ;
- les widgets ne doivent plus prendre une decision boot finale.

## Fichiers relus

| fichier | role observe |
| --- | --- |
| `lib/src/core/router/app_routes.dart` | Declare les routes boot, les widgets associes et `_LaunchGate`. |
| `lib/src/core/router/app_router.dart` | Cree `GoRouter`, branche `LaunchRedirectGuard` en `redirect` et `refreshListenable`. |
| `lib/src/core/router/launch_redirect_guard.dart` | Applique les destinations legacy ou les surfaces `TunnelState` projetees. |
| `lib/src/core/router/route_catalog.dart` | Liste les routes critiques du boot. |
| `lib/src/core/router/tunnel_surface.dart` | Mappe `TunnelState` vers les routes en mode projected routing. |
| `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart` | Expose `appLaunchOrchestratorProvider`, `appLaunchStateProvider` et `appLaunchRunnerProvider`. |
| `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` | Contient creation/selection profil, auto-push auth et navigations retry/bootstrap. |
| `lib/src/features/welcome/presentation/pages/welcome_source_page.dart` | Contient ajout source, retry recovery, back fallback et navigation vers loading. |
| `lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart` | Contient selection source, retry recovery, back fallback et navigation vers loading. |
| `lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart` | Contient refresh catalogue, erreurs source, retour source/select et navigation Home. |

## Table des routes boot

| route | source de decision actuelle | source cible | guard | widget | risque |
| --- | --- | --- | --- | --- | --- |
| `/launch` (`launch`) | Router initial + `_LaunchGate` declenche `appLaunchRunnerProvider('startup')`; guard renvoie vers `/launch` quand auth non resolue, status `idle` ou `running`. | Route d'attente appliquee par le router; l'orchestrateur reste source du run et de la destination. | Autorise `/launch` pendant attente auth et status `idle/running`; apres lancement, peut rediriger vers `/bootstrap` ou destination finale. | `_LaunchGate` affiche `OverlaySplash` et lance `AppLaunchOrchestrator.run()`. Plusieurs pages font `reset()` puis `go('/launch')` pour retry. | Le declenchement du run est couple a un widget; les retry disperses peuvent produire des runs concurrents ou heterogenes. |
| `/auth/otp` (`auth`) | `LaunchRedirectGuard` mappe `BootstrapDestination.auth` et `TunnelSurface.auth`; `WelcomeUserPage` peut aussi pousser l'auth en priorite si Supabase est unauthenticated. | Orchestrateur decide `auth_required`; router applique `/auth/otp`; pages auth gardent login/signup/reset. | Si route auth ouverte manuellement, laisse passer si non authentifie; redirige vers `/bootstrap` si deja authentifie, sauf `return_to=previous`. | `WelcomeUserPage` push `${authOtp}?return_to=previous`; `AuthPasswordPage` et `AuthOtpPage` naviguent vers `/launch` apres succes. | Deux chemins coexistent : decision boot par guard et ouverture auth opportuniste depuis widget. Le retour post-auth est encore widget-driven. |
| `/welcome/user` (`welcomeUser`) | `LaunchRedirectGuard` mappe `BootstrapDestination.welcomeUser`; projected routing y envoie `profileRequired`. | Orchestrateur decide profil requis ou selection profil; router applique `/welcome/user`; page gere creation/selection profil. | Redirige vers cette route quand destination legacy `welcomeUser` ou surface projected `createProfile/chooseProfile`. | `WelcomeUserPage` cree/selectionne le profil puis `reset()` et `go('/bootstrap')`; retry recovery fait `reset()` puis `go('/launch')`. | La page collecte bien le profil, mais decide encore le retour dans le tunnel via `/bootstrap` ou `/launch`. |
| `/welcome/sources` (`welcomeSources`) | `LaunchRedirectGuard` mappe `BootstrapDestination.welcomeSources`; projected routing y envoie `sourceRequired` hors `chooseSource`. | Orchestrateur decide source requise; router applique `/welcome/sources`; page gere ajout/reconnexion source. | Redirige vers cette route quand destination legacy `welcomeSources` ou surface projected `chooseSource` sans `chooseSource` legacy. | `WelcomeSourcePage` back fallback vers `/welcome/user` ou settings; activation source navigue vers `/welcome/sources/loading`; retry recovery va `/launch`. `WelcomeSourceSelectPage` peut y envoyer pour ajouter une source. | La page contient encore une decision de transition vers loading apres activation, au lieu d'une action boot centralisee. |
| `/welcome/sources/select` (`welcomeSourceSelect`) | `LaunchRedirectGuard` mappe `BootstrapDestination.chooseSource`; projected routing y envoie `chooseSource` quand legacy destination est `chooseSource`. | Orchestrateur decide selection source; router applique `/welcome/sources/select`; page choisit une source et notifie le tunnel. | Redirige vers cette route quand destination legacy `chooseSource`. | `WelcomeSourceSelectPage` choisit une source, met a jour prefs/app state, push preferences puis `goNamed(welcomeSourceLoading, force_reload=1)`; retry va `/launch`. | Selection et transition catalogue sont encore embarquees dans la page; risque de divergence avec l'orchestrateur. |
| `/welcome/sources/loading` (`welcomeSourceLoading`) | Route declaree, mais absente de `AppRouteCatalog.criticalRoutes`; guard autorise un cas special si destination success vaut `welcomeSources` ou `chooseSource`. Projected routing y envoie `loadingMedia` selon contexte. | Destination transitoire ou renderer `catalog_preparing` applique par router/handler, pas refresh catalogue proprietaire du widget. | Exception dediee `allowsWelcomeSourceLoading`; en mode projected, `TunnelSurface.loadingMedia` peut retourner cette route. | `WelcomeSourcePage` et `WelcomeSourceSelectPage` y naviguent avec `force_reload=1`; `WelcomeSourceLoadingPage` fait resolution source, refresh Xtream/Stalker, erreurs, retry, select source et `go('/')`. | C'est le plus gros doublon : logique catalogue critique + navigation Home dans le widget; omission des `criticalRoutes` peut masquer certains cas router. |
| `/` (`home`) | `LaunchRedirectGuard` mappe `BootstrapDestination.home` si `criteria.isHomeReady`; sinon redirige vers `/bootstrap`. Des widgets non boot peuvent aussi aller Home. | Orchestrateur decide `home_ready` ou Home partiel; router applique `/`; widgets boot ne doivent pas contourner cette decision. | Autorise Home seulement si destination `home` et criteria prets; logge et renvoie `/bootstrap` si destination Home sans readiness. | `WelcomeSourceLoadingPage._goToHome()` selectionne l'onglet Home puis `go('/')`; `welcome_form.dart` navigue Home; autres navigations Home hors boot existent. | La sortie Home depuis loading contourne partiellement le guard/orchestrateur et peut ouvrir Home avec une readiness differente du contrat cible. |

## Route legacy critique hors liste utilisateur

| route | source de decision actuelle | source cible | guard | widget | risque |
| --- | --- | --- | --- | --- | --- |
| `/bootstrap` (`bootstrap`) | Surface legacy du boot. Guard y redirige apres `/launch`, en cas failure, et si destination Home n'a pas les criteres readiness. Plusieurs widgets y retournent apres action. | Fallback legacy temporaire ou renderer boot; ne doit pas rester une deuxieme source de decision. | Autorise `/bootstrap` pendant failure ou Home non pret; laisse passer si deja dessus. | `SplashBootstrapPage` lit l'orchestrateur; `WelcomeUserPage`, settings/source pages peuvent y naviguer. | Risque de conserver deux surfaces concurrentes `/launch` et `/bootstrap` pour le meme etat boot. |

## Redirections decidees par le guard

| signal | redirection actuelle |
| --- | --- |
| Auth non resolue | Toute route non `/launch` et non recovery auth retourne vers `/launch`. |
| `AppLaunchStatus.idle` ou `running` sur route critique | Reste ou retourne vers `/launch`. |
| `AppLaunchStatus.failure` sur route critique | Reste ou retourne vers `/bootstrap`. |
| `AppLaunchStatus.success` + destination non Home | Mappe `auth`, `welcomeUser`, `welcomeSources`, `chooseSource` vers leur route. |
| Destination Home sans `criteria.isHomeReady` | Reste ou retourne vers `/bootstrap` avec log warning. |
| Destination Home prete | Mappe vers `/`. |
| Auth route avec `return_to=previous` | Laisse passer sans redirection. |
| Auth recovery routes | Laisse passer depuis tout etat auth. |
| Flags `enableEntryJourneyStateModelV2` + `enableEntryJourneyRoutingV2` | Utilise `TunnelStateRegistry` et `TunnelSurfaceRouteMapper`. |

## Navigations directes encore decidees par les widgets

| widget | navigation | classification Phase 2 |
| --- | --- | --- |
| `_LaunchGate` | Lance `appLaunchRunnerProvider('startup')`. | A isoler derriere le contrat de boot ou conserver comme runner minimal documente. |
| `WelcomeUserPage` | Auto-push `/auth/otp?return_to=previous`. | A clarifier : auth opportuniste ou decision boot `auth_required`. |
| `WelcomeUserPage` | Apres profil, `reset()` puis `go('/bootstrap')`. | Decision boot a centraliser. |
| `WelcomeUserPage` | Recovery retry `reset()` puis `go('/launch')`. | Action `retry` a centraliser. |
| `WelcomeSourcePage` | Back fallback vers `/welcome/user` ou settings. | Navigation locale a conserver si hors decision boot finale. |
| `WelcomeSourcePage` | Apres activation source, `goNamed(welcomeSourceLoading, force_reload=1)`. | Decision boot/source loading a centraliser. |
| `WelcomeSourcePage` | Recovery retry `reset()` puis `go('/launch')`. | Action `retry` a centraliser. |
| `WelcomeSourceSelectPage` | Back fallback vers `/welcome/sources` ou settings. | Navigation locale a conserver si hors decision boot finale. |
| `WelcomeSourceSelectPage` | Selection source puis `goNamed(welcomeSourceLoading, force_reload=1)`. | Decision boot/catalogue a centraliser. |
| `WelcomeSourceSelectPage` | Recovery retry `reset()` puis `go('/launch')`. | Action `retry` a centraliser. |
| `WelcomeSourceLoadingPage` | Back vers `/welcome/sources` ou `/welcome/sources/select`. | Peut rester une action locale tant que loading legacy existe. |
| `WelcomeSourceLoadingPage` | Erreur source -> action select source. | A convertir en action `chooseSource`. |
| `WelcomeSourceLoadingPage` | Success catalogue -> `completeManualSourceLoadingToHome()` puis `go('/')`. | Decision Home a centraliser. |
| `AuthPasswordPage` / `AuthOtpPage` | Succes auth -> `go('/launch')`. | Retour boot a centraliser ou encapsuler comme action auth success. |

## Routes a garder accessibles directement

| route | justification |
| --- | --- |
| `/launch` | Route initiale et fallback de lancement tant que `_LaunchGate` existe. |
| `/auth/otp` | Page auth accessible directement, y compris `return_to=previous` et recovery auth. |
| `/auth/forgot-password` | Recovery auth explicitement autorisee par le guard. |
| `/auth/update-password` | Deep link recovery auth explicitement autorise par le guard. |
| `/welcome/user` | Page d'action profil, doit rester atteignable comme destination router. |
| `/welcome/sources` | Page d'action ajout/reconnexion source, doit rester atteignable comme destination router. |
| `/welcome/sources/select` | Page d'action selection source, doit rester atteignable comme destination router. |
| `/` | Destination Home normale et deep link racine. |

## Routes a devenir des destinations appliquees par le router

| route | decision cible |
| --- | --- |
| `/welcome/sources/loading` | Ne doit plus etre une transition decidee par les widgets apres ajout/selection source; doit representer `catalog_preparing` ou rester fallback legacy controle. |
| `/bootstrap` | Doit devenir fallback/renderer boot temporaire, pas une destination metier dispersee. |
| `/launch` depuis retry | Le retry doit passer par `BootActionHandler.retry`, puis le router applique la route utile. |
| `/` depuis `WelcomeSourceLoadingPage` | Home doit etre applique par le guard apres destination `home_ready`, pas par le widget loading. |

## Risques principaux pour les etapes suivantes

| risque | impact | mitigation Phase 2 |
| --- | --- | --- |
| `/welcome/sources/loading` absent de `criticalRoutes` | Le guard ne le traite pas comme route critique generale et depend d'exceptions. | Revoir son statut quand `catalog_preparing` est introduit. |
| Deux surfaces `/launch` et `/bootstrap` | Ambiguite sur le premier ecran boot et sur les retries. | Decider en Etape 2 quelle surface reste canonique. |
| Refresh catalogue dans `WelcomeSourceLoadingPage` | Doublon avec `AppLaunchOrchestrator`; erreurs et readiness peuvent diverger. | Extraire en Phase 3 ou router via action boot avant remplacement UI. |
| Navigation Home directe depuis loading | Risque de contourner `criteria.isHomeReady`. | Remplacer par action/etat orchestrateur puis guard. |
| Auth opportuniste depuis `WelcomeUserPage` | Peut masquer une vraie decision `auth_required`. | Centraliser la decision auth dans orchestrateur/guard, garder les pages auth pour saisie. |
| Retry disperses | Reset/run heterogenes. | Introduire `BootActionHandler.retry`. |

## Definition de fini - etape 1

- Les decisions router et widgets sont separees.
- Les routes qui doivent rester accessibles directement sont identifiees.
- Les routes qui doivent devenir des destinations appliquees par le router sont
  identifiees.

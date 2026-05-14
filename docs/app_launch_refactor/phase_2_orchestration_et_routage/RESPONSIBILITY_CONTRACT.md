# Contrat de responsabilite orchestration/router/UI

## Decision

Une decision boot ne doit avoir qu'une seule source.

Le contrat cible est :

```text
AppLaunchOrchestrator
  -> produit l'etat runtime et la destination boot
LaunchRedirectGuard / GoRouter
  -> applique la destination
Pages auth/profil/source
  -> collectent ou modifient les donnees utilisateur
BootScreenModel / renderer
  -> affichent l'etat et emettent des intentions d'action
BootActionHandler
  -> execute les intentions sans disperser les navigations
```

Le router ne doit pas inventer de decision metier. Les widgets ne doivent pas
decider seuls d'une destination finale du tunnel boot.

## Table de responsabilites

| couche | responsabilite cible | decisions autorisees | decisions interdites | contrat |
| --- | --- | --- | --- | --- |
| `AppLaunchOrchestrator` | Source de verite runtime du tunnel applicatif : session, profil, source, catalogue, Home readiness, recovery et destination boot. | Produire `AppLaunchState`, `AppLaunchPhase`, `AppLaunchCriteria`, `AppLaunchRecovery`, reason code log-safe et `BootstrapDestination`. Decider `auth_required`, `profile_required`, `source_required`, `source_selection_required`, `catalog_preparing`, recovery source, `opening_home`, `home_ready`, Home partiel. | Appeler directement `context.go`, connaitre les widgets, construire des textes UI, lancer une navigation Flutter. | `AppLaunchState` + `BootstrapDestination` + reason codes + registries. |
| `LaunchRedirectGuard` | Appliquer au router la destination fournie par l'orchestrateur ou par la projection `TunnelState` quand les flags V2 sont actifs. | Rediriger vers `/launch`, `/auth/otp`, `/welcome/user`, `/welcome/sources`, `/welcome/sources/select`, `/welcome/sources/loading` si conservé, `/bootstrap` fallback, `/`. Proteger Home si readiness incomplete. Laisser passer les routes auth recovery. | Recalculer les criteres metier session/profil/source/catalogue, declencher refresh catalogue, reset orchestrateur, choisir une action utilisateur, afficher une erreur. | `GoRouter.redirect`, `AppLaunchStateRegistry`, `TunnelStateRegistry`, `AppRoutePaths`. |
| `GoRouter` / catalogue de routes | Declarer les routes et monter les pages associees. | Associer path/name/widget, appliquer les redirects fournis, conserver les deep links auth recovery. | Decider qu'un utilisateur doit creer un profil, choisir une source ou ouvrir Home sans etat orchestrateur. | `AppRoutePaths`, `AppRouteIds`, `buildAppRoutes`, `AppRouteCatalog`. |
| `_LaunchGate` | Surface minimale de lancement tant que le renderer boot n'est pas branche. | Declencher un run initial documente si aucun handler ne le remplace encore; afficher un fallback non interactif. | Porter des decisions de destination, gerer retry, connaitre les etapes auth/profil/source/catalogue. | Fallback legacy vers `appLaunchRunnerProvider('startup')`; cible : renderer `BootScreenModel`. |
| `BootScreenModel` | Contrat de presentation derive de l'etat runtime. | Porter `screenType`, textes utilisateur, action principale/secondaire, destination abstraite, `reasonCode`, focus initial. | Naviguer, lire storage/reseau, relancer l'orchestrateur, choisir une destination differente de l'etat runtime. | `BootScreenMapper.fromLaunchState(AppLaunchState)` et `bootScreenModelProvider`. |
| Renderer boot Figma | Afficher le modele et emettre des intentions utilisateur. | Rendre loading/action/recovery/opening Home/Home partial, demander le focus initial, appeler le handler avec `BootActionIntent`. | Appeler directement `context.go`, `reset`, refresh catalogue, selectionner source/profil, exposer les reason codes. | `BootScreenModel -> Widget`, `BootActionHandler.handle(intent)`. |
| `BootActionHandler` | Centraliser l'execution des actions boot. | Executer `retry`, `login`, `createProfile`, `chooseProfile`, `addSource`, `chooseSource`, `reconnectSource`, `resyncSource`, `openHome`, `retryHomeSections`, `retryLibrary`, `exportLogs`. Deleguer aux controllers metier si necessaire. | Contenir de la logique UI, dupliquer les validations de formulaire, decider un etat runtime sans passer par l'orchestrateur ou le router. | `BootActionIntent -> route/controller/orchestrator`. |
| Pages auth existantes | Collecter les credentials et gerer login/signup/reset/password/OTP. | Valider saisie auth, appeler les controllers auth, afficher erreurs auth locales, signaler success au tunnel boot. Garder les routes recovery auth. | Decider Home, profil, source ou catalogue. Relancer le tunnel via navigation directe dispersee. | Pages auth + controllers auth; sortie cible via action/notification boot success. |
| Pages profil existantes | Collecter creation ou selection profil. | Creer profil, selectionner profil, gerer PIN/focus/erreurs profil locales, signaler success au tunnel boot. | Aller directement a `/bootstrap` ou `/launch`, decider source/catalogue/Home. | `profilesControllerProvider`, `selectedProfileControllerProvider`, action cible `createProfile` / `chooseProfile`. |
| Pages source existantes | Collecter ajout, reconnexion ou selection source. | Valider formulaire source, connecter/reconnecter, selectionner source, gerer erreurs saisie/locales et focus. | Lancer directement un refresh catalogue bloquant, choisir Home, naviguer vers loading comme decision finale non centralisee. | Controllers source/IPTV + actions cible `addSource`, `chooseSource`, `reconnectSource`, `resyncSource`. |
| `WelcomeSourceLoadingPage` legacy | Fallback temporaire de preparation source tant que le catalogue n'est pas extrait. | Afficher l'etat legacy et permettre retry/select source pendant la migration. | Rester proprietaire durable du refresh catalogue, de la readiness Home et de la navigation Home. | Fallback Phase 2/3; cible : orchestration catalogue + renderer `catalog_preparing`. |
| `AppStartupGate` | Bootstrap technique avant `MyApp`. | Charger config/dependances, afficher erreurs techniques avant router, safe mode/update blocking. | Prendre les decisions du tunnel applicatif apres `/launch`. | `appStartupProvider`, `AppStartupOrchestrator`, `LaunchErrorPanel`. |

## Transitions interdites depuis les widgets

| transition widget actuelle | decision cible |
| --- | --- |
| Retry recovery : `reset()` puis `go('/launch')`. | `BootActionHandler.retry` relance l'orchestrateur; le router applique la surface cible. |
| Profil cree/selectionne : `go('/bootstrap')`. | La page signale success profil; l'orchestrateur reevalue et le guard applique source/Home/recovery. |
| Source ajoutee : `goNamed(welcomeSourceLoading, force_reload=1)`. | La page signale success source; l'orchestrateur entre en `catalog_preparing` ou destination equivalente. |
| Source selectionnee : `goNamed(welcomeSourceLoading, force_reload=1)`. | La page signale success selection; l'orchestrateur reevalue catalogue. |
| Loading source success : `completeManualSourceLoadingToHome()` puis `go('/')`. | L'orchestrateur produit `home_ready`; le guard applique `/`. |
| Erreur source : bouton direct vers select source. | `BootActionIntent.chooseSource`, execute par le handler. |
| Auth success : `go('/launch')` disperse. | Auth signale success; le handler/orchestrateur relance le tunnel ou le guard applique la prochaine destination. |
| Auto-push auth depuis `WelcomeUserPage` pour Supabase unauthenticated. | A remplacer par decision `auth_required` si auth est obligatoire pour ce contexte, ou a documenter comme action auth locale non boot. |

## Navigations locales autorisees dans les pages d'action

| navigation | justification |
| --- | --- |
| Auth password <-> OTP. | Navigation interne auth, ne decide pas le tunnel global. |
| Auth forgot/update password. | Recovery auth autorisee par le guard. |
| Back local quand `context.canPop()`. | Navigation locale hors decision boot finale. |
| Welcome source select -> welcome source pour ajouter une source. | Navigation locale d'action utilisateur, tant qu'elle ne decide pas Home/catalogue. |
| Settings hors boot vers pages IPTV. | Parcours settings, a distinguer du tunnel initial. |

## Surface canonique pendant la migration

Decision temporaire :

- `/launch` reste la surface canonique d'entree du tunnel applicatif.
- `/bootstrap` reste un fallback legacy pour `SplashBootstrapPage`, failure et
  Home non pret tant que le renderer boot n'est pas branche.
- `/bootstrap` ne doit pas etre utilise comme destination metier nouvelle.
- Les nouvelles actions doivent viser le handler/orchestrateur, pas
  `go('/bootstrap')`.

Decision cible :

- le renderer `BootScreenModel` remplace progressivement `/launch` puis
  `/bootstrap` ;
- `/bootstrap` peut etre supprime, fusionne ou garde seulement comme compat
  apres migration selon les tests Phase 4/5.

## Regles de decision

- `AppLaunchState.destination` ou son equivalent cible est la seule source de
  destination boot finale.
- `BootScreenModel.destination` est informatif pour l'action/UI, pas prioritaire
  sur le guard.
- `LaunchRedirectGuard` applique une destination; il ne calcule pas la cause.
- Une page d'action peut modifier des donnees metier, puis notifier le tunnel.
- Une page d'action ne choisit pas l'etape suivante globale.
- Home ne s'ouvre que si l'orchestrateur a produit un etat ouvrable.
- Home partiel reste apres Home; il ne renvoie pas vers recovery source.
- Les reason codes restent dans les logs/tests, jamais comme texte visible.

## Definition de fini - etape 2

- Une decision boot a une seule source : `AppLaunchOrchestrator` ou projection
  runtime equivalente.
- Le router applique les destinations sans inventer de logique metier.
- Les pages d'action collectent les donnees et signalent leur resultat sans
  piloter le tunnel global.
- Les transitions interdites depuis les widgets sont explicites pour les etapes
  d'implementation.

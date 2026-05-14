# Cartographie des widgets legacy du boot

## Synthese

Les surfaces UI legacy du boot ne sont pas seulement des vues. Certaines
embarquent encore des decisions metier, du refresh catalogue, de la persistence
de source, du routage direct et de la logique de focus TV.

Classification globale :

| widget | classement | raison |
| --- | --- | --- |
| `OverlaySplash` | Adapter | Base visuelle reutilisee partout, mais le logo doit devenir l'image asset reelle et le texte doit respecter la spec Figma en bas d'ecran. |
| `LaunchErrorPanel` | Adapter ou remplacer | Simple et reutilisable pour erreurs techniques, mais pas aligne sur les ecrans recovery Figma complets. |
| `LaunchRecoveryBanner` | Remplacer | Bannier legacy, style et texte generique, action unique hardcodee. |
| `SplashBootstrapPage` | Remplacer comme ecran boot principal | Surface legacy du tunnel `/bootstrap`; la logique retry/focus peut etre conservee. |
| `WelcomeSourcePage` | Refactor lourd | UI d'ajout source + logique Supabase + activation + decrypt credentials + routage. |
| `WelcomeSourceSelectPage` | Adapter | Selection source utile, mais selection/persistence/routage doivent etre rapproches de l'orchestrateur. |
| `WelcomeSourceLoadingPage` | Extraire logique, remplacer UI | Duplique le refresh catalogue de l'orchestrateur et navigue directement vers Home. |

## Table detaillee

| widget | role actuel | providers/controllers | actions | routes | messages | logique a garder | logique a extraire |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `SplashBootstrapPage` | Surface `/bootstrap` qui affiche le chargement Home ou une erreur de preparation. | `appLaunchStateProvider`, `homeBootstrapProgressStageProvider`, `appLaunchOrchestratorProvider`, `appLaunchRunnerProvider`. | Retry : `orchestrator.reset()` puis `appLaunchRunnerProvider('retry')`. | Pas de navigation directe. Le router redirige selon `AppLaunchState`. | `overlayPreparingHome`, `overlayLoadingMoviesAndSeries`, `overlayLoadingCategories`, `overlayOpeningHome`, `errorPrepareHome`, `actionRetry`, `recoveryMessage` concatene au message. | Focus region `splashBootstrapPrimary`, retry focus, mapping progress Home. | Remplacer l'ecran par la nouvelle UI boot; ne plus concatener `recoveryMessage` technique dans le texte court; separer les etats catalogue/Home. |
| `WelcomeSourcePage` | Ecran d'ajout/activation source Xtream avec sources sauvegardees Supabase optionnelles. | `slProvider`, `authRepositoryProvider`, `iptvConnectControllerProvider`, `currentAccentColorProvider`, `appLaunchStateProvider`, `focusOrchestratorProvider`, `SupabaseIptvSourcesRepository`, `IptvCredentialsEdgeService`. | Charger/rafraichir sources Supabase, selectionner source sauvegardee, pre-remplir credentials, afficher/masquer password, activer source via `controller.connect`, retry recovery. | Back vers `welcomeUser` ou `iptvSources`; succes activation vers `welcomeSourceLoading?force_reload=1`; retry recovery vers `launch`. | `welcomeSourceTitle`, `welcomeSourceSubtitle`, `errorFillFields`, `snackbarSourceAddedBackground`, `errorConnectionFailed`, `errorUnknown`; textes hardcodes : `Sources sauvegardees`, `Activer une source`, `Nom de la source`, `Server URL`, `Username`, `Password`, `Activer`, `Rafraichir`, `Aucune source trouvee sur Supabase...`. | Champs de saisie, focus TV du formulaire, selection de source sauvegardee, local-first Supabase best-effort. | Connexion source, choix de policy Supabase, decrypt credentials, logs, routage apres activation, recovery banner, textes hardcodes a deplacer/localiser ou remplacer par spec. |
| `WelcomeSourceSelectPage` | Ecran de choix d'une source locale existante. | `allIptvAccountsProvider`, `appLaunchStateProvider`, `slProvider`, `SelectedIptvSourcePreferences`, `appStateControllerProvider`, `appLaunchOrchestratorProvider`. | Choisir source, persister `selectedSourceId`, mettre a jour `activeIptvSources`, pousser preferences si signed-in, retry recovery, ajouter source. | Back vers `welcomeSources` ou `iptvSources`; ajouter source vers `welcomeSources`; selection vers `welcomeSourceLoading?force_reload=1`; retry recovery vers `launch`. | `activeSourceTitle`, `welcomeSourceSubtitle`, `errorUnknown`; textes hardcodes : `Ajouter une source`. | Liste sources, focus item par source, fallback ajout source. | Persistence selection + update app state + push preferences + navigation loading; recovery banner. |
| `WelcomeSourceLoadingPage` | Ecran manuel de chargement source apres ajout/selection. | `shellControllerProvider`, `appStateControllerProvider`, `slProvider`, `SelectedIptvSourcePreferences`, `IptvLocalRepository`, `RefreshXtreamCatalog`, `RefreshStalkerCatalog`, `authRepositoryProvider`, `appLaunchOrchestratorProvider`, `currentAccentColorProvider`. | Resoudre source active, restaurer source selectionnee, refresh catalogue avec timeout 20s, verifier items, completer orchestrateur vers Home, retry, choisir autre source. | Home via `context.go(AppRouteNames.home)`; back vers `welcomeSourceSelect` ou `welcomeSources`; erreur avec choix source vers `welcomeSourceSelect`. | `Chargement de votre catalogue...`, `Chargement complet de la source...`, `Telechargement des playlists...`, `Chargement des films et series...`, `Preparation de l'accueil...`, `Reessayer`, `Choisir une autre source`, `Continuer quand meme`, messages source locale absente / source active non selectionnee / timeout / catalogue non pret. | Ecran de transition source, focus retry/select source, helpers purs `resolveWelcomeSourceLoadingSourceResolution`, `formatWelcomeSourceLoadingErrorMessage`, `shouldOfferWelcomeSourceSelectionOnFailure`. | Refresh catalogue, verification catalogue, source resolution runtime, direct Home navigation, duplication avec `_ensureIptvCatalogReady` et `ResolveCatalogReadiness`. |
| `LaunchErrorPanel` | Panneau generique d'erreur avec retry. | Aucun provider. Recoit props `message`, `retryLabel`, `onRetry`, `details`, `retryFocusNode`. | Afficher details tronques, appeler retry. | Aucune. | Messages fournis par callers; details limites a 300 chars / 4 lignes. | Pattern simple erreur + action, support focus node, details techniques optionnels. | Adapter visuellement; limiter l'usage aux erreurs techniques startup, pas aux recoveries metier Figma. |
| `LaunchRecoveryBanner` | Bannier retry inseree dans Welcome et Shell. | Aucun provider. Recoit `message`, `onRetry`, `retryFocusNode`. | Retry. | Aucune directe; route choisie par caller. | Texte bouton hardcode `Reessayer`. | Aucun besoin metier fort hors transition. | Remplacer par composants recovery Figma; action unique insuffisante pour `RecoveryAction` multiples. |
| `OverlaySplash` | Splash generique logo centre + spinner/message en bas. | `slProvider`, `currentAccentColorProvider`; fallback couleur theme. | Fade-in, affichage temps ecoule. | Aucune. | Semantics hardcode `MOVI splash logo`, `Chargement en cours`, fallback `Chargement...`, message + secondes. | Structure logo centre + spinner bas, reuse pour chargements non interactifs. | Logo vectoriel colore a remplacer par image asset reelle selon spec; retirer ou controler secondes si non demande; aligner texte court bas d'ecran. |

## Focus nodes et regions

| widget | focus nodes / regions |
| --- | --- |
| `SplashBootstrapPage` | `SplashBootstrapLoading`, `SplashBootstrapRetry`, region `splashBootstrapPrimary`. |
| `WelcomeSourcePage` | `WelcomeSourceRetry`, `WelcomeSourceRefresh`, `WelcomeSourceErrorRetry`, `WelcomeSourceName`, `WelcomeSourceServer`, `WelcomeSourceUser`, `WelcomeSourcePassword`, `WelcomeSourcePasswordToggle`, `WelcomeSourceSubmit`, `WelcomeSourceSavedN`; regions `welcomePrimary`, `welcomeSavedSources`, `welcomeSourceForm`. |
| `WelcomeSourceSelectPage` | `WelcomeSourceSelectBack`, `WelcomeSourceSelectRetry`, `WelcomeSourceSelectAddSource`, `WelcomeSourceSelectItemN`; region `welcomeSourceSelectPrimary`. |
| `WelcomeSourceLoadingPage` | `WelcomeSourceLoadingSurface`, `WelcomeSourceLoadingRetry`, `WelcomeSourceLoadingSelectSource`; region `welcomeSourceLoadingPrimary`. |
| `LaunchErrorPanel` | Recoit un `retryFocusNode`. |
| `LaunchRecoveryBanner` | Recoit un `retryFocusNode`. |
| `OverlaySplash` | Aucun focus interne, focus gere par parent si necessaire. |

## Messages generiques ou hardcodes a supprimer/remplacer

| message | fichier | probleme |
| --- | --- | --- |
| `recoveryMessage` concatene a `overlayPreparingHome` avec ` - ` | `SplashBootstrapPage` | Expose des details techniques dans un texte de chargement court. |
| `Chargement...` + secondes | `OverlaySplash` | Texte generique et compteur non specifie par les maquettes boot. |
| `Reessayer` | `LaunchRecoveryBanner`, `WelcomeSourceLoadingContent` | Hardcode, action unique, ne couvre pas les recovery actions multiples. |
| `Sources sauvegardees`, `Activer une source`, labels `Server URL`, `Username`, `Password` | `WelcomeSourcePage` | Textes hardcodes / melange FR-EN. |
| `Aucune source trouvee sur Supabase...` | `WelcomeSourcePage` | Mention technique Supabase cote utilisateur. |
| `Type de source inconnu pour ...` | `WelcomeSourceLoadingPage` | Message technique avec id source possible. |
| `Le chargement semble avoir echoue. Aucune playlist trouvee.` | `WelcomeSourceLoadingPage` | Ne distingue pas catalogue vide, provider error, source invalide. |
| `Le catalogue IPTV n'est pas pret...` | `WelcomeSourceLoadingPage` | Message technique non mappe a un reason code UI. |
| `Continuer quand meme` | `WelcomeSourceLoadingContent` | Action exposee par composant mais non cablee dans ce chemin; a justifier ou retirer. |

## Duplications UI / orchestrateur

| duplication | localisation | risque |
| --- | --- | --- |
| Refresh catalogue bloquant | `WelcomeSourceLoadingPage._loadCatalog` et `AppLaunchOrchestrator._ensureIptvCatalogReady`. | Deux mappings erreurs/timeouts, deux jeux de logs, comportements divergents Xtream/Stalker. |
| Resolution source active / selectionnee | `WelcomeSourceLoadingPage.resolveWelcomeSourceLoadingSourceResolution` et logique orchestrateur source selection. | Les cas source absente/invalide peuvent diverger entre lancement automatique et flow manuel. |
| Navigation vers Home | `WelcomeSourceLoadingPage._goToHome` et `LaunchRedirectGuard`/destination orchestrateur. | Le widget contourne le guard apres `completeManualSourceLoadingToHome`. |
| Retry recovery | `SplashBootstrapPage`, `WelcomeSourcePage`, `WelcomeSourceSelectPage`, `WelcomeSourceLoadingPage`. | Reset/rerun ou reload local differents selon surface. |
| Messages catalogue | `SplashBootstrapPage`, `WelcomeSourceLoadingPage`, `OverlaySplash`. | Les etats Figma risquent d'etre alimentes par des strings ad hoc au lieu d'un modele UI unique. |

## Recommandations pour la suite

- Garder les helpers de focus TV, mais les rattacher a de nouveaux composants
  boot plus petits.
- Centraliser la decision catalogue dans l'orchestrateur et rendre
  `WelcomeSourceLoadingPage` purement presentationnelle ou la supprimer.
- Remplacer `LaunchRecoveryBanner` par une surface recovery basee sur
  `RecoveryAction`.
- Faire de `OverlaySplash` un composant visuel compatible Figma : logo asset,
  contenu central, texte court en bas, sans details techniques.
- Sortir les messages hardcodes vers le mapping UI boot avant toute
  implementation visuelle.

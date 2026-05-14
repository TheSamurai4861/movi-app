# Remplacement des navigations directes dispersees

## Synthese

Les navigations boot directes les plus critiques des widgets welcome sont
remplacees par `executeBootAction(...)`, qui utilise `BootActionPlanner` et
`BootActionRequest`.

Ce changement ne remplace pas encore toutes les navigations locales :

- `context.pop()` reste autorise pour le back local ;
- les fallback back vers pages welcome/settings restent conserves ;
- l'ouverture auth opportuniste depuis `WelcomeUserPage` reste une navigation
  metier auth a clarifier separement ;
- `WelcomeSourceLoadingPage` garde encore la logique catalogue legacy jusqu'a
  l'extraction Phase 3.

## Table de classification

| fichier | navigation actuelle | type | remplacement cible | risque | test |
| --- | --- | --- | --- | --- | --- |
| `welcome_user_page.dart` | Recovery retry : `reset()` puis `go('/launch')`. | Decision boot a centraliser. | `executeBootAction(retry, reasonCode: launchRecovery.reasonCode)`. | Retry heterogene entre pages. | `welcome_user_page_auth_priority_test.dart`. |
| `welcome_user_page.dart` | Profil choisi : `reset()` puis `go('/bootstrap')`. | Decision boot a centraliser. | `executeBootAction(retry, reasonCode: profile_completed)`. | `/bootstrap` restait une surface legacy choisie par le widget. | `new_user_auth_launch_flow_test.dart`. |
| `welcome_user_page.dart` | Profil cree : `reset()` puis `router.go('/bootstrap')`. | Decision boot a centraliser. | `executeBootAction(retry, reasonCode: profile_created)`. | Relance du tunnel dispersee. | `welcome_user_page_auth_priority_test.dart`, `new_user_auth_launch_flow_test.dart`. |
| `welcome_user_page.dart` | Auto `push('/auth/otp?return_to=previous')`. | Navigation metier auth conservee provisoirement. | A clarifier avec decision `auth_required` ou action auth locale. | Peut masquer la decision orchestrateur auth. | `welcome_user_page_auth_priority_test.dart`. |
| `welcome_user_page.dart` | `context.pop()` back local. | Navigation UI locale. | Conserver. | Aucun si hors decision boot finale. | Couverture widget existante. |
| `welcome_source_page.dart` | Activation source success -> `goNamed(welcomeSourceLoading, force_reload=1)`. | Decision boot/source loading a centraliser. | `executeBootAction(resyncSource, reasonCode: source_connected, destinationOverride: /welcome/sources/loading?force_reload=1)`. | Transition catalogue decidee par widget. | Tests router/handler + analyse ciblée. |
| `welcome_source_page.dart` | Recovery retry : `reset()` puis `go('/launch')`. | Decision boot a centraliser. | `executeBootAction(retry, reasonCode: launchRecovery.reasonCode)`. | Retry heterogene. | Analyse ciblée; test widget source a renforcer. |
| `welcome_source_page.dart` | Back fallback vers `/welcome/user` ou settings. | Navigation UI locale. | Conserver. | Peut rester tant que c'est un retour utilisateur, pas une destination finale. | Analyse ciblée. |
| `welcome_source_select_page.dart` | Recovery retry : `reset()` puis `go('/launch')`. | Decision boot a centraliser. | `executeBootAction(retry, reasonCode: launchRecovery.reasonCode)`. | Retry heterogene. | Analyse ciblée; test widget selection a renforcer. |
| `welcome_source_select_page.dart` | Selection source -> `goNamed(welcomeSourceLoading, force_reload=1)`. | Decision boot/catalogue a centraliser. | `executeBootAction(resyncSource, reasonCode: source_selected, destinationOverride: /welcome/sources/loading?force_reload=1)`. | Transition catalogue decidee par widget. | Tests router/handler + analyse ciblée. |
| `welcome_source_select_page.dart` | Bouton ajouter source -> `/welcome/sources`. | Navigation locale d'action utilisateur. | Conserver provisoirement. | Faible : l'utilisateur demande explicitement l'ajout. | Analyse ciblée. |
| `welcome_source_select_page.dart` | Back fallback vers `/welcome/sources` ou settings. | Navigation UI locale. | Conserver. | Faible. | Analyse ciblée. |
| `welcome_source_loading_page.dart` | Success catalogue -> selection onglet Home puis `go('/')`. | Decision Home a centraliser. | Selection onglet conservee, navigation via `executeBootAction(openHome, reasonCode: home_ready)`. | Home pouvait etre ouverte hors contrat action. | `welcome_source_loading_page_test.dart`, tests router. |
| `welcome_source_loading_page.dart` | Selection requise apres refresh -> `/welcome/sources/select`. | Decision action utilisateur. | `executeBootAction(chooseSource, reasonCode: source_selection_required)`. | Transition source dispersee. | `welcome_source_loading_page_test.dart`. |
| `welcome_source_loading_page.dart` | Bouton choisir source -> `/welcome/sources/select`. | Decision action utilisateur. | `executeBootAction(chooseSource, reasonCode: source_selection_required)`. | Action recovery dispersee. | `welcome_source_loading_page_test.dart`. |
| `welcome_source_loading_page.dart` | Back vers source/select. | Navigation UI locale. | Conserver tant que loading legacy existe. | Moyen : sera requalifie apres extraction catalogue Phase 3. | Analyse ciblée. |
| `welcome_form.dart` | Source connectee -> Home direct. | Legacy non remplace dans cette etape. | A supprimer/remplacer quand `WelcomeForm` sera retire ou raccorde au handler. | Peut encore contourner le guard si utilise hors parent `onConnect`. | Test a ajouter si widget reste utilise. |

## Navigations directes restantes justifiees

| navigation | justification |
| --- | --- |
| `context.pop()` dans pages welcome. | Back UI local. |
| Fallback back vers page precedente welcome/settings. | Retour utilisateur explicite, pas destination boot finale. |
| `context.push('/auth/otp?return_to=previous')`. | Parcours auth opportuniste existant, couvert par tests; decision a clarifier en Phase 5/6 si l'auth devient un ecran boot complet. |
| Bouton ajouter source depuis selection. | Navigation locale vers une page d'action utilisateur. |
| `WelcomeForm` vers Home. | Surface legacy restante a traiter quand le widget sera confirme encore utilise. |

## Definition de fini - etape 6

- Les widgets welcome principaux utilisent une intention boot pour retry,
  source loading, selection source et ouverture Home.
- Les navigations locales conservees sont classees.
- Les suppressions de navigation directe sont couvertes par tests existants,
  tests handler et analyse statique ciblee.

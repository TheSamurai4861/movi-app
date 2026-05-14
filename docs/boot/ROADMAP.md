# Roadmap boot

## Objectif

Stabiliser le tunnel de demarrage pour garantir un seul parcours lisible :

1. Chargement initial de l'app.
2. Authentification.
3. Profil.
4. Source IPTV.
5. Chargement du catalogue.
6. Home.

Le boot doit rester simple, explicite et testable. L'orchestrateur applicatif
doit etre la source de decision. Les pages UI collectent les donnees utilisateur
et declenchent une action de boot, mais ne doivent pas decider seules de la
destination finale.

## Principes

- Un seul responsable de decision : `AppLaunchOrchestrator`.
- Un seul responsable d'application de destination : `LaunchRedirectGuard`.
- Les pages `auth`, `welcome/user`, `welcome/sources` et
  `welcome/sources/select` ne font que collecter ou selectionner.
- Les actions utilisateur passent par un contrat explicite, pas par des
  navigations ad hoc dispersees.
- Chaque correction est petite, testee et reversible.
- Aucun nouveau service ou pattern si une fonction locale suffit.
- Les logs doivent permettre de reconstruire le run sans exposer de secret.

## Parcours cible

### 1. Chargement initial

- `AppStartupGate` execute le bootstrap technique.
- `MyApp` s'affiche seulement apres `startup_ready`.
- Le router ouvre `/launch`.
- `_LaunchGate` ou une action boot equivalente lance
  `AppLaunchOrchestrator.run()`.

### 2. Auth

- Cas 1 : aucune session valide.
  - Destination : `auth`.
  - Route : `/auth/otp`.
  - Apres connexion validee : relancer le boot applicatif.
- Cas 2 : session deja presente et valide.
  - Skip de l'ecran auth.
  - Passage direct a l'etape profil.

### 3. Profil

- Cas 1 : aucun profil.
  - Destination : `welcomeUser`.
  - L'utilisateur cree un profil.
  - Apres creation : relancer le boot applicatif.
- Cas 2 : profils existants.
  - Si un dernier profil local valide existe : le restaurer.
  - Si un seul profil existe : auto-selection possible.
  - Si plusieurs profils existent et aucune selection locale valide : afficher
    la selection profil.

### 4. Sources

- Cas 1 : aucune source locale ou hydratable.
  - Destination : `welcomeSources`.
  - L'utilisateur cree une source.
  - Apres creation : relancer le boot applicatif vers le chargement catalogue.
- Cas 2 : une source existante.
  - Selection automatique.
  - Route de chargement catalogue.
  - Refresh bloquant si le snapshot catalogue manque ou est inexploitable.
  - Destination finale : Home si readiness OK.
- Cas 3 : plusieurs sources.
  - Si une derniere source locale valide existe : la restaurer.
  - Sinon : afficher la selection source.
  - Apres selection : relancer le boot applicatif vers le chargement catalogue.

### 5. Home

- Home s'ouvre seulement si les criteres sont vrais :
  - session ou mode local accepte selon le contexte ;
  - profil selectionne ;
  - source selectionnee ;
  - catalogue minimal pret ;
  - preload Home effectue ;
  - library prete ou degradation explicite autorisee.

## Ecarts constates

### Ecart A - Le refresh auth peut arriver apres une premiere decision auth

Observation log :

```text
session=null userId=n/a
step=auth_session ... invalid session -> explicit reauth
supabase.auth: INFO: Refresh session
step=auth_session hasAccount=true ... session validated
```

Risque :

- Un compte existant peut passer par `auth` si la session Supabase n'est pas
  hydratee au moment exact du premier run.

Decision :

- Garder le fail-closed cote orchestration.
- Eviter le freeze cote router.
- Ajouter une observation dediee pour mesurer le cas `session_null_then_refresh`.

### Ecart B - Selection profil trop automatique

Observation code :

- Si le profil selectionne est invalide, l'orchestrateur repare avec
  `profiles.first.id`.

Risque :

- Si plusieurs profils existent et que c'est la premiere connexion sur
  l'appareil, le schema cible demande une selection utilisateur, pas une
  selection arbitraire.

Decision :

- Auto-selectionner seulement quand il y a exactement un profil.
- Si plusieurs profils et aucune selection locale valide : destination
  `welcomeUser` en mode selection profil.

### Ecart C - Apres ajout de source, le catalogue ne se charge pas

Observation log :

```text
no local accounts available -> welcomeSources
IptvConnectController ... upsert succeeded
Application finished.
```

Logs attendus mais absents :

```text
step=iptv_source_selection
step=preload_complete_home
catalog_preparation_started
refresh_xtream start
iptv catalog snapshot ready for launch
home preload done
complete preload done -> home
```

Cause probable :

- `WelcomeSourcePage` appelle `connect(..., runCatalogSyncInBackground: false)`.
- La page appelle ensuite une action `retry` avec route
  `/welcome/sources/loading`.
- `executeBootAction` fait `reset()` puis `context.go(route)`, mais ne relance
  pas `AppLaunchOrchestrator.run()`.
- La route `welcomeSourceLoading` affiche un etat boot, mais ne demarre pas le
  run.

Decision :

- Les actions `launchRun` doivent relancer explicitement l'orchestrateur.
- La route de loading reste une surface d'affichage, pas un declencheur cache.

### Ecart D - Source selection et navigation catalogue encore dans les pages

Observation :

- `WelcomeSourcePage` et `WelcomeSourceSelectPage` mettent a jour prefs/app
  state puis naviguent vers une route de loading.

Risque :

- Divergence entre l'etat UI, les prefs et la decision finale du boot.

Decision :

- Les pages peuvent persister la selection utilisateur.
- La transition catalogue doit passer par une action boot commune.

## Phases

## Phase 0 - Gel du contrat cible

But :

- Documenter les etats et transitions autorises avant de modifier le code.

Travail :

- Ajouter un test de contrat pur pour `ResolveEntryDecision` :
  - pas de session + auth requise -> `RequireAuth`;
  - zero profil -> `RequireProfile`;
  - plusieurs profils sans selection -> `RequireProfile`;
  - zero source -> `RequireSource`;
  - plusieurs sources sans selection -> `RequireSourceSelection`;
  - source selectionnee + catalogue non pret -> `RequireSource`;
  - source selectionnee + catalogue pret -> `OpenHome`.
- Ajouter un tableau de correspondance :
  - decision domaine ;
  - `BootstrapDestination` ;
  - route attendue ;
  - surface UI.

Fichiers probables :

- `lib/src/core/startup/domain/resolve_entry_decision.dart`
- `test/core/startup/resolve_entry_decision_test.dart`
- `docs/boot/ROADMAP.md`

Critere d'acceptation :

- Le contrat cible est couvert par des tests rapides sans Flutter.

Table de correspondance :

| Etat lu par le contrat | Decision domaine | `BootstrapDestination` | Route attendue | Surface UI |
| --- | --- | --- | --- | --- |
| Auth cloud requise et session absente ou non valide | `RequireAuth` | `auth` | `/auth/otp` | Ecran de connexion |
| Aucun profil | `RequireProfile` | `welcomeUser` | `/welcome/user` | Creation profil |
| Plusieurs profils et aucune selection locale valide | `RequireProfile` | `welcomeUser` | `/welcome/user` | Selection profil |
| Aucun source locale ou hydratable | `RequireSource` | `welcomeSources` | `/welcome/sources` | Creation source |
| Plusieurs sources et aucune selection locale valide | `RequireSourceSelection` | `chooseSource` | `/welcome/sources/select` | Selection source |
| Source selectionnee mais catalogue non exploitable | `RequireSource` | `welcomeSources` | `/welcome/sources` ou `/welcome/sources/loading` selon recovery | Chargement catalogue puis recovery source |
| Profil, source et catalogue exploitable | `OpenHome` | `home` | `/` | Home |

## Phase 1 - Corriger l'action boot apres ajout/selection source

Statut : implemente.

But :

- Garantir que `source connected` et `source selected` relancent le pipeline
  catalogue via l'orchestrateur.

Travail :

- Modifier `executeBootAction` pour que `BootActionExecutionKind.launchRun` :
  - reset l'orchestrateur ;
  - lance `appLaunchOrchestratorProvider.notifier.run()` ;
  - navigue vers la route d'affichage demandee si fournie.
- Ne pas faire porter ce lancement a `SplashBootstrapPage`.
- Conserver `/launch` comme fallback historique.
- Ajouter un test qui prouve :
  - action `retry` avec `destinationOverride=/welcome/sources/loading` ;
  - `run()` est appele ;
  - la route de loading est affichee pendant le run.

Fichiers probables :

- `lib/src/core/startup/presentation/boot_action_executor.dart`
- `test/core/startup/boot_action_executor_test.dart`
- `test/core/router/launch_redirect_guard_boot_alignment_test.dart`

Critere d'acceptation :

- Apres ajout source, les logs contiennent :

```text
step=iptv_source_selection
step=preload_complete_home
```

Validation :

```powershell
flutter test test\core\startup\boot_action_executor_test.dart test\core\startup\boot_action_handler_test.dart
flutter test test\core\router\launch_redirect_guard_boot_alignment_test.dart
```

## Phase 2 - Verrouiller le chargement catalogue avant Home

Statut : implemente.

But :

- Le cas "une source existante" doit toujours passer par readiness catalogue
  avant Home.

Travail :

- Verifier que `AppLaunchOrchestrator` lit la source locale creee avant de
  selectionner.
- Verifier que `selectedSourceId` est ecrit avant le run.
- Verifier que `runCatalogSyncInBackground: false` reste coherent :
  l'orchestrateur devient responsable du refresh bloquant.
- Ajouter un test orchestrateur :
  - source locale creee ;
  - snapshot catalogue manquant ;
  - refresh Xtream appele ;
  - Home ouvert seulement apres snapshot exploitable.
- Ajouter un test d'echec :
  - refresh catalogue timeout ou provider error ;
  - destination `welcomeSources` avec recovery source.

Fichiers probables :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/domain/resolve_catalog_readiness.dart`
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`

Critere d'acceptation :

- Aucun chemin source -> Home ne contourne `preload_complete_home`.

Validation :

```powershell
flutter test test\core\startup\app_launch_orchestrator_local_mode_test.dart --name "blocking refresh creates|catalog preparing|provider refresh fails"
```

## Phase 3 - Aligner la selection profil sur le schema cible

Statut : implemente.

But :

- Ne plus choisir arbitrairement le premier profil quand plusieurs profils
  existent.

Travail :

- Dans l'orchestrateur :
  - si `profiles.length == 1` et selection invalide : auto-selection ;
  - si `profiles.length > 1` et selection invalide : destination
    `welcomeUser`.
- Clarifier dans le model UI si `welcomeUser` signifie creation ou selection.
- Ajouter tests :
  - zero profil -> creation profil ;
  - un profil -> auto-selection ;
  - plusieurs profils + selection valide -> restauration ;
  - plusieurs profils + selection absente -> selection profil.

Fichiers probables :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/presentation/boot_screen_mapper.dart`
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`

Critere d'acceptation :

- Le premier profil n'est jamais choisi automatiquement quand plusieurs profils
  existent sans selection locale valide.

## Phase 4 - Aligner la selection source sur le schema cible

Statut : implemente.

But :

- Distinguer clairement creation source, selection source et restauration de la
  derniere source.

Travail :

- Dans l'orchestrateur :
  - zero source -> `welcomeSources` ;
  - une source -> auto-selection ;
  - plusieurs sources + selection locale valide -> restauration ;
  - plusieurs sources + aucune selection locale valide -> `chooseSource`.
- Dans `WelcomeSourceSelectPage` :
  - apres selection, persister `selectedSourceId` ;
  - declencher une action boot commune ;
  - ne pas ouvrir Home directement.
- Ajouter tests router :
  - plusieurs sources sans selection -> route selection source ;
  - selection source -> loading catalogue -> Home.

Fichiers probables :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart`
- `test/core/router/new_user_auth_launch_flow_test.dart`
- `test/core/router/launch_redirect_guard_boot_alignment_test.dart`

Critere d'acceptation :

- La derniere source valide est restauree.
- Sinon la selection manuelle est obligatoire quand plusieurs sources existent.

## Phase 5 - Stabiliser auth restore sans rendre le boot magique

Statut : implemente.

But :

- Reduire les faux `auth_required` quand Supabase restaure une session juste
  apres le boot, sans affaiblir la securite.

Travail :

- Mesurer et logger le cas `currentSession == null` puis auth refresh valide.
- Etudier un court delai borne ou une lecture explicite de refresh dans
  `AuthOrchestrator.bootstrapSession()`.
- Garder un timeout clair.
- Ne jamais ouvrir Home sans session valide quand cloud auth est requis.

Fichiers probables :

- `lib/src/core/auth/application/auth_orchestrator.dart`
- `lib/src/core/auth/presentation/providers/auth_providers.dart`
- `test/core/auth/auth_orchestrator_test.dart`

Critere d'acceptation :

- Une session restaurable ne force pas un aller-retour auth inutile.
- Une session vraiment absente reste fail-closed vers auth.

## Phase 6 - Nettoyer les navigations boot dispersees

Statut : implemente.

But :

- Reduire les transitions cachees dans les pages.

Travail :

- Rechercher les appels :

```text
context.go(AppRoutePaths.launch)
context.go(AppRoutePaths.bootstrap)
context.go(AppRoutePaths.home)
context.go(AppRoutePaths.welcomeSourceLoading)
```

- Classer chaque appel :
  - navigation locale legitime ;
  - action boot a centraliser ;
  - contournement a supprimer.
- Remplacer les transitions boot par `executeBootAction` quand c'est une
  decision de tunnel.

Fichiers probables :

- `lib/src/features/auth/presentation/auth_password_page.dart`
- `lib/src/features/auth/presentation/auth_otp_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_source_page.dart`
- `lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart`
- `lib/src/features/settings/presentation/pages/iptv_source_add_page.dart`

Critere d'acceptation :

- Les pages ne choisissent plus Home.
- Home est uniquement atteint apres une destination `home` avec readiness OK.

Classement applique :

| Appel | Classement | Decision |
| --- | --- | --- |
| Auth OTP/password apres succes | action boot deja centralisee | conserve `executeBootAction(retry)` |
| `WelcomeUserPage` profil cree/selectionne | action boot deja centralisee | conserve `executeBootAction(retry)` |
| `WelcomeSourcePage` source ajoutee | action boot deja centralisee | conserve `executeBootAction(retry, /welcome/sources/loading)` |
| `WelcomeSourceSelectPage` source selectionnee | action boot deja centralisee | conserve `executeBootAction(retry, /welcome/sources/loading)` |
| `IptvSourceAddPage` utiliser maintenant | action boot a centraliser | remplace reset + `/bootstrap` par `executeBootAction(retry, /welcome/sources/loading)` |
| `IptvConnectPage` source connectee hors pile locale | action boot a centraliser | remplace reset + `/bootstrap` par `executeBootAction(retry, /welcome/sources/loading)` |
| `SettingsPage` deconnexion | action boot a centraliser | remplace reset + `/launch` par `executeBootAction(retry)` |
| `AppShellPage` retry recovery | action boot a centraliser | remplace reset + `/launch` par `executeBootAction(retry)` |
| `WelcomeForm` fallback legacy source | contournement a supprimer | remplace `/home` par `executeBootAction(retry, /welcome/sources/loading)` |
| `IptvConnectPage` retour sans pile | navigation locale legitime | remplace `/home` par `/settings/iptv/sources` |
| `VideoPlayerPage` fallback sans detail | navigation locale legitime | remplace `/home` par `/search` |

## Phase 7 - Observabilite runtime

But :

- Pouvoir diagnostiquer un run boot avec les logs seuls.

Travail :

- Ajouter ou verifier les logs structures :
  - `boot_action_triggered` avec route et run reason ;
  - `boot_run_started` ;
  - `source_connected`;
  - `source_selected`;
  - `catalog_preparation_started`;
  - `catalog_preparation_completed`;
  - `catalog_preparation_failed`;
  - `entry_journey_completed`.
- Ne pas logger server URL complete, username, password, token ou anon key.
- Ajouter un test de non-regression sur les reason codes principaux si
  possible.

Fichiers probables :

- `lib/src/core/startup/boot_event_contract_logger.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/presentation/boot_action_executor.dart`

Critere d'acceptation :

- Un log apres ajout source montre clairement :

```text
source_connected
boot_run_started
catalog_preparation_started
catalog_preparation_completed
entry_journey_completed destination=home
```

## Phase 8 - Validation manuelle et regression

Statut : implemente.

But :

- Verifier les vrais parcours utilisateur.

Scenarios manuels :

- Nouvelle installation :
  - auth -> creation profil -> creation source -> loading catalogue -> Home.
- Session deja presente :
  - skip auth -> profil restaure ou selection -> source restauree ou selection
    -> Home.
- Plusieurs profils :
  - premiere connexion appareil -> selection profil.
  - connexion suivante -> dernier profil.
- Plusieurs sources :
  - premiere connexion appareil -> selection source.
  - connexion suivante -> derniere source.
- Source invalide :
  - loading catalogue -> recovery source, pas Home.
- Fermeture et relance app :
  - reprise sur le dernier profil et la derniere source si valides.

Commandes de verification :

```powershell
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter test test/core/router/launch_redirect_guard_boot_alignment_test.dart
flutter test test/core/router/new_user_auth_launch_flow_test.dart
flutter test test/core/startup/boot_action_handler_test.dart
```

Critere d'acceptation :

- Les tests passent.
- Le log runtime suit le parcours cible sans trou entre source connectee et
  chargement catalogue.

Validation executee (2026-05-14) :

- `flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `flutter test test/core/router/launch_redirect_guard_boot_alignment_test.dart`
- `flutter test test/core/router/new_user_auth_launch_flow_test.dart`
- `flutter test test/core/startup/boot_action_handler_test.dart`
- Resultat : OK (all tests passed).

## Ordre recommande

1. Phase 1 : relancer vraiment l'orchestrateur apres action source.
2. Phase 2 : verrouiller le catalogue avant Home.
3. Phase 4 : corriger la selection source.
4. Phase 3 : corriger la selection profil.
5. Phase 5 : stabiliser auth restore.
6. Phase 6 : nettoyer les navigations dispersees.
7. Phase 7 et 8 : observabilite et validation.

Cet ordre traite d'abord le bug utilisateur constate : ajout source sans
chargement catalogue fiable.

## Definition of done

- L'orchestrateur est la seule source de decision du tunnel.
- Les pages d'action ne font plus de navigation finale vers Home.
- Apres ajout ou selection source, le catalogue est charge par le pipeline boot.
- Les cas profil/source multiples respectent la premiere connexion appareil.
- Les tests couvrent les chemins nominaux, limites et erreurs.
- Les logs permettent d'expliquer un run sans instrumentation supplementaire.

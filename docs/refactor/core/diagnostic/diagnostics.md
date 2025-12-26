## Fiche diagnostic — `lib/src/core/startup/` 

### But déclaré (ce que le dossier est censé faire)

* Fournir une **porte d’entrée de démarrage** (“gate”) qui exécute l’initialisation technique de l’app, puis redirige l’utilisateur vers la destination correcte (auth / onboarding / home).
* Centraliser la logique “bootstrap” : configuration, DI, session, sélection profil/source, préchargement minimal, sync IPTV.

> Indices dans le code : `AppStartupGate` décrit explicitement “running initialization logic before rendering the main application” et affiche un écran loading / erreur / succès. 

---

### Ce qu’il fait réellement (d’après le code)

Le dossier contient **3 niveaux de “startup”** qui s’entrecroisent :

1. **`app_startup_provider.dart`** : init technique “infra”

* `WidgetsFlutterBinding.ensureInitialized()`
* chargement env/flavor + `registerConfig`
* `initDependencies` (DI GetIt + modules)
* “bridge” Riverpod → GetIt pour `AppStateController` (`replace<AppStateController>(ref.read(appStateProvider.notifier))`)
* “sanity check” Supabase
* setup logging (`LoggingModule.register()`)
* setup IPTV sync service (interval + écoute changements prefs + stop onDispose) 

2. **`app_startup_gate.dart`** : shell UI de bootstrap

* Observe `appStartupProvider`
* Affiche un mini `MaterialApp` dark pendant loading / erreur
* Sur succès, rend `child` (l’app) 

3. **`app_launch_orchestrator.dart`** : orchestrateur “métier de lancement”

* Vérifie session auth
* Fetch profils Supabase, répare le profil sélectionné si invalide (fallback sur le premier)
* Fetch sources IPTV Supabase
* Migre credentials legacy vers Edge (best-effort)
* Hydrate les comptes IPTV locaux depuis Supabase si DB locale vide
* Sélectionne la source active (single source auto / sinon restaure préférée / sinon force écran chooseSource)
* **Précharge Home en attendant TOUJOURS IPTV** (`awaitIptv: true`) + timeout 45s + ignore erreurs + délai fixe +2s
* Lance un background sync IPTV après arrivée à Home 

En clair : ce dossier ne fait pas que “bootstrap technique”, il implémente aussi une partie importante du **parcours produit** (profil/source/onboarding) et de la **politique IPTV** (sync, hydration, migration credentials).

---

### API publique (classes/services/providers/export principaux)

* **Provider**

  * `appStartupProvider: FutureProvider<void>` (initialisation tech + DI + sync prefs) 

* **Widget**

  * `AppStartupGate extends ConsumerWidget` (gate UI loading/error/success) 

* **Orchestration / state**

  * `AppLaunchOrchestrator extends StateNotifier<AppLaunchState>`
  * `AppLaunchState`, `AppLaunchStatus`, `AppLaunchPhase`
  * `AppLaunchCriteria`
  * `AppLaunchResult`, `AppLaunchMeta`, `AppLaunchFailure`
  * `AppLaunchStateRegistry extends ChangeNotifier` 

* **Types “injectés”**

  * typedef `AppStartupRunner`, `HomePreloadRunner` 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **Le point d’entrée UI** : `main.dart` / `app.dart` (via `AppStartupGate` + `appStartupProvider`) — dépendance “app-level”.
* **Le routing / bootstrap pages** : probablement `welcome/splash_bootstrap_page.dart` et/ou un guard de routing, car `AppLaunchOrchestrator` renvoie un `BootstrapDestination` (auth, welcomeUser, welcomeSources, chooseSource, home). 

> Remarque : on ne voit pas dans ce dump qui instancie `AppLaunchOrchestrator`, mais il est clairement conçu pour être appelé depuis une couche de bootstrap/navigation.

#### De quoi il dépend ?

* **Core infra** : `core/config`, `core/di`, `core/logging`, `core/state`, `core/preferences`, `core/storage`, `core/security`, `core/auth` 
* **Supabase SDK** : `supabase_flutter` (dans `app_startup_provider`) 
* **Features (couplage fort)** :

  * `features/iptv/*` (sync service, refresh catalog, repositories, edge credential service, entités Xtream) 
  * `features/welcome/domain/enum.dart` (BootstrapDestination) 

👉 Point important : **`core/startup` importe directement des features** (iptv, welcome), et même du `core/profile` (qui ressemble déjà à une feature). Ça inverse la promesse “core = indépendant”.

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **`core/startup` dépend de `features/*`**

* `AppLaunchOrchestrator` tire directement des usecases/services IPTV + `BootstrapDestination` (welcome). Ça fait de `core/startup` un “super-feature” central. 

2. **Deux systèmes de state pour la même chose**

* `AppLaunchOrchestrator` est déjà un `StateNotifier<AppLaunchState>`, mais tu ajoutes `AppLaunchStateRegistry extends ChangeNotifier` qui réplique l’état (mise à jour dans `_updateState`). Ça sent le pont legacy UI/non-Riverpod, mais c’est un coût mental + risque de divergence si un jour ça dérive. 

3. **Le provider de startup fait beaucoup**

* `appStartupProvider` fait à la fois : bindings, env, config, DI, patch AppStateController, check Supabase, logging, config IPTV sync + subscribe prefs. Ce n’est pas “mauvais”, mais ça mélange des responsabilités “one-shot” (init) et “long-running” (watch prefs + piloter sync). 

4. **Politique de preload Home “bloquante”**

* Commentaire + impl : “TOUJOURS attendre le chargement complet du catalogue IPTV” (`awaitIptv: true`, timeout 45s, puis `Future.delayed(2s)`).
  Ça contredit ton objectif UX validé (“instant home + sync background”). 

5. **Gestion d’erreurs “best-effort” parfois silencieuse**

* `homePreload` : erreurs ignorées (`catchError -> return null`) et timeout “continuing” sans remonter un état riche.
* Migration / hydration : nombreux `catch (_) { // best-effort }` (ok pour migration, mais ça peut rendre des bugs invisibles). 

6. **Sync IPTV pilotée à deux endroits**

* `app_startup_provider` configure `XtreamSyncService` (interval + subscription + stop).
* `AppLaunchOrchestrator` lance aussi `_ensureIptvCatalogReady` puis `xtreamSyncService.start(...)`.
  Risque : politique de sync dispersée (source de vérité floue). 

---

### Risques (couplage, complexité, testabilité, performances)

1. **Couplage architecturel élevé**

* Un changement dans `features/iptv` ou `features/welcome` peut casser `core/startup`.
* `core/startup` devient le “hub” où tout finit par passer. 

2. **Testabilité**

* `AppLaunchOrchestrator` est testable (injections au constructeur), mais :

  * énorme surface de dépendances
  * logique multi-étapes + timeouts + delays
  * usage de singletons/side-effects via `LoggingService.log`, `debugPrint`, `Supabase.instance`, etc. 

3. **Perf / UX au démarrage**

* Blocage sur preload IPTV (jusqu’à 45s) + `delay 2s` systématique = risque de “l’app met trop longtemps à s’ouvrir”, surtout si Xtream prend ~20s et parfois plus. 

4. **Fiabilité / états non déterministes**

* Beaucoup de best-effort + ignore erreurs = l’utilisateur peut arriver à Home avec des états partiels, sans explication claire.
* `AppLaunchCriteria` existe mais n’est pas utilisé comme contrat d’écran (juste stocké dans state). 

5. **Dette technique “bridges”**

* Le commentaire sur `AppStateController` dit qu’il ne faut pas l’instancier via GetIt, puis tu fais un `replace` GetIt depuis Riverpod. C’est pragmatique, mais ça indique une **architecture hybride** (GetIt + Riverpod) qui demande discipline stricte pour rester saine. 

---

### Hypothèses de refactor (sans décider)

1. **Scinder “Startup infra” vs “Launch flow produit”**

* `app_startup_provider` = infra (bindings/env/DI/logging)
* `app_launch_orchestrator` = flow produit (session→profil→source→home)
* Mais déplacer la “destination” (`BootstrapDestination`) hors de `features/welcome` (ou définir un type neutre côté core) pour couper l’import feature. 

2. **Déplacer certaines responsabilités de `AppLaunchOrchestrator` vers les features**

* Migration credentials + hydration comptes locaux : probablement mieux dans `features/iptv` (service “AccountHydrationService”, “CredentialMigrationService”).
* Le core appellerait une interface “IptvBootstrapper.ensureLocalAccountsReady()” au lieu de manipuler XtreamAccount directement. 

3. **Revoir la politique preload Home**

* Remplacer “await IPTV complet” par “cache-first + skeleton + sync background”, et utiliser le mécanisme `_ensureIptvCatalogReady` seulement si cache absent (P0 minimal). (Aujourd’hui tu bloques même quand tu pourrais afficher.) 

4. **Réduire / clarifier la duplication de state**

* Décider si `AppLaunchStateRegistry` est réellement nécessaire.
  Si c’est un pont legacy, le documenter explicitement (“consommé par X”), sinon supprimer à terme.

5. **Centraliser la politique de sync IPTV**

* Une seule source de vérité : soit “startup infra configure + orchestrator déclenche”, soit l’inverse. Aujourd’hui c’est réparti.

6. **Renommer / repositionner**

* Le dossier `core/startup` porte aussi une notion de **“launch”** (produit). Peut-être le séparer : `core/bootstrap/` (infra) + `features/launch/` (flow), ou `core/launch/` mais sans dépendre de features (interfaces only).

---

### Notes & questions ouvertes (à tracer pour la synthèse core)

1. **Où est définie la navigation réelle ?**

* `AppLaunchOrchestrator` renvoie `BootstrapDestination`, mais on ne voit pas ici qui consomme ce résultat (page bootstrap ? guard router ?). À documenter en croisant avec `core/router` et `features/welcome`. 

2. **Pourquoi `AppLaunchStateRegistry` existe ?**

* Qui l’écoute ? (UI non Riverpod ? analytics ?)
  Si personne, c’est du bruit. Si quelqu’un, il faut l’identifier et documenter le besoin.

3. **Pourquoi “TOUJOURS attendre IPTV” + délai fixe 2s ?**

* Hypothèse : contournement d’un bug de disponibilité state/race condition.
  Il faut identifier la cause, car c’est un anti-pattern UX et un signe de manque de “ready signals” robustes. 

4. **GetIt + Riverpod**

* Tu assumes une architecture hybride. Il faudra écrire une règle claire dans la doc core : “qui vit dans GetIt”, “qui vit dans Riverpod”, et comment on évite les notifiers non initialisés. 

5. **Critères de “Home ready”**

* `AppLaunchCriteria.isHomeReady` = session + selected profile + selected source. Mais ton produit veut aussi “cache Xtream P0 dispo” (catégories/hero minimal). Est-ce un critère à ajouter (ou à laisser hors criteria) ? 

## Fiche diagnostic — `lib/src/core/router/` 

### But déclaré (ce que le dossier est censé faire)

* Centraliser la **navigation** (paths + names GoRouter), construire le `GoRouter`, et gérer la **redirection initiale** (Launch → Auth → Bootstrap → Home) via un guard.
* Fournir une couche “route catalog” (routes critiques + deep links) et une page 404 générique.

> Indices : `LaunchRedirectGuard` est décrit comme “Guard responsable de la logique de redirection initiale”, `AppRoutePaths`/`Ids` centralisent la navigation, `createRouterHandle` gère le lifecycle du guard. 

---

### Ce qu’il fait réellement (d’après le code)

1. **Centralisation des constantes de routes**

* `app_route_paths.dart` (URLs), `app_route_ids.dart` (names GoRouter)
* `app_route_names.dart` maintenu pour compat/migration progressive (paths historiques). 

2. **Création du router + lifecycle**

* `app_router.dart` construit le `GoRouter` avec :

  * `initialLocation = /launch`
  * `refreshListenable = guard`
  * `redirect = guard.handle`
  * `routes = buildAppRoutes(guard)`
  * `errorPageBuilder` → `NotFoundPage` localisée 
* Fournit `createRouterHandle` (router+guard disposables) + `appRouterProvider` (Provider Riverpod qui dispose automatiquement). 

3. **Définition des routes applicatives**

* `app_routes.dart` construit *toutes* les routes, incluant :

  * le flow startup/welcome (`/launch`, `/welcome/*`, `/bootstrap`, `/auth/otp`)
  * `home` qui wrap `AuthGate(child: AppShellPage())`
  * pages features (movie, tv, player, search, settings, library, etc.)
  * `pin_recovery` qui pointe vers une page… dans `core/parental` (ce qui ressemble à une feature). 

4. **Le guard**

* `LaunchRedirectGuard` gère :

  * résolution auth (timeout 4s, écoute `onAuthStateChange`)
  * redirections Launch/Auth/Bootstrap selon `AppLaunchStateRegistry.state` (status + destination)
  * protège les “startup routes” (criticalRoutes) pendant que le launch est running/idle
  * mappe `BootstrapDestination` → route path. 

5. **Un mini “launch gate”**

* `_LaunchGate` déclenche `ref.read(appLaunchRunnerProvider)('startup')` en microtask, puis affiche `OverlaySplash`. 

---

### API publique (classes/services/providers/export principaux)

* **Factories**

  * `createRouterBundle(...)` → `(router, guard)`
  * `createRouterHandle(...)` → `RouterHandle(router, guard)` avec `dispose()` 
  * `createRouter(...)` (deprecated, car ne dispose pas guard) 

* **Provider**

  * `appRouterProvider: Provider<GoRouter>` 

* **Guard**

  * `LaunchRedirectGuard extends ChangeNotifier` + `handle(...)` 

* **Routes constants**

  * `AppRoutePaths`, `AppRouteIds`, `AppRouteNames` (compat) 

* **Routing helpers**

  * `AppRouteCatalog` (criticalRoutes, deepLinkRoutes) 
  * `PlayerRouteArgs` (convertit en `VideoSource`) 
  * `NotFoundPage` 
  * `router.dart` export barrel 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* Toute l’app (navigation globale) via `appRouterProvider` / `createRouterHandle`. 
* Les features utilisent indirectement `AppRoutePaths/Ids` pour naviguer (go/push/goNamed). (Sous-entendu par la centralisation) 

#### De quoi il dépend ?

* **Core**

  * `core/auth` (`AuthRepository`, `AuthGate`)
  * `core/state` (`AppStateController`, `app_state_provider`)
  * `core/startup` (`AppLaunchStateRegistry`, `AppLaunchStatus`, `appLaunchRunnerProvider`)
  * `core/logging`
  * `core/di` (GetIt `sl`) 
* **Features**

  * `features/welcome` (pages + `BootstrapDestination`)
  * plein de pages feature : `movie`, `tv`, `player`, `search`, `settings`, `library`, `category_browser`, `shell` 
* **Shared**

  * `shared/presentation/router/content_route_args.dart`
  * `shared/domain/entities/person_summary.dart`
  * `shared/presentation/ui_models/ui_models.dart` 

👉 Le router est, logiquement, un point central. Mais il “connaît” beaucoup de features, ce qui est normal pour la table de routes, **moins normal** pour des dépendances de guard/startup.

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Couplage `router` ↔ `startup` ↔ `welcome`**

* `LaunchRedirectGuard` dépend de `AppLaunchStateRegistry` (core/startup) *et* de `BootstrapDestination` (features/welcome). Le routing initial mélange core + feature. 

2. **Deux mécanismes qui déclenchent le launch**

* `_LaunchGate` déclenche `appLaunchRunnerProvider('startup')` dès `/launch`.
* `LaunchRedirectGuard` redirige ensuite selon l’état `launchRegistry.state`.
  => logique “qui pilote quoi” pas totalement unifiée : le guard dépend d’un state externe, et la route `/launch` déclenche l’action. 

3. **Compat routes : `AppRouteNames` vs `AppRoutePaths`**

* Tu as 3 sources (Ids / Paths / Names). C’est assumé (“migration progressive”), mais ça augmente le coût mental et le risque d’incohérence si un dev utilise “Names” en pensant que c’est des route names alors que c’est des paths. 

4. **Routes “placeholder redirect to home”**

* `search`, `library`, `settings` redirigent vers `/` et ont des `SizedBox.shrink()`.
  Ça peut être temporaire, mais c’est surprenant : ces paths existent mais sont inutilisables. Risque pour deep links / QA. 

5. **Core qui pointe vers `core/parental`**

* La route `pin_recovery` utilise `PinRecoveryPage` dans `core/parental`. Si `parental` est une feature, ça renforce le problème “feature déguisée en core”. 

6. **`PlayerRouteArgs` dépend d’une entity feature (`VideoSource`)**

* `core/router/route_args` dépend directement de `features/player`. C’est pratique, mais ça fait fuiter la dépendance feature dans core. 

7. **Auth resolution timeout arbitraire (4s)**

* Si l’auth met plus longtemps (refresh token, cold start, IO), tu “forces” `_authResolved = true` et rediriges selon `currentSession`. Ça peut causer des flashs d’écran ou des redirections incorrectes sur devices lents. 

---

### Risques (couplage, complexité, testabilité, performances)

1. **Couplage élevé**

* Router connaît trop de concepts : “bootstrap destination”, “launch registry”, “welcome pages”, “auth gate”…
  Ça complique l’extraction/évolution future (ex: remplacer welcome flow). 

2. **Testabilité du guard**

* `LaunchRedirectGuard` est testable mais nécessite :

  * `AuthRepository` mock avec stream
  * `AppStateController` (listener)
  * `AppLaunchStateRegistry` (ChangeNotifier)
    Et la logique dépend de temps (`Timer`, scheduler phase), ce qui rend les tests plus délicats. 

3. **Risques UX au démarrage**

* L’état auth peut être “unresolved”, tu forces `/launch` → overlay splash.
  Si ensuite bootstrap prend long, l’utilisateur peut avoir un “splash” prolongé sans feedback progressif.
* Timeout 4s peut déclencher des transitions non désirées. 

4. **Complexité de maintenance**

* `app_routes.dart` est déjà énorme. Chaque feature ajoutée augmente le bruit + le risque de conflits / merge.
* Une erreur de `state.extra` manque → NotFoundPage (ok), mais beaucoup de parsing manuel à maintenir. 

---

### Hypothèses de refactor (sans décider)

1. **Découpler le guard de `features/welcome`**

* Remplacer `BootstrapDestination` (feature) par un type neutre dans core (ex: `LaunchTarget`) ou par des route paths directement dans `AppLaunchState`.
* Ou déplacer `BootstrapDestination` dans un package “core/bootstrap_types” neutre. 

2. **Clarifier “qui déclenche le launch”**

* Option A : le guard détecte `idle` et déclenche le runner (pas la route `/launch`).
* Option B : `/launch` déclenche, et le guard ne fait que router en fonction de `launchRegistry`, sans gérer `idle/running` de manière aussi fine.
  Aujourd’hui c’est un peu mixte. 

3. **Éclater `app_routes.dart`**

* Pattern fréquent “pro” : chaque feature expose un `List<RouteBase> featureRoutes()` et `buildAppRoutes()` compose.
* Ça réduit les imports et isole les dépendances. (Mais à décider plus tard.) 

4. **Déplacer `PlayerRouteArgs`**

* Soit dans `features/player/presentation/router/`
* Soit dans `shared/presentation/router/` si utilisé cross-feature
* But : éviter que `core/router` dépende de player. 

5. **Réduire / éliminer `AppRouteNames`**

* Une fois migration terminée, n’avoir que `AppRoutePaths` (URLs) + `AppRouteIds` (names).
  `AppRouteNames` est un alias trompeur (paths “historique”) qui peut créer des erreurs d’usage.

6. **Revoir les routes placeholder**

* Soit supprimer ces routes si non utilisées.
* Soit leur donner un écran réel.
* Soit les marquer explicitement “deprecated/blocked” avec un NotFound informatif. 

---

### Notes & questions ouvertes

1. **`appLaunchRunnerProvider` est défini où ?**

* On voit son usage dans `_LaunchGate`, mais pas sa définition ici. À documenter côté `features/welcome/presentation/providers/bootstrap_providers.dart` (probable). 

2. **Quelle est la source de vérité du “launch state” ?**

* `LaunchRedirectGuard` lit `AppLaunchStateRegistry.state`.
  Mais l’orchestrateur est un `StateNotifier<AppLaunchState>` : comment s’aligne-t-il avec `Registry` ? (on l’a vu côté startup : duplication potentielle). 

3. **Deep links**

* `AppRouteCatalog.deepLinkRoutes` liste des routes, mais rien ici ne montre une logique spécifique pour deep links. Est-ce géré ailleurs (ex: app_links) ? À noter pour la doc globale. 

4. **AuthGate sur Home**

* Home est défini comme `AuthGate(child: AppShellPage())`.
  Donc même si le guard redirige, la home “self-protect” aussi. Double barrière : c’est bien en sécurité, mais risque de doublon/flash si les deux ne sont pas alignés. 

## Fiche diagnostic — `lib/src/core/di/` 

### But déclaré (ce que le dossier est censé faire)

* Centraliser l’initialisation des dépendances (GetIt) de l’app : config, storage, réseau, supabase/auth, modules features.
* Fournir une surface d’accès unifiée via un **service locator** (`sl`) + un bridge Riverpod (`slProvider`) pour permettre overrides en tests.
* Proposer une infra de tests isolée (`initTestDependencies`) pour ne pas polluer le scope global. 

---

### Ce qu’il fait réellement (d’après le code)

1. **GetIt global + helper “replace”**

* `sl = GetIt.instance`
* `replace<T>(instance)` unregister puis registerSingleton. 

2. **`initDependencies()` est un mega-orchestrateur**

* Enchaîne :

  * `_registerConfig()` + `_registerSecretStore()`
  * `_registerPreferences()` (locale, selected profile, selected source, iptv sync, player, accent)
  * `_registerLoggingIfReady()`
  * `StorageModule.register()`
  * `_registerCloudSyncPreferences()`
  * `_registerNetwork()`
  * `PerformanceModule.register(sl)`
  * `_registerTmdbInfrastructure()` + `_registerSharedServices()`
  * `_registerState()` **avant** supabase/auth (commentaire “must be registered before”)
  * `SupabaseModule.register(sl)`
  * `_registerSupabaseRepositories()` (profile repo, iptv sources repo, edge credentials, reporting)
  * `AuthModule.register(sl)`
  * `_registerFeatureModules()` (iptv/movie/tv/person/saga/search/playlist/home/library/category/settings)
  * `_assertCriticalRegistrations()` debug-only 

3. **DI qui mélange “core infra” et “features modules”**

* Le fichier `injector.dart` référence énormément de features et de core (iptv, home, search, library, settings, parental, reporting…). 

4. **Bridges Riverpod**

* `slProvider = Provider<GetIt>((_) => sl)` pour laisser override en tests. 
* Exemple concret : `repository_providers.dart` expose `categoryRepositoryProvider` via `slProvider` (éviter import direct GetIt dans présentation). 

5. **Test injector**

* `initTestDependencies()` push scope GetIt, register config/secrets, appelle `initDependencies`, puis popScope via `TestInjectorScope.dispose()`. 

---

### API publique (classes/services/providers/export principaux)

* `sl` (GetIt global)
* `replace<T>()`
* `initDependencies({ appConfig, secretStore, localeProvider, registerFeatureModules })` 
* `slProvider` (Provider Riverpod)
* `repository_providers.dart` (ex: `categoryRepositoryProvider`) 
* Tests :

  * `initTestDependencies()` + `TestInjectorScope` 
* Export barrel : `di.dart` exporte `injector.dart` 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **core/startup** appelle `initDependencies()` au lancement (via `appStartupProvider`) 
* Toute la base code qui fait `sl<T>()` ou `ref.watch(slProvider)` / `categoryRepositoryProvider`
* Des modules `*DataModule.register()` (features) supposent GetIt prêt
* Les tests utilisent `initTestDependencies()` pour isoler les registrations 

#### De quoi il dépend ?

* **Core** : config, logging, network, preferences, storage, supabase module, auth module, state, performance, parental, reporting. 
* **Features** : iptv/home/search/movie/tv/person/saga/library/category/settings/playlist… directement importées dans `injector.dart`. 
* **SDKs** : `supabase_flutter` pour `SupabaseClient`, Flutter `ui.PlatformDispatcher` pour locale device. 

👉 Point clé : `core/di` devient le **point de convergence de tout** (core + features), ce qui est “normal” pour un injector global, mais dangereux si le reste du core dépend ensuite des features (effet boule de neige).

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Injector “dossier core” qui connaît toutes les features**

* `injector.dart` importe une grande partie du projet. Ça crée :

  * gros fichier difficile à maintenir
  * risques de cycles / import hell
  * “core” n’est plus neutre (même si DI central peut être dans core, il devrait idéalement **composer** des modules, pas tout assembler à la main). 

2. **Ordre d’enregistrement fragile**

* Commentaire : “AppStateController must be registered before Auth/Supabase modules”
* `_registerSupabaseRepositories()` a des chemins conditionnels / exceptions (si supabase pas configuré / pas registered)
* `_registerFeatureModules()` dépend implicitement que certains services TMDB/Network soient déjà prêts
* On voit plusieurs `if (!sl.isRegistered<...>() && sl.isRegistered<...>())` → architecture très dépendante de l’ordre. 

3. **Gestion du cas “Supabase non configuré”**

* `_registerSupabaseRepositories()` peut `return` silencieusement si pas configuré, mais `_assertCriticalRegistrations()` va ensuite log “missing SupabaseClient” etc.
  → c’est un peu contradictoire : soit “supabase optional”, soit “critical”. Là c’est entre deux. 

4. **LoggingModule register appelé à deux endroits**

* Ici : `_registerLoggingIfReady()` (si AppConfig registered)
* Et dans `core/startup/app_startup_provider` : `LoggingModule.register()` aussi.
  → duplication, risque d’init multiple / “dispose then register” dans `_registerConfig`. 

5. **AppStateController enregistré en GetIt mais instancié via Riverpod ailleurs**

* `_registerState()` enregistre `AppStateController` lazy singleton GetIt.
* Mais côté startup tu fais `replace<AppStateController>(ref.read(appStateProvider.notifier))` pour imposer l’instance Riverpod dans GetIt.
  → Ça montre un conflit de responsabilité : “qui crée le controller ? GetIt ou Riverpod ?”. 

6. **“isRegistered checks” partout**

* C’est utile pour idempotence, mais ça masque les vrais contrats de dépendances. Ça finit par ressembler à un système “best effort” plutôt qu’un graph strict.

7. **Provider de repo placé dans core/di**

* `repository_providers.dart` (category repo) ressemble à une pattern “feature infra”, mais placé dans `core/di/providers`. Ça peut devenir un dumping ground si chaque repo a son provider ici. 

---

### Risques (couplage, complexité, testabilité, performances)

1. **Couplage & cycles**

* Plus l’injector est central et “aware” de features, plus tu risques des imports croisés (ex: une feature importe core/di, et core/startup importe la feature, etc.). 

2. **Complexité de debug au startup**

* Si un service manque, tu as des logs “missing” mais pas forcément une exception (debug only). Résultat : crash tardif ailleurs.
* Plusieurs services sont conditionnels → comportements différents selon config/platform/test.

3. **Testabilité**

* `initTestDependencies` est bien : `pushNewScope()` + pop. 👍 
* Mais le fait que le controller dépende de `ui.PlatformDispatcher` + prefs async crée des tests plus lourds.
* Et les modules feature peuvent enregistrer beaucoup de choses inutiles pour certains tests (d’où le flag `registerFeatureModules=false`). 👍

4. **Performance**

* `initDependencies` fait beaucoup d’async au démarrage (prefs + storage + network + performance + supabase). Si tout est séquentiel, tu payes le coût total (même si certains seraient parallélisables).
* Le DI “idempotent + conditions” peut coûter un peu, mais le vrai coût c’est les initialisations qu’il déclenche. 

---

### Hypothèses de refactor (sans décider)

1. **Isoler DI “composition root” hors de `core/`**

* Option classique : `lib/src/app/bootstrap/` ou `lib/src/bootstrap/`
  Le “composition root” n’est pas vraiment du “core” (au sens clean), c’est l’endroit où tout est assemblé.

2. **Découper l’injector par modules**

* Aujourd’hui, `_registerFeatureModules()` appelle `*DataModule.register()`. Ça c’est bien.
* Mais `injector.dart` enregistre aussi plein de services feature-ish (parental/reporting/shared services).
* Hypothèse : chaque domaine (core/auth, core/supabase, core/storage, shared/tmdb, parental, reporting…) devrait exposer un `Module.register(sl)` pour réduire le mega fichier et clarifier les contrats.

3. **Clarifier “GetIt vs Riverpod” (règle stricte)**

* Choix A : `AppStateController` appartient à Riverpod (source), GetIt ne fait que “pointer” dessus via `replace`.
* Choix B : `AppStateController` appartient à GetIt, Riverpod ne fait que le lire via un Provider (wrapper).
* Aujourd’hui c’est mixte et fragile.

4. **Supabase: strict ou optionnel**

* Soit Supabase fait partie des “critical dependencies” et l’absence doit fail-fast (exception claire)
* Soit Supabase est optionnel (mode offline/local), et alors `_assertCriticalRegistrations` doit adapter ses attentes.

5. **Unifier logging init**

* Une seule autorité (DI *ou* startup provider), pas les deux.

6. **Déplacer les “repository_providers”**

* Soit dans chaque feature (`features/category_browser/presentation/providers`)
* Soit dans un dossier `shared/di_providers` si vraiment cross-feature
* But : éviter l’effet “tout provider DI dans core/di”.

---

### Notes & questions ouvertes

1. **Pourquoi l’injector dépend de `core/startup/app_launch_orchestrator.dart` ?**

* Il est importé mais je ne vois pas son usage direct ici. C’est un signe de couplage inutile (ou un reste). À nettoyer plus tard. 

2. **Où est créé `AppConfig` et quand est appelé `initDependencies()` exactement ?**

* On sait que `core/startup` le fait, mais l’ordre `registerConfig` vs `initDependencies(appConfig: config)` doit être cohérent (actuellement le code supporte appConfig null). 

3. **Pourquoi `AppStateController` est enregistré sans dépendances, alors qu’il dépend de prefs via GetIt ?**

* Il lit `sl<LocalePreferences>()` en build : ça impose que les prefs soient déjà là. Ici c’est vrai (prefs avant state). Mais c’est une contrainte cachée qui mérite une doc explicite.

4. **Locale normalization**

* La logique `supportedLocales` est codée en dur ici : est-ce la bonne place (DI) ou plutôt `l10n`/`config`/`LocalePreferences` ? À noter.

## Fiche diagnostic — `lib/src/core/state/` 

### But déclaré (ce que le dossier est censé faire)

* Porter un **état global runtime** (non persistant) de l’application : thème, locale, connectivité “logique”, sources IPTV actives, etc.
* Fournir une **API de mise à jour** (controller) synchronisée avec les préférences persistées.
* Exposer des **providers Riverpod** (state + derived providers) consommables partout.
* Fournir un **bus d’événements** global “fire-and-forget” pour des signaux ponctuels (ex: “IPTV synced”). 

---

### Ce qu’il fait réellement (d’après le code)

1. **Un AppState immuable, Equatable**

* `AppState` contient : `themeMode`, `isOnline`, `preferredLocale`, `accentColor`, `preferredAudioLanguageCode`, `preferredSubtitleLanguageCode`, `iptvSyncInterval`, `activeIptvSources`.
* Il protège `activeIptvSources` en `Set.unmodifiable` et normalise `iptvSyncInterval` (default 15 min). 

2. **Un contrôleur Riverpod v3 (`Notifier<AppState>`)**

* `AppStateController` :

  * lit `LocalePreferences` via GetIt (`sl<LocalePreferences>()`)
  * initialise l’état depuis les prefs (locale + theme)
  * s’abonne aux streams `languageStream` + `themeStream`
  * expose mutateurs : `setThemeMode`, `setPreferredLocale`, `setConnectivity`, `setActiveIptvSources`, `addIptvSource`, `removeIptvSource`
  * expose `connectivityStream` via `StreamController<bool>.broadcast()`
  * ajoute une compat `addListener()` “style StateNotifier” pour des consommateurs non-Riverpod (ex: guard router) 

3. **Un ensemble de providers “dérivés”**

* `appStateProvider` = `NotifierProvider<AppStateController, AppState>`
* providers dérivés : `isOnlineProvider`, `currentLocaleProvider`, `currentThemeModeProvider`, `activeIptvSourcesProvider`, etc.
* et en parallèle, plusieurs providers lisent directement **des préférences** (pas AppState) :

  * `IptvSyncPreferences`, `PlayerPreferences`, `AccentColorPreferences` via `slProvider`
  * * `StreamProvider` associés et helpers `_valueOr` 

4. **Un AppEventBus**

* `AppEventBus` basé sur `StreamController.broadcast` avec `AppEventType` (`iptvSynced`, `librarySynced`) et `appEventBusProvider`. 

---

### API publique (classes/services/providers/export principaux)

* **Data**

  * `AppState` 
* **Controller**

  * `AppStateController extends Notifier<AppState>`
  * * `addListener(void Function(AppState)) -> unsubscribe` (compat externe)
  * `connectivityStream`, `preferredIptvSourceIds`, `activeIptvSourceIds` 
* **Providers**

  * `appStateProvider`, `appStateControllerProvider`
  * derived providers : `isOnlineProvider`, `activeIptvSourcesProvider`, `currentLocaleProvider`, `currentThemeModeProvider`, etc.
  * providers de préférences “en dehors du state” : `iptvSyncPreferencesProvider`, `playerPreferencesProvider`, `accentColorPreferencesProvider` + streams associés 
* **Eventing**

  * `AppEventBus`, `AppEvent`, `AppEventType`, `appEventBusProvider` 
* **Barrel**

  * `state.dart` exporte tout 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **Core/router** : mention explicite dans la doc du controller : `LaunchRedirectGuard` utilise `addListener` (consommation non-Riverpod). 
* **UI globale** : thème et locale (via `currentThemeModeProvider`, `currentLocaleProvider`).
* **IPTV / Home / Settings** : via `activeIptvSourcesProvider`, `hasActiveIptvSourcesProvider`, etc.
* Toute feature qui veut des préférences player/audio/subtitles/accent peut consommer les providers de `app_state_provider.dart`. 

#### De quoi il dépend ?

* **Core/preferences** : `LocalePreferences`, `SelectedIptvSourcePreferences`, `IptvSyncPreferences`, `PlayerPreferences`, `AccentColorPreferences` 
* **Core/di** : `sl` (GetIt) + `slProvider` (bridge) 
* **Core/theme** : `AppColors` pour fallback accent color 
* Flutter (`ThemeMode`, `Locale`) + Riverpod. 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Deux sources de vérité pour des “prefs globales”**

* Une partie est dans `AppState` (locale + theme + activeIptvSources), mais d’autres prefs restent **hors AppState** (iptv sync interval, player prefs, accent color) et sont gérées via providers séparés.
  → Ça crée une architecture hybride “global state + direct prefs”, donc des chemins multiples pour le même type de besoin (ex: “où je lis la valeur ?”). 

2. **`AppState` contient des champs pas réellement pilotés**

* `preferredAudioLanguageCode`, `preferredSubtitleLanguageCode`, `accentColor`, `iptvSyncInterval` existent dans `AppState`, mais le code indique que pour l’instant on lit ces valeurs via prefs directement.
  → risque de “dead fields” / confusion : un dev pourrait croire que `AppState.accentColor` est à jour alors que non. 

3. **Couplage IPTV dans le state global**

* `activeIptvSources` + logique `preferredIptvSourceIds` (dépend de `SelectedIptvSourcePreferences`) : c’est utile, mais ça ancre IPTV dans un “core state”. Ça peut être OK, mais ça pose la question : “AppState est-il un state produit (Movi) ou un state fondation ?”. 

4. **Bridge GetIt + Riverpod dans le Controller**

* Le controller dépend de GetIt (`sl<LocalePreferences>()`) au lieu d’injecter via `ref.watch(...)`. C’est pragmatique pour compat, mais ça complique tests et cohérence (deux systèmes de DI). 

5. **`addListener` “compat non-Riverpod”**

* Très utile pour des consumers non-Riverpod (guard), mais c’est une API parallèle à `ref.listen`.
  → à documenter comme “pont legacy” pour éviter usage incontrôlé partout. 

6. **EventBus vs state**

* Le bus d’events est bien séparé (événements ponctuels), mais le risque est que des devs commencent à tout y mettre (“libraryRefreshed” etc.) au lieu de state / usecases. À cadrer. 

---

### Risques (couplage, complexité, testabilité, performances)

1. **Testabilité**

* `AppStateController` s’appuie sur `sl` GetIt, donc en test tu dois configurer GetIt correctement (ou mocker globalement), au lieu de pouvoir injecter via Riverpod.
* Les streams prefs + listeners externes + StreamController connectivité rendent les tests un peu plus “lourds”, mais gérables. 

2. **Risque de divergence de state**

* Les champs “non synchronisés” de `AppState` peuvent devenir faux/obsolètes, alors que l’app lit ailleurs (prefs providers). C’est le risque le plus concret ici. 

3. **Couplage inter-modules**

* `preferredIptvSourceIds` lit `SelectedIptvSourcePreferences` si enregistré : ce “if registered” est un signe de dépendance optionnelle. Ça marche, mais ça cache des états “partiellement init” (surtout au startup). 

4. **Perf**

* Plutôt correct : usage de `select` dans providers dérivés limite les rebuilds.
* Le controller évite les updates inutiles (`if same return;`) → bon. 

---

### Hypothèses de refactor (sans décider)

1. **Clarifier la mission de `AppState`**

* Option A : `AppState` = *runtime app-wide* (locale, theme, connectivité, contexte courant minimal).
* Option B : `AppState` = *source unique* de toutes les prefs globales (incluant accent/audio/subtitles/iptv sync).
  Dans les deux cas, l’objectif est d’éliminer l’ambiguïté “certains champs sont là mais pas utilisés”. 

2. **Sortir les champs “non pilotés” de `AppState`**

* Si tu gardes “prefs direct via providers”, alors retirer `accentColor`, `iptvSyncInterval`, `preferredAudioLanguageCode`, `preferredSubtitleLanguageCode` de `AppState` (ou les alimenter réellement). 

3. **Choisir une stratégie DI**

* À terme : injecter `LocalePreferences` via `ref.watch(...)` au lieu de `sl<>()` dans le controller, ou documenter fermement “core/state utilise GetIt par compat uniquement”.
* La présence du bridge est justifiable, mais doit être assumée explicitement dans la doc “core”. 

4. **Encadrer `addListener`**

* Le garder uniquement pour 1-2 consommateurs (router guard, peut-être startup), et éviter qu’il devienne un pattern général.

5. **Gouvernance de l’EventBus**

* Documenter clairement les cas d’usage : événements “one-shot” non persistants, pas de logique métier durable.

---

### Notes & questions ouvertes

1. **Qui décide de `activeIptvSources` ?**

* Le controller expose `setActiveIptvSources`, mais où est-il appelé (startup ? settings ? iptv sync ?). À croiser avec `core/startup` et `features/iptv`. 

2. **Pourquoi `AppState` contient déjà `iptvSyncInterval` alors que `app_state_provider` lit `IptvSyncPreferences` directement ?**

* C’est une transition prévue (“On pourra migrer plus tard”). OK, mais il faut le noter comme **incohérence temporaire** et décider plus tard de la direction. 

3. **Le “online” est-il un vrai signal réseau ?**

* `setConnectivity(bool)` est manuel. Est-ce alimenté par un service réseau (connectivity_plus) ou par des failures Dio ? À documenter en recoupant `core/network`. 

4. **`preferredIptvSourceIds` dépend d’un `SelectedIptvSourcePreferences` “optionnel”**

* Pourquoi ce service peut ne pas être enregistré ? (platform? tests? ordre init?)
  À recouper avec `core/di` et `core/startup/appStartupProvider`. 

---

Si tu veux, prochain P0 : **`core/di/`** (c’est souvent la clé pour comprendre les ponts GetIt↔Riverpod et les “isRegistered” qu’on voit ici).

## Fiche diagnostic — `lib/src/core/preferences/` 

### But déclaré (ce que le dossier est censé faire)

* Fournir des **préférences locales persistées** (device-local) avec **notifications de changements** (streams broadcast).
* Servir de couche **infrastructure** (dépend de Flutter + `flutter_secure_storage`) et ne pas être importée depuis le `domain/` (mentionné dans le README). 

---

### Ce qu’il fait réellement (d’après le code)

Le dossier contient une mini-“lib” de préférences, toutes basées sur le même pattern :

* **Create async** (`static Future<...> create`) :

  * lit la valeur depuis `FlutterSecureStorage`
  * calcule une valeur initiale (fallback defaults)
  * instancie un `StreamController.broadcast()`
* **Getters sync** (valeur actuelle en mémoire)
* **Stream des changements** + *StreamWithInitial* (yield initial puis changes)
* **Setter async** : écrit dans secure storage puis émet sur le stream
* **dispose()** ferme le stream controller

Les préférences couvertes :

* `LocalePreferences` : `languageCode` (tag type `en-US`) + `themeMode` 
* `SelectedProfilePreferences` : `selected_profile_id` device-local 
* `SelectedIptvSourcePreferences` : `selected_iptv_source_id` device-local 
* `IptvSyncPreferences` : intervalle de sync IPTV (minutes) + sentinel `disabled` 
* `PlayerPreferences` : audio/subtitles lang + `VideoFitMode` (dépend d’un VO feature `VideoFitMode`) 
* `AccentColorPreferences` : accent `Color` sérialisé en hex ARGB 

---

### API publique (classes/services/providers/export principaux)

* Exports via `preferences.dart` :
  `LocalePreferences`, `PlayerPreferences`, `SelectedProfilePreferences`, `SelectedIptvSourcePreferences`, `AccentColorPreferences`, `IptvSyncPreferences` 
* Chaque classe expose :

  * `create(...)`
  * valeur courante (`get ...`)
  * `...Stream` et souvent `...StreamWithInitial`
  * `set...(...)`
  * `dispose()` 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **core/di** : enregistre toutes ces prefs dans GetIt au démarrage (on l’a vu dans `injector.dart`) 
* **core/state** : `AppStateController` dépend directement de `LocalePreferences` (streams theme + language) 
* **core/startup** et/ou **features/welcome** : utilisent `SelectedProfilePreferences` + `SelectedIptvSourcePreferences` pour “auto-open last profile/source” (déjà dans ton flow).
* **features/player** : via `PlayerPreferences` (audio/subtitles/video fit).
* **settings** : probablement via providers `app_state_provider` qui lisent `IptvSyncPreferences` / `AccentColorPreferences`. 

#### De quoi il dépend ?

* `flutter_secure_storage` partout (infra) 
* Flutter (`Color`, `ThemeMode`, `Locale`) 
* **⚠️ Dépendance feature** : `PlayerPreferences` importe `features/player/domain/value_objects/video_fit_mode.dart` 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Core preferences dépend d’une feature (`VideoFitMode`)**

* C’est un couplage inversé : `core/preferences` devrait idéalement être indépendant des features.
* Ici, une préférence “player” ressemble plus à une préférence **feature** qu’une préférence **core**. 

2. **Deux niveaux de “préférences” dans l’architecture**

* Tu as :

  * classes de prefs ici (infra)
  * providers dérivés dans `core/state/app_state_provider.dart` qui exposent ces prefs
  * et `AppState` qui contient déjà des champs proches (accentColor, iptvSyncInterval…) mais pas forcément alimentés.
* Risque : confusion “où est la source de vérité ?” (on l’a déjà noté dans la fiche state).

3. **Beaucoup de logique dupliquée**

* Chaque préférence réimplémente :

  * create/read/normalize
  * stream controllers
  * streamWithInitial
  * dispose
* Le pattern est clean mais répétitif ; le coût d’évolution (ex: ajouter “reset”, “export debug”, “transaction”) se multiplie.

4. **Security storage pour tout**

* `flutter_secure_storage` est très bien pour tokens/identifiants.
* Mais pour `accentColor`, `themeMode`, `iptv_sync_interval`… ce n’est pas nécessairement requis et peut être plus lent / sujet à restrictions sur certaines plateformes.
* Ce point devient important au **startup** car toutes les prefs font des reads async. 

5. **Absence de notion de “namespace user/profile”**

* Tu stockes `selected_profile_id` et `selected_iptv_source_id` en local.
* Mais si “compte global” change (autre email / autre user supabase), ces valeurs pourraient devenir invalides et provoquer fallback/patch ailleurs (ce que fait ton orchestrator).
  → ce n’est pas “mauvais”, mais ça crée une dette : les prefs ne savent pas à quel “user global” elles appartiennent. 

---

### Risques (couplage, complexité, testabilité, performances au startup)

1. **Performance startup**

* Chaque `create()` fait un `storage.read()` async.
* Si tu en crées 6–7 au démarrage en séquence, tu rajoutes de la latence.
* SecureStorage peut être particulièrement coûteux (Keychain/Keystore). 

2. **Testabilité**

* Les classes sont testables mais nécessitent mocker `FlutterSecureStorage` (ou passer un faux storage).
* Dans ton DI, tu instancies souvent `const FlutterSecureStorage()` sans injection explicite => tests doivent override via `initDependencies(secretStore...)` ou overrides GetIt. 

3. **Couplage architecture**

* Le plus gros risque ici : `PlayerPreferences` qui dépend d’une feature. Ça peut entraîner des cycles d’import si un jour `features/player` dépend de `core/preferences` autrement. 

4. **Gestion de lifecycle**

* Chaque prefs a `dispose()` mais on ne voit pas ici qui les dispose. En pratique on les enregistre en singletons GetIt et on ne les dispose probablement jamais.
* Ce n’est pas dramatique, mais ça veut dire : `StreamController` reste vivant tout le runtime, et “dispose” est surtout théorique.

---

### Hypothèses de refactor (sans décider)

1. **Split “core prefs” vs “feature prefs”**

* Garder dans `core/preferences` uniquement ce qui est app-wide neutre :

  * locale + theme
  * peut-être selected profile/source (car c’est un pivot cross-feature)
* Déplacer `PlayerPreferences` vers `features/player/preferences/` ou `features/player/data/preferences/`.
* Déplacer `AccentColorPreferences` vers `core/theme/` ou `features/settings/` selon ownership UX.
* Déplacer `IptvSyncPreferences` vers `features/iptv/` ou `features/settings/` (car c’est une option de feature). 

2. **Créer une base abstraite pour réduire la duplication**

* Exemple (concept) : `SecurePreference<T>` avec :

  * key
  * parse/stringify
  * default value
  * in-memory + broadcast + withInitial
* Puis chaque préférence devient une configuration.
* But : cohérence + moins de boilerplate.

3. **Revoir le backend de stockage**

* `secure_storage` pour secrets (credentials, tokens, ids sensibles)
* `shared_preferences`/Hive pour UI prefs (theme, accent, interval)
* Ce choix est surtout orienté perf + simplicité cross-platform.

4. **Namespacing par user**

* Inclure un “scope key” basé sur `auth.users.id` ou `globalAccountId` :

  * `prefs.<userId>.selected_profile_id`
  * ou stocker un `prefs.current_user_id` et invalider/clear automatiquement les prefs liées si user change.
* Ça éviterait du “réparage” dans startup quand on change de compte global.

---

### Notes & questions ouvertes

1. **Pourquoi `defaultLanguageCode = 'en-US'` ?**

* Tu as un système l10n multi-langues ; tu utilises aussi `ui.PlatformDispatcher.locale` dans DI. L’interaction entre “device locale” et “defaultLanguageCode” doit être claire (priorité).

2. **Quel est le vrai besoin de sécurité pour les keys**

* `selected_profile_id` et `selected_iptv_source_id` sont-ils sensibles ? Si non, secure_storage est surdimensionné.
* Par contre, si ces ids permettent d’accéder à des credentials (ex: id de compte IPTV local), ça peut se justifier.

3. **Dispose**

* Est-ce que tu as un mécanisme de “shutdown/restart” (tu as `app_restart.dart`) qui devrait disposer proprement GetIt/prefs ? Si oui, ça mérite une stratégie. 

4. **“disabledInterval = 365 days”**

* Tu as une valeur sentinelle + string “disabled”, plus back-compat “huge minutes”.
* C’est propre, mais ça montre qu’il y a déjà eu des migrations. À documenter dans la doc finale comme “compat layer”. 

---

Si tu veux, prochain dossier “core” très lié au lancement : **`core/auth/`** (car ton flow OTP, session, et “pas de code au 2e lancement” dépend de comment tu gères la session Supabase + refresh).

## Fiche diagnostic — `core/storage/` 

### But déclaré (ce que le dossier est censé faire)

Centraliser la **persistance locale** (SQLite + Secure Storage), exposer des **repositories** stables (watchlist, history, continue_watching, playlists, cache, IPTV…), et fournir un **module d’enregistrement DI** pour rendre ces services disponibles au reste de l’app.

---

### Ce qu’il fait réellement (d’après le code)

* **SQLite “singleton” + migrations** via `LocalDatabase` (`sqflite` / `sqflite_ffi` desktop) avec :

  * choix de répertoire (Application Support) + **migration** depuis Documents + WAL best-effort + `PRAGMA foreign_keys = ON` 
  * base versionnée (v17) + `onUpgrade` très long (beaucoup de versions + défensif `_ensureColumn/_ensureTable`) 
* **Repositories SQLite** :

  * `ContentCacheRepository` (cache JSON + TTL, write-queue + retry “database locked”) 
  * `WatchlistLocalRepositoryImpl`, `HistoryLocalRepositoryImpl`, `ContinueWatchingLocalRepositoryImpl`, `PlaylistLocalRepository` (CRUD + ordering + outbox sync) 
  * `IptvLocalRepository` : persistance comptes & playlists IPTV + **migration legacy → v2**, recherche SQL, settings visibilité/ordre, cache épisodes, etc. 
* **Secure storage** via `SecureStorageRepository` (JSON encode/decode) 
* **Outbox local-first** `SyncOutboxRepository` (SQLite) utilisé par watchlist/playlists 
* **DI registration** via `StorageModule.register()` :

  * initialise DB (timeout 10s) + logs “startup”
  * en cas d’échec : **fallback in-memory database** (tables “essentielles”) + continue sans crasher 
  * enregistre aussi `CredentialsVault` + `XtreamLookupService` (qui dépend de `IptvLocalRepository` + logger) 

---

### API publique (classes/services/providers/export principaux)

Exposés via `storage.dart` :

* Repos : `IptvLocalRepository`, `ContentCacheRepository`, `SecureStorageRepository`, `PlaylistLocalRepository`, `WatchlistLocalRepository`, `ContinueWatchingLocalRepository`, `HistoryLocalRepository`, `SyncOutboxRepository`
* Services : `CachePolicy`
* Errors : `StorageFailure` (+ Read/Write/Unknown) 
  Hors barrel export mais utilisés : `LocalDatabase`, `StorageModule` 

---

### Dépendances entrantes/sortantes

#### De quoi `core/storage` dépend ?

* Packages : `sqflite`, `sqflite_common_ffi`, `path_provider`, `path`, `flutter_secure_storage`, `clock`, `flutter/widgets` (debugPrint) 
* **Core** : `core/di/di.dart` (service locator `sl`), `core/security/*` (vault), `core/logging/logger.dart` 
* **Shared** : `shared/domain/value_objects/*` (ContentReference, MediaTitle…), `shared/data/services/xtream_lookup_service.dart` (dans `StorageModule`) 
* ⚠️ **Features** : `IptvLocalRepository` importe directement `features/iptv/domain/...` (entities + value objects) 

#### Qui dépend de lui ?

* Potentiellement **la majorité des features** qui ont besoin :

  * watchlist / history / continue_watching / playlists utilisateur
  * IPTV (comptes, playlists, items, settings, episodes)
  * cache de contenu
  * secure storage / credentials

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Violation de frontière “core” ↔ “features”**

   * `core/storage/repositories/iptv_local_repository.dart` dépend de `features/iptv/domain/*` 
     → ton “core” devient **feature-aware**, ce qui complique un refactor global du core (et les tests isolés).
2. **`StorageModule` fait plus que “storage”**

   * enregistre `CredentialsVault` + `XtreamLookupService/XtreamLookup` (qui ressemble à un service “shared”/feature), et dépend du logger 
     → risque de “God module” : *tout ce qui touche vaguement au local finit ici*.
3. **DB schema très large + migrations monolithiques**

   * `LocalDatabase` porte à la fois : chemin, migration de fichiers, PRAGMAs, création et upgrades de toutes les tables 
     → devient difficile à maintenir/relire, difficile à tester, et chaque ajout de table augmente la surface de risque au startup.
4. **Mix “domain objects” et “storage rows”**

   * Ex : `PlaylistLocalRepository` reconstruit des `ContentReference`/`MediaTitle` directement depuis SQLite 
     → couplage “storage ↔ domain mapping” dans le repo (pas forcément mauvais, mais ça rend le repo très “application-specific”).
5. **Incohérences de stratégie “robustesse”**

   * Certains endroits sont “best effort” (WAL, ensureColumn/table, fallback memory, retry locked dans cache) 
   * D’autres sont “straight SQL” sans couche d’erreur uniforme (pas d’usage réel des `StorageFailure` dans les repos).
6. **Performance startup & logs**

   * Beaucoup de `debugPrint('[DEBUG][Startup] ...')` dans la DB et StorageModule 
     → utile en dev, mais risque de bruit en prod (selon config) + ça révèle que des choses lourdes se passent tôt.

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Couplage architectural** : core dépend de feature IPTV → refactor plus cher, séparation domain/data moins claire 
* **Complexité DB** : migrations longues + défensif “ensureColumn/table” peut masquer des problèmes de versioning (on “répare” au runtime) 
* **Testabilité** :

  * `LocalDatabase` singleton global + side effects (file system, platform checks, path_provider) 
  * repos directement sur `sqflite Database` → tests unitaires demandent DB réelle ou doubles
* **Startup** :

  * ouverture DB + potentielle migration de fichiers + `onOpen` + `ensure*` + indexes + etc. 
  * fallback in-memory : risque de comportement “mode dégradé” silencieux si mal monitoré (cloud-only implicite) 
* **Concurrence/locks** :

  * seul `ContentCacheRepository` a une write-queue + retry locked 
  * les autres repos font des écritures directes → potentiellement OK, mais incohérent.

---

### Hypothèses de refactor (sans décider)

Candidats **fusion / split / move / rename** :

1. **Sortir IPTV de `core/storage`**

   * option A : déplacer `IptvLocalRepository` vers `features/iptv/data/local/` (ou `features/iptv/infrastructure/`)
   * option B : garder un “storage” générique en core mais **définir des models storage** propres (DTO/rows) qui n’importent pas `features/*`, puis adapter côté feature.

2. **Scinder `LocalDatabase` en modules**

   * `database/` pourrait contenir :

     * un “DB bootstrap” (path, WAL, openDatabase)
     * des “schema fragments” par domaine (watchlist_schema, iptv_schema, playlists_schema…)
     * une couche migrations plus lisible (ex: classes MigrationVxx)
   * Objectif : rendre les changements de tables **localisés**.

3. **Clarifier le rôle de `StorageModule`**

   * option A : `StorageModule` ne fait QUE storage (DB + repos)
   * option B : renommer en `PersistenceModule` si on assume “local data + vault + lookup”
   * option C : extraire `CredentialsVault` et `XtreamLookupService` vers d’autres modules (security/shared/feature).

4. **Uniformiser stratégie d’erreurs**

   * soit supprimer `StorageFailure` si non utilisé
   * soit l’appliquer réellement (wrappers et mapping d’erreurs) pour donner une API cohérente.

5. **Uniformiser stratégie de concurrence**

   * décider si tous les repos doivent avoir une write-queue/retry locked (ou uniquement ceux “à risque”)
   * alternativement, centraliser les écritures via transactions/batch selon patterns.

---

### Notes & questions ouvertes

* Le fallback in-memory : **quels écrans/features restent fonctionnels** sans DB disque ? Est-ce attendu ou “cache-miss catastrophique masqué” ? 
* `StorageModule` “enregistre tout” : est-ce que ça correspond à ta vision de `core/` (socle neutre) ou c’est devenu un “app layer” ?
* Pourquoi `history`/`continue_watching` n’utilisent pas `SyncOutboxRepository` alors que playlists/watchlist l’utilisent ? (choix produit ou dette ?)
* `IptvLocalRepository` est énorme : est-ce qu’il y a des sous-domaines clairs (accounts, playlists, items, settings, episodes, search) à découper ?
* Les `ensureColumn` défensifs suggèrent des DB “en circulation” avec schémas divergents : est-ce une conséquence d’anciennes versions, ou d’un process de migration pas strict ? 

---

Si tu veux, prochaine étape logique : on fait une **mini-cartographie “imports entrants/sortants”** (qui appelle quel repo + depuis quels features) pour objectiver “qui dépend de quoi”, avant de proposer une structure cible.

## Fiche diagnostic — `lib/src/core/auth/` 

### But déclaré (ce que le dossier est censé faire)

* Fournir une **abstraction d’auth** (domain) indépendante du provider (Supabase).
* Implémenter l’auth Supabase (OTP / password / sign-out) via un repository.
* Exposer des **providers Riverpod** pour refléter l’état d’auth dans l’UI.
* Optionnel : gérer la **déconnexion propre** (nettoyage local) pour éviter les fuites de données entre comptes.

---

### Ce qu’il fait réellement (d’après le code)

1. **AuthRepository + modèles domain**

* `AuthRepository` expose `onAuthStateChange`, `currentSession`, `signInWithOtp`, `verifyOtp`, `signOut` + password login.
* `AuthSession` et `AuthSnapshot` sont des wrappers “domain-friendly” (pas de types Supabase dans le domain). 

2. **Implémentations**

* `SupabaseAuthRepository` :

  * mappe `supabase.auth.onAuthStateChange` → `AuthSnapshot`
  * `currentSession` lit `supabase.auth.currentSession`
  * OTP via `signInWithOtp` + `verifyOTP(type: email)`
  * `signOut()` délègue à Supabase. 
* `StubAuthRepository` :

  * fallback quand Supabase non configuré : stream “unauthenticated” et méthodes qui throw (sauf signOut no-op). 

3. **DI module**

* `AuthModule.register(sl)` :

  * détecte config Supabase (`SupabaseConfig.fromEnvironment.isConfigured`)
  * si non configuré → stub
  * si configuré mais `SupabaseClient` absent → stub (pour éviter crash)
  * sinon enregistre `SupabaseAuthRepository`
  * enregistre aussi `LocalDataCleanupService(db, sl)` (lié au logout). 

4. **UI state via Riverpod**

* `AuthController` (Notifier) :

  * s’abonne à `repo.onAuthStateChange` et met à jour `AuthControllerState(status, userId)`
  * à `build()`, il derive une valeur initiale depuis `repo.currentSession`
  * gère resubscribe si le repo change (hot reload / DI replacement).
* Providers : `authControllerProvider`, `authStatusProvider`, `authUserIdProvider`. 

5. **AuthGate**

* Si Supabase non configuré → laisse passer `child`.
* Sinon :

  * `authenticated` → `child`
  * sinon → écran “OverlaySplash” (pas de vraie page login ici). 

6. **LocalDataCleanupService**

* Service de purge locale lors de sign-out :

  * supprime IPTV accounts via `IptvLocalRepository`
  * delete tables direct SQL: `history`, `playlist_items`, `playlists`, `watchlist`, `continue_watching`, `sync_outbox`
  * clear cache via `ContentCacheRepository.clearType('search'|'settings')`
  * supprime des clés secure storage listées (`selected_profile_id`, `selected_iptv_source_id`, etc.)
  * supprime credentials IPTV via `CredentialsVault`
  * best-effort : catch partout, ne bloque jamais la déconnexion. 

---

### API publique (classes/services/providers/export principaux)

* Domain :

  * `AuthRepository`
  * `AuthStatus`, `AuthSession`, `AuthSnapshot` 
* Data :

  * `SupabaseAuthRepository`
  * `StubAuthRepository` 
* DI :

  * `AuthModule.register(GetIt sl)` 
* Presentation (Riverpod) :

  * `authRepositoryProvider`
  * `AuthController` + `authControllerProvider`
  * `authStatusProvider`, `authUserIdProvider` 
* Widgets :

  * `AuthGate` 
* Services :

  * `LocalDataCleanupService.clearAllLocalData()` 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **core/router** : le `LaunchRedirectGuard` lit `AuthRepository.currentSession` et écoute `onAuthStateChange` (dans ton dump router).
* **UI shell** : `AuthGate` wrap l’`AppShellPage` sur la route `/` (home).
* **features/auth** (OTP page) utilise probablement `AuthRepository` (non inclus ici, mais logique).
* Potentiellement **startup** : selon ton orchestration, la présence d’une session supabase peut changer le flow (pas de code au 2e lancement). 

#### De quoi il dépend ?

* **Supabase** (`supabase_flutter`) côté implémentation + module DI. 
* **core/storage** et **core/security** pour cleanup (db + secure + vault + iptv local repo). 
* **core/di** (GetIt + slProvider) 
* Flutter/Riverpod. 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **AuthGate ne montre pas l’écran de login**

* Le docstring dit “shows OTP login page”, mais le code montre seulement `OverlaySplash()` pour `unknown/unauthenticated`. 
  → incohérence de comportement/documentation. Ça peut expliquer des UX bizarres au lancement (splash infini si non-auth).

2. **Duplication de logique d’auth entre Router Guard et AuthGate**

* Router guard décide déjà `/launch`/`/auth/otp`/`/bootstrap` selon session/état launch. 
* AuthGate décide aussi si on laisse entrer dans shell.
  → deux gates = plus de robustesse, mais risque de “double logique” et flash/redirections contradictoires.

3. **LocalDataCleanupService = grosse responsabilité transverse**

* Il touche : iptv, db tables, cache, secure storage, outbox, vault. 
  Ça ressemble à du “session management” global (plutôt startup/auth/session) plus qu’un simple service auth.

4. **Cleanup service supprime “secure storage keys” en dur**

* La liste de clés recopie celles de `core/preferences` (et d’autres). Si tu renommes une clé, tu dois penser à mettre à jour ici. 
  → risque de drift.

5. **AuthRepository contient password login mais ton flow est OTP**

* Pas grave, mais c’est une API un peu “large” vs besoin actuel (à voir si tu assumes “évolutif” ou si tu veux un contrat plus minimal). 

6. **StubAuthRepository “unauthenticated” mais méthodes throw**

* Si des écrans appellent `signInWithOtp` alors que Supabase n’est pas configuré, ça throw (ok) mais ça doit être géré proprement côté UI. 

---

### Risques (couplage, complexité, testabilité, performances au startup)

1. **Couplage auth ↔ storage**

* Auth “orchestration de session” déclenche un nettoyage très profond des données locales. C’est logique produit, mais couplage fort. 

2. **Testabilité**

* AuthController est testable mais dépend du bridge DI (`slProvider`) et du repo stream.
* LocalDataCleanupService est testable avec une DB mock/fixture, mais il fait des deletes “hardcoded table names” (tests fragiles). 

3. **Perf / UX au logout**

* Cleanup fait potentiellement beaucoup de deletes + loops sur comptes IPTV.
* Comme c’est best-effort sans feedback, un signOut peut paraître instantané mais laisser des données résiduelles si certains deletes échouent.

4. **UX au startup**

* Si l’app est “unauthenticated” et AuthGate rend un splash, tu peux avoir un splash “bloquant” si la navigation vers `/auth/otp` dépend d’un autre composant (router guard).

---

### Hypothèses de refactor (sans décider)

1. **Clarifier la responsabilité du “gate”**

* Option A : Router guard est la seule autorité de routing d’auth (AuthGate devient inutile, ou devient un simple wrapper de “loading overlay” non bloquant).
* Option B : AuthGate est l’autorité UI et le router ne gère que le deep link.
  Aujourd’hui c’est mix.

2. **Rendre AuthGate cohérent avec la doc**

* Soit afficher vraiment `AuthOtpPage` quand unauthenticated
* Soit changer doc/commentaires et renommer en `AuthStatusOverlay` (si l’intention est juste “bloquer l’UI pendant résolution”). 

3. **Déplacer `LocalDataCleanupService`**

* Plutôt dans `core/session/` ou `core/startup/` (ou `core/user_context/`) car c’est “session lifecycle”, pas “auth provider”.
* Ou le transformer en `UserDataResetService` dans storage, et auth ne fait qu’appeler une interface. 

4. **Centraliser la connaissance des clés secure storage**

* Exposer une liste de clés “user-scoped” depuis `core/preferences` ou `SecureStorageRepository` (ex: `UserPreferenceKeys.all`), et cleanup s’appuie dessus.
* Évite les strings dupliquées.

5. **Éventuelle simplification de l’API AuthRepository**

* Si OTP-only pour V1 : séparer `PasswordAuthRepository` ou rendre password login optionnel.
* Sinon, garder comme “contrat futur”.

---

### Notes & questions ouvertes

* Où est déclenché `LocalDataCleanupService.clearAllLocalData()` ? (SignOut flow actuel : AuthController.signOut appelle seulement `repo.signOut()`, pas cleanup). 
  👉 Donc aujourd’hui, **le cleanup est enregistré en DI mais peut ne jamais être appelé** (à vérifier côté UI/settings).
* Comment gères-tu “switch account global” (email différent) ? Idéalement cleanup + reset preferences + reset state.
* Est-ce que tu veux garder un “mode offline / no-supabase” (Stub) en prod, ou c’est seulement dev ?

Si tu veux, je te propose qu’on enchaîne avec **`core/supabase/`** (client provider + error mapper + module), parce que c’est la base de ton flow OTP + profils + sources.

## Fiche diagnostic — `lib/src/core/supabase/` 

### But déclaré (ce que le dossier est censé faire)

* Offrir un **point d’entrée unique** pour Supabase (initialisation + client partagé).
* Garantir que **l’auth et les repositories utilisent exactement le même SupabaseClient** (éviter les “auth OK mais données vides”).
* Fournir un **mapper d’erreurs** Supabase → `Failure` UI-safe.
* Exposer un **provider Riverpod** pour accéder au client sans importer GetIt partout. 

---

### Ce qu’il fait réellement (d’après le code)

1. **Initialisation idempotente de Supabase**

* `SupabaseModule.register(GetIt sl)` :

  * lit `SupabaseConfig.fromEnvironment`
  * si pas configuré → log + return (Supabase “désactivé”, app continue)
  * `ensureValid()` sinon throw (fail-fast config invalide)
  * `Supabase.initialize(url, anonKey)` une seule fois via `_initialized` static
  * enregistre `Supabase.instance.client` dans GetIt en garantissant une **instance unique** (replace si mismatch). 

2. **Accès au client**

* `SupabaseClientProvider` : wrapper qui jette un `StateError` si pas configuré (contrat “tu ne peux pas l’utiliser si Supabase off”). 
* `supabaseClientProvider` (Riverpod) : renvoie `SupabaseClient?` (nullable) :

  * null si pas enregistré
  * null si l’accès throw (ex: init échouée) 

3. **Mapping d’erreurs**

* `mapSupabaseError(Object error)` :

  * `AuthException` : map 401→Unauthorized, 403/permission denied→Forbidden, sinon `ServerFailure(message)`
  * `PostgrestException` : permission denied→Forbidden sinon `ServerFailure(msg)`
  * fallback : `Failure.fromException(code: SUPABASE_UNKNOWN)` 

---

### API publique (classes/services/providers/export principaux)

* `SupabaseModule.register(GetIt sl)` 
* `SupabaseClientProvider` (getter `client`) 
* `supabaseClientProvider` (Provider<SupabaseClient?>) 
* `mapSupabaseError(...)` 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **core/di** appelle `SupabaseModule.register(sl)` au démarrage
* **core/auth** : `AuthModule` dépend de `SupabaseClient` (via GetIt) pour instancier `SupabaseAuthRepository`
* Les repos “Supabase” (profiles, iptv sources, library sync, reporting…) dépendent implicitement de ce client enregistré (vu dans DI).
* Les widgets/services Riverpod qui veulent accéder au client utilisent `supabaseClientProvider`. 

#### De quoi il dépend ?

* `supabase_flutter` 
* `core/config/models/supabase_config.dart` (validation + env) 
* `core/di` uniquement côté providers (slProvider) 
* `core/shared/failure.dart` + `core/network/network_failures.dart` pour mapper vers failures 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Deux manières d’accéder au client**

* `SupabaseClientProvider.client` (throw si pas configuré) vs `supabaseClientProvider` (nullable + swallow exceptions). 
  👉 Ça peut être justifié (strict vs tolerant), mais c’est une **ambiguïté de contrat** : certains composants vont crash, d’autres vont “mode dégradé silencieux”.

2. **Supabase “optionnel” mais pas clairement gouverné**

* `SupabaseModule.register` retourne silencieusement si non configuré. 
* Pourtant, plusieurs parties de l’app semblent “supabase-first” (auth, profils, iptv sources).
  👉 Il manque une règle produit claire : *Supabase est-il obligatoire en prod ?* Si oui, ce “skip” devrait plutôt fail-fast (ou au moins afficher une erreur UX).

3. **`supabaseClientProvider` masque les erreurs d’init**

* Le `catch (_) { return null; }` est très permissif. 
  👉 UX potentielle : écran qui se comporte “comme si Supabase était off” alors que la config est mauvaise ou l’init a crash → plus dur à diagnostiquer.

4. **Mapper d’erreurs : RLS vs codes**

* Le mapping “permission denied” → Forbidden est bon, mais dépend d’un substring. 
  👉 Si Supabase change le message, ou si la langue change, tu perds la catégorisation.

---

### Risques (couplage, complexité, testabilité, performances au startup)

1. **Couplage DI**

* Tu relies Supabase à GetIt et Riverpod (via slProvider). C’est OK, mais ça renforce le mélange DI (on l’a vu dans la fiche `core/di`).

2. **Testabilité**

* `SupabaseModule` utilise un flag static `_initialized` : en tests, si tu exécutes plusieurs suites dans le même process, tu peux avoir des effets de bord (init déjà faite).
* Mais tu as une garde idempotente + GetIt scopes (bon), il faudra juste penser à reset `_initialized` si nécessaire (ou wrapper). 

3. **Perf startup**

* `Supabase.initialize` est un coût au démarrage (réseau pas requis, mais setup SDK). Tu le fais uniquement si configuré et une fois → correct. 

4. **Observabilité**

* Beaucoup de logs debug : top en dev. Mais en prod, il te manque peut-être un “signal” central (ex: Sentry) si init échoue et que `supabaseClientProvider` retourne juste null.

---

### Hypothèses de refactor (sans décider)

1. **Unifier le contrat d’accès au client**

* Choix A (strict) : toujours throw si pas dispo, et gérer l’erreur à un niveau “startup gate” qui affiche un écran explicite.
* Choix B (tolerant) : toujours nullable + “SupabaseUnavailable” typed result, jamais throw.
* Aujourd’hui, tu as les deux.

2. **Créer un état “SupabaseAvailability” explicite**

* Un provider global : `supabaseAvailabilityProvider -> {configured, initialized, error?}`
* Très utile pour ton flow de lancement : tu peux décider proprement “mode offline / mode normal / écran erreur config”.

3. **Mapper erreurs plus structuré**

* Ajouter `statusCode` pour Postgrest (si accessible) et mapper sur 401/403 sans substring autant que possible.
* Garder substring “permission denied” en fallback.

4. **Rendre `SupabaseModule` plus pure DI**

* Sortir les logs debug + sanity ping dans une couche “startup diagnostics” (ou `core/startup`), si tu veux que `core/supabase` reste minimal.

---

### Notes & questions ouvertes

* Supabase est-il **obligatoire** pour Movi en prod ? (vu ton app IPTV + profils + sources, je dirais “oui”, mais ton code autorise “skip”). 
* En cas de config incorrecte (mauvais projet Supabase), tu as des logs explicites (bon). Mais UX : est-ce que l’utilisateur final verra quelque chose ? (actuellement, beaucoup de choses retomberont en null/stub).
* Le “single client rule” est une excellente protection contre un bug réel (auth et repos sur des clients différents). Tu l’as déjà blindé. 

---

Si tu veux, prochain dossier à documenter pour compléter le “socle launch” : **`core/network/`** (interceptors auth/locale + retry + telemetry) parce que ça influence beaucoup les timings et les erreurs pendant le bootstrap.

## Fiche diagnostic — `lib/src/core/network/` 

### But déclaré (ce que le dossier est censé faire)

* Centraliser l’infra réseau de l’app : **Dio configuré**, **interceptors**, **proxy**, et un **exécuteur robuste** pour standardiser :

  * timeouts,
  * retries/backoff,
  * mapping d’erreurs,
  * limitation de concurrence,
  * déduplication “in-flight”,
  * mini cache mémoire. 

---

### Ce qu’il fait réellement (d’après le code)

#### 1) Enregistrement DI réseau (GetIt)

* `NetworkModule.register(...)` :

  * exige `AppConfig` déjà enregistré (sinon `StateError`)
  * construit `HttpClientFactory(...)`
  * remplace (unregister/register) :

    * `Dio`
    * `NetworkExecutor(dio, defaultMaxConcurrent: 12, limiterAcquireTimeout: 10s)`
  * ferme l’ancien Dio (`close(force:true)`) et `dispose()` l’ancien executor. 

#### 2) Construction de Dio + options

* `HttpClientFactory.create()` :

  * `BaseOptions`:

    * `baseUrl` depuis `config.network.restBaseUrl` (peut être vide)
    * timeouts connect/receive/send depuis config
    * headers : `Accept: application/json`, `User-Agent: MOVI/<version> (<env>)`
    * `validateStatus: 2xx only` → **tous les 4xx/5xx deviennent des DioExceptionType.badResponse**
  * `dio_proxy.configureDioProxyFromEnvironment(dio)` (optionnel)
  * ajoute interceptors :

    * `AuthInterceptor` (si `AuthTokenProvider` fourni)
    * `LocaleInterceptor`
    * `RetryInterceptor`
    * `TelemetryInterceptor` (feature flag) 

#### 3) Interceptors

* **AuthInterceptor**

  * ajoute `Authorization` si pas déjà présent
  * en cas de `401` : tente **1 refresh** (`forceRefresh: true`) et rejoue la requête (flag `auth_retry` dans `extra`) 
* **LocaleInterceptor**

  * ajoute `Accept-Language` si dispo 
* **RetryInterceptor**

  * retry automatique (max 3) sur : timeouts/connectionError + status 429 / >=500
  * delay linéaire croissante : `delay * attempt` 
* **TelemetryInterceptor**

  * mesure latence et log si > `thresholdMs` (400ms) 

#### 4) Exécution “haut niveau” via NetworkExecutor

`NetworkExecutor.run<T,R>(...)` ajoute beaucoup de logique :

* **concurrencyKey** : limiteur par upstream (ex “tmdb”, “iptv”) + adaptation dynamique
* **cache mémoire** LRU+TTL (uniquement si `dedupKey` fourni)
* **dédup in-flight** (si `dedupKey`) + `inflightJoinTimeout`
* **retry/backoff** optionnel interne (param `retries`) avec full jitter exponentiel
* **circuit breaker 429** : cooldown 2s
* **garde-fous anti-blocage** :

  * timeout sur acquire limiter + retries acquire
  * timeout sur join inflight
* mapping errors : `mapDioToFailure` (NetworkFailure typé) 

#### 5) Proxy (Dio + HttpOverrides)

* `proxy/dio_proxy_*` : proxy pour Dio via defines `HTTP_PROXY/HTTPS_PROXY/NO_PROXY`
* `proxy/http_overrides_*` : proxy global `HttpOverrides.global` (important pour libs non-Dio comme Supabase/http) 

---

### API publique (classes/services/providers/export principaux)

* `NetworkModule.register({ localeProvider, authTokenProvider })` 
* `HttpClientFactory` 
* `NetworkExecutor` (+ `LimiterStats`) 
* `mapDioToFailure(DioException)` 
* Interceptors :

  * `AuthInterceptor`, `AuthTokenProvider`, `MemoizedTokenProvider`
  * `LocaleInterceptor`
  * `RetryInterceptor`
  * `TelemetryInterceptor` 
* Proxy helpers :

  * `configureDioProxyFromEnvironment`
  * `configureHttpOverridesFromEnvironment` 
* `network.dart` export barrel 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* Toute datasource/repository qui fait du HTTP “maison” (TMDB, etc.) devrait passer par `NetworkExecutor` (le README le recommande). 
* Le bootstrap DI (`core/di`) appelle `NetworkModule.register(...)` (dans ton orchestrateur de startup typiquement).
* Les features `movie/person/tv/search` utilisent TMDB → donc dépendance très probable sur `NetworkExecutor` (via repositories). 

#### De quoi il dépend ?

* `dio`
* `core/config` (`AppConfig` + feature flags + timeouts + baseUrl)
* `core/logging`
* `core/di` (GetIt `sl`)
* `core/shared/failure.dart` via `network_failures.dart` 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Double retry = risque majeur**

* Tu as **RetryInterceptor** (niveau Dio) **ET** un retry loop dans `NetworkExecutor.run` (param `retries`). 
  👉 Si une datasource met `retries>0`, tu peux te retrouver avec des **multiplications de tentatives**, et surtout des timings imprévisibles au startup (et des rafales sur TMDB / IPTV).

2. **Executor très ambitieux pour “core”**

* `NetworkExecutor` mélange :

  * concurrency limiter adaptatif,
  * dédup,
  * cache mémoire,
  * circuit breaker,
  * timeouts anti-hang,
  * logs perf,
  * mapping Failure.

C’est puissant, mais ça devient une “mini-lib” interne. 
👉 Risque : personne n’ose l’utiliser correctement → chaque feature refait “sa sauce”.

3. **Cache mémoire couplé à dedupKey**

* Cache activé seulement si `dedupKey` est fourni. 
  👉 OK, mais ça crée un “piège UX” : si tu oublies `dedupKey` sur les endpoints chauds (home hero, continue watching), tu perds 80% du bénéfice.

4. **`validateStatus` 2xx-only**

* Ça force la logique “4xx/5xx = exception”. 
  👉 C’est cohérent avec un mapping typé, mais attention : certains endpoints utilisent 204/304/empty body. Là tu throws `EmptyResponseFailure` si `data == null` même si HTTP était OK selon validateStatus (si Dio donne `data=null` sur un 204). 

5. **BaseUrl potentiellement vide**

* `baseUrl: ''` si `restBaseUrl` vide. 
  👉 Pour TMDB (full URLs) c’est ok, mais ça permet aussi des requêtes mal formées sans que tu t’en rendes compte. À clarifier : est-ce que tu as réellement un “REST base url” global ?

6. **Proxy infra dans network**

* `http_overrides.dart` est dans `core/network/proxy` mais ce n’est pas Dio ; c’est “transport global”. 
  👉 Ça peut être cohérent (connectivité), mais ça brouille la frontière “network=dio”. À documenter pour ton refactor global.

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Startup perf** : avec `defaultMaxConcurrent: 12` et retries potentiellement doublés, tu peux te créer un “storm” réseau au lancement (surtout si tu lances TMDB + IPTV + Supabase sync en parallèle). 
* **Testabilité** :

  * `NetworkExecutor` contient beaucoup de temps/stopwatch/random jitter → tests flakys si non injecté (horloge/rng).
  * `RetryInterceptor` fait des delays réels.
* **Observabilité** : logs détaillés, mais pas de structure “requestId” stable → débogage multi-appels compliqué.
* **Couplage** : `NetworkExecutor` dépend de `AppLogger` et de failures “core/shared” → ça force ton domaine réseau à connaître les erreurs UI. 

---

### Hypothèses de refactor (sans décider)

1. **Choisir un seul endroit pour le retry**

* Option A : retry uniquement dans `NetworkExecutor` (et `RetryInterceptor` devient off / minimal)
* Option B : retry uniquement dans `RetryInterceptor` (et `NetworkExecutor.retries` interdit/0 par convention) 

2. **Scinder “network infra” vs “network runtime”**

* `core/network/` pourrait devenir :

  * `transport/` (dio factory + interceptors + proxy)
  * `executor/` (NetworkExecutor + cache/dedup/limiters)
  * `failures/` (mapping)
    Aujourd’hui tout est mélangé, ce qui rend le dossier intimidant.

3. **Rendre l’executor plus “library-like” et configurable**

* Injecter `Clock` et `Random` (ou au moins optionnels) pour tests.
* Mettre le cache/dedup derrière des petites interfaces (facile à remplacer).

4. **Clarifier la stratégie cache**

* Documenter une convention globale de `dedupKey` (inclure locale + profile + source IPTV), sinon tu risques des collisions / mauvaises données sur switch profil/source. 

5. **Déplacer `http_overrides`**

* Candidat pour sortir de `network/` vers un `core/connectivity/` ou `core/platform/` parce que ça touche toutes les libs, pas seulement Dio.

---

### Notes & questions ouvertes

* Est-ce que certaines datasources utilisent **directement Dio** au lieu de `NetworkExecutor` ? (si oui, tes garanties cache/dedup/limiters ne s’appliquent pas).
* Utilises-tu `NetworkExecutor.retries` en pratique ? Si oui, tu as probablement déjà le risque “double retry” avec `RetryInterceptor`. 
* Tu as des cas 204/empty body côté TMDB/Supabase ? Si oui, `EmptyResponseFailure` peut créer des faux négatifs. 
* Quelle est la “frontière” : supabase utilise son propre client HTTP → tu relies ça via `HttpOverrides.global` (bien vu). Mais est-ce configuré au startup systématiquement ? (ça dépend plutôt de `main.dart/startup`). 

## Fiche diagnostic — `lib/src/core/error/` 

### But déclaré (ce que le dossier est censé faire)

* Mettre en place une **gestion d’erreurs globale** (catch “le maximum” d’erreurs non gérées) dès le démarrage :

  * erreurs Flutter framework (widgets/render),
  * erreurs engine/platform (plugins, channels),
  * erreurs isolate (uncaught errors).
* Servir de base pour une future **observabilité** (logs structurés, Sentry/Crashlytics), sans devoir modifier tous les modules. 

---

### Ce qu’il fait réellement (d’après le code)

Le dossier contient **un seul fichier** : `global_error_handler.dart` avec une seule fonction `setupGlobalErrorHandling()`.

Cette fonction :

1. **FlutterError.onError**

* Appelle `FlutterError.dumpErrorToConsole(details)` (formatage Flutter en debug)
* Ajoute un `debugPrint` compact + stack si présent. 

2. **PlatformDispatcher.instance.onError**

* Log l’erreur + stack en `debugPrint`
* Retourne `true` (= “handled”) → tente d’empêcher la propagation par défaut (et potentiellement éviter un crash selon contexte). 

3. **Isolate-level errors**

* Crée un `RawReceivePort` stocké globalement (évite GC)
* Parse `(error, stack)` depuis la liste reçue
* Log en `debugPrint`
* Attache le listener à `Isolate.current.addErrorListener(...)`. 

Le tout est **idempotent** via `_initialized` et réutilise `_isolateErrorPort`.

---

### API publique (classes/services/providers/export principaux)

* `setupGlobalErrorHandling()` 

Aucun provider Riverpod, aucune classe/exception custom.

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **`main.dart`** l’appelle (tu l’as montré au début : “global error handling (Flutter / platform / isolates)”).
* Potentiellement tout le runtime, car c’est global (mais dépendance explicite = main). 

#### De quoi il dépend ?

* `dart:isolate`
* `flutter/foundation.dart` (`FlutterError`, `PlatformDispatcher`, `debugPrint`) 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **“Error handling” = uniquement logging**

* Aucun mapping vers ton `Failure`, pas d’intégration à ton `core/logging` (AppLogger), pas de reporting (Sentry/Crashlytics).
* Ça peut être ok si c’est volontairement minimaliste, mais alors il faut le documenter comme “console-only”. 

2. **PlatformDispatcher.onError retourne `true`**

* Tu “handles” toujours les erreurs engine/platform.
* Pour un dev “pro”, c’est discutable : en debug on veut souvent **crasher** (retourner `false`) pour voir le vrai stack dans le debugger.
* En prod, handle=true est ok, mais sans reporting tu peux masquer des crashs importants. 

3. **Isolate listener = isolate courant seulement**

* Tu écoutes `Isolate.current`. Si plus tard tu crées d’autres isolates (download/sync), leurs erreurs ne seront pas catchées par ce listener (sauf ajout explicite). 

4. **Pas de zone (runZonedGuarded)**

* Beaucoup de setups “robustes” encapsulent `runApp` dans `runZonedGuarded` pour attraper certaines async errors non captées autrement.
* Ici, ce n’est pas fait (ou pas dans ce fichier). 

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Risque principal : invisibilité des crashs prod**

  * Tu logs seulement.
  * Sur mobile, les logs ne remontent pas aux utilisateurs/à toi.
  * Donc tu peux “perdre” des erreurs critiques sans le savoir. 

* **Risque secondaire : masquer des erreurs en debug**

  * Le `return true` côté PlatformDispatcher peut empêcher certains comportements de crash/propagation. 

* **Perf** : négligeable (setup une fois).

* **Testabilité** : testable mais peu utile ; c’est global, donc plutôt “integration tests”.

---

### Hypothèses de refactor (sans décider)

1. **Renommer / replacer**

* `core/error/` pourrait devenir `core/observability/` ou `core/crash_reporting/` si tu comptes y mettre :

  * reporting (Sentry, Crashlytics),
  * breadcrumbs (network, startup steps),
  * logs structurés.

2. **Brancher sur ton `core/logging`**

* Au lieu de `debugPrint`, utiliser `AppLogger` (catégorie “error”, “fatal”) avec sanitizer éventuel.

3. **Mode debug vs prod**

* Conditionner `PlatformDispatcher.onError` :

  * debug : `return false` (laisse crash / remonte)
  * release : `return true` + reporting + éventuellement “graceful restart”.

4. **Ajout runZonedGuarded**

* Déporter dans un “bootstrapper” (startup) :

  * `runZonedGuarded(() => runApp(...), (e, s) => log/report)`
* Et garder ce fichier comme “wiring” Flutter/Platform/Isolate.

5. **Gestion isolates multiples**

* Si tu utilises des isolates plus tard : proposer une helper pour attacher un error listener à tout isolate créé (ou wrapper `spawnIsolateWithErrorForwarding`).

---

### Notes & questions ouvertes

* Est-ce que tu utilises déjà `core/logging` pour écrire en fichier (tu as `file_logger.dart`) ? Si oui, ça vaut le coup que `global_error_handler` logue dedans, sinon tu perds l’info sur les devices. 
* Est-ce que tu as un “mode prod” où tu veux **continuer** après une erreur (ex: afficher `launch_error_panel` + bouton restart) ? Si oui, ce fichier doit s’intégrer avec `core/widgets/app_restart.dart` et/ou `startup gate`.
* As-tu `runZonedGuarded` ailleurs (main.dart) ? Si non, c’est un candidat P0 pour améliorer le “socle pro”.

Si tu veux, prochaine fiche utile pour ton “socle launch” : **`core/logging/`** (vu que là tu log seulement en debugPrint, ça croise directement avec l’observabilité).

## Fiche diagnostic — `lib/src/core/logging/` 

### But déclaré (ce que le dossier est censé faire)

* Fournir un **logger applicatif unique** (API stable) utilisable partout (core + features).
* Supporter plusieurs sorties (console, fichier) + options (filtrage, sampling, rate limiting).
* Empêcher les fuites de secrets dans les logs (sanitizer).
* Être **non fatal** (le logging ne doit jamais faire crasher l’app). 

---

### Ce qu’il fait réellement (d’après le code)

#### 1) API de base

* `AppLogger` + `LogLevel` (debug/info/warn/error).
* Helpers `debug/info/warn/error(...)`.
* `LoggerLifecycle.dispose()` pour les loggers qui ont des ressources (fichier/timer). 

#### 2) Adapters

* `ConsoleLogger` :

  * écrit via `debugPrint` (ou printer custom),
  * sanitize message/category/error. 
* `FileLogger` :

  * écrit dans `ApplicationDocumentsDirectory/app.log` (par défaut),
  * **buffer mémoire** (capacité 2000, dropOldest par défaut),
  * flush périodique (500ms),
  * rotation par taille + option rotation journalière + option gzip,
  * `alsoConsole` pour dupliquer en console,
  * init async “best effort” (ne throw jamais) et ne drop pas les logs “early” (buffer). 

#### 3) Wrappers / middlewares

* `LevelFilteringLogger` : min level global + override par catégorie.
* `SamplingLogger` : probabilité par level ou par catégorie (Random interne).
* `RateLimitingLogger` : limite par minute par catégorie + option metrics “dropped/min”. 
* `CategoryLogger` : force une catégorie fixe (wrapper “scoped logger”). 

#### 4) Registration DI + “legacy wrapper”

* `LoggingModule.register()` :

  * construit l’adapter (file ou console) selon `AppConfig.logging`
  * puis enchaîne wrappers : LevelFiltering → Sampling → RateLimiting
  * enregistre `AppLogger` en lazy singleton dans GetIt (`sl`). 
* `LoggingService` :

  * wrapper “legacy” (`init/log/dispose`) qui redirige vers `AppLogger`
  * `init(fileName)` ignoré (compat). 

#### 5) Sanitizer

* `MessageSanitizer` :

  * masque JWT, Bearer tokens, longs hex/base64,
  * masque headers cookie/authorization,
  * masque paires key=value pour clés sensibles (password/token/secret/etc. + extraSensitiveKeys). 

---

### API publique (classes/services/providers/export principaux)

* `logger.dart` : `AppLogger`, `LogLevel`, `LoggerLifecycle` 
* `LoggingModule.register()` / `LoggingModule.dispose()` 
* `LoggingService.init/log/dispose` (compat) 
* Adapters : `ConsoleLogger`, `FileLogger`
* Wrappers : `LevelFilteringLogger`, `SamplingLogger`, `RateLimitingLogger`, `CategoryLogger`
* Sanitizer : `MessageSanitizer` 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **core/network** logge beaucoup (Telemetry, Executor, proxy, etc.) et dépend d’un logger stable.
* **core/storage** utilise `AppLogger` dans `StorageModule.register()` (logs startup).
* Potentiellement tous les features (via `sl<AppLogger>()` ou wrappers).

#### De quoi il dépend ?

* `core/config/models/app_config.dart` (logging_config) 
* `core/di/di.dart` (GetIt `sl`) 
* Flutter (`kIsWeb`, `debugPrint`) + `path_provider` pour FileLogger 
* `dart:io`, `dart:async`, `dart:math`, `gzip` (compression) 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Deux “entry points” : `LoggingModule` vs `LoggingService`**

* `LoggingService` est “legacy”, mais il reste une API publique utilisable.
* Risque : l’équipe (toi) utilise les deux styles → incohérence (catégories, levels, async inutile). 

2. **Ownership/dispose ambigu**

* `LoggingModule.dispose()` dispose le logger global si `LoggerLifecycle`.
* Les wrappers (`LevelFiltering/Sampling/RateLimiting`) implémentent `LoggerLifecycle` mais `dispose()` ne dispose pas inner (volontaire).
* `CategoryLogger` a un flag `disposeInner` (rare). 
  👉 Globalement OK, mais c’est une zone où une mauvaise utilisation peut “leak” le FileLogger (timer/sink).

3. **`FileLogger` : rotation size check sync à chaque log**

* `lengthSync()` à chaque call peut devenir coûteux si tu logges énormément (ex: réseau très bavard). 
  Tu as sampling/rate limiting, mais si mal configurés en debug, ça peut être lourd.

4. **Path des logs**

* `ApplicationDocumentsDirectory` (pas `ApplicationSupportDirectory`) → selon plateformes, ce n’est pas forcément l’endroit “standard” pour logs. 
  (Ça peut être voulu pour faciliter l’accès.)

5. **Sanitization : bon, mais non garanti à 100%**

* Il masque beaucoup, mais si tu passes des objets `error` complexes, c’est converti en string et sanitize (OK), mais pas de “structured fields” (pas de JSON log safe). 

6. **Random dans SamplingLogger**

* `Random()` non injectable → tests potentiellement flakys si tu testes “exactement N logs”. 

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Couplage DI** : logger global via GetIt ; si `AppConfig` pas prêt, `LoggingModule.register()` va tenter `sl<AppConfig>()` (donc ordre de startup important). 
* **Startup** : `FileLogger` init async non bloquante, bon ; mais si beaucoup de logs early, tu peux remplir le buffer rapidement (2000) et perdre des events (dropOldest). 
* **Perf** : gros risque si logs très nombreux + `lengthSync()` + console duplication + stacktraces.
* **Observabilité** : tu as une base solide (file logs + sanitizer), mais `core/error/global_error_handler` n’utilise pas ce logger (actuellement debugPrint).

---

### Hypothèses de refactor (sans décider)

1. **Clarifier une API unique**

* Option A : garder `AppLogger` (recommandé) et **déprécier** `LoggingService` (ou le déplacer hors core/logging).
* Option B : supprimer `LoggingService` quand tu seras prêt (breaking change).

2. **Optimiser `FileLogger` rotation**

* Ne pas faire `lengthSync()` à chaque log :

  * soit compter bytes écrits (approx),
  * soit check size à intervalle (timer), ou toutes les N écritures.

3. **Brancher `core/error` sur `AppLogger`**

* `setupGlobalErrorHandling()` devrait log via `sl<AppLogger>()` si dispo, sinon fallback debugPrint.
* * ajouter un “category: 'fatal'/'flutter'/'isolate'”.

4. **Introduire un “LoggerFactory / scoped loggers”**

* Une helper : `loggerFor('startup')` → `CategoryLogger(sl<AppLogger>(), 'startup')`.
* Évite de répéter `category:` partout.

5. **Structured logging léger**

* Sans faire du JSON complet, tu peux ajouter une convention “key=value” + sanitizer map.
* Tu as déjà `sanitizeMap`, mais pas utilisé par les loggers (il sanitize des strings). 

---

### Notes & questions ouvertes

* Est-ce que tu veux conserver les logs fichier en release ? (privacy + taille + support client).
* Est-ce que tu as besoin d’un “export logs” UI (settings → share) ? Ta base `FileLogger` le permet facilement.
* Ton réseau a déjà un TelemetryInterceptor ; si tu actives file+console, tu risques d’avoir un volume très grand. Les configs `sampling/rate limiting` doivent être pensées “prod vs dev”.

## Fiche diagnostic — `lib/src/core/security/` 

### But déclaré (ce que le dossier est censé faire)

* Fournir une **couche sécurité minimale** et réutilisable :

  * stockage sûr de secrets (vault),
  * chiffrement/déchiffrement des credentials IPTV avant sync cloud (Supabase),
  * compatibilité multi-plateformes (mobile/desktop/web),
  * support test (vault in-memory). 

---

### Ce qu’il fait réellement (d’après le code)

#### 1) Vault abstrait + implémentations

* `CredentialsVault` (interface) : `storePassword/readPassword/removePassword(accountId)` 
* `MemoryCredentialsVault` : implémentation in-memory (tests / plateformes sans secure storage) 
* `SecureCredentialsVault` : implémentation `flutter_secure_storage` avec options platform spécifiques :

  * Android: `encryptedSharedPreferences: true`
  * iOS: `KeychainAccessibility.passcode`
  * macOS: `first_unlock_this_device` + `useDataProtectionKeyChain: true`
  * Web: `dbName: movi_credentials`, `publicKey: MOVI_SECURE_STORAGE`
  * prefix de clé `secret_pw_` 

#### 2) Chiffrement IPTV

* `IptvCredentialsCipher` :

  * génère/stocke une **clé AES-256** par user (`iptv_cipher_key_<userId>`)
  * conserve un **IV legacy** stocké (`iptv_cipher_iv_<userId>`) uniquement pour rétro-compatibilité
  * **v2 recommandé** : AES-256-CBC avec IV aléatoire par message, format `"v2:" + base64(iv||ciphertext)`
  * déchiffrement :

    * si prefix `v2:` → unpack iv + cipherBytes
    * sinon → legacy v1 (IV fixe) via `_legacyIv`
  * peut chiffrer/déchiffrer un `IptvCredentialsPayload(username,password)` via JSON. 

---

### API publique (classes/services/providers/export principaux)

* `CredentialsVault` + `CredentialsVaultException` 
* `MemoryCredentialsVault` 
* `SecureCredentialsVault` 
* `IptvCredentialsCipher` + `IptvCredentialsPayload` 

*(Pas de module DI dans ce dossier ; l’enregistrement se fait ailleurs : `core/storage/storage_module.dart` enregistre un `CredentialsVault`.)*

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* **core/storage** :

  * `StorageModule.register()` enregistre `CredentialsVault` et l’utilise pour `XtreamLookupService` et/ou purge credentials (via `CredentialsVault`).
* **core/auth** :

  * `LocalDataCleanupService` dépend de `CredentialsVault` et supprime les secrets IPTV lors du logout.
* **features/profile (providers)** :

  * tu as `iptv_cipher_provider.dart` dans profile/presentation (vu dans ton arbre), donc le cipher est probablement initialisé “par user/profile”. 

#### De quoi il dépend ?

* `flutter_secure_storage` (SecureCredentialsVault) 
* `encrypt` package (AES CBC) 
* `dart:convert`, `dart:math`, `dart:typed_data` 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Le vault s’appelle “password”**

* L’API est `storePassword/readPassword/removePassword(accountId)` et la clé est prefixée `secret_pw_`. 
  👉 Dans les faits, tu stockes :

  * des mots de passe IPTV
  * une clé AES (`iptv_cipher_key_...`) et IV legacy (`iptv_cipher_iv_...`)
  * peut-être d’autres secrets.

Ça marche, mais le naming “password” peut créer de la confusion (ce n’est pas toujours un password). Un pro voudrait plutôt `storeSecret/readSecret/removeSecret`.

2. **AES-CBC sans authentification**

* Ton v2 améliore l’IV (aléatoire) mais reste en CBC sans MAC/AEAD : ça ne garantit pas l’intégrité (risque de tampering si un attaquant modifie le ciphertext en DB). 
  Pour ton use-case (credentials IPTV stockés côté Supabase), ce n’est pas forcément critique *si* tu considères Supabase comme “stockage non hostile” et que l’objectif est surtout de ne pas stocker en clair. Mais c’est un point “security pro”.

3. **Gestion “userId” dans le cipher**

* `initialize(userId)` stocke `_userId` et associe la clé à `userId`. 
  👉 Si tu changes de compte global, ou si plusieurs users co-existent, il faut être très clair :

  * qui appelle initialize ?
  * quand on rotate / deleteKey ?
  * quelle portée : “auth user id supabase” ou “profile id movi” ?

4. **Rétro-compat (v1) permanente**

* Tu conserves un IV legacy et le stockes si absent. 
  👉 Tant que v1 existe, tu gardes une dette de sécurité (IV fixe). Il faudra un plan de migration : “à la prochaine sync, re-encrypt en v2”.

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Couplage** : `IptvCredentialsCipher` dépend d’un `CredentialsVault` (bien), mais l’endroit où tu l’initialises (probablement profile providers) va influencer le flow de lancement.
* **Testabilité** : bonne (MemoryCredentialsVault facilite). 
* **Perf startup** : légère (lecture secure storage key+iv). Mais si tu initialises pour chaque profil au démarrage, ça devient coûteux.
* **Sécurité** :

  * CBC sans authentification
  * key stockée localement (normal) mais si un attaquant a accès device + DB supabase, il peut tout déchiffrer (c’est attendu : security “at rest on server” plutôt que “zero knowledge”). 

---

### Hypothèses de refactor (sans décider)

1. **Renommer / clarifier l’API du vault**

* `CredentialsVault` → `SecretsVault`
* `storePassword` → `writeSecret`, etc.
* Et changer le prefix `secret_pw_` → `secret_`. 

2. **Déplacer le chiffrement IPTV hors “core/security”**

* Option A : garder `vault` en core/security (vraiment transversal)
* Option B : déplacer `IptvCredentialsCipher` vers `features/iptv/application/services/` (ou `core/iptv_security/`) car c’est très spécifique IPTV.
  Aujourd’hui, `core/security` contient déjà un élément feature-ish (iptv cipher).

3. **Passer à un mode AEAD**

* Si le package le permet simplement : AES-GCM ou ChaCha20-Poly1305 (intégrité + confidentialité).
* Garder déchiffrement legacy CBC pour migration.

4. **Ajouter une stratégie de rotation/migration**

* Quand on lit un ciphertext legacy (sans `v2:`), après déchiffrement → re-chiffrer en v2 et re-sauver côté Supabase (si possible au moment où tu touches la donnée).
  Ça efface progressivement v1.

5. **Clarifier la “scope key”**

* Documenter : la clé est par `supabaseUserId` (global account) ou par “profile movi” ?
* Si plusieurs profils dans un même compte, généralement la clé devrait être **par compte global**, pas par profil (sinon duplication + complexité).

---

### Notes & questions ouvertes

* Les credentials IPTV chiffrés sont stockés **où** exactement ? (dans Supabase sources, ou dans local DB, ou les deux).
* Lors du logout, tu supprimes `selected_profile_id` et `selected_iptv_source_id` + tu clear des tables + tu removes secrets : très bien, mais est-ce que tu appelles aussi `IptvCredentialsCipher.deleteKey()` quelque part ? (sinon tu gardes key/iv en secure storage).
* Sur Web, `flutter_secure_storage` utilise un mécanisme basé sur `publicKey`. Est-ce acceptable pour ton modèle de menace ? (probablement oui vu l’objectif “obfuscation + éviter clair”, mais à noter).

Si tu veux, prochaine fiche “core” critique pour le lancement : **`core/config/`** (parce que supabase/network/logging dépendent fortement de la config, et l’ordre d’initialisation DI est souvent la source des soucis au startup).

## Fiche diagnostic — `lib/src/core/config/` 

### But déclaré (ce que le dossier est censé faire)

* Définir **la configuration runtime** de l’app (flavor/env, endpoints réseau, feature flags, metadata, logging).
* Sélectionner l’environnement actif via **dart-define** ou fallback intelligent.
* Exposer la config via **Riverpod** (providers) et/ou via **service locator** (GetIt).
* Éventuellement résoudre des secrets au runtime (TMDB key) via un `SecretStore`. 

---

### Ce qu’il fait réellement (d’après le code)

#### 1) Sélection d’environnement (compile-time → runtime)

* `EnvironmentLoader` choisit `AppEnvironment` selon :

  1. override param,
  2. defines `APP_ENV` / `FLUTTER_APP_ENV`,
  3. fallback selon plateforme + release (iOS => dev, sinon release => prod, sinon dev). 
* `dev_environment.dart` construit les flavors dev/staging/prod :

  * endpoints (rest/image),
  * timeouts,
  * feature flags par défaut,
  * metadata (version/build),
  * tentative de résolution TMDB via `--dart-define` (générique + par env). 

#### 2) Assemblage AppConfig

* `AppConfigFactory.build()` :

  * TMDB key: priorité au flavor (dart-define) ; si manquante et `requireTmdbKey=false` alors tentative via `SecretStore.read('TMDB_API_KEY')`.
  * compose `AppConfig(environment, network, flags, metadata, logging, requireTmdbKey)`
  * `LoggingConfig` est déterminé par `_defaultLoggingFor(flavor.environment)` puis `validate()`, puis `config.ensureValid()`. 
* `registerConfig()` :

  * optionnellement enregistre dans GetIt (`sl`) : `SecretStore`, `EnvironmentFlavor`, `AppConfig`, `FeatureFlags`. 

#### 3) Exposition via Riverpod

* `appConfigProvider` lit d’abord un fallback `sl` si présent (via `slProvider`), sinon throw.
* Providers dérivés : `environmentProvider`, `featureFlagsProvider`, `networkEndpointsProvider`, `appMetadataProvider`. 
* `overrides.dart` génère des overrides pour tests/stories. 

#### 4) SecretStore (runtime secrets)

* `SecretStore` (IO) :

  * cache mémoire,
  * tente `Platform.environment`,
  * puis lit un `.env` en remontant plusieurs dossiers (cwd + script dir), cache TTL 5 min,
  * peut aussi écrire (persist) dans `.env`. 
* `SecretStore` (Web) :

  * uniquement cache mémoire (pas d’IO). 

#### 5) Config Supabase séparée

* `SupabaseConfig.fromEnvironment` lit `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_PROJECT_REF` via dart-define.
* `ensureValid()` fait un check URL/key + mismatch project ref. 

---

### API publique (classes/services/providers/export principaux)

* Barrel `config.dart` exporte : `AppConfig`, `Environment*`, `FeatureFlags`, `NetworkEndpoints`, `LoggingConfig`, `SupabaseConfig`, `EnvironmentLoader`, `SecretStore`, providers/overrides. 
* Fonctions : `loadAppConfig`, `registerConfig`, `registerEnvironmentLoader`. 
* Providers : `appConfigProvider`, `environmentProvider`, `featureFlagsProvider`, `networkEndpointsProvider`, `appMetadataProvider`, `createConfigOverrides(...)`. 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* `core/logging` dépend de `AppConfig.logging` pour choisir file/console, sampling, rate limits. 
* `core/network` dépend de `NetworkEndpoints` (base urls, timeouts, tmdb host/version/key). 
* `core/supabase` dépend de `SupabaseConfig` (et probablement de `EnvironmentFlavor`/`AppConfig`). 
* Beaucoup de features lisent `featureFlagsProvider` pour toggles (home remote, hero, telemetry…). 

#### De quoi il dépend ?

* `core/di` (`sl`, `slProvider`) pour le fallback GetIt + registerConfig. 
* `core/logging/logger.dart` juste pour `LogLevel` dans `LoggingConfig` (petit couplage cross-core). 
* Flutter foundation (`kIsWeb`, `defaultTargetPlatform`, `kReleaseMode`). 
* Riverpod. 
* IO uniquement dans `SecretStoreIO` (dart:io). 

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Dual system: GetIt + Riverpod (fallback)**

* `appConfigProvider` va chercher dans `sl` si pas override Riverpod. 
  👉 Ça marche, mais ça crée un “deuxième chemin” d’initialisation :

  * soit tu relies tout à ProviderScope overrides,
  * soit tu relies tout à GetIt.

Un pro choisit généralement **une source of truth** (ou alors documente strictement l’ordre + les règles).

2. **Couplage config ↔ logging**

* `LoggingConfig` dépend de `LogLevel` dans `core/logging`. 
  👉 Du coup `core/config` n’est plus “le plus bas niveau”. C’est léger, mais ça casse l’idée “config = ultra-fondation”.

3. **SecretStore est “trop puissant” pour une app mobile**

* Lire `.env` en remontant les dossiers + écrire `.env`… 
  👉 Utile en dev desktop, mais sur mobile c’est rare. Risque : complexité inutile + comportements imprévus si l’app tourne sur desktop et trouve un `.env` inattendu.

4. **Env loader + dev_environment.dart portent des “opinions produit”**

* Ex: fallback iOS → dev, endpoints dev/staging/prod hardcodés, flags par env. 
  👉 C’est normal, mais ça “mélange” : *infrastructure config* + *politique produit* (quels flags en prod). Pas grave, mais à assumer.

5. **SupabaseConfig est dans config, mais pas intégré à AppConfig**

* `AppConfig` contient network/flags/metadata/logging, mais pas `SupabaseConfig`. 
  👉 Résultat : tu as deux systèmes de config parallèles :

  * Supabase via dart-define direct,
  * le reste via Flavor → AppConfig.

6. **Validation**

* `AppConfig` a assert (debug) + `ensureValid()` runtime, très bien. 
  Mais `NetworkEndpoints` a des helpers `isRestBaseUrlValid` etc. qui ne sont pas utilisés dans `ensureValid()`.

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Ordre de boot fragile** :

  * si `LoggingModule.register()` lit `sl<AppConfig>()`, il faut que `registerConfig()` ait tourné avant. 
* **Testabilité**

  * Bonne si tu utilises `createConfigOverrides()` Riverpod.
  * Mais moyenne si tu relies des tests à GetIt (global mutable).
* **Web**

  * `EnvironmentLoader` optimise les defines “pré-calculées”, bon. 
* **Sécurité**

  * `SecretStore` peut charger des secrets depuis `.env` en clair (en dev ok). Risque si par erreur ce chemin est utilisé en prod desktop.
* **Complexité**

  * “Deux sources de vérité + secret store + fallback resolver” = beaucoup de chemins de configuration à documenter.

---

### Hypothèses de refactor (sans décider)

1. **Trancher Riverpod vs GetIt pour la config**

* Option A (pro Riverpod) : config fournie par `ProviderScope(overrides: createConfigOverrides(config))` et GetIt ne sert pas pour config.
* Option B (pro GetIt) : `AppConfig` uniquement via `sl`, et Riverpod ne fait que lire `sl` (mais alors l’override Riverpod devient secondaire).

2. **Découpler `LoggingConfig` de `core/logging`**

* Remplacer `LogLevel` par un enum propre à config (ou un int) et mapper dans logging.
* Ou déplacer `LogLevel` dans un sous-dossier “foundation” commun.

3. **Intégrer SupabaseConfig dans AppConfig**

* AppConfig pourrait contenir `supabase: SupabaseConfig` → une seule config runtime complète.
* Ça clarifie les dépendances (supabase module lit `appConfig.supabase`).

4. **SecretStore : scoper et simplifier**

* Le renommer `DevSecretStore` ou `RuntimeSecretResolver`.
* En prod : uniquement compile-time defines (pas de `.env`).
* Ou le déplacer hors core/config (dans tooling/dev).

5. **Env endpoints & flags : externaliser**

* Mettre endpoints/flags dans des fichiers par flavor (déjà le cas) mais mieux structurer :

  * `flavors/dev.dart`, `flavors/staging.dart`, `flavors/prod.dart` au lieu d’un `dev_environment.dart` fourre-tout.

6. **Validation plus cohérente**

* Faire `AppConfig.ensureValid()` vérifier aussi :

  * `network.isRestBaseUrlValid` / `isImageBaseUrlValid`,
  * timeouts > 0,
  * supabase isConfigured (si intégré).

---

### Notes & questions ouvertes

* Tu veux que **TMDB key** soit obligatoire en prod ? (actuellement `requireTmdbKey` default true et assert fail fast). 
* Pourquoi fallback iOS → dev ? (choix volontaire pour TestFlight/debug ?) 
* Tu préfères une app “pure mobile” ou tu assumes un vrai support desktop ? (car `SecretStoreIO` + `.env` + Platform.environment sentent le desktop/dev). 
* Est-ce que tu veux un écran “Debug config” (afficher env, flags, endpoints masqués) ? Ton `toString()` masque déjà la TMDB key et la supabase anon key est masquée dans `toString()`. 

## Fiche diagnostic — `lib/src/core/theme/` 

### But déclaré (ce que le dossier est censé faire)

* Centraliser l’**identité visuelle Movi** (couleurs, thèmes clair/sombre).
* Fournir un `ThemeData` cohérent (Material 3) avec une **couleur d’accent** potentiellement dynamique.
* Éviter les divergences de styles entre features (boutons, inputs, cards, etc.). 

---

### Ce qu’il fait réellement (d’après le code)

#### 1) Palette “AppColors”

* Définit une couleur d’accent par défaut (`0xFF2160AB`).
* Définit des couleurs de fond/surface/texte séparées pour dark/light (très simple, sans niveaux multiples). 

#### 2) `AppTheme` construit un ThemeData complet

* `useMaterial3: true`, avec `ColorScheme.fromSeed(...)` puis `copyWith(...)` pour réinjecter tes palettes Movi.
* Désactive volontairement les effets de splash/hover/focus (NoSplash + transparent). 
* Personnalise des thèmes composants :

  * AppBar
  * Card
  * ListTile
  * Chip
  * InputDecoration (TextField)
  * IconTheme
  * Filled/Elevated/TextButton (style principal cohérent)
  * Divider
  * Checkbox
  * SnackBar
* Construit un `TextTheme` via `Typography.whiteMountainView / blackMountainView` puis override tailles/weights/couleurs. 

#### 3) Barrel `theme.dart`

* Export simple des deux fichiers. 

---

### API publique (classes/services/providers/export principaux)

* `AppColors` (palette statique) 
* `AppTheme.dark({Color? accentColor})`
* `AppTheme.light({Color? accentColor})` 
* `theme.dart` (exports) 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* `src/app.dart` (ou app root) utilise forcément `ThemeData`.
* Les widgets core (`movi_primary_button`, cards, pills, etc.) s’appuient implicitement sur les `Theme.of(context)` values.
* Les features qui stylent des composants Material se basent dessus (ListTile, SnackBar, TextField etc.). 

#### De quoi il dépend ?

* Flutter `material.dart` uniquement. 
  ✅ Bon point : **pas** de dépendance DI, config, prefs, etc.

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Commentaire “Montserrat” mais pas de GoogleFonts**

* Le code dit “TextTheme basée sur Montserrat”, mais en réalité il prend `Typography.*MountainView` et ne set aucune font family. 
  👉 Incohérence doc / réalité. Et dans ton `main.dart` tu imports `google_fonts` (vu précédemment). Donc soit :
* tu voulais réellement Montserrat via GoogleFonts,
* soit tu as changé d’avis et le commentaire est resté.

2. **Désactivation globale des splash/hover**

* Pour une esthétique “TV/ciné”, ok.
* Mais sur mobile, ça peut nuire au feedback tactile (UX : l’utilisateur ne sait pas si ça a cliqué). 
  👉 Ça devrait peut-être être une décision “par plateforme” (mobile vs TV) ou “par composant” (boutons principaux gardent un feedback).

3. **Palette trop “plate”**

* Tu as background/surface/surfaceVariant mais pas de niveaux (surfaceContainerLow/High etc.) sauf en ColorScheme copyWith (tu remplis `surfaceContainerHigh/Highest`).
* Ça peut suffire, mais plus l’app grossit, plus tu vas vouloir une hiérarchie (ex: 6 niveaux de surface). 

4. **Couleur d’accent dynamique : pas d’intégration prefs**

* `accentColor` est paramétrable, mais il n’y a aucun provider/bridge avec `core/preferences/accent_color_preferences.dart` (que tu as).
  👉 Donc soit c’est géré ailleurs, soit c’est incomplet.

5. **Boutons: `_primaryButtonStyle` utilise `FilledButton.styleFrom` même pour ElevatedButton**

* Tu appliques le même style pour Filled et Elevated (cohérent visuellement), mais ça détourne l’intention Material (elevation/tonal). C’est un choix produit, juste à assumer. 

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Couplage** : très faible (excellent). 
* **Testabilité** : très bonne (pure functions).
* **Perf** : négligeable.
* **Risque UX** : absence de feedback (NoSplash) peut faire “app non réactive” selon pages.

---

### Hypothèses de refactor (sans décider)

1. **Rendre la typo cohérente**

* Option A : réellement appliquer Montserrat via `GoogleFonts.montserratTextTheme(...)` (tu l’as déjà en dépendance ailleurs).
* Option B : supprimer la mention “Montserrat” et accepter Typography par défaut.
* Option C : “Font config” via `core/preferences` (mais attention, ça devient plus complexe).

2. **Décision NoSplash par plateforme**

* TV : NoSplash ok.
* Mobile : conserver ripple sur certains widgets (ou au minimum sur boutons) via `ThemeData.splashFactory` conditionnel ou via `InkWell` custom.

3. **Extraire des “tokens” UI**

* Quand tu vas scaler, tu peux introduire un fichier `theme_tokens.dart` :

  * radii (16, stadium),
  * spacing,
  * elevations,
  * durations.
    (Tu as déjà `core/utils/app_spacing.dart`, donc à harmoniser.)

4. **Brancher accent color sur prefs**

* Un provider `accentColorProvider` qui lit `AccentColorPreferences`.
* `AppTheme.light/dark(accentColor: ref.watch(accentColorProvider))`.

5. **Séparer “ColorScheme builder” et “Component themes”**

* Aujourd’hui `AppTheme._buildTheme` fait tout.
  Tu pourrais split :

  * `buildColorScheme()`
  * `buildTextTheme()`
  * `buildComponentThemes()`
    pour rendre les diff plus simples, et éviter de faire grossir le fichier.

---

### Notes & questions ouvertes

* Tu veux un style différent “TV layout” vs “mobile layout” ? (tu as un dossier `features/shell/...tv_layout`).
* Est-ce que l’accent color est vraiment modifiable par l’utilisateur (prefs), ou c’est une future feature ?
* Est-ce que tu veux supporter “OLED true black” sur TV ? (actuellement darkBackground = 20,20,20, donc pas full black). 

## Fiche diagnostic — `lib/src/core/responsive/` 

### But déclaré (ce que le dossier est censé faire)

* Offrir une **détection centralisée du type d’écran** (mobile/tablet/desktop/tv) et un moyen simple d’adapter l’UI.
* Être **pure & testable** côté “résolution” (sans dépendances Flutter), et **facile à consommer** côté UI (BuildContext helpers + widget wrapper). 

---

### Ce qu’il fait réellement (d’après le code)

#### 1) Résolution du type d’écran (métier “pure”)

* `ScreenTypeResolver.resolve(width, height)` :

  * calcule `aspectRatio = width/height`
  * si `width > Breakpoints.desktopMax` ET `aspectRatio >= 16/9` → `ScreenType.tv`
  * sinon si `width > tabletMax` → `desktop`
  * sinon si `width > mobileMax` → `tablet`
  * sinon → `mobile` 

✅ Point fort : logique isolée, testable.

#### 2) Widget provider de contexte

* `ResponsiveLayout` :

  * `LayoutBuilder` lit `constraints.maxWidth/ maxHeight`
  * résout `screenType`
  * choisit un builder spécifique (mobile/tablet/desktop/tv) ou fallback `child`
  * expose le `screenType` via un `InheritedWidget` privé (`_ResponsiveLayoutData`) accessible via `ResponsiveLayout.of(context)` 

#### 3) Ergonomie côté UI

* Extension `ResponsiveContext` :

  * `context.screenType`, `context.isMobile` etc.
  * helper `context.responsive<T>(mobile:..., tablet:..., desktop:..., tv:...)` 

#### 4) Barrel d’exports

* `responsive.dart` exporte domain/application/presentation. 

---

### API publique (classes/services/providers/export principaux)

* `Breakpoints` 
* `ScreenType` 
* `ScreenTypeResolver` (+ `instance`) 
* `ResponsiveLayout` + `ResponsiveLayout.of(context)` 
* `ResponsiveContext` extension + `responsive<T>()` 
* `responsive.dart` (exports) 

---

### Dépendances entrantes/sortantes

#### Qui dépend de lui ?

* Toute UI “layout-aware” : `features/shell` (mobile/large/tv layouts), `home` (home_mobile_layout/home_desktop_layout), etc.
  Même si ce n’est pas listé ici, c’est clairement son usage cible. 

#### De quoi il dépend ?

* Très peu :

  * Flutter `material.dart` uniquement dans presentation (ResponsiveLayout + extension context) 
  * Domain/application ne dépend que de classes internes (breakpoints, enum). 

✅ Couplage ultra faible = bon “core”.

---

### Points de friction (doublons, responsabilités mélangées, “feature-like”)

1. **Détection TV basée sur `width > 1920`**

* `desktopMax = 1920` puis TV = “plus large que 1920 + aspect >=16/9”. 
  👉 Sur beaucoup de TV Android / box, le layout Flutter peut être 1920 exactement (ou 1280/720). Résultat : “TV” ne sera jamais détecté → tu tomberas en desktop.

2. **Breakpoints “pixel logiques” vs devicePixelRatio**

* Tu utilises `constraints.maxWidth` (logical px). C’est correct pour Flutter, mais ça implique que tes thresholds doivent être calibrés en logical px, pas en “résolution réelle”.
  👉 À documenter : sinon tu te demandes pourquoi une 4K n’est pas “tv”.

3. **Aspect ratio seul ne suffit pas**

* Ultra-wide monitor desktop (21:9) + width > 1920 => ratio >= 16/9 est vrai → détecté “tv” alors que c’est desktop. 
  👉 Si tu veux “TV” au sens “10-foot UI”, il faut souvent un autre signal (platform, input device, mode TV).

4. **`ResponsiveLayout.of` assert-only**

* En release, si `ResponsiveLayout` n’est pas dans l’arbre et que quelqu’un appelle `context.screenType`, tu peux te retrouver avec un NPE ou un crash (assert non exécuté). 
  👉 Pour un core “pro”, on veut soit :
* un fallback (ex: mobile), soit
* une erreur claire aussi en release.

5. **Dossier “responsive” fait peu**

* Il est clean, mais minimal. La question : est-ce que ça mérite un dossier core complet ? Oui, si tu standardises l’usage partout et évites les checks MediaQuery dispersés.

---

### Risques (couplage, complexité, testabilité, performances au startup)

* **Couplage** : faible (excellent). 
* **Testabilité** : très bonne pour `ScreenTypeResolver`.
* **Perf** : négligeable (calcul simple à chaque rebuild LayoutBuilder).
* **Risque UX** : mauvaise classification TV/desktop (cf seuils) → mauvais layout au lancement sur TV/box.

---

### Hypothèses de refactor (sans décider)

1. **Revoir la détection TV**

* Option A : TV = `defaultTargetPlatform == android` + “device type”/window size + maybe input
* Option B : TV = `aspect >= 16/9` + largeur >= 1200 (ou >= 1024) **et** “mode TV” dans settings
* Option C : TV déduite via `features/performance/device_capabilities` (tu as déjà ce module !) : ça peut devenir la source de vérité “isTvDevice”.

2. **Breakpoints plus réalistes**

* Ajuster `desktopMax` (1920 est une valeur “resolution” plus que “breakpoint UI”).
* Convention Flutter souvent utilisée :

  * mobile < 600
  * tablet 600–1024
  * desktop > 1024
    … et TV géré séparément.

3. **Sécuriser `ResponsiveLayout.of`**

* Retourner `mobile` si absent (et log warn), au lieu d’un crash.
* Ou exposer une méthode “tryOf(context)” + garder `of` strict.

4. **Éviter l’effet “screenType change trop souvent”**

* Si tu as du split view / resizing (desktop), ton inherited widget notifie à chaque change.
* Possible d’ajouter une “hysteresis” (zone tampon) pour éviter de switch tablet/desktop au pixel près.

---

### Notes & questions ouvertes

* Quelle est ta définition de “TV” ? (10-foot UI, navigation D-pad/remote, density, overscan) — ton code actuel le définit seulement par taille + ratio. 
* Tu veux que les TV Android (1920x1080 logical) soient classées TV ? Si oui, ton `width > 1920` doit changer.
* Est-ce que `features/shell` décide déjà du layout TV autrement (route/flag/prefs) ? Si oui, ce module peut devenir redondant ou au contraire, doit devenir la source unique.


# Cartographie du codebase

## Objectif

Ce document donne une vue de travail fiable du depot `Movi`.

Il sert a :

- comprendre rapidement ou se trouve chaque responsabilite ;
- identifier les vrais points d'entree du runtime ;
- savoir quels dossiers lire en premier selon le type de changement ;
- reperer les zones sensibles et les incoherences structurelles.

## Contexte

Etat observe le 17 mars 2026.

Cette cartographie decrit l'etat reel du depot, pas une architecture ideale theorique.

---

## Vue racine

Elements importants a la racine :

- [`lib/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib)
  Code Flutter principal.
- [`assets/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/assets)
  Assets runtime et branding.
- [`docs/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs)
  Documentation active du projet.
- [`android/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android)
  Plateforme Android supportee.
- [`ios/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/ios)
  Plateforme iOS supportee conditionnellement.
- [`windows/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/windows)
  Plateforme Windows supportee pour le dev local.
- [`tool/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/tool)
  Outil Dart auxiliaire versionne, actuellement [`gen_l10n.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/tool/gen_l10n.dart).
- [`pubspec.yaml`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml)
  Socle des dependances, assets et metadata projet.
- [`analysis_options.yaml`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/analysis_options.yaml)
  Lints et exclusions d'analyse.
- [`codemagic.yaml`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml)
  Base CI/CD.

Constat important :

- il n'existe pas de dossier `test/` dans l'etat courant du projet.

---

## Points d'entree runtime

Ordre de lecture recommande pour comprendre le demarrage :

1. [`main.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
2. [`app_startup_gate.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_gate.dart)
3. [`app_startup_provider.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)
4. [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)
5. [`app.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/app.dart)
6. [`app_router.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_router.dart)
7. [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart)
8. [`app_shell_page.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/shell/presentation/pages/app_shell_page.dart)

Resume du flux :

- `main()` initialise Flutter, MediaKit, les overrides reseau et le handling global d'erreurs
- `AppStartupGate` bloque le rendu tant que le bootstrap n'est pas termine
- `appStartupProvider` charge l'environnement, construit la config et initialise GetIt
- `MyApp` branche le theme, la locale et le routeur
- `GoRouter` delegue les redirections au `LaunchRedirectGuard`
- `AppShellPage` devient la coquille principale des onglets Home / Search / Library / Settings

Implication architecture :

- le projet n'est pas purement Riverpod
- le runtime repose sur un mix :
  - Riverpod pour l'etat et plusieurs providers UI
  - GetIt pour l'infrastructure et une partie des services partages
  - GoRouter pour les transitions d'etat applicatif visibles

---

## Structure de `lib/`

Arborescence principale :

```text
lib/
  main.dart
  l10n/
  src/
    app.dart
    core/
    features/
    shared/
```

Lecture :

- [`lib/main.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
  Point d'entree unique.
- [`lib/l10n/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/l10n)
  Fichiers `.arb` et classes de localisation generees.
- [`lib/src/app.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/app.dart)
  Composition du `MaterialApp.router`.
- [`lib/src/core/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core)
  Infrastructure transverse et socle applicatif.
- [`lib/src/features/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features)
  Fonctionnalites produit.
- [`lib/src/shared/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared)
  Types et services transverses aux features medias.

---

## `lib/src/core/`

`core/` est la plus grosse zone transverse du projet. Elle contient a la fois :

- de l'infrastructure pure
- des modules fonctionnels transverses
- des widgets/UI communs
- des bridges entre Riverpod et GetIt

Comptage observe :

- `parental` : 26 fichiers Dart
- `profile` : 26
- `config` : 17
- `widgets` : 16
- `network` : 16
- `storage` : 13
- `logging` : 11
- `utils` : 11
- `router` : 10

### Sous-modules les plus structurants

- [`core/startup/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup)
  Bootstrap applicatif, gate de demarrage, orchestration de lancement.
- [`core/di/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di)
  GetIt global, initialisation des modules et providers de pont.
- [`core/router/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router)
  Definitions de routes, ids, paths, guard de redirection et pages techniques.
- [`core/state/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/state)
  Etat applicatif global expose via Riverpod.
- [`core/config/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config)
  Chargement d'environnement, configuration applicative, feature flags et secret stores.
- [`core/storage/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage)
  Base SQLite locale, repositories de persistence et policies de cache.
- [`core/security/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/security)
  Secure storage et chiffrement des credentials IPTV.
- [`core/network/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/network)
  Clients reseau, interceptors, configuration et proxy.
- [`core/logging/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/logging)
  Pipeline de logs, sanitization, sampling, filtering et adapters.
- [`core/theme/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/theme)
  Couleurs et theming global.
- [`core/widgets/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/widgets)
  Widgets reutilisables de presentation transverse.

### Sous-modules transverses a logique metier

Ces dossiers sont dans `core/` mais ont une vraie dimension fonctionnelle :

- [`core/auth/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/auth)
  Authentification transverse et `AuthGate`.
- [`core/parental/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/parental)
  Controle parental, PIN et classification maturite.
- [`core/profile/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/profile)
  Gestion des profils utilisateur.
- [`core/reporting/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/reporting)
  Signalement de problemes de contenu.
- [`core/performance/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/performance)
  Profiling device et tuning.
- [`core/responsive/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/responsive)
  Breakpoints, layouts responsives et helpers.

### Sous-modules plus simples

- [`core/preferences/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/preferences)
  Preferences locales persistantes et streams de changement.
- [`core/supabase/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/supabase)
  Wiring Supabase et mapping d'erreurs.
- [`core/error/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/error)
  Handler global d'erreurs.
- [`core/shared/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/shared)
  Tres petit dossier aujourd'hui, avec peu de poids structurel.

### Fichiers pivot a connaitre

- [`app_startup_provider.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)
  Bootstrap effectif du runtime.
- [`app_launch_orchestrator.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_launch_orchestrator.dart)
  Etat de lancement et coordination startup/router.
- [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)
  Point central GetIt.
- [`app_state_controller.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/state/app_state_controller.dart)
  Etat global transverse.
- [`environment_loader.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config/env/environment_loader.dart)
  Resolution de l'environnement actif.
- [`sqlite_database.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage/database/sqlite_database.dart)
  Base locale et migrations.
- [`secure_credentials_vault.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/security/secure_credentials_vault.dart)
  Persistence sensible.
- [`app_router.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_router.dart)
  Creation du `GoRouter`.
- [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart)
  Graphe des routes.
- [`app_assets.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/utils/app_assets.dart)
  Registre central des assets.

### Observations utiles

- `core/` melange infrastructure pure et modules fonctionnels transverses
- plusieurs sous-dossiers suivent une organisation `application / data / domain / presentation`
- d'autres sous-dossiers restent plats ou utilitaires
- le dossier [`core/profile/README.md`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/profile/README.md) est present mais son encodage est degrade, donc peu fiable comme source actuelle

---

## `lib/src/shared/`

`shared/` sert de couche commune aux features qui manipulent du contenu media, TMDB ou IPTV.

Structure observee :

- [`shared/domain/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/domain)
  Entites, value objects, constantes et contrats de services
- [`shared/data/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/data)
  Services concrets comme TMDB, caches et similarite
- [`shared/presentation/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/presentation)
  `ui_models`, providers transverses et arguments de route

Fichiers pivots :

- [`services.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/services.dart)
  Barrel des contrats partages
- [`tmdb_client.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/data/services/tmdb_client.dart)
  Client TMDB
- [`iptv_content_resolver_impl.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/data/services/iptv_content_resolver_impl.dart)
  Resolution transverse de contenu IPTV

Lecture :

- `shared/` n'est pas un "misc"
- il joue le role de socle metier transverse pour plusieurs features de contenu

---

## `lib/src/features/`

Les features sont globalement decoupees par domaine produit.

Comptage notable :

- `library` : 46 fichiers
- `iptv` : 43
- `search` : 42
- `movie` : 38
- `player` : 32
- `home` : 30
- `settings` : 29

### Features les plus lourdes

- [`features/library/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/library)
  Bibliotheque, playlists, sync cloud et vues utilisateur.
- [`features/iptv/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/iptv)
  Domaine le plus riche cote data/integration.
- [`features/search/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/search)
  Recherche, providers, genres et resultats.
- [`features/player/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/player)
  Player video, controles, tracks, PiP et sources.

### Organisation interne observee

Les features suivent souvent une organisation par couches :

- `data/`
- `domain/`
- `presentation/`
- parfois `application/`

Mais cette organisation n'est pas uniforme partout :

- `iptv`, `library`, `player`, `playlist` ont une vraie couche `application/`
- `movie`, `search`, `home`, `tv` n'ont pas toutes cette couche
- `shell` et `auth` sont plus minces et davantage centres presentation/navigation
- `welcome` joue un role particulier de bootstrap/onboarding plutot que de feature metier classique

### Features a lire selon le besoin

- Home et shell :
  - [`features/home/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/home)
  - [`features/shell/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/shell)
- Recherche et navigation secondaire :
  - [`features/search/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/search)
  - [`features/category_browser/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/category_browser)
- Lecture :
  - [`features/player/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/player)
- Bibliotheque :
  - [`features/library/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/library)
  - [`features/playlist/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/playlist)
- Fiches de contenu :
  - [`features/movie/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/movie)
  - [`features/tv/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/tv)
  - [`features/person/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/person)
  - [`features/saga/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/saga)
- Onboarding / bootstrap utilisateur :
  - [`features/welcome/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/welcome)
- Settings et administration locale :
  - [`features/settings/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/settings)

---

## `lib/l10n/`

Cette zone contient :

- les fichiers `.arb`
- les classes generees `app_localizations*.dart`

Constat utile :

- la zone est volumineuse en lignes mais ce n'est pas une zone d'architecture applicative
- elle genere beaucoup de bruit dans `git diff`
- il faut la traiter comme du genere + du contenu de traduction, pas comme du code metier

---

## `assets/`

Structure actuelle :

```text
assets/
  branding/
  icons/
    actions/
    media/
    navigation/
```

Regle actuelle :

- tous les chemins doivent idealement passer par [`app_assets.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/utils/app_assets.dart)

Document associe :

- [`assets_reorganization_2026-03-17.md`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/assets_reorganization_2026-03-17.md)

---

## Plateformes et outilings

- [`android/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android)
  Cible officielle avec release/signing documentes.
- [`windows/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/windows)
  Cible officielle de dev local.
- [`ios/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/ios)
  Cible conditionnelle.
- [`tool/gen_l10n.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/tool/gen_l10n.dart)
  Outil de support pour la localisation.

Document associe :

- [`platform_scope_decision_2026-03-17.md`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/platform_scope_decision_2026-03-17.md)

---

## Zones sensibles pour les prochaines modifications

### 1. Bootstrap et wiring global

Impact fort si vous touchez :

- `main.dart`
- `core/startup/`
- `core/di/`
- `core/router/`
- `core/state/`

### 2. Configuration et secrets

Impact fort si vous touchez :

- `core/config/`
- `core/security/`
- `core/supabase/`
- preferences persistees et `--dart-define`

### 3. Persistence locale

Impact fort si vous touchez :

- `core/storage/database/sqlite_database.dart`
- `core/storage/repositories/`
- les services de cache et de sync

### 4. Domaines les plus denses

Dette ou complexite probable plus fortes dans :

- `features/iptv/`
- `features/library/`
- `features/search/`
- `features/player/`

---

## Incoherences et dettes structurelles visibles

- pas de dossier `test/` versionne actuellement
- heterogeneite des couches selon les features
- coexistence GetIt + Riverpod qui impose des bridges explicites
- `core/` contient a la fois de l'infrastructure pure et des domaines transverses metier
- certains README internes ne sont pas fiables ou pas maintenus

Ce ne sont pas des erreurs immediates, mais ce sont des points a garder en tete avant un refactoring large.

---

## Ordre de lecture recommande selon l'objectif

### Comprendre le runtime

1. [`main.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/main.dart)
2. [`app_startup_gate.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_gate.dart)
3. [`app_startup_provider.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/startup/app_startup_provider.dart)
4. [`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart)
5. [`app.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/app.dart)
6. [`app_router.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_router.dart)

### Comprendre le socle technique

1. [`core/config/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/config)
2. [`core/state/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/state)
3. [`core/storage/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/storage)
4. [`core/security/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/security)
5. [`core/logging/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/logging)

### Comprendre le produit

1. [`features/shell/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/shell)
2. [`features/home/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/home)
3. [`features/search/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/search)
4. [`features/library/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/library)
5. [`features/player/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/player)

## Derniere mise a jour

2026-03-17

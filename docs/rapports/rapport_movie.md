# Rapport d’analyse — `src/features/movie`

## 1. Résumé global

Le dossier `features/movie` est globalement **très bien structuré** et s’inscrit clairement dans une approche **Clean Architecture** :

- Séparation nette **Domain / Data / Presentation**.
- Entités `Movie`, `MovieSummary`, `MovieCredit` propres, centrées métier, sans dépendances Flutter.
- Repository `MovieRepositoryImpl` bien isolé, avec mapping DTO → Domain correct.
- Providers Riverpod bien utilisés pour orchestrer les use cases.

En revanche, quelques points empêchent d’atteindre un niveau “vraiment pro” :

- **`MovieDetailPage` est une “god widget”** : trop de responsabilités (UI, navigation, playlists IPTV, historique, logique métier, DI).
- **DI doublée/mixte** (service locator + Riverpod) autour de `MovieRepository`, ce qui crée une architecture moins lisible.
- Quelques **problèmes de null-safety et de robustesse**, plus des **hard-coded strings** qui cassent l’i18n.
- Potentiel **surcoût réseau** côté TMDB (détail + recommandations) dû au design actuel du cache.

---

## 2. Architecture & organisation

### 2.1 Structure du dossier

- `movie.dart`  
  → Fichier “barrel” qui ré-exporte entités, repository, use cases et DTO principal pour simplifier les imports.

- `data/`
  - `datasources/`
    - `movie_local_data_source.dart`  
      → Accès cache pour détail film + recommandations, policies TTL configurées.
    - `tmdb_movie_remote_data_source.dart`  
      → I/O réseau TMDB, renvoie des DTO / Map décodés, pas de dépendance à `Response`.
  - `dtos/`
    - `tmdb_movie_detail_dto.dart`  
      → DTO principal (détail film, cast, crew, recommendations, logos, posters, etc.) + helpers de parsing.
  - `repositories/`
    - `movie_repository_impl.dart`  
      → Implémentation concrète de `MovieRepository`.

  - `movie_data_module.dart`  
    → Enregistre les data sources + repo + use case `FilterRecommendationsByIptvAvailability` dans le service locator `sl`.

- `domain/`
  - `entities/`
    - `movie.dart`, `movie_summary.dart`, `movie_credit.dart`  
      → Modèles métier, immutables, `Equatable`.
  - `repositories/`
    - `movie_repository.dart`  
      → Contrat Domain.
  - `usecases/`
    - `get_movie_detail.dart`, `get_movie_credits.dart`, `get_movie_recommendations.dart`,  
      `get_continue_watching_movies.dart`, `search_movies.dart`,  
      `is_in_watchlist.dart`, `toggle_watchlist.dart`,  
      `filter_recommendations_by_iptv.dart`.  
      → Chacun encapsule une opération métier unique.

- `presentation/`
  - `models/`
    - `movie_detail_view_model.dart`  
      → Adaptateur Domain → UI (formatage durée, rating, localisation des rôles…).
  - `pages/`
    - `movie_detail_page.dart`  
      → Page détail film (UI + interactions lourdes).
  - `providers/`
    - `movie_detail_providers.dart`  
      → Providers pour repo, favoris, détails, saga, etc.

### 2.2 Points forts

- **Clean Architecture respectée** :
  - Domain pur (aucune import Flutter).
  - Data → Domain → Presentation dans le bon sens.
- Use cases fins, mono-responsabilité (`GetMovieDetail`, `SearchMovies`, …).
- `TmdbMovieRemoteDataSource` encapsule bien l’I/O réseau et ne fuit pas `Response`.
- `MovieLocalDataSource` gère des policies de cache (TTL) propres.
- `MovieDetailViewModel` centralise une bonne partie du formatage UI.

### 2.3 Points à corriger

- **Mélange DI service locator (`sl`) + Riverpod** :
  - `movie_data_module.dart` enregistre `MovieRepository`, `FilterRecommendationsByIptvAvailability`, etc.
  - `movie_detail_providers.dart` reconstruit `MovieRepositoryImpl` à la main via `slProvider`.  
  → Deux sources de vérité possibles, ce qui complique la compréhension et les tests.

- **`MovieDetailPage` concentre trop de responsabilités** :
  - UI, timers, retry network, playlist IPTV, historique, navigation player, ajout à playlist, favoris, etc.
  - Plusieurs providers déclarés “inline” dans le State (`_movieAvailabilityProvider`, `_movieSeenProvider`, `_movieHistoryProvider`), ce qui brouille la frontière entre couche Presentation logique et UI.

- **Cache TMDB non optimisé** :
  - `getMovie` et `getRecommendations` peuvent **re-fetch** `fetchMovieFull` chacun de leur côté, car les recommandations sont stockées dans un cache séparé (`movie_reco_`) qui n’est jamais rempli par `getMovie`.

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Critique

#### 3.1.1 `MovieDetailPage` = “god widget”

- **Fichier / élément**  
  `presentation/pages/movie_detail_page.dart` — classe `_MovieDetailPageState`.

- **Problème**  
  - Le State gère :
    - état UI (opacité, synopsis expand/collapse),
    - auto-refresh timer + retry réseau,
    - logique de favoris,
    - gestion de l’historique (vu/non vu),
    - logique d’ajout à des playlists de la bibliothèque,
    - recherche d’items IPTV dans tous les comptes/playlists,
    - construction de l’URL de stream + navigation vers le player.
  - C’est un mélange de **UI, orchestration métier, I/O, DI** dans un seul fichier.

- **Pourquoi c’est un problème**
  - **Complexité cognitive très élevée** (difficile à lire, maintenir, tester).
  - Très difficile d’écrire des tests ciblés (il faut tout mocker : `sl`, repo IPTV, history, logger, navigation, etc.).
  - Risque élevé de régressions à chaque modification.

- **Suggestion de correction**
  - Extraire :
    - **Services / use cases dédiés** :
      - `MarkMovieAsSeen`, `MarkMovieAsUnseen`,
      - `BuildMovieStreamSource` (retourne un `VideoSource` à partir d’un `movieId`),
      - `AddMovieToPlaylist`.
    - **Providers Riverpod dédiés** :
      - Provider pour disponibilité IPTV d’un film.
      - Provider pour l’état “vu” du film.
      - Provider pour les playlists “éligibles” à l’ajout.
    - **Widgets UI séparés** :
      - `MovieDetailHeroSection`,
      - `MovieDetailActionsRow`,
      - `MovieDetailSynopsisSection`,
      - `MovieDetailCastSection`,
      - `MovieDetailSagaSection`,
      - `MovieDetailRecommendationsSection`.
  - Garder `MovieDetailPage` comme **orchestrateur léger** qui compose ces widgets et appelle les use cases/providers.

---

#### 3.1.2 Null-safety / timer avec `media == null`

- **Fichier / élément**  
  `movie_detail_page.dart` → `_startAutoRefreshTimer()` + usage de `widget.media!.id`.

- **Problème**  
  - `initState` appelle `_startAutoRefreshTimer();` même si `widget.media` peut être `null`.
  - Dans le callback du `Timer`, on lit :
    ```dart
    final vmAsync = ref.read(
      movieDetailControllerProvider(widget.media!.id),
    );
    ```
  - Si la page est construite avec `media == null`, le timer déclenchera un `NoSuchMethodError` / `LateError`.

- **Pourquoi c’est un problème**
  - Crashes potentiels dans un cas déjà prévu dans l’UI (tu gères `media == null` avec un message dans le `build`).
  - Non respect total de la null-safety ici.

- **Suggestion de correction**
  - Protéger clairement :
    ```dart
    void initState() {
      super.initState();
      _isTransitioningFromLoading = true;
      _primeFromArgs();
      if (widget.media != null) {
        _startAutoRefreshTimer();
      }
    }
    ```
  - Dans `_startAutoRefreshTimer`, re-checker `widget.media != null` avant d’utiliser `.id`.

---

### 3.2 Important

#### 3.2.1 DI doublée : `MovieDataModule` vs `movieRepositoryProvider`

- **Fichier / élément**  
  - `data/movie_data_module.dart`  
  - `presentation/providers/movie_detail_providers.dart` → `movieRepositoryProvider`.

- **Problème**
  - D’un côté, `MovieDataModule.register()` enregistre :
    ```dart
    sl.registerLazySingleton<MovieRepository>(
      () => MovieRepositoryImpl(...),
    );
    ```
  - De l’autre, `movieRepositoryProvider` reconstruit manuellement un `MovieRepositoryImpl` en lisant les dépendances via `slProvider`.
  - On a donc deux chemins d’instanciation possibles pour le même service.

- **Pourquoi c’est un problème**
  - **Perte de lisibilité** : difficile de savoir “la” source officielle de `MovieRepository`.
  - **Risque d’incohérence** (ex. userId différent, config différente).
  - Complexifie les tests (il faut décider si on mocke `sl` ou le provider).

- **Suggestion de correction**
  - **Choisir une seule stratégie** :
    - Option A (recommandée) : **tout passer par Riverpod** :
      - `TmdbMovieRemoteDataSource`, `MovieLocalDataSource`, `WatchlistLocalRepository`, etc. exposés via des providers.
      - `movieRepositoryProvider` devient l’unique factory pour `MovieRepository`.
      - `MovieDataModule` reste éventuellement pour les parties non-Riverpod, mais ne crée plus `MovieRepository`.
    - Option B : tout passer par `sl` et exposer dans Riverpod seulement un “provider adapter” :
      ```dart
      final movieRepositoryProvider = Provider<MovieRepository>((ref) {
        return sl<MovieRepository>();
      });
      ```
  - L’important : **une seule source de vérité** pour l’instanciation.

---

#### 3.2.2 Cache TMDB non mutualisé (double requête potentielle)

- **Fichiers / éléments**  
  - `data/repositories/movie_repository_impl.dart` → `getMovie`, `getRecommendations`.  
  - `data/datasources/movie_local_data_source.dart`.

- **Problème**
  - `getMovie` :
    - Si pas en cache, appelle `_remote.fetchMovieFull(...)` puis `saveMovieDetail(dto: remote)`.
    - `MovieLocalDataSource.saveMovieDetail` écrit sous la clé `'movie_detail_$id'`.
  - `getRecommendations` :
    - Cherche dans `_local.getRecommendations(movieId)` (clé `'movie_reco_$movieId'`).
    - Si rien, rappelle `_remote.fetchMovieFull(...)` et ensuite `saveRecommendations(...)`.

  → Résultat : **premier appel** à `getMovie` + `getRecommendations` sur un film sans cache peut effectuer **deux appels `fetchMovieFull`** alors que les recommandations sont déjà dans le DTO du premier appel.

- **Pourquoi c’est un problème**
  - Surcoût réseau inutile vers TMDB, surtout sur connexions lentes ou avec limitations de rate.
  - Complexité accrue pour un cache qui pourrait être plus cohérent.

- **Suggestion de correction**
  - Option simple :
    - Dans `getMovie`, après `saveMovieDetail(dto: remote)`, **sauvegarder aussi les recommandations** :
      ```dart
      if (remote.recommendations.isNotEmpty) {
        await _local.saveRecommendations(
          movieId: movieId,
          summaries: remote.recommendations,
        );
      }
      ```
  - Ou :
    - Modifier `MovieLocalDataSource` pour pouvoir **extraire les recommandations** directement depuis la valeur cache du détail.
    - Redéfinir le contrat de cache : une seule entrée `movie_detail_$id` contient tout, et `getRecommendations` lit dedans.

---

#### 3.2.3 Providers déclarés “dans” le State

- **Fichier / élément**  
  `movie_detail_page.dart` → `_movieAvailabilityProvider`, `_movieSeenProvider`, `_movieHistoryProvider`.

- **Problème**
  - Ces providers sont définis comme champs d’instance :
    ```dart
    final _movieAvailabilityProvider = FutureProvider.family<bool, String>(...);
    ```
  - Style atypique : dans Riverpod, les providers sont **habituellement top-level**, dans `providers/`.

- **Pourquoi c’est un problème**
  - Rend la logique moins réutilisable (ces providers sont “enfermés” dans la page).
  - Complexifie la navigation dans le code : on ne les trouve pas dans `presentation/providers`.
  - Moins clair pour d’autres développeurs habitués aux conventions Riverpod.

- **Suggestion de correction**
  - Déplacer ces providers dans `presentation/providers/movie_detail_providers.dart` :
    - `movieAvailabilityProvider`,
    - `movieSeenProvider`,
    - `movieHistoryProvider`.
  - Les consommer ensuite dans la page via `ref.watch(...)` comme aujourd’hui.

---

#### 3.2.4 Hard-coded strings (i18n cassée)

- **Fichier / élément**  
  `movie_detail_page.dart` : exemples
  - `'Aucune playlist disponible'`
  - `'Aucune playlist disponible pour les films'`
  - `'Voir la page'`
  - `'Film non disponible dans la playlist'`
  - `'Le média trouvé n\'est pas un film'`
  - `'Impossible de construire l\'URL de streaming'`
  - etc.

- **Problème**
  - Mélange de strings localisées (via `AppLocalizations`) et de texte en dur en français.

- **Pourquoi c’est un problème**
  - Rupture de cohérence dans l’i18n.
  - Impossible de traduire correctement l’app.
  - Maintenance plus difficile (les textes sont dispersés dans le code UI).

- **Suggestion de correction**
  - Ajouter ces textes dans `AppLocalizations` (ARB) et les consommer via `AppLocalizations.of(context)!`.
  - Règle à adopter : **aucun texte UI user-facing ne doit rester en dur dans le code**.

---

### 3.3 Nice to have

#### 3.3.1 Duplication de logique IPTv / history

- **Fichier / élément**  
  `_markAsSeen`, `_playMovie` dans `movie_detail_page.dart`.

- **Problème**
  - `MarkAsSeen` fait une boucle sur comptes + playlists pour trouver un `XtreamPlaylistItem`, mais au final **n’utilise jamais** `xtreamItem` (durée par défaut 2h).
  - `_playMovie` a une logique similaire pour retrouver l’item IPTV, mais avec plus de logs.

- **Pourquoi c’est un problème**
  - Code superflu, coûts I/O inutiles dans `_markAsSeen`.
  - Logique dupliquée non testée.

- **Suggestion de correction**
  - Soit :
    - Utiliser effectivement `xtreamItem` dans `_markAsSeen` pour déterminer une durée réelle.
  - Soit :
    - Supprimer la recherche et se contenter du `Duration(hours: 2)`.
  - Et dans tous les cas :
    - Extraire la logique “find XtreamPlaylistItem by movieId” dans un **service unique** (ex. `XtreamLookupService`) ou un use case, réutilisé par `_playMovie` et `_markAsSeen`.

---

#### 3.3.2 Micro-optimisations / style

- Utiliser `const` plus largement pour les widgets statiques (`SizedBox`, `Text` sans variables, etc.) dans `movie_detail_page.dart`.
- Factoriser quelques `SizedBox(height: ...)` récurrents avec des constantes d’espacement partagées (ex. `AppSpacing.l`, `AppSpacing.m`).
- Dans `_local.getRecommendations`, `final items = (cached['items'] as List<dynamic>? ?? const [])` : ok, mais on peut typer davantage pour limiter les `dynamic`.

---

## 4. Plan de refactorisation par étapes

### Étape 1 — Clarifier la DI et les providers (structurant)

1. Choisir une approche **unique** pour `MovieRepository` :
   - Idéalement : provider Riverpod + dépendances injectées via providers (`TmdbMovieRemoteDataSource`, `MovieLocalDataSource`, etc.).
2. Mettre à jour `movie_detail_providers.dart` pour qu’il dépend exclusivement de ces providers (et non du service locator pour ces services-là).
3. Laisser `MovieDataModule.register()` gérer seulement les composants non gérés par Riverpod, ou le marquer comme legacy.

---

### Étape 2 — Éclater `MovieDetailPage` en widgets + logique testable

1. Créer des widgets séparés :
   - `MovieDetailHeroSection`,
   - `MovieDetailMainActions`,
   - `MovieDetailSynopsisSection`,
   - `MovieDetailCastSection`,
   - `MovieDetailSagaSection`,
   - `MovieDetailRecommendationsSection`.
2. Garder `_buildHeroImage` dans un widget dédié (`MovieHeroImage`) éventuellement réutilisable.
3. Réduire la méthode `_buildWithValues` pour qu’elle ne fasse plus que composer ces widgets.

---

### Étape 3 — Extraire la logique métier (IPTV, favoris, historique) en use cases / services

1. Créer un dossier `presentation/controllers/` ou `application/` (selon ton organisation globale) pour :
   - `MarkMovieAsSeen`,
   - `MarkMovieAsUnseen`,
   - `AddMovieToPlaylist`,
   - `GetMovieAvailabilityOnIptv`,
   - `BuildMovieVideoSource` (renvoie un `VideoSource` ou un résultat `Result<VideoSource, Error>`).
2. Créer des providers Riverpod pour ces use cases, et les consommer depuis la page :
   - `_playMovie` devient un simple appel à `ref.read(buildMovieVideoSourceProvider(movieId).future)` + navigation.
   - `_markAsSeen` / `_markAsUnseen` se réduisent à l’appel du use case + invalidation de quelques providers.

---

### Étape 4 — Séparer les providers “inline” de la page

1. Déplacer `_movieAvailabilityProvider`, `_movieSeenProvider`, `_movieHistoryProvider` dans `movie_detail_providers.dart`.
2. Renommer de manière cohérente :
   - `movieAvailabilityProvider`,
   - `movieSeenProvider`,
   - `movieHistoryProvider`.
3. Adapter la page pour les importer depuis le fichier de providers.

---

### Étape 5 — Optimiser le cache TMDB

1. Ajuster `MovieRepositoryImpl.getMovie` pour qu’il remplisse le cache des recommandations lorsqu’il récupère un `TmdbMovieDetailDto` avec des recommandations.
2. Vérifier que `getRecommendations` utilise en priorité ce cache, et ne refait un appel réseau que si nécessaire.
3. (Optionnel) Documenter dans un commentaire le contrat du cache pour les films.

---

### Étape 6 — i18n et nettoyage style

1. Passer en revue toutes les strings en dur dans `movie_detail_page.dart` et les déplacer dans les fichiers de localisation.
2. Appliquer des micro-optimisations :
   - Ajouter des `const` là où c’est possible.
   - Factoriser les marges/espacements récurrents dans une petite classe `AppSpacing`.

---

## 5. Bonnes pratiques à adopter pour la suite

- **Une responsabilité par fichier / classe** : éviter les “god widgets” ; déplacer la logique métier hors des pages UI.
- **DI unifiée** : une seule façon d’instancier `MovieRepository` et ses dépendances (Riverpod ou service locator, pas les deux pour le même service).
- **Providers top-level** : définir les providers Riverpod dans des fichiers `providers/`, jamais “inline” dans les `State`.
- **Domain pur** : continuer à garder les entités & use cases entièrement indépendants de Flutter et des datasources.
- **I/O hors du `build`** : les opérations coûteuses (IPTV, historique, etc.) doivent passer par des use cases/providers, pas par du code imbriqué dans les widgets.
- **Cache cohérent** : définir un contrat clair pour le cache (clé, contenu, TTL) et éviter les doublons de requêtes réseau.
- **i18n stricte** : aucune string user-facing en dur dans le code ; tout passe par les localisations.
- **Null-safety stricte** : éviter les `!` sur des champs potentiellement nuls (comme `widget.media`) et systématiser les guards.
- **Logs structurés** : continuer à logger des infos utiles (durées, ids, etc.) mais via des services dédiés, pas dispersés dans l’UI.
- **Tests ciblés** : viser des tests unitaires sur :
  - les mappers DTO → Domain (`MovieRepositoryImpl`, `TmdbMovieDetailDto`),
  - les use cases (watchlist, IPTV, historique),
  - les view models (`MovieDetailViewModel.fromDomain`).


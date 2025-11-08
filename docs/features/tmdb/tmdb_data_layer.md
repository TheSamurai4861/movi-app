# TMDB — Plan d’implémentation clean architecture

## 1. Objectifs
- Couvrir toutes les métadonnées requises pour Movies, Series, Persons et Sagas décrites dans la demande.
- Respecter l’architecture existante (`features/<feature>/{domain,data,presentation}`) avec des repositories alimentés par TMDB.
- Gérer les préférences de langue pour les métadonnées (titres, synopsis, logos) et fournir des fallbacks cohérents (fr → en → défaut).

## 2. Architecture générale

```
features/
├── movie/
│   ├── data/
│   │   ├── datasources/tmdb_movie_remote_data_source.dart
│   │   ├── dtos/{movie_detail_dto.dart, movie_credit_dto.dart, movie_recommendation_dto.dart}
│   │   └── repositories/movie_repository_impl.dart
│   └── domain/ (déjà présent)
├── tv/
│   ├── data/… (équivalent série)
├── person/
│   ├── data/… (credits, bio, stats)
├── saga/
│   ├── data/… (collection TMDB)
└── shared/
    └── data/services/tmdb_client.dart (wrapper pour TMDB API v3/v4 + langue préférée)
```

### 2.1 TMDB Client partagé
- `core/network` fournit déjà `Dio` + `NetworkExecutor`.
- Ajouter `shared/data/services/tmdb_client.dart` :
  ```dart
  class TmdbClient {
    TmdbClient(this._executor, this._config, this._localeStore);

    Future<R> get<R>(String path, {Map<String, dynamic>? query, required R Function(Map<String, dynamic>) mapper}) {
      final params = {
        'api_key': _config.network.tmdbApiKey,
        'language': _localeStore.preferredLocale,
        'include_image_language': '${_localeStore.preferredLocale},en,null',
        ...?query,
      };
      return _executor.run<Map<String, dynamic>, R>(
        request: (client) => client.get<Map<String, dynamic>>('/3/$path', queryParameters: params),
        mapper: mapper,
      );
    }
  }
  ```
- `_localeStore` : service (ex: `core/state/app_state_controller` ou `core/preferences`) qui expose la langue préférée (fr, en, etc.) + fallback.

## 3. Movie Feature
### 3.1 Domain (déjà présent)
`Movie`, `MovieSummary`, `PersonSummary`.

### 3.2 Data layer
- `TmdbMovieRemoteDataSource`
  - `Future<MovieDetailDto> fetchMovie(MovieId id)`
  - `Future<List<PersonCreditDto>> fetchCredits(MovieId id)`
  - `Future<List<MovieSummaryDto>> fetchRecommendations(MovieId id)`
- Endpoints TMDB :
  - `/movie/{id}?append_to_response=images,release_dates`
  - `/movie/{id}/credits`
  - `/movie/{id}/recommendations`
- Mapping :
  - `logo` : `images.logos` filtrer par `iso_639_1 == preferredLocale` sinon fallback.
  - `poster/backdrop` : prendre `file_path` + config TMDB.
  - `synopsis` : `overview`
  - `duration` : `runtime`
  - `actors` : `credits.cast` avec `character`
  - `note tmdb` : `vote_average`
  - `releaseYear` : `release_date`
- Repository :
  ```dart
  class MovieRepositoryImpl implements MovieRepository {
    final TmdbMovieRemoteDataSource remote;
    @override Future<Movie> getMovie(MovieId id) => remote.fetchMovie(id).toDomain();
    // etc.
  }
  ```

## 4. Series Feature
### 4.1 Data layer
- `TmdbTvRemoteDataSource`
  - `/tv/{id}?append_to_response=images`
  - `/tv/{id}/credits`
  - `/tv/{id}/recommendations`
  - `/tv/{id}/season/{season_number}`
- Mapping :
  - Saisons : `seasons[]` (title, poster, overview)
  - Episodes : `season/{n}` endpoint (title, air_date, vote_average, runtime, still_path, overview)
  - Pas de durée globale (afficher `episode_run_time` ou `season runtime` si dispo)

## 5. Person Feature
### 5.1 Requirements
- Nom, nb films/séries, métiers, date de naissance.
- Use `/person/{id}` + `/person/{id}/combined_credits`.
- Calculer `filmCount`, `seriesCount` via `combined_credits.cast` filtré sur `media_type`.
- `jobs` : `combined_credits.crew` (set unique des `department` ou `job`).
- `birthday` : `person.birthday`.

## 6. Saga Feature
- TMDB `collection` endpoint `/collection/{id}`.
- `parts[]` => films appartenant à la saga.
- `nombre films` = `parts.length`.
- `durée totale` : somme `runtime` (requiert fetch movie detail par film ou `append_to_response=movie` n’existe pas, donc prévoir un job additionnel / caching).
- `image` : `poster_path` (sans texte). TMDB propose `backdrop` et `poster`; utiliser `POSTER` (souvent artwork sans texte).

## 7. Langue préférée & fallback
- `core/state/AppState` stocke déjà `theme` + `isOnline`; ajouter `preferredLocale` + `availableLocales`.
- Créer `core/preferences/locale_preferences.dart` (ou store) pour lire/écrire la langue.
- `TmdbClient` reçoit `LocaleStore` → paramètre `language`.
- Fallback : si `overview` vide pour la langue courante, re-fetch en anglais ? Proposer :
  1. Appel initial avec `language=preferred`.
  2. Si certains champs critiques sont vides (overview, logo), lancer un second fetch avec `language='en'` (ou `null`) pour compléter.
  3. Stocker les variations dans la couche data pour éviter multi-requests sur la même session (ex: `MovieDetailDto` contient `localizedFields`).

## 8. Clean architecture – orchestration
1. **Data Source** : appelle TMDB via `TmdbClient`.
2. **Repository** : fusionne réponses multiples (ex: movie detail + credits + recommendations), applique fallback de langue, mappe vers entités domain.
3. **Use cases** : déjà présents dans `features/movie/tv/person`.
4. **State management** : Riverpod/Controllers consomment les use cases.

## 9. Checklist d’implémentation
1. Ajouter `shared/data/services/tmdb_client.dart` + `LocaleStore`.
2. Étendre `AppState` ou créer `PreferencesService` pour la langue.
3. Créer les data sources TMDB par feature + DTO + mapping.
4. Implémenter les repositories `MovieRepositoryImpl`, `TvRepositoryImpl`, `PersonRepositoryImpl`, `SagaRepositoryImpl`.
5. Injecter via `core/di` (modules `movie_module.dart`, `tv_module.dart`, etc.) pour enregistrer data sources et repositories.
6. Adapter les pages (MovieDetailPage, etc.) pour consommer les entités réelles.

## 10. Notes supplémentaires
- Config TMDB (base image URL, sizes) : récupérer via `/configuration` une fois (caché dans `core/network` ou `core/config`).
- Gestion des logos “sans texte” : TMDB ne distingue pas explicitement, mais les `images.logos` sont généralement textless; fallback sur `poster`.
- Durée totale saga : prévoir un `SagaAggregator` qui somme `Movie.runtime` (après fetch) et met en cache le résultat.

Ce plan garde la séparation Clean Architecture et introduit la préférence de langue dès la couche data, afin que toutes les features puissent proposer des métadonnées cohérentes pour MOVI.

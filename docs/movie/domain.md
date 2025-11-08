# Journal – Feature Movie / Domain Layer

## 2024-XX-XX — Modélisation des entités
- Ajout du dossier `lib/src/features/movie/domain/entities/` avec trois entités principales :
  - `Movie` : représentation complète (id, titre, synopsis, durée, poster/backdrop, date de sortie, rating, genres, cast/directeurs).
  - `MovieSummary` : version légère pour listes/sections (id, titre, poster, backdrop optionnelle, tags, année).
  - `MovieCredit` : lien entre un film et une personne (cast ou crew).
- Introduction des value objects/entités partagées :
  - `shared/domain/value_objects/media_id.dart` — `MovieId`, `SeriesId`, `PersonId`, etc.
  - `shared/domain/value_objects/media_title.dart`, `synopsis.dart`, `content_rating.dart`.
  - `shared/domain/entities/person_summary.dart` utilisé par `Movie` et `MovieCredit`.

## 2024-XX-XX — Contrat de repository
- Interface `MovieRepository` (`lib/src/features/movie/domain/repositories/movie_repository.dart`) définie avec les méthodes :
  - `getMovie` (détail complet),
  - `getCredits`,
  - `getRecommendations`,
  - `getContinueWatching`,
  - `searchMovies`,
  - `isInWatchlist` / `setWatchlist`.
  Ces signatures couvrent les sections prévues (détail film, distribution, recommandations, reprise de lecture, watchlist).

## 2024-XX-XX — Use cases
- Ajout du dossier `lib/src/features/movie/domain/usecases/` avec :
  - `GetMovieDetail`, `GetMovieCredits`, `GetMovieRecommendations`,
    `GetContinueWatchingMovies`, `SearchMovies`, `ToggleWatchlist`, `IsMovieInWatchlist`.
- Chaque use case encapsule un appel au repository, prêt pour l’injection Riverpod/GetIt.

## TODO prochains steps
- Définir les entités `Season`, `Episode`, `Saga` et les VO complémentaires (duration, imageUrl).
- Ajouter les DTO correspondants dans `features/movie/data/dtos` et mapping `dto -> domain`.

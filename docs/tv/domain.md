# Journal – Feature TV / Domain Layer

## 2024-XX-XX — Modélisation des entités
- `TvShow` : id, titre, synopsis, poster/backdrop, dates, statut, rating, genres, cast/creators, saisons.
- `Season` : id, numéro, titre, overview, poster, épisodes, date de diffusion.
- `Episode` : id, numéro, titre, overview, durée, date, still.
- `TvShowSummary` : aperçu (id, poster, backdrop, nombre de saisons, statut).

## 2024-XX-XX — Contrat de repository
- Interface `TvRepository` :
  - `getShow`, `getSeasons`, `getEpisodes`,
  - `getFeaturedShows`, `getUserWatchlist`, `getContinueWatching`,
  - `searchShows`, `isInWatchlist`, `setWatchlist`.

## 2024-XX-XX — Use cases
- `GetTvShowDetail`, `GetTvSeasons`, `GetSeasonEpisodes`,
  `GetFeaturedTvShows`, `GetTvWatchlist`, `GetContinueWatchingTv`,
  `SearchTvShows`, `ToggleTvWatchlist`, `IsTvShowInWatchlist`.

## TODO prochains steps
- Définir les DTO/mappers pour shows/saisons/épisodes.
- Ajouter des VO spécifiques si nécessaire (EpisodeNumber, SeasonNumber).

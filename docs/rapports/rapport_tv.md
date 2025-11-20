# Plan d’implémentation — Feature « Séries TV »

Ce plan détaille l’implémentation des Séries TV dans Movi, alignée avec Clean Architecture, Riverpod, DI, i18n, performance et tests.

## Objectifs
- Afficher les détails d’une série: synopsis, casting, créateurs, saisons, épisodes.
- Gérer la disponibilité IPTV (détection streamId, playlists), et le rafraîchissement.
- Continuer à regarder, recommandations, et watchlist (ajout/suppression).
- Support de recherche, pagination, lazy loading des saisons/épisodes.
- UI localisée (Material 3), accessible et performante.

## Architecture

### Domain
- Entités:
  - `TvShow` (`lib/src/features/tv/domain/entities/tv_show.dart`) — métadonnées (title, synopsis, cast, seasons, etc.).
- Repositories (contrats):
  - `TvRepository` (`lib/src/features/tv/domain/repositories/tv_repository.dart`) — détails, saisons, épisodes, featured, watchlist, continue watching.
- Use cases (existants):
  - `GetTvShowDetail`, `GetTvSeasons`, `GetSeasonEpisodes` — chargements hiérarchiques.
  - `GetFeaturedTvShows`, `SearchTvShows` — découverte.
  - `GetContinueWatchingTv`, `IsTvShowInWatchlist`, `ToggleTvWatchlist` — état utilisateur.

### Data
- Remote Data Source:
  - `TmdbTvRemoteDataSource` (`lib/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart`) — TMDB API.
- Local Data Source:
  - `TvLocalDataSource` (`lib/src/features/tv/data/datasources/tv_local_data_source.dart`) — cache/stockage local.
- Repository:
  - `TvRepositoryImpl` (`lib/src/features/tv/data/repositories/tv_repository_impl.dart`) — mapping TMDB→Domain, enrichissements (casting, créateurs), garde-fous sur `poster`.
- DI:
  - `TvDataModule.register()` (`lib/src/features/tv/data/tv_data_module.dart`) — enregistrer Data Sources + Repository + Use cases.

### Presentation
- Page détail:
  - `TvDetailPage` (`lib/src/features/tv/presentation/pages/tv_detail_page.dart`) — UI principale: saisons/épisodes, actions IPTV, sections cast/reco.
- Providers/Controllers:
  - Inclure providers pour état `isAvailableOnIptv`, `episodesBySeason`, `watchlistStatus`, `continueWatching`, en branchant sur use cases.
- Navigation/Router:
  - Routes typées via `GoRouter` (`lib/src/core/router/router.dart`) pour navigations vers saisons/épisodes.

## Flux clés
- Chargement détail série:
  - UI → `GetTvShowDetail` → `TvRepositoryImpl` (remote + mappers) → ViewModel.
- Saisons/épisodes:
  - UI → `GetTvSeasons`/`GetSeasonEpisodes` pour la saison sélectionnée (lazy).
- IPTV disponibilité:
  - UI → provider de disponibilité → `IptvLocalRepository` (playlists) → match TMDB→streamId → `true/false`.
  - Rafraîchissement playlists via event bus et service `XtreamSyncService`.
- Watchlist/Continue watching:
  - UI → `ToggleTvWatchlist`/`IsTvShowInWatchlist`/`GetContinueWatchingTv`.
- Recherche séries:
  - UI → `SearchTvShows` avec pagination et debounce.

## Erreurs & État
- Data failures typées, messages localisés en UI (`AppLocalizations`).
- États déterministes: loading/success/error par section (détail/saisons/épisodes/IPTV).
- Sans `print`; logs via `AppLogger`.

## Performance
- Lazy loading des saisons/épisodes.
- Mémoisation/mapping minimal pour TMDB images (`TmdbImageResolver`).
- Pagination côté `SearchTvShows`.
- Limiter cast à 10 items en Domain (déjà en place).

## i18n
- Clés utilisées:
  - `tvSeasonLabel(number)` (`lib/l10n/app_localizations.dart:883`),
  - `tvNoEpisodesAvailable`, `tvResumeSeasonEpisode(season, episode)` (`lib/l10n/app_localizations_fr.dart:459`),
  - Sections et actions locales (`settings...` pour appels transverses si nécessaire).

## Tests
- Domain:
  - `get_tv_show_detail_usecase_test.dart` — succès/erreur.
  - `get_tv_seasons_usecase_test.dart`, `get_season_episodes_usecase_test.dart` — cas de base + bordures.
  - `toggle_tv_watchlist_usecase_test.dart`, `is_tv_in_watchlist_usecase_test.dart`.
- Data:
  - `tv_repository_impl_test.dart` — poster obligatoire, mapping cast/creators, dates, genres.
  - `tmdb_tv_remote_data_source_test.dart` — erreurs réseau mappées.
- Presentation:
  - `tv_detail_controller_test.dart` — transitions d’état.
  - `tv_detail_page_widget_test.dart` — sections visibles, i18n, interactions basiques.

## DI
- Vérifier `TvDataModule.register()` est appelé dans `initDependencies(registerFeatureModules: true)` (`lib/src/core/di/injector.dart:144–155`).
- Vérifier la chaîne TMDB (client/executor/endpoints) prête (`injector.dart:118–141`).

## Checklist
- [x] Modules data déclarés (`tv_data_module.dart`).
- [x] Use cases Domain existants (chargement, watchlist, recherche).
- [ ] Providers Presentation pour saisons/épisodes/watchlist/continue.
- [ ] Tests Domain/Data/Presentation (ajouter fichiers listés).
- [ ] i18n: vérifier les traductions `tv*` dans `app_*.arb`.
- [ ] Performance: lazy loading confirmé en UI.

---

## Références
- `lib/src/features/tv/data/tv_data_module.dart:1`
- `lib/src/features/tv/data/repositories/tv_repository_impl.dart:274`
- `lib/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:1`
- `lib/src/features/tv/presentation/pages/tv_detail_page.dart:691`
- `lib/src/core/di/injector.dart:144`
- `lib/l10n/app_localizations.dart:883`

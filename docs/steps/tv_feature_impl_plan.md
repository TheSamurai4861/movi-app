# Plan de complétion — Feature `tv`

Liste des étapes pour finaliser l’implémentation Séries TV conformément au rapport.

## Étape 1 — Domain (Use cases & contrats)
- [ ] Ajouter tests: `test/features/tv/domain/get_tv_show_detail_usecase_test.dart`.
- [ ] Ajouter tests: `test/features/tv/domain/get_tv_seasons_usecase_test.dart`.
- [ ] Ajouter tests: `test/features/tv/domain/get_season_episodes_usecase_test.dart`.
- [ ] Ajouter tests: `test/features/tv/domain/toggle_tv_watchlist_usecase_test.dart`.
- [ ] Ajouter tests: `test/features/tv/domain/is_tv_in_watchlist_usecase_test.dart`.
- [ ] Ajouter tests: `test/features/tv/domain/search_tv_shows_usecase_test.dart`.

Références:
- `lib/src/features/tv/domain/entities/tv_show.dart`
- `lib/src/features/tv/domain/repositories/tv_repository.dart`
- `lib/src/features/tv/domain/usecases/get_tv_show_detail.dart`
- `lib/src/features/tv/domain/usecases/get_tv_seasons.dart`
- `lib/src/features/tv/domain/usecases/get_season_episodes.dart`

## Étape 2 — Data (DS & Repo)
- [ ] Ajouter tests: `test/features/tv/data/tv_repository_impl_test.dart` (mapping images/dates/cast, poster obligatoire → erreur).
- [ ] Ajouter tests: `test/features/tv/data/tmdb_tv_remote_data_source_test.dart` (erreurs réseau mappées).

Références:
- `lib/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart`
- `lib/src/features/tv/data/datasources/tv_local_data_source.dart`
- `lib/src/features/tv/data/repositories/tv_repository_impl.dart`

## Étape 3 — Presentation (Controllers & UI)
- [ ] Créer providers: `episodesBySeasonProvider`, `watchlistStatusProvider`, `continueWatchingProvider`, `tvAvailabilityProvider`.
- [ ] Ajouter tests: `test/features/tv/presentation/tv_detail_controller_test.dart`.
- [ ] Ajouter tests: `test/features/tv/presentation/tv_detail_page_widget_test.dart` (sections, i18n, interactions basiques).

Références:
- `lib/src/features/tv/presentation/pages/tv_detail_page.dart`
- `lib/src/shared/data/services/tmdb_image_resolver.dart`
- `lib/src/core/storage/repositories/iptv_local_repository.dart`

## Étape 4 — DI (enregistrement)
- [ ] Vérifier que `TvDataModule.register()` est bien appelé via `initDependencies(registerFeatureModules: true)`.

Références:
- `lib/src/features/tv/data/tv_data_module.dart`
- `lib/src/core/di/injector.dart`

## Étape 5 — Intégration (flux & cohérence)
- [ ] Vérifier lazy loading des saisons/épisodes (chargement uniquement à la demande).
- [ ] Vérifier le flux de disponibilité IPTV (match TMDB→streamId, playlists, refresh via event bus).
- [ ] Vérifier watchlist/continue watching (états cohérents, messages localisés).

Références:
- `lib/src/features/iptv/application/iptv_catalog_reader.dart`
- `lib/src/shared/data/services/xtream_lookup_service.dart`
- `lib/src/features/home/data/home_feed_data_module.dart`

## Étape 6 — i18n
- [ ] Vérifier et compléter les clés `tvSeasonLabel`, `tvNoEpisodesAvailable`, `tvResumeSeasonEpisode` dans `app_*.arb`.

Références:
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_*.arb`

## Étape 7 — Performance
- [ ] Valider pagination sur la recherche séries.
- [ ] Confirmer limitation cast en Domain et memo images.

## Étape 8 — Documentation
- [ ] Mettre à jour `docs/rapports/rapport_tv.md` après implémentations (providers, tests, i18n).

Checklist synthèse:
- [x] Modules Data existants.
- [ ] Providers Presentation complétés.
- [ ] Tests Domain/Data/Presentation ajoutés et verts.
- [ ] i18n complétée.
- [ ] Lazy loading confirmé.
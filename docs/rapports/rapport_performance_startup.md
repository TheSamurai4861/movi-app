# Rapport — Performance au démarrage (Home/Player/Search)

## Constat (logs de démarrage)
- Rafales d’appels TMDB dès le succès du `Startup` et navigation vers Home:
  - `GET trending/movie/week?page=1&language=fr` (425ms)
  - `GET movie/{id}?append_to_response=credits,recommendations&language=fr` (≈900ms) ×2
  - `GET movie/{id}/images?include_image_language=fr,en,null` (≈355–763ms) ×2
  - `GET tv/{id}/images?include_image_language=null` (55–163ms) ×3
  - `GET watch/providers/movie?watch_region=FR` (420ms)
  - `GET discover/movie?with_watch_providers={id}&watch_region=FR&page=1&language=fr` (308–547ms) ×6
- Messages additionnels:
  - `unhandled element <defs/>; Svg loader` (assets SVG)
  - `LateInitializationError: Field '_repo@…' has already been initialized` (Riverpod `late final` réassigné)

## Origines dans le code
- Hero Home (trending + match sur TMDB IDs locaux):
  - `getHeroMovies()` dans `lib/src/features/home/data/repositories/home_feed_repository_impl.dart:52-110`
  - Pagination jusqu’à 3 pages `trending/movie/week` et mapping candidat: `home_feed_repository_impl.dart:48-75`
- Enrichissements Continue Watching (poster/backdrop/durée/titre):
  - Service: `lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:25-114`
  - Appels à `movieRepository.getMovie`, `tvRepository.getShowLite` et éventuellement `getEpisodes`
- Watch Providers et Discover par provider:
  - Data source: `lib/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart:16-60` (regions + providers)
  - Discover: `tmdb_watch_providers_remote_data_source.dart:62-88` et `90-116`
- Détails Movie avec images séparées:
  - `fetchMovieFull()` sépare l’appel images pour filtrage `include_image_language`: `lib/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart:57-104`
- Riverpod late init réassigné (cause du `LateInitializationError`):
  - `HomeController` assigne des `late final` dans `build()`: `lib/src/features/home/presentation/providers/home_providers.dart:92-104`

## Coûts principaux
- Faible cache sur endpoints `discover/*` et `watch/providers/*` → répétés au premier rendu.
- Appels images TMDB séparés par ressource pour backdrops/posters.
- Enrichissement Continue Watching boucle sur éléments et multiplie les fetchs.
- `late final` réassigné sur chaque `build()` du Notifier (crash ponctuel).
- SVG non nettoyés ralentissent le rendu et loggent des warnings.

## Recommandations (rapides, non‑intrusives)
- Réseau/cache:
  - Mémoïser les résultats de `watch/providers` (TTL 6–12 h) et `regions`: `tmdb_watch_providers_remote_data_source.dart:16-60`.
  - Appliquer `cacheTtl: Duration(minutes: 30)` sur `discover/movie`/`discover/tv`: `tmdb_watch_providers_remote_data_source.dart:62-116`.
  - Limiter la pagination trending à 1 page au démarrage, pages supplémentaires en arrière‑plan: `home_feed_repository_impl.dart:48-75`.
  - Conserver `append_to_response` mais désactiver `fetchMovieFull` côté Home si non requis (n’utiliser que `fetchMovieLite` + images via cache): `tmdb_movie_remote_data_source.dart:16-56`.
- Chargement progressif:
  - Déferer les images “détails” et backdrops aux scrolls/visibilité (lazy load) au lieu de précharger toutes.
  - Charger `ContinueWatchingEnrichmentService` après le premier `paint` et interrompre après un budget temps (ex. 250ms) puis reprendre en tâche de fond: `continue_watching_enrichment_service.dart:25-114`.
- UI/Assets:
  - Remplacer les assets SVG problématiques ou migrer vers `vector_graphics`; nettoyer `<defs/>`: voir `lib/src/core/widgets/overlay_splash.dart:41-45` et `movi_bottom_nav_bar.dart:211-217`.
  - Introduire `cached_network_image` pour posters/backdrops et ajuster `PaintingBinding.instance.imageCache.maximumSizeBytes` (256–512MB desktop).
- Robustesse Riverpod:
  - Éviter les `late final` assignés dans `build()`. Utiliser des champs nullable avec guard: `HomeController` → `_repo ??= ref.watch(homeFeedRepositoryProvider)`; idem pour `_loadHero/_loadCw/_loadIptv`: `home_providers.dart:92-104`.

## Alignement avec `docs/future_work/tuning_core_network_and_assets.md`
- Telemetry: filtrer logs >400ms, réduire bruit: `telemetry_interceptor.dart`.
- `tmdb_client.dart`: activer TTL pour endpoints lourds et `retries=2`.
- Search: cache TTL + lazy provider tiles: `search_providers.dart:211-281`.
- SVG: mise à jour `flutter_svg` ou `vector_graphics` et nettoyage.
- Mesures: compter rafales au lancement, p95/p99 via Telemetry.

## Plan d’action priorisé
- P1 Cache & déduplication
  - TTL 30 min sur `discover/*`, mémoise `watch/providers` + `regions`.
  - Déduplication des enrichissements (garder `_enrichedIds` côté Home) déjà présent, vérifier clé.
- P2 Chargement progressif
  - Lazy load images et enrichissements après premier rendu; “hero” limité à page 1.
- P3 Assets & SVG
  - Assainir SVG, envisager `vector_graphics`, réduire warnings.
- P4 Robustesse state
  - Corriger `late final` dans `HomeController` pour éviter `LateInitializationError`.
- P5 Mesures
  - Activer Telemetry avec seuils et collecter métriques de rafales.

## Bénéfices attendus
- Réduction nette des pics de requêtes au démarrage (×2 à ×4 moins d’appels).
- Amélioration du TTI (time‑to‑interactive) grâce au lazy load et au cache.
- Diminution des warnings SVG et du risque de crash Riverpod.
- Chargement perçu plus rapide sans perdre les enrichissements visuels.

## Notes
- Respect Clean Architecture: toutes modifications côté Data/Presentation avec providers/services; pas de logique métier dans Widgets.
- Null‑safety stricte: éviter `!`, guards explicites sur données optionnelles.
# Future Work — Optimisations réseau et assets

Ce document liste les fichiers hors des features demandées (ou dans le core) à modifier pour corriger/optimiser les soucis constatés: rafales TMDB, absence de cache sur certains endpoints, logs HTTP verbeux, avertissements SVG, et gestion d’images.

## Réseau / Core
- `lib/src/core/network/interceptors/telemetry_interceptor.dart`: ajouter un seuil (ex. `> 400ms`) avant log; ou désactiver via flag config.
- `lib/src/core/network/http_client_factory.dart`: exposer le flag `featureFlags.telemetry.enableTelemetry` par environnement; revoir ordre des interceptors si nécessaire.
- `lib/src/core/network/network_executor.dart`: vérifier capacité initiale du limiteur et p95; documenter l’usage de `cacheTtl` côté appelants.
- `lib/src/shared/data/services/tmdb_client.dart`: passer `cacheTtl` pour `discover/*` et endpoints lourds; augmenter `retries` à 2 pour routes lentes.

## Recherche (hors périmètre demandé mais impactée)
- `lib/src/features/search/presentation/providers/search_providers.dart:211–281`: 
  - ajouter `cacheTtl: Duration(minutes: 30)` dans `client.getJson` pour `discover/movie` et `discover/tv`.
  - étaler les appels par visibilité (lazy load des tuiles providers).
- `lib/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart:20–57`:
  - mémoïser la région/les providers (TTL 6–12 h) pour éviter des appels répétés.

## TV Detail (support et robustesse)
- `lib/src/features/tv/presentation/pages/tv_detail_page.dart:104–140`: renforcer la relance automatique par backoff+jitter et limiter les tentatives.
- `lib/src/features/tv/presentation/providers/tv_detail_providers.dart:303, 775–811`: auditer le cycle cache/lecture; éviter boucles de fetch si clé de cache instable.

## Assets / Images
- Introduire `cached_network_image` pour posters/backdrops là où approprié (Home, Recherche, Person, Library) pour cache disque.
- Ajuster le cache images Flutter desktop:
  - `PaintingBinding.instance.imageCache.maximumSizeBytes` à 256–512 MB selon RAM.
- Tailles TMDB cohérentes via `TmdbImageResolver` (`poster: w342/w500`, `backdrop: w780`), éviter `original`.

## SVG
- Mettre à jour `flutter_svg` ou migrer vers `vector_graphics` pour compilation build-time.
- Auditer les assets SVG utilisés dans:
  - `lib/src/core/widgets/overlay_splash.dart:41–45`
  - `lib/src/core/widgets/movi_bottom_nav_bar.dart:211–217`
- Nettoyer les SVG problématiques (supprimer `<defs/>` vide) ou ré-exporter.

## Vérification & Mesures
- Ajouter métriques: compter les rafales d’appels au lancement, suivre p95/p99 via `TelemetryInterceptor` (après filtrage).
- Mettre en place tests d’intégration réseau simulant une page avec 6 providers et valider:
  - déduplication effective,
  - respect du `cacheTtl` appliqué,
  - absence de tempête d’appels au premier rendu.
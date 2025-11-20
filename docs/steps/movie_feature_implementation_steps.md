# Plan d’implémentation — Feature Movie

## Étape 1 — DI unifiée via Riverpod
- Objectif: Une seule source de vérité pour `MovieRepository` et dépendances.
- Actions:
  - Créer providers pour `TmdbMovieRemoteDataSource`, `MovieLocalDataSource`, `WatchlistLocalRepository`.
  - Mettre à jour `movieRepositoryProvider` pour composer ces providers.
  - Adapter `movie_detail_providers.dart` pour n’utiliser que ces providers.
  - Désactiver l’enregistrement du `MovieRepository` dans `movie_data_module.dart` (garder legacy si nécessaire).
- Fichiers à modifier: `presentation/providers/movie_detail_providers.dart`, `data/movie_data_module.dart`.
- Critères d’acceptation: Aucun accès direct à `sl` pour `MovieRepository` dans la présentation.

## Étape 2 — Découper `MovieDetailPage` en sous‑widgets
- Objectif: Réduire la complexité UI et isoler les responsabilités.
- Actions:
  - Créer `MovieDetailHeroSection`, `MovieDetailMainActions`, `MovieDetailSynopsisSection`, `MovieDetailCastSection`, `MovieDetailSagaSection`, `MovieDetailRecommendationsSection`.
  - Extraire `_buildHeroImage` en `MovieHeroImage` réutilisable.
  - Adapter `MovieDetailPage` pour composer ces widgets dans `_buildWithValues`.
- Fichiers à modifier/ajouter: `presentation/pages/movie_detail_page.dart`, nouveaux widgets sous `presentation/widgets/`.
- Critères d’acceptation: `MovieDetailPage` sert d’orchestrateur, ≤ logique UI minimale.

## Étape 3 — Extraire la logique métier en use cases/services
- Objectif: Sortir IPTV/favoris/historique de l’UI, rendre testable.
- Actions:
  - Créer use cases: `MarkMovieAsSeen`, `MarkMovieAsUnseen`, `AddMovieToPlaylist`, `GetMovieAvailabilityOnIptv`, `BuildMovieVideoSource`.
  - Créer `XtreamLookupService` pour trouver l’`XtreamPlaylistItem` par `movieId` et le réutiliser.
  - Ajouter providers Riverpod pour ces use cases et les consommer dans la page.
  - Remplacer `_playMovie` par appel à `buildMovieVideoSourceProvider(movieId).future` + navigation.
- Fichiers: `domain/usecases/`, `shared/domain/services/xtream_lookup_service.dart`, `presentation/providers/movie_detail_providers.dart`, `presentation/pages/movie_detail_page.dart`.
- Critères: Méthodes UI réduites à des appels de use cases; pas d’accès direct aux repos dans la page.

## Étape 4 — Déplacer les providers “inline” dans `providers/`
- Objectif: Conventions Riverpod claires et réutilisables.
- Actions:
  - Déplacer `_movieAvailabilityProvider`, `_movieSeenProvider`, `_movieHistoryProvider` vers `presentation/providers/movie_detail_providers.dart`.
  - Les renommer: `movieAvailabilityProvider`, `movieSeenProvider`, `movieHistoryProvider`.
  - Mettre à jour les imports et usages dans la page.
- Critères: Aucun provider défini dans un `State`.

## Étape 5 — Mutualiser le cache TMDB
- Objectif: Éviter les doubles requêtes `fetchMovieFull`.
- Actions:
  - Définir le contrat de cache côté `MovieLocalDataSource` (clean, typé):
    - Clés: `movie:<lang>:<tmdbId>:detail` et `movie:<lang>:<tmdbId>:reco`.
    - Contenu: DTOs TMDB stables (pas de JSON brut en domaine), champs requis par UI.
    - TTL: 24h par défaut (paramétrable), aucune boucle de retry infinie.
  - Étendre `MovieLocalDataSource`:
    - `saveRecommendations(MovieId id, List<MovieSummaryDto> items, {required String lang})`.
    - `getCachedRecommendations(MovieId id, {required String lang}) -> List<MovieSummaryDto>?`.
  - Mettre à jour `MovieRepositoryImpl.getMovie`:
    - Après `saveMovieDetail`, si des recommandations sont disponibles (payload TMDB), appeler `saveRecommendations`.
    - Logs sobres (`debug/info`), mapping d’erreurs réseau → échecs typés.
  - Adapter `MovieRepositoryImpl.getRecommendations`:
    - Lire en priorité `getCachedRecommendations(id, lang)`.
    - Si cache manquant/expiré: fetch TMDB, puis `saveRecommendations`.
    - Respect de la langue courante (clé de cache incluant `lang`).
  - Vérifier les invalidations pertinentes (changement de langue, clear cache).
- Fichiers: `data/repositories/movie_repository_impl.dart`, `data/datasources/movie_local_data_source.dart`.
- Critères: Un seul fetch pour détail + reco sur cache froid.

## Étape 6 — i18n stricte et micro‑optimisations OK OK
- Objectif: Zéro chaîne en dur et UI plus performante/lisible.
- Actions:
  - Ajouter dans ARB toutes les chaînes listées (ex: “Aucune playlist disponible”, “Voir la page”, …).
  - Remplacer dans `movie_detail_page.dart` par `AppLocalizations`.
  - Ajouter `const` là où possible; factoriser les espacements via `AppSpacing`.
- Fichiers: `l10n/*.arb`, `presentation/pages/movie_detail_page.dart`, `core/utils/app_spacing.dart` (si absent).
- Critères: Pas de hard‑coded strings; lints `prefer_const_constructors` améliorés.

## Étape 7 — Null‑safety des timers et guards
- Objectif: Éliminer crashs potentiels liés à `media == null`.
- Actions:
  - Protéger `initState` pour ne démarrer le timer que si `widget.media != null`.
  - Re‑checker dans `_startAutoRefreshTimer` avant d’accéder à `.id`.
- Fichiers: `presentation/pages/movie_detail_page.dart`.
- Critères: Aucun `!` sur `widget.media`; pas de accès non‑null sans guard.

## Étape 8 — Validation (lint/analyze)
- Objectif: Qualité et cohérence.
- Actions:
  - Lancer `dart format .` et `flutter analyze`.
  - Corriger warnings liés aux imports inutiles/const/flow control.
- Critères: Analyse sans warnings bloquants; formatage conforme.

## Notes d’implémentation
- Respecter Clean Architecture: Domain sans Flutter/JSON; mapping en Data; Presentation utilise providers.
- DI: privilégier Riverpod; pas d’instances cachées.
- Sécurité: pas de logs sensibles; timeouts/retry centralisés.
- Performance: éviter re‑fetch; mesurer avant d’optimiser.
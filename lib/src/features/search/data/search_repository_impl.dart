import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/data/datasources/tmdb_search_remote_data_source.dart';
import 'package:movi/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart';
import 'package:movi/src/features/search/data/dtos/tmdb_watch_provider_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_discovery_cache_data_source.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/shared/domain/services/playlist_tmdb_enrichment_service.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(
    this._remote,
    this._watchProvidersRemote,
    this._discoveryCache,
    this._images,
    this._catalogReader,
    this._similarity,
    this._enrichmentService,
    this._tmdbIdResolver,
    this._appState,
  );

  final TmdbSearchRemoteDataSource _remote;
  final TmdbWatchProvidersRemoteDataSource _watchProvidersRemote;
  final TmdbDiscoveryCacheDataSource _discoveryCache;
  final TmdbImageResolver _images;
  final IptvCatalogReader _catalogReader;
  final SimilarityService _similarity;
  final ContentEnrichmentService _enrichmentService;
  final TmdbIdResolverService _tmdbIdResolver;
  final AppStateController _appState;

  @override
  Future<SearchPage<MovieSummary>> searchMovies(
    String query, {
    int page = 1,
  }) async {
    final q = query.trim();
    final refs = await _catalogReader.searchCatalog(
      query,
      activeSourceIds: _appState.preferredIptvSourceIds,
    );
    final items = <MovieSummary>[];
    for (final ref in refs) {
      if (ref.type != ContentType.movie) continue;

      // Enrichir avec TMDB si le poster est manquant
      final enrichedRef = await _enrichIptvReferenceForSearch(ref);

      // Inclure l'item seulement si le poster est disponible après enrichissement
      // MovieSummary nécessite un poster non-null
      if (enrichedRef.poster != null) {
        final tmdbId = int.tryParse(enrichedRef.id);
        items.add(
          MovieSummary(
            id: MovieId(enrichedRef.id),
            tmdbId: tmdbId,
            title: MediaTitle(enrichedRef.title.value),
            poster: enrichedRef.poster!,
            backdrop: null,
            releaseYear: null,
          ),
        );
      }
    }
    // Déduplication par tmdbId (on garde l'élément le plus proche de la requête)
    final bestByTmdb = <int, MovieSummary>{};
    final withoutTmdb = <MovieSummary>[];
    for (final m in items) {
      final id = m.tmdbId;
      if (id == null) {
        withoutTmdb.add(m);
        continue;
      }
      final current = bestByTmdb[id];
      if (current == null) {
        bestByTmdb[id] = m;
      } else {
        final scoreNew = _similarity.score(q, m.title.value);
        final scoreCur = _similarity.score(q, current.title.value);
        if (scoreNew > scoreCur) {
          bestByTmdb[id] = m;
        }
      }
    }
    final unique = <MovieSummary>[...bestByTmdb.values, ...withoutTmdb];
    // Tri par similarité décroissant
    unique.sort((a, b) {
      final sa = _similarity.score(q, a.title.value);
      final sb = _similarity.score(q, b.title.value);
      return sb.compareTo(sa);
    });
    return SearchPage(items: List.unmodifiable(unique), page: 1, totalPages: 1);
  }

  @override
  Future<SearchPage<TvShowSummary>> searchShows(
    String query, {
    int page = 1,
  }) async {
    final q = query.trim();
    final refs = await _catalogReader.searchCatalog(
      query,
      activeSourceIds: _appState.preferredIptvSourceIds,
    );
    final items = <TvShowSummary>[];
    for (final ref in refs) {
      if (ref.type != ContentType.series) continue;

      // Enrichir avec TMDB si le poster est manquant
      final enrichedRef = await _enrichIptvReferenceForSearch(ref);

      // Inclure l'item seulement si le poster est disponible après enrichissement
      // TvShowSummary nécessite un poster non-null
      if (enrichedRef.poster != null) {
        final tmdbId = int.tryParse(enrichedRef.id);
        items.add(
          TvShowSummary(
            id: SeriesId(enrichedRef.id),
            tmdbId: tmdbId,
            title: MediaTitle(enrichedRef.title.value),
            poster: enrichedRef.poster!,
            backdrop: null,
            seasonCount: null,
            status: null,
          ),
        );
      }
    }
    // Déduplication par tmdbId (on garde l'élément le plus proche de la requête)
    final bestByTmdb = <int, TvShowSummary>{};
    final withoutTmdb = <TvShowSummary>[];
    for (final s in items) {
      final id = s.tmdbId;
      if (id == null) {
        withoutTmdb.add(s);
        continue;
      }
      final current = bestByTmdb[id];
      if (current == null) {
        bestByTmdb[id] = s;
      } else {
        final scoreNew = _similarity.score(q, s.title.value);
        final scoreCur = _similarity.score(q, current.title.value);
        if (scoreNew > scoreCur) {
          bestByTmdb[id] = s;
        }
      }
    }
    final unique = <TvShowSummary>[...bestByTmdb.values, ...withoutTmdb];
    unique.sort((a, b) {
      final sa = _similarity.score(q, a.title.value);
      final sb = _similarity.score(q, b.title.value);
      return sb.compareTo(sa);
    });
    return SearchPage(items: List.unmodifiable(unique), page: 1, totalPages: 1);
  }

  @override
  Future<SearchPage<PersonSummary>> searchPeople(
    String query, {
    int page = 1,
  }) async {
    final res = await _remote.searchPeople(query, page: page);
    final mapped = res.items.map(_mapPerson).toList(growable: true);
    final q = query.trim();
    mapped.sort((a, b) {
      final sa = _similarity.score(q, a.name);
      final sb = _similarity.score(q, b.name);
      return sb.compareTo(sa);
    });
    return SearchPage(
      items: List.unmodifiable(mapped),
      page: page,
      totalPages: res.totalPages,
    );
  }

  @override
  Future<List<WatchProvider>> getWatchProviders(String region) async {
    final language = _languageCode;
    final cached = await _discoveryCache.getCachedWatchProviders(
      region: region,
      language: language,
    );
    if (cached.value != null) {
      return cached.value!.map(_mapWatchProvider).toList(growable: false);
    }

    final remote = await _watchProvidersRemote.fetchWatchProviders(
      language: language,
      watchRegion: region,
    );
    await _discoveryCache.putWatchProviders(
      remote,
      region: region,
      language: language,
    );

    return remote.map(_mapWatchProvider).toList();
  }

  @override
  Future<SearchPage<MovieSummary>> getMoviesByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) async {
    final remote = await _watchProvidersRemote.getMoviesByProvider(
      providerId,
      region: region,
      page: page,
    );
    final items = <MovieSummary>[];
    for (final dto in remote.items) {
      final poster = _images.poster(dto.posterPath);
      if (poster != null) {
        items.add(_mapMovieDto(dto, poster));
      }
    }
    return SearchPage(
      items: items,
      page: remote.page,
      totalPages: remote.totalPages,
    );
  }

  @override
  Future<SearchPage<TvShowSummary>> getShowsByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) async {
    final remote = await _watchProvidersRemote.getShowsByProvider(
      providerId,
      region: region,
      page: page,
    );
    final items = <TvShowSummary>[];
    for (final dto in remote.items) {
      final poster = _images.poster(dto.posterPath);
      if (poster != null) {
        items.add(_mapTvDto(dto, poster));
      }
    }
    return SearchPage(
      items: items,
      page: remote.page,
      totalPages: remote.totalPages,
    );
  }

  PersonSummary _mapPerson(TmdbPersonDetailDto dto) {
    return PersonSummary(
      id: PersonId(dto.id.toString()),
      tmdbId: dto.id,
      name: dto.name,
      photo: _images.poster(dto.profilePath),
    );
  }

  WatchProvider _mapWatchProvider(TmdbWatchProviderDto dto) {
    return WatchProvider(
      providerId: dto.providerId,
      providerName: dto.providerName,
      logoPath: _images.poster(dto.logoPath)?.toString(),
      displayPriority: dto.displayPriority,
    );
  }

  MovieSummary _mapMovieDto(TmdbMovieSummaryDto dto, Uri poster) {
    return MovieSummary(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.title),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      releaseYear: dto.releaseDate != null && dto.releaseDate!.length >= 4
          ? int.tryParse(dto.releaseDate!.substring(0, 4))
          : null,
    );
  }

  TvShowSummary _mapTvDto(TmdbTvSummaryDto dto, Uri poster) {
    return TvShowSummary(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      seasonCount: null,
      status: null,
    );
  }

  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  Future<ContentReference> _enrichIptvReferenceForSearch(
    ContentReference reference,
  ) async {
    var current = await _resolveMissingTmdbId(reference);
    if (current.poster == null) {
      current = await _enrichmentService.enrichPoster(current);
    }
    if (current.year == null) {
      current = await _enrichmentService.enrichYear(current);
    }
    return current;
  }

  Future<ContentReference> _resolveMissingTmdbId(
    ContentReference reference,
  ) async {
    if (int.tryParse(reference.id) != null) {
      return reference;
    }

    final title = reference.title.value.trim();
    if (title.isEmpty) {
      return reference;
    }

    int? tmdbId;
    switch (reference.type) {
      case ContentType.movie:
        tmdbId = await _tmdbIdResolver.searchTmdbIdByTitleForMovie(
          title: title,
          releaseYear: reference.year,
        );
        break;
      case ContentType.series:
        tmdbId = await _tmdbIdResolver.searchTmdbIdByTitleForTv(
          title: title,
          releaseYear: reference.year,
        );
        break;
      default:
        return reference;
    }

    if (tmdbId == null || tmdbId <= 0) {
      return reference;
    }

    return reference.copyWith(id: tmdbId.toString());
  }
}

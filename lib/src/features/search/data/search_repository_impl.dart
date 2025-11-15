import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/data/datasources/tmdb_search_remote_data_source.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(
    this._remote,
    this._images,
    this._catalogReader,
    this._similarity,
  );

  final TmdbSearchRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final IptvCatalogReader _catalogReader;
  final SimilarityService _similarity;

  @override
  Future<SearchPage<MovieSummary>> searchMovies(
    String query, {
    int page = 1,
  }) async {
    final q = query.trim();
    final refs = await _catalogReader.searchCatalog(query);
    final items = <MovieSummary>[];
    for (final ref in refs) {
      if (ref.type != ContentType.movie) continue;
      final poster = ref.poster;
      if (poster == null) continue;
      final tmdbId = int.tryParse(ref.id);
      items.add(
        MovieSummary(
          id: MovieId(ref.id),
          tmdbId: tmdbId,
          title: MediaTitle(ref.title.value),
          poster: poster,
          backdrop: null,
          releaseYear: null,
        ),
      );
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
    final refs = await _catalogReader.searchCatalog(query);
    final items = <TvShowSummary>[];
    for (final ref in refs) {
      if (ref.type != ContentType.series) continue;
      final poster = ref.poster;
      if (poster == null) continue;
      final tmdbId = int.tryParse(ref.id);
      items.add(
        TvShowSummary(
          id: SeriesId(ref.id),
          tmdbId: tmdbId,
          title: MediaTitle(ref.title.value),
          poster: poster,
          backdrop: null,
          seasonCount: null,
          status: null,
        ),
      );
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

  PersonSummary _mapPerson(TmdbPersonDetailDto dto) {
    return PersonSummary(
      id: PersonId(dto.id.toString()),
      tmdbId: dto.id,
      name: dto.name,
      photo: _images.poster(dto.profilePath),
    );
  }
}

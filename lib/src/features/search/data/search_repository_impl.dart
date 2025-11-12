import '../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../core/iptv/domain/entities/xtream_playlist_item.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../../movie/domain/entities/movie_summary.dart';
import '../../tv/domain/entities/tv_show.dart';
import '../../person/data/dtos/tmdb_person_detail_dto.dart';
import '../../../shared/domain/entities/person_summary.dart';
import '../domain/entities/search_page.dart';
import '../domain/repositories/search_repository.dart';
import 'datasources/tmdb_search_remote_data_source.dart';
import '../../../shared/domain/value_objects/media_title.dart';
import '../../../shared/domain/services/similarity_service.dart';
import '../../../shared/domain/value_objects/media_id.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(
    this._remote,
    this._images,
    this._iptvLocal,
    this._similarity,
  );

  final TmdbSearchRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final IptvLocalRepository _iptvLocal;
  final SimilarityService _similarity;

  @override
  Future<SearchPage<MovieSummary>> searchMovies(
    String query, {
    int page = 1,
  }) async {
    final accounts = await _iptvLocal.getAccounts();
    final q = query.trim();
    final items = <MovieSummary>[];
    for (final acc in accounts) {
      final playlists = await _iptvLocal.getPlaylists(acc.id);
      for (final pl in playlists) {
        for (final it in pl.items) {
          if (it.type != XtreamPlaylistItemType.movie) continue;
          final title = it.title.trim();
          final posterUrl = it.posterUrl;
          if (posterUrl == null || posterUrl.isEmpty) continue;
          // Filtre texte simple (contient) avant scoring
          if (q.isNotEmpty && !title.toLowerCase().contains(q.toLowerCase())) {
            // on garde quand même pour scoring si besoin ; ici on skip pour limiter bruit
            continue;
          }
          final poster = Uri.tryParse(posterUrl);
          if (poster == null) continue;
          items.add(
            MovieSummary(
              id: MovieId((it.tmdbId?.toString()) ?? it.streamId.toString()),
              tmdbId: it.tmdbId,
              title: MediaTitle(title),
              poster: poster,
              backdrop: null,
              releaseYear: null,
            ),
          );
        }
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
    final accounts = await _iptvLocal.getAccounts();
    final q = query.trim();
    final items = <TvShowSummary>[];
    for (final acc in accounts) {
      final playlists = await _iptvLocal.getPlaylists(acc.id);
      for (final pl in playlists) {
        for (final it in pl.items) {
          if (it.type != XtreamPlaylistItemType.series) continue;
          final title = it.title.trim();
          final posterUrl = it.posterUrl;
          if (posterUrl == null || posterUrl.isEmpty) continue;
          if (q.isNotEmpty && !title.toLowerCase().contains(q.toLowerCase())) {
            continue;
          }
          final poster = Uri.tryParse(posterUrl);
          if (poster == null) continue;
          items.add(
            TvShowSummary(
              id: SeriesId((it.tmdbId?.toString()) ?? it.streamId.toString()),
              tmdbId: it.tmdbId,
              title: MediaTitle(title),
              poster: poster,
              backdrop: null,
              seasonCount: null,
              status: null,
            ),
          );
        }
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

  PersonSummary _mapPerson(TmdbPersonDetailDto dto) {
    return PersonSummary(
      id: PersonId(dto.id.toString()),
      tmdbId: dto.id,
      name: dto.name,
      photo: _images.poster(dto.profilePath),
    );
  }
}

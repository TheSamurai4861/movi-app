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
import '../../movie/data/dtos/tmdb_movie_detail_dto.dart';
import '../../tv/data/dtos/tmdb_tv_detail_dto.dart';
import '../../../shared/domain/value_objects/media_title.dart';
import '../../../shared/domain/value_objects/media_id.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(
    this._remote,
    this._images,
    this._iptvLocal,
  );

  final TmdbSearchRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final IptvLocalRepository _iptvLocal;

  @override
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1}) async {
    final res = await _remote.searchMovies(query, page: page);
    final available = await _iptvLocal.getAvailableTmdbIds(type: XtreamPlaylistItemType.movie);
    final items = res.items
        .where((m) => m.posterPath != null && available.contains(m.id))
        .map(_mapMovie)
        .whereType<MovieSummary>()
        .toList(growable: false);
    return SearchPage(items: items, page: page, totalPages: res.totalPages);
  }

  @override
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1}) async {
    final res = await _remote.searchShows(query, page: page);
    final available = await _iptvLocal.getAvailableTmdbIds(type: XtreamPlaylistItemType.series);
    final items = res.items
        .where((s) => s.posterPath != null && available.contains(s.id))
        .map(_mapShow)
        .whereType<TvShowSummary>()
        .toList(growable: false);
    return SearchPage(items: items, page: page, totalPages: res.totalPages);
  }

  @override
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1}) async {
    final res = await _remote.searchPeople(query, page: page);
    final items = res.items.map(_mapPerson).toList(growable: false);
    return SearchPage(items: items, page: page, totalPages: res.totalPages);
  }

  MovieSummary? _mapMovie(TmdbMovieSummaryDto dto) {
    final poster = _images.poster(dto.posterPath, size: 'w342');
    if (poster == null) return null;
    return MovieSummary(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.title),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      releaseYear: _parseYear(dto.releaseDate),
    );
  }

  TvShowSummary? _mapShow(TmdbTvSummaryDto dto) {
    final poster = _images.poster(dto.posterPath, size: 'w342');
    if (poster == null) return null;
    return TvShowSummary(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      seasonCount: null,
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

  int? _parseYear(String? raw) => (raw != null && raw.isNotEmpty) ? int.tryParse(raw.substring(0, 4)) : null;
}

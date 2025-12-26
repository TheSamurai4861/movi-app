import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';

class SagaRepositoryImpl implements SagaRepository {
  SagaRepositoryImpl(this._remote, this._images, this._local, this._watchlist);

  final TmdbSagaRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final SagaLocalDataSource _local;
  final WatchlistLocalRepository _watchlist;

  @override
  Future<Saga> getSaga(SagaId id) async {
    final sagaId = int.parse(id.value);
    // Try local cache first
    final cached = await _local.getSagaDetail(sagaId);
    final dto = await (() async {
      if (cached != null) return cached;
      try {
        final remote = await _remote.fetchSaga(sagaId);
        await _local.saveSagaDetail(remote);
        return remote;
      } catch (_) {
        // If remote fails and no cache, rethrow
        rethrow;
      }
    })();

    // Enrich parts with runtime when possible
    final parts = await Future.wait(
      dto.parts.map((part) async {
        try {
          final runtime =
              part.runtime ?? await _remote.fetchMovieRuntime(part.id);
          return part.copyWith(runtime: runtime);
        } catch (_) {
          return part; // keep existing data if runtime call fails
        }
      }),
    );

    final cacheChanged = dto.parts.length == parts.length
        ? List.generate(
          dto.parts.length,
          (i) => dto.parts[i].runtime != parts[i].runtime,
        ).any((changed) => changed)
        : true;
    if (cacheChanged) {
      await _local.saveSagaDetail(dto.copyWith(parts: parts));
    }
    final entries = parts
        .map(
          (part) => SagaEntry(
            reference: ContentReference(
              id: part.id.toString(),
              title: MediaTitle(part.title),
              type: ContentType.movie,
              poster: _images.poster(part.posterPath),
            ),
            duration: part.runtime == null
                ? null
                : Duration(minutes: part.runtime!),
            notes: null,
            timelineYear: _parseDate(part.releaseDate)?.year,
          ),
        )
        .toList();

    return Saga(
      id: SagaId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      synopsis: dto.overview.isEmpty ? null : Synopsis(dto.overview),
      cover: _images.poster(dto.posterPath),
      timeline: entries,
      tags: const [],
      updatedAt: DateTime.now(),
    );
  }

  @override
  /// Returns user sagas scoped by `userId` using the watchlist storage.
  ///
  /// Entries are ordered by `added_at DESC` at the storage level and mapped
  /// to `SagaSummary`, filtering out items without a poster.
  Future<List<SagaSummary>> getUserSagas(String userId) async {
    final entries = await _watchlist.readAll(ContentType.saga, userId: userId);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => SagaSummary(
            id: SagaId(e.contentId),
            title: MediaTitle(e.title),
            cover: e.poster!,
          ),
        )
        .toList();
  }

  @override
  Future<List<SagaSummary>> searchSagas(String query) async {
    final dtos = await _remote.searchSagas(query);
    return dtos
        .map(
          (dto) => SagaSummary(
            id: SagaId(dto.id.toString()),
            tmdbId: dto.id,
            title: MediaTitle(dto.name),
            cover: _images.poster(dto.posterPath),
            itemCount: dto.parts.length,
          ),
        )
        .toList();
  }

  DateTime? _parseDate(String? date) =>
      date == null || date.isEmpty ? null : DateTime.tryParse(date);
}

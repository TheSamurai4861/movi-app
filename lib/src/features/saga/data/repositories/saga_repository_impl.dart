import 'dart:async';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';

class SagaRepositoryImpl implements SagaRepository {
  SagaRepositoryImpl(this._remote, this._images, this._local, this._watchlist);

  final TmdbSagaRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final SagaLocalDataSource _local;
  final WatchlistLocalRepository _watchlist;
  final Map<String, Future<Saga>> _inFlightSagaLoads = <String, Future<Saga>>{};
  static const int _maxConcurrentRuntimeFetches = 3;

  @override
  Future<Saga> getSaga(SagaId id) async {
    final sagaId = int.parse(id.value);
    final language = _remote.currentLanguageCode;
    final inFlightKey = '$language:$sagaId';
    final existing = _inFlightSagaLoads[inFlightKey];
    if (existing != null) {
      _log(
        'saga_get_join_inflight',
        context: <String, Object?>{'sagaId': sagaId, 'language': language},
      );
      return existing;
    }
    final future = _loadSaga(id, sagaId: sagaId, language: language);
    _inFlightSagaLoads[inFlightKey] = future;
    return future.whenComplete(() => _inFlightSagaLoads.remove(inFlightKey));
  }

  Future<Saga> _loadSaga(
    SagaId id, {
    required int sagaId,
    required String language,
  }) async {
    final stopwatch = Stopwatch()..start();
    _log(
      'saga_get_started',
      context: <String, Object?>{'sagaId': sagaId, 'language': language},
    );

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

    final missingRuntimeCount = dto.parts
        .where((p) => p.runtime == null)
        .length;
    var runtimeFetchCount = 0;
    final parts = await _enrichPartsWithBoundedRuntimeFetches(
      dto.parts,
      onRuntimeFetch: () => runtimeFetchCount++,
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

    final saga = Saga(
      id: SagaId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      synopsis: dto.overview.isEmpty ? null : Synopsis(dto.overview),
      cover: _images.poster(dto.posterPath),
      timeline: entries,
      tags: const [],
      updatedAt: DateTime.now(),
    );
    stopwatch.stop();
    _log(
      'saga_get_completed',
      context: <String, Object?>{
        'sagaId': sagaId,
        'language': language,
        'partsCount': dto.parts.length,
        'missingRuntimeCount': missingRuntimeCount,
        'runtimeFetchCount': runtimeFetchCount,
        'cacheChanged': cacheChanged,
        'durationMs': stopwatch.elapsedMilliseconds,
      },
    );
    return saga;
  }

  Future<List<TmdbSagaPartDto>> _enrichPartsWithBoundedRuntimeFetches(
    List<TmdbSagaPartDto> parts, {
    required void Function() onRuntimeFetch,
  }) async {
    if (parts.isEmpty) return const <TmdbSagaPartDto>[];
    final resolvedParts = List<TmdbSagaPartDto?>.filled(parts.length, null);
    var cursor = 0;

    Future<void> worker() async {
      while (true) {
        if (cursor >= parts.length) break;
        final index = cursor++;
        final part = parts[index];
        if (part.runtime != null) {
          resolvedParts[index] = part;
          continue;
        }
        try {
          onRuntimeFetch();
          final runtime = await _remote.fetchMovieRuntime(part.id);
          resolvedParts[index] = part.copyWith(runtime: runtime);
        } catch (_) {
          resolvedParts[index] = part;
        }
      }
    }

    final workers = List<Future<void>>.generate(
      parts.length < _maxConcurrentRuntimeFetches
          ? parts.length
          : _maxConcurrentRuntimeFetches,
      (_) => worker(),
    );
    await Future.wait(workers);
    return resolvedParts.cast<TmdbSagaPartDto>();
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

  void _log(
    String event, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final logger = sl<AppLogger>();
    final payload = context.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    logger.debug(
      '$event${payload.isEmpty ? '' : ' $payload'}',
      category: 'saga_repository',
    );
  }
}

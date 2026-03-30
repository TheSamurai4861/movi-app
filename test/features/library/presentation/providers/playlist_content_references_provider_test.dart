import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/services/playlist_tmdb_enrichment_service.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  test(
    'playlistContentReferencesProvider keeps raw references when enrichment fails',
    () async {
      final rawReference = ContentReference(
        id: 'xtream:100',
        title: MediaTitle('The Matrix'),
        type: ContentType.movie,
      );

      sl.registerSingleton<AppLogger>(_MemoryLogger());
      sl.registerSingleton<ContentEnrichmentService>(
        _ThrowingContentEnrichmentService(),
      );

      final container = ProviderContainer(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(
            _FakePlaylistRepository(
              playlist: _playlistWithReference(rawReference),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        playlistContentReferencesProvider('playlist-1'),
        (_, __) {},
      );
      addTearDown(subscription.close);

      await container.read(playlistItemsProvider('playlist-1').future);

      final results = await container.read(
        playlistContentReferencesProvider('playlist-1').future,
      );

      expect(results, [rawReference]);
    },
  );

  test(
    'playlistContentReferencesProvider returns enriched references when available',
    () async {
      final rawReference = ContentReference(
        id: '42',
        title: MediaTitle('Inception'),
        type: ContentType.movie,
      );
      final enrichedReference = rawReference.copyWith(year: Optional.of(2010));

      sl.registerSingleton<AppLogger>(_MemoryLogger());
      sl.registerSingleton<ContentEnrichmentService>(
        _StubContentEnrichmentService(enrichedReference),
      );

      final container = ProviderContainer(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(
            _FakePlaylistRepository(
              playlist: _playlistWithReference(rawReference),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        playlistContentReferencesProvider('playlist-1'),
        (_, __) {},
      );
      addTearDown(subscription.close);

      await container.read(playlistItemsProvider('playlist-1').future);

      final results = await container.read(
        playlistContentReferencesProvider('playlist-1').future,
      );

      expect(results, [enrichedReference]);
    },
  );
}

Playlist _playlistWithReference(ContentReference reference) {
  return Playlist(
    id: PlaylistId('playlist-1'),
    title: MediaTitle('Tests'),
    items: <PlaylistItem>[PlaylistItem(reference: reference, position: 1)],
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
    owner: 'tester',
  );
}

class _FakePlaylistRepository implements PlaylistRepository {
  _FakePlaylistRepository({required this.playlist});

  final Playlist playlist;

  @override
  Future<Playlist> getPlaylist(PlaylistId id) async => playlist;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _ThrowingContentEnrichmentService implements ContentEnrichmentService {
  @override
  Future<ContentReference> enrichPoster(ContentReference reference) async {
    return reference;
  }

  @override
  Future<ContentReference> enrichYear(ContentReference reference) async {
    throw StateError('TMDB unavailable');
  }
}

class _StubContentEnrichmentService implements ContentEnrichmentService {
  _StubContentEnrichmentService(this.enrichedReference);

  final ContentReference enrichedReference;

  @override
  Future<ContentReference> enrichPoster(ContentReference reference) async {
    return enrichedReference;
  }

  @override
  Future<ContentReference> enrichYear(ContentReference reference) async {
    return enrichedReference;
  }
}

class _MemoryLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void warn(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

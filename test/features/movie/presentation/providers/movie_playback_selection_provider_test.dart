import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/domain/services/movie_playback_variant_resolver.dart';
import 'package:movi/src/features/movie/domain/services/iptv_availability_service.dart';
import 'package:movi/src/features/movie/domain/usecases/get_movie_availability_on_iptv.dart';
import 'package:movi/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  test(
    'moviePlaybackSelectionProvider forwards persisted playback preferences',
    () async {
      final localePreferences = _MemoryLocalePreferences();
      final playerPreferences = _FakePlayerPreferences(
        preferredAudioLanguage: 'fr',
        preferredSubtitleLanguage: 'en',
        preferredPlaybackQuality: PreferredPlaybackQuality.ultraHd4k,
      );
      final recordingUseCase = _RecordingResolveMoviePlaybackSelection();

      sl.registerSingleton<LocalePreferences>(localePreferences);
      sl.registerSingleton<PlayerPreferences>(playerPreferences);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-a'),
          resolveMoviePlaybackSelectionUseCaseProvider.overrideWithValue(
            recordingUseCase,
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(localePreferences.dispose);

      container.read(appStateControllerProvider).setActiveIptvSources({
        'source-a',
        'source-b',
      });

      await container.read(
        moviePlaybackSelectionProvider((
          movieId: '603',
          title: 'The Matrix',
          releaseYear: 1999,
          poster: null,
        )).future,
      );

      expect(recordingUseCase.recordedMovieId, '603');
      expect(recordingUseCase.recordedTitle, 'The Matrix');
      expect(recordingUseCase.recordedReleaseYear, 1999);
      expect(recordingUseCase.recordedUserId, 'user-a');
      expect(recordingUseCase.recordedCandidateSourceIds, {
        'source-a',
        'source-b',
      });
      expect(
        recordingUseCase.recordedPreferences,
        const PlaybackSelectionPreferences(
          preferredAudioLanguageCode: 'fr',
          preferredSubtitleLanguageCode: 'en',
          preferredQualityRank: 4,
        ),
      );
      expect(
        recordingUseCase.recordedContext,
        const PlaybackSelectionContext(contentType: ContentType.movie),
      );
    },
  );

  test('movieAvailabilityOnIptvProvider forwards active source ids', () async {
    final localePreferences = _MemoryLocalePreferences();
    final playerPreferences = _FakePlayerPreferences();
    final availabilityUseCase = _RecordingGetMovieAvailabilityOnIptv();

    sl.registerSingleton<LocalePreferences>(localePreferences);
    sl.registerSingleton<PlayerPreferences>(playerPreferences);

    final container = ProviderContainer(
      overrides: [
        getMovieAvailabilityOnIptvUseCaseProvider.overrideWithValue(
          availabilityUseCase,
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(localePreferences.dispose);

    container.read(appStateControllerProvider).setActiveIptvSources({
      'source-a',
      'source-b',
    });

    final isAvailable = await container.read(
      movieAvailabilityOnIptvProvider('603').future,
    );

    expect(isAvailable, isTrue);
    expect(availabilityUseCase.recordedMovieId, '603');
    expect(availabilityUseCase.recordedCandidateSourceIds, {
      'source-a',
      'source-b',
    });
  });
}

class _RecordingResolveMoviePlaybackSelection
    extends ResolveMoviePlaybackSelection {
  _RecordingResolveMoviePlaybackSelection()
    : super(
        const _FakeMoviePlaybackVariantResolver(),
        const PlaybackSelectionService(),
        const _FakePlaybackHistoryRepository(),
        _SilentLogger(),
        PerformanceDiagnosticLogger(_SilentLogger()),
      );

  String? recordedMovieId;
  String? recordedTitle;
  String? recordedUserId;
  int? recordedReleaseYear;
  Set<String>? recordedCandidateSourceIds;
  PlaybackSelectionPreferences? recordedPreferences;
  PlaybackSelectionContext? recordedContext;

  @override
  Future<PlaybackSelectionDecision> call({
    required String movieId,
    required String title,
    required PlaybackSelectionPreferences preferences,
    required PlaybackSelectionContext context,
    int? releaseYear,
    Uri? poster,
    String? userId,
    Set<String>? candidateSourceIds,
  }) async {
    recordedMovieId = movieId;
    recordedTitle = title;
    recordedReleaseYear = releaseYear;
    recordedUserId = userId;
    recordedCandidateSourceIds = candidateSourceIds;
    recordedPreferences = preferences;
    recordedContext = context;

    return PlaybackSelectionDecision(
      disposition: PlaybackSelectionDisposition.autoPlay,
      reason: PlaybackSelectionReason.singlePlayableVariant,
      rankedVariants: <PlaybackVariant>[
        PlaybackVariant(
          id: 'source-b:42',
          sourceId: 'source-b',
          sourceLabel: 'Bedroom',
          videoSource: const VideoSource(
            url: 'https://video.example/42.mp4',
            title: 'The Matrix',
            contentId: '603',
            contentType: ContentType.movie,
          ),
          contentType: ContentType.movie,
          rawTitle: 'The.Matrix.1999.1080p',
          normalizedTitle: 'The Matrix',
          qualityLabel: 'Full HD',
          qualityRank: 3,
        ),
      ],
      selectedVariant: PlaybackVariant(
        id: 'source-b:42',
        sourceId: 'source-b',
        sourceLabel: 'Bedroom',
        videoSource: const VideoSource(
          url: 'https://video.example/42.mp4',
          title: 'The Matrix',
          contentId: '603',
          contentType: ContentType.movie,
        ),
        contentType: ContentType.movie,
        rawTitle: 'The.Matrix.1999.1080p',
        normalizedTitle: 'The Matrix',
        qualityLabel: 'Full HD',
        qualityRank: 3,
      ),
    );
  }
}

class _RecordingGetMovieAvailabilityOnIptv extends GetMovieAvailabilityOnIptv {
  _RecordingGetMovieAvailabilityOnIptv()
    : super(const _FakeIptvAvailabilityService());

  String? recordedMovieId;
  Set<String>? recordedCandidateSourceIds;

  @override
  Future<bool> call(String movieId, {Set<String>? candidateSourceIds}) async {
    recordedMovieId = movieId;
    recordedCandidateSourceIds = candidateSourceIds;
    return true;
  }
}

class _FakePlayerPreferences implements PlayerPreferences {
  _FakePlayerPreferences({
    this.preferredAudioLanguage,
    this.preferredSubtitleLanguage,
    this.preferredPlaybackQuality,
  });

  @override
  final String? preferredAudioLanguage;

  @override
  final String? preferredSubtitleLanguage;

  @override
  final PreferredPlaybackQuality? preferredPlaybackQuality;

  @override
  Stream<String?> get preferredAudioLanguageStream =>
      Stream<String?>.value(preferredAudioLanguage);

  @override
  Stream<String?> get preferredAudioLanguageStreamWithInitial async* {
    yield preferredAudioLanguage;
  }

  @override
  Stream<String?> get preferredSubtitleLanguageStream =>
      Stream<String?>.value(preferredSubtitleLanguage);

  @override
  Stream<String?> get preferredSubtitleLanguageStreamWithInitial async* {
    yield preferredSubtitleLanguage;
  }

  @override
  Stream<PreferredPlaybackQuality?> get preferredPlaybackQualityStream =>
      Stream<PreferredPlaybackQuality?>.value(preferredPlaybackQuality);

  @override
  Stream<PreferredPlaybackQuality?>
  get preferredPlaybackQualityStreamWithInitial async* {
    yield preferredPlaybackQuality;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryLocalePreferences implements LocalePreferences {
  final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  String _languageCode = 'en-US';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  String get languageCode => _languageCode;

  @override
  Stream<String> get languageStream => _languageController.stream;

  @override
  Stream<String> get languageStreamWithInitial async* {
    yield _languageCode;
    yield* _languageController.stream;
  }

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;

  @override
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield _themeMode;
    yield* _themeController.stream;
  }

  @override
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    _languageController.add(code);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _themeController.add(mode);
  }

  @override
  Future<void> dispose() async {
    await _languageController.close();
    await _themeController.close();
  }
}

class _FakeMoviePlaybackVariantResolver
    implements MoviePlaybackVariantResolver {
  const _FakeMoviePlaybackVariantResolver();

  @override
  Future<List<PlaybackVariant>> resolveVariants({
    required String movieId,
    required String title,
    int? releaseYear,
    Uri? poster,
    Set<String>? candidateSourceIds,
  }) async {
    return const <PlaybackVariant>[];
  }
}

class _FakePlaybackHistoryRepository implements PlaybackHistoryRepository {
  const _FakePlaybackHistoryRepository();

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIptvAvailabilityService implements IptvAvailabilityService {
  const _FakeIptvAvailabilityService();

  @override
  Future<bool> isMovieAvailable(
    String movieId, {
    Set<String>? candidateSourceIds,
  }) async {
    return true;
  }
}

class _SilentLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warn(String message, {String? category}) {}
}

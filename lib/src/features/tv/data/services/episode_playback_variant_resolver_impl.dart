import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';
import 'package:movi/src/features/tv/domain/services/episode_playback_variant_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class EpisodePlaybackVariantResolverImpl
    implements EpisodePlaybackVariantResolver {
  EpisodePlaybackVariantResolverImpl({
    required IptvLocalRepository iptvLocal,
    required XtreamStreamUrlBuilder urlBuilder,
    required AppLogger logger,
    required PerformanceDiagnosticLogger diagnostics,
  }) : _iptvLocal = iptvLocal,
       _urlBuilder = urlBuilder,
       _logger = logger,
       _diagnostics = diagnostics;

  final IptvLocalRepository _iptvLocal;
  final XtreamStreamUrlBuilder _urlBuilder;
  final AppLogger _logger;
  final PerformanceDiagnosticLogger _diagnostics;

  @override
  Future<List<PlaybackVariant>> resolveVariants({
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required List<EpisodePlaybackSeasonSnapshot> seasonSnapshots,
    Set<String>? candidateSourceIds,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final xtreamEpisodeNumber = _convertEpisodeNumber(
        episodeNumber: episodeNumber,
        seasonNumber: seasonNumber,
        seasonSnapshots: seasonSnapshots,
      );
      final items = await _iptvLocal.getAllPlaylistItems(
        accountIds: candidateSourceIds,
        type: XtreamPlaylistItemType.series,
      );
      if (items.isEmpty) {
        _diagnostics.completed(
          'episode_variant_resolver',
          elapsed: stopwatch.elapsed,
          result: 'empty_items',
          context: <String, Object?>{
            'seriesId': seriesId,
            'candidateSources': candidateSourceIds?.length ?? 0,
          },
        );
        return const <PlaybackVariant>[];
      }

      final sourceContext = await _loadSourceContext();
      final matchedItems =
          _matchSeriesItems(
            seriesId: seriesId,
            items: items,
          ).toList(growable: false)..sort(
            (left, right) => _compareItems(
              left,
              right,
              sourceOrder: sourceContext.orderBySourceId,
            ),
          );
      if (matchedItems.isEmpty) {
        _diagnostics.completed(
          'episode_variant_resolver',
          elapsed: stopwatch.elapsed,
          result: 'empty_matches',
          context: <String, Object?>{
            'seriesId': seriesId,
            'candidateSources': candidateSourceIds?.length ?? 0,
            'scannedItems': items.length,
          },
        );
        return const <PlaybackVariant>[];
      }

      final variants = <PlaybackVariant>[];
      final seenVariantIds = <String>{};
      for (final item in matchedItems) {
        final variant = await _buildVariant(
          item: item,
          seriesId: seriesId,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          xtreamEpisodeNumber: xtreamEpisodeNumber,
          sourceLabels: sourceContext.labels,
        );
        if (variant == null) {
          continue;
        }
        if (seenVariantIds.add(variant.id)) {
          variants.add(variant);
        }
      }

      _diagnostics.completed(
        'episode_variant_resolver',
        elapsed: stopwatch.elapsed,
        context: <String, Object?>{
          'seriesId': seriesId,
          'seasonNumber': seasonNumber,
          'episodeNumber': episodeNumber,
          'xtreamEpisodeNumber': xtreamEpisodeNumber,
          'candidateSources': candidateSourceIds?.length ?? 0,
          'scannedItems': items.length,
          'matchedItems': matchedItems.length,
          'playableVariants': variants.length,
        },
      );
      return variants;
    } catch (error, stackTrace) {
      _diagnostics.failed(
        'episode_variant_resolver',
        elapsed: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          'seriesId': seriesId,
          'seasonNumber': seasonNumber,
          'episodeNumber': episodeNumber,
          'candidateSources': candidateSourceIds?.length ?? 0,
        },
      );
      rethrow;
    }
  }

  Future<PlaybackVariant?> _buildVariant({
    required XtreamPlaylistItem item,
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required int xtreamEpisodeNumber,
    required Map<String, String> sourceLabels,
  }) async {
    final url = await _urlBuilder.buildStreamUrlFromSeriesItem(
      item: item,
      seasonNumber: seasonNumber,
      episodeNumber: xtreamEpisodeNumber,
    );
    if (url == null || url.trim().isEmpty) {
      _logger.warn(
        'Ignoring unreadable episode variant '
        'seriesId=$seriesId source=${item.accountId} streamId=${item.streamId} '
        'season=$seasonNumber episode=$xtreamEpisodeNumber',
        category: 'playback_selection',
      );
      return null;
    }

    final trimmedRawTitle = item.title.trim();
    final titleData = TitleCleaner.cleanWithYear(item.title);
    final normalizedTitle = titleData.cleanedTitle.trim().isEmpty
        ? trimmedRawTitle
        : titleData.cleanedTitle.trim();

    return PlaybackVariant(
      id: '${item.accountId}:${item.streamId}',
      sourceId: item.accountId,
      sourceLabel: sourceLabels[item.accountId] ?? item.accountId,
      videoSource: VideoSource(
        url: url,
        title: trimmedRawTitle,
        contentId: seriesId,
        tmdbId: item.tmdbId ?? _parseTmdbId(seriesId),
        contentType: ContentType.series,
        season: seasonNumber,
        episode: episodeNumber,
      ),
      contentType: ContentType.series,
      rawTitle: item.title,
      normalizedTitle: normalizedTitle,
    );
  }

  Iterable<XtreamPlaylistItem> _matchSeriesItems({
    required String seriesId,
    required List<XtreamPlaylistItem> items,
  }) {
    if (seriesId.startsWith('xtream:')) {
      final streamId = int.tryParse(seriesId.substring(7));
      if (streamId == null) {
        return const <XtreamPlaylistItem>[];
      }
      return items.where(
        (item) => item.streamId == streamId && item.streamId > 0,
      );
    }

    final tmdbId = int.tryParse(seriesId);
    if (tmdbId == null) {
      return const <XtreamPlaylistItem>[];
    }

    return items.where((item) => item.tmdbId == tmdbId && item.streamId > 0);
  }

  int _compareItems(
    XtreamPlaylistItem left,
    XtreamPlaylistItem right, {
    required Map<String, int> sourceOrder,
  }) {
    final leftOrder = sourceOrder[left.accountId] ?? sourceOrder.length;
    final rightOrder = sourceOrder[right.accountId] ?? sourceOrder.length;
    if (leftOrder != rightOrder) {
      return leftOrder.compareTo(rightOrder);
    }
    return left.streamId.compareTo(right.streamId);
  }

  int _convertEpisodeNumber({
    required int episodeNumber,
    required int seasonNumber,
    required List<EpisodePlaybackSeasonSnapshot> seasonSnapshots,
  }) {
    final targetSeason = _findSeasonSnapshot(
      seasonNumber: seasonNumber,
      seasonSnapshots: seasonSnapshots,
    );
    if (targetSeason == null || !targetSeason.usesGlobalNumbering) {
      return episodeNumber;
    }

    var totalEpisodesBefore = 0;
    for (final season in seasonSnapshots) {
      if (season.seasonNumber > 0 && season.seasonNumber < seasonNumber) {
        totalEpisodesBefore += season.episodeCount;
      }
    }

    final convertedEpisodeNumber = episodeNumber - totalEpisodesBefore;
    return convertedEpisodeNumber > 0 ? convertedEpisodeNumber : 1;
  }

  EpisodePlaybackSeasonSnapshot? _findSeasonSnapshot({
    required int seasonNumber,
    required List<EpisodePlaybackSeasonSnapshot> seasonSnapshots,
  }) {
    for (final season in seasonSnapshots) {
      if (season.seasonNumber == seasonNumber) {
        return season;
      }
    }
    return null;
  }

  Future<_EpisodeSourceContext> _loadSourceContext() async {
    final labels = <String, String>{};
    final orderBySourceId = <String, int>{};
    var order = 0;

    void registerSource(String sourceId, String alias) {
      orderBySourceId[sourceId] = order++;
      final trimmedAlias = alias.trim();
      labels[sourceId] = trimmedAlias.isEmpty ? sourceId : trimmedAlias;
    }

    final accounts = await _iptvLocal.getAccounts();
    for (final account in accounts) {
      registerSource(account.id, account.alias);
    }

    final stalkerAccounts = await _iptvLocal.getStalkerAccounts();
    for (final account in stalkerAccounts) {
      registerSource(account.id, account.alias);
    }

    return _EpisodeSourceContext(
      labels: labels,
      orderBySourceId: orderBySourceId,
    );
  }

  int? _parseTmdbId(String seriesId) {
    if (seriesId.startsWith('xtream:')) {
      return null;
    }
    return int.tryParse(seriesId);
  }
}

class _EpisodeSourceContext {
  const _EpisodeSourceContext({
    required this.labels,
    required this.orderBySourceId,
  });

  final Map<String, String> labels;
  final Map<String, int> orderBySourceId;
}

import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/features/movie/domain/entities/movie_variant_match_result.dart';
import 'package:movi/src/features/movie/domain/services/movie_playback_variant_resolver.dart';
import 'package:movi/src/features/movie/domain/services/movie_variant_matcher.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/data/services/movie_variant_title_metadata_extractor.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class MoviePlaybackVariantResolverImpl implements MoviePlaybackVariantResolver {
  MoviePlaybackVariantResolverImpl({
    required IptvLocalRepository iptvLocal,
    required XtreamStreamUrlBuilder urlBuilder,
    required MovieVariantMatcher matcher,
    required AppLogger logger,
    required PerformanceDiagnosticLogger diagnostics,
    MovieVariantTitleMetadataExtractor metadataExtractor =
        const MovieVariantTitleMetadataExtractor(),
  }) : _iptvLocal = iptvLocal,
       _urlBuilder = urlBuilder,
       _matcher = matcher,
       _logger = logger,
       _diagnostics = diagnostics,
       _metadataExtractor = metadataExtractor;

  final IptvLocalRepository _iptvLocal;
  final XtreamStreamUrlBuilder _urlBuilder;
  final MovieVariantMatcher _matcher;
  final AppLogger _logger;
  final PerformanceDiagnosticLogger _diagnostics;
  final MovieVariantTitleMetadataExtractor _metadataExtractor;

  @override
  Future<List<PlaybackVariant>> resolveVariants({
    required String movieId,
    required String title,
    int? releaseYear,
    Uri? poster,
    Set<String>? candidateSourceIds,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final items = await _iptvLocal.getAllPlaylistItems(
        accountIds: candidateSourceIds,
        type: XtreamPlaylistItemType.movie,
      );
      if (items.isEmpty) {
        _diagnostics.completed(
          'movie_variant_resolver',
          elapsed: stopwatch.elapsed,
          result: 'empty_items',
          context: <String, Object?>{
            'movieId': movieId,
            'candidateSources': candidateSourceIds?.length ?? 0,
          },
        );
        return const <PlaybackVariant>[];
      }

      final sourceLabels = await _loadSourceLabels();
      final referenceItems = _buildReferenceItems(
        items: items,
        movieId: movieId,
        title: title,
        releaseYear: releaseYear,
      );
      if (referenceItems.isEmpty) {
        _diagnostics.completed(
          'movie_variant_resolver',
          elapsed: stopwatch.elapsed,
          result: 'empty_references',
          context: <String, Object?>{
            'movieId': movieId,
            'scannedItems': items.length,
          },
        );
        return const <PlaybackVariant>[];
      }

      final matchedItems = items
          .where((item) => _bestMatch(referenceItems, item).isMatch)
          .toList(growable: false);
      final variants = <PlaybackVariant>[];
      final seenVariantIds = <String>{};

      for (final item in matchedItems) {
        final variant = await _buildVariant(
          item: item,
          fallbackTitle: title,
          poster: poster,
          movieId: movieId,
          sourceLabels: sourceLabels,
        );
        if (variant == null) {
          continue;
        }
        if (seenVariantIds.add(variant.id)) {
          variants.add(variant);
        }
      }

      _diagnostics.completed(
        'movie_variant_resolver',
        elapsed: stopwatch.elapsed,
        context: <String, Object?>{
          'movieId': movieId,
          'candidateSources': candidateSourceIds?.length ?? 0,
          'scannedItems': items.length,
          'referenceItems': referenceItems.length,
          'matchedItems': matchedItems.length,
          'playableVariants': variants.length,
        },
      );
      return variants;
    } catch (error, stackTrace) {
      _diagnostics.failed(
        'movie_variant_resolver',
        elapsed: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          'movieId': movieId,
          'candidateSources': candidateSourceIds?.length ?? 0,
        },
      );
      rethrow;
    }
  }

  Future<PlaybackVariant?> _buildVariant({
    required XtreamPlaylistItem item,
    required String fallbackTitle,
    required Uri? poster,
    required String movieId,
    required Map<String, String> sourceLabels,
  }) async {
    final url = await _urlBuilder.buildStreamUrlFromMovieItem(item);
    if (url == null || url.trim().isEmpty) {
      _logger.warn(
        'Ignoring unreadable movie variant movieId=$movieId source=${item.accountId} streamId=${item.streamId}',
        category: 'playback_selection',
      );
      return null;
    }

    final titleData = TitleCleaner.cleanWithYear(item.title);
    final normalizedTitle = titleData.cleanedTitle.trim().isEmpty
        ? fallbackTitle
        : titleData.cleanedTitle.trim();
    final metadata = _metadataExtractor.extract(item.title);

    return PlaybackVariant(
      id: '${item.accountId}:${item.streamId}',
      sourceId: item.accountId,
      sourceLabel: sourceLabels[item.accountId] ?? item.accountId,
      videoSource: VideoSource(
        url: url,
        title: fallbackTitle,
        contentId: movieId,
        tmdbId: item.tmdbId,
        contentType: ContentType.movie,
        poster: poster,
      ),
      contentType: ContentType.movie,
      rawTitle: item.title,
      normalizedTitle: normalizedTitle,
      qualityLabel: metadata.qualityLabel,
      qualityRank: metadata.qualityRank,
      dynamicRangeLabel: metadata.dynamicRangeLabel,
      audioLanguageCode: metadata.audioLanguageCode,
      audioLanguageLabel: metadata.audioLanguageLabel,
      subtitleLanguageCode: metadata.subtitleLanguageCode,
      subtitleLanguageLabel: metadata.subtitleLanguageLabel,
      hasSubtitles: metadata.hasSubtitles,
    );
  }

  List<XtreamPlaylistItem> _buildReferenceItems({
    required List<XtreamPlaylistItem> items,
    required String movieId,
    required String title,
    required int? releaseYear,
  }) {
    final references = <XtreamPlaylistItem>[];
    if (movieId.startsWith('xtream:')) {
      final streamId = int.tryParse(movieId.substring(7));
      if (streamId != null) {
        references.addAll(
          items.where(
            (item) =>
                item.type == XtreamPlaylistItemType.movie &&
                item.streamId == streamId,
          ),
        );
      }
    } else {
      final tmdbId = int.tryParse(movieId);
      if (tmdbId != null) {
        references.add(
          XtreamPlaylistItem(
            accountId: '__request__',
            categoryId: '__request__',
            categoryName: '__request__',
            streamId: -1,
            title: title,
            type: XtreamPlaylistItemType.movie,
            releaseYear: releaseYear,
            tmdbId: tmdbId,
          ),
        );
      }
    }

    if (references.isNotEmpty) {
      return references;
    }

    if (movieId.startsWith('xtream:')) {
      final streamId = int.tryParse(movieId.substring(7));
      if (streamId == null) {
        return const <XtreamPlaylistItem>[];
      }

      return <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: '__request__',
          categoryId: '__request__',
          categoryName: '__request__',
          streamId: streamId,
          title: title,
          type: XtreamPlaylistItemType.movie,
          releaseYear: releaseYear,
        ),
      ];
    }

    return const <XtreamPlaylistItem>[];
  }

  MovieVariantMatchResult _bestMatch(
    List<XtreamPlaylistItem> referenceItems,
    XtreamPlaylistItem candidateItem,
  ) {
    MovieVariantMatchResult? bestMatch;
    XtreamPlaylistItem? weakReferenceItem;
    MovieVariantMatchResult? weakMatch;

    for (final referenceItem in referenceItems) {
      final result = _matcher.match(
        referenceItem: referenceItem,
        candidateItem: candidateItem,
      );
      if (result.isStrict) {
        return result;
      }
      if (result.isCompatible && bestMatch == null) {
        bestMatch = result;
        continue;
      }
      if (_shouldLogWeakMatch(result) && weakMatch == null) {
        weakReferenceItem = referenceItem;
        weakMatch = result;
      }
    }

    if (bestMatch != null) {
      return bestMatch;
    }

    if (weakReferenceItem != null && weakMatch != null) {
      _logWeakMatch(
        referenceItem: weakReferenceItem,
        candidateItem: candidateItem,
        result: weakMatch,
      );
      return weakMatch;
    }

    return const MovieVariantMatchResult(
      kind: MovieVariantMatchKind.none,
      reason: MovieVariantMatchReason.cleanTitleMismatch,
      referenceTitle: '',
      candidateTitle: '',
      referenceYear: null,
      candidateYear: null,
    );
  }

  bool _shouldLogWeakMatch(MovieVariantMatchResult result) {
    return result.reason == MovieVariantMatchReason.conflictingYear ||
        result.reason == MovieVariantMatchReason.conflictingTmdbId;
  }

  void _logWeakMatch({
    required XtreamPlaylistItem referenceItem,
    required XtreamPlaylistItem candidateItem,
    required MovieVariantMatchResult result,
  }) {
    _logger.warn(
      'Ignoring weak movie variant match '
      'referenceStreamId=${referenceItem.streamId} '
      'candidateSource=${candidateItem.accountId} '
      'candidateStreamId=${candidateItem.streamId} '
      'reason=${result.reason.name}',
      category: 'playback_selection',
    );
  }

  Future<Map<String, String>> _loadSourceLabels() async {
    final labels = <String, String>{};

    final xtreamAccounts = await _iptvLocal.getAccounts();
    for (final account in xtreamAccounts) {
      labels[account.id] = _resolveXtreamAlias(account);
    }

    final stalkerAccounts = await _iptvLocal.getStalkerAccounts();
    for (final account in stalkerAccounts) {
      labels[account.id] = _resolveStalkerAlias(account);
    }

    return labels;
  }

  String _resolveXtreamAlias(XtreamAccount account) {
    final alias = account.alias.trim();
    return alias.isEmpty ? account.id : alias;
  }

  String _resolveStalkerAlias(StalkerAccount account) {
    final alias = account.alias.trim();
    return alias.isEmpty ? account.id : alias;
  }
}

import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';

class NextEpisodeFailure {
  NextEpisodeFailure(this.code, this.message);
  final String code;
  final String message;
}

class NextEpisodeResult {
  NextEpisodeResult.success(this.source)
      : error = null;
  NextEpisodeResult.failure(this.error)
      : source = null;

  final VideoSource? source;
  final NextEpisodeFailure? error;
}

class NextEpisodeService {
  NextEpisodeService({
    required IptvLocalRepository iptvLocal,
    required XtreamStreamUrlBuilder urlBuilder,
  })  : _iptvLocal = iptvLocal,
        _urlBuilder = urlBuilder;

  final IptvLocalRepository _iptvLocal;
  final XtreamStreamUrlBuilder _urlBuilder;

  Future<NextEpisodeResult> computeNext({
    required VideoSource current,
    required List<SeasonViewModel> seasons,
    required String seriesId,
    required String seriesTitle,
    Uri? poster,
    Set<String>? activeSourceIds,
  }) async {
    if (current.contentType != ContentType.series ||
        current.season == null ||
        current.episode == null) {
      return NextEpisodeResult.failure(
        NextEpisodeFailure('invalid_source', 'Source actuelle invalide'),
      );
    }

    final currentSeason = current.season!;
    final currentEpisode = current.episode!;

    final currentSeasonData = _getSeason(seasons, currentSeason);
    final idx = currentSeasonData.episodes.indexWhere(
      (e) => e.episodeNumber == currentEpisode,
    );

    int? nextSeasonNumber;
    int? nextEpisodeNumber;
    String? nextEpisodeTitle;

    if (idx >= 0 && idx < currentSeasonData.episodes.length - 1) {
      final ep = currentSeasonData.episodes[idx + 1];
      nextSeasonNumber = currentSeason;
      nextEpisodeNumber = ep.episodeNumber;
      nextEpisodeTitle = ep.title;
    } else {
      final sidx = seasons.indexWhere((s) => s.seasonNumber == currentSeason);
      if (sidx >= 0 && sidx < seasons.length - 1) {
        final nextSeasonData = seasons[sidx + 1];
        if (nextSeasonData.episodes.isNotEmpty) {
          final ep = nextSeasonData.episodes.first;
          nextSeasonNumber = nextSeasonData.seasonNumber;
          nextEpisodeNumber = ep.episodeNumber;
          nextEpisodeTitle = ep.title;
        }
      }
    }

    if (nextSeasonNumber == null || nextEpisodeNumber == null) {
      return NextEpisodeResult.failure(
        NextEpisodeFailure('no_next_episode', 'Aucun épisode suivant disponible'),
      );
    }

    var xtreamEpisodeNumber = nextEpisodeNumber;
    final isGlobal = _isSeasonUsingGlobalNumbering(nextSeasonNumber, seasons);
    if (isGlobal) {
      xtreamEpisodeNumber = _convertTmdbEpisodeToXtream(
        nextEpisodeNumber,
        nextSeasonNumber,
        seasons,
      );
    }

    final xtreamItem = await _findSeriesPlaylistItem(
      seriesId,
      activeSourceIds: activeSourceIds,
    );
    if (xtreamItem == null) {
      return NextEpisodeResult.failure(
        NextEpisodeFailure('not_found_in_playlist', 'Épisode non disponible dans la playlist'),
      );
    }

    final streamUrl = await _urlBuilder.buildStreamUrlFromSeriesItem(
      item: xtreamItem,
      seasonNumber: nextSeasonNumber,
      episodeNumber: xtreamEpisodeNumber,
    );
    if (streamUrl == null) {
      return NextEpisodeResult.failure(
        NextEpisodeFailure('build_url_failed', 'Impossible de construire l\'URL de streaming'),
      );
    }

    final formattedTitle = nextEpisodeTitle != null && nextEpisodeTitle.isNotEmpty
        ? '$seriesTitle - S${nextSeasonNumber.toString().padLeft(2, '0')}E${nextEpisodeNumber.toString().padLeft(2, '0')} - $nextEpisodeTitle'
        : '$seriesTitle - S${nextSeasonNumber.toString().padLeft(2, '0')}E${nextEpisodeNumber.toString().padLeft(2, '0')}';

    final resolvedTmdbId = int.tryParse(seriesId) ?? xtreamItem.tmdbId;
    final source = VideoSource(
      url: streamUrl.toString(),
      title: formattedTitle,
      contentId: seriesId,
      tmdbId: resolvedTmdbId,
      contentType: ContentType.series,
      poster: poster,
      season: nextSeasonNumber,
      episode: nextEpisodeNumber,
    );

    return NextEpisodeResult.success(source);
  }

  Future<XtreamPlaylistItem?> _findSeriesPlaylistItem(
    String seriesId, {
    Set<String>? activeSourceIds,
  }) async {
    final xtreamAccounts = await _iptvLocal.getAccounts();
    final stalkerAccounts = await _iptvLocal.getStalkerAccounts();
    final ids = <String>{
      ...xtreamAccounts.map((a) => a.id),
      ...stalkerAccounts.map((a) => a.id),
    };
    if (activeSourceIds != null && activeSourceIds.isNotEmpty) {
      ids.removeWhere((id) => !activeSourceIds.contains(id));
    }
    if (ids.isEmpty) return null;

    for (final accountId in ids) {
      final playlists = await _iptvLocal.getPlaylists(accountId);
      for (final playlist in playlists) {
        if (seriesId.startsWith('xtream:')) {
          final streamIdStr = seriesId.substring(7);
          final streamId = int.tryParse(streamIdStr);
          if (streamId != null) {
            try {
              final found = playlist.items.firstWhere(
                (item) => item.streamId == streamId,
              );
              if (found.type == XtreamPlaylistItemType.series &&
                  found.streamId > 0) {
                return found;
              }
            } catch (_) {}
          }
        } else {
          final tmdbId = int.tryParse(seriesId);
          if (tmdbId != null) {
            try {
              final candidates = playlist.items
                  .where(
                    (item) => item.tmdbId == tmdbId &&
                        item.type == XtreamPlaylistItemType.series,
                  )
                  .toList();

              if (candidates.isNotEmpty) {
                final validCandidate = candidates.firstWhere(
                  (item) => item.streamId > 0,
                  orElse: () => candidates.first,
                );
                if (validCandidate.streamId > 0) {
                  return validCandidate;
                }
              }
            } catch (_) {}
          }
        }
      }
    }
    return null;
  }

  SeasonViewModel _getSeason(List<SeasonViewModel> seasons, int seasonNumber) {
    try {
      return seasons.firstWhere((s) => s.seasonNumber == seasonNumber);
    } catch (_) {
      return seasons.first;
    }
  }

  bool _isSeasonUsingGlobalNumbering(
    int seasonNumber,
    List<SeasonViewModel> seasons,
  ) {
    final season = _getSeason(seasons, seasonNumber);
    if (season.episodes.isEmpty) return false;
    final firstEpisodeNumber = season.episodes.first.episodeNumber;
    if (firstEpisodeNumber > 1) return true;
    final lastEpisodeNumber = season.episodes.last.episodeNumber;
    if (lastEpisodeNumber > season.episodes.length) return true;
    return false;
  }

  int _convertTmdbEpisodeToXtream(
    int tmdbEpisodeNumber,
    int seasonNumber,
    List<SeasonViewModel> seasons,
  ) {
    if (!_isSeasonUsingGlobalNumbering(seasonNumber, seasons)) {
      return tmdbEpisodeNumber;
    }
    var totalEpisodesBefore = 0;
    for (final season in seasons) {
      if (season.seasonNumber > 0 && season.seasonNumber < seasonNumber) {
        totalEpisodesBefore += season.episodes.length;
      }
    }
    final xtreamEpisodeNumber = tmdbEpisodeNumber - totalEpisodesBefore;
    return xtreamEpisodeNumber > 0 ? xtreamEpisodeNumber : 1;
  }
}

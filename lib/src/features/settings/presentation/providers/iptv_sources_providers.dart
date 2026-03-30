import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

export 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';

final iptvAccountsProvider = FutureProvider<List<XtreamAccount>>((ref) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  return local.getAccounts();
});

/// Provider pour les comptes Stalker
final stalkerAccountsProvider = FutureProvider<List<StalkerAccount>>((
  ref,
) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  return local.getStalkerAccounts();
});

class IptvSourceStats {
  const IptvSourceStats({
    required this.movieCount,
    required this.movieIndexedCount,
    required this.seriesCount,
    required this.seriesIndexedCount,
  });

  final int movieCount;
  final int movieIndexedCount;
  final int seriesCount;
  final int seriesIndexedCount;
}

final iptvSourceStatsProvider = FutureProvider.family<IptvSourceStats, String>((
  ref,
  accountId,
) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  final playlists = await local.getPlaylists(accountId);

  var movieCount = 0;
  var movieIndexedCount = 0;
  var seriesCount = 0;
  var seriesIndexedCount = 0;

  for (final pl in playlists) {
    for (final it in pl.items) {
      if (it.type == XtreamPlaylistItemType.movie) {
        movieCount += 1;
        if ((it.tmdbId ?? 0) > 0) movieIndexedCount += 1;
      } else if (it.type == XtreamPlaylistItemType.series) {
        seriesCount += 1;
        if ((it.tmdbId ?? 0) > 0) seriesIndexedCount += 1;
      }
    }
  }

  return IptvSourceStats(
    movieCount: movieCount,
    movieIndexedCount: movieIndexedCount,
    seriesCount: seriesCount,
    seriesIndexedCount: seriesIndexedCount,
  );
});

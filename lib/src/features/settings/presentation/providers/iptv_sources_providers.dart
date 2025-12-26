import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

final iptvAccountsProvider = FutureProvider<List<XtreamAccount>>((ref) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  return local.getAccounts();
});

/// Provider pour les comptes Stalker
final stalkerAccountsProvider = FutureProvider<List<StalkerAccount>>((ref) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  return local.getStalkerAccounts();
});

/// Wrapper pour combiner Xtream et Stalker
class AnyIptvAccount {
  AnyIptvAccount.xtream(this.xtream) : stalker = null;
  AnyIptvAccount.stalker(this.stalker) : xtream = null;

  final XtreamAccount? xtream;
  final StalkerAccount? stalker;

  String get id => xtream?.id ?? stalker!.id;
  String get alias => xtream?.alias ?? stalker!.alias;
  bool get isStalker => stalker != null;
  
  String getHost() => xtream?.endpoint.host ?? stalker!.endpoint.host;
  String getUsername() => xtream?.username ?? stalker!.macAddress;
  DateTime? getExpiration() {
    if (xtream != null) {
      return xtream!.expirationDate;
    }
    return stalker?.expirationDate;
  }
  bool isActive() {
    if (isStalker) {
      final s = stalker!;
      if (s.status == StalkerAccountStatus.error) return false;
      if (s.status == StalkerAccountStatus.expired) return false;
      final exp = s.expirationDate;
      if (exp == null) return s.status == StalkerAccountStatus.active;
      return exp.isAfter(DateTime.now());
    } else {
      final x = xtream!;
      if (x.status == XtreamAccountStatus.error) return false;
      if (x.status == XtreamAccountStatus.expired) return false;
      final exp = x.expirationDate;
      if (exp == null) return x.status == XtreamAccountStatus.active;
      return exp.isAfter(DateTime.now());
    }
  }
}

/// Provider combiné pour tous les comptes IPTV
final allIptvAccountsProvider = FutureProvider<List<AnyIptvAccount>>((ref) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  
  final xtreamAccounts = await local.getAccounts();
  final stalkerAccounts = await local.getStalkerAccounts();
  
  return [
    ...xtreamAccounts.map((a) => AnyIptvAccount.xtream(a)),
    ...stalkerAccounts.map((a) => AnyIptvAccount.stalker(a)),
  ];
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

final iptvSourceStatsProvider =
    FutureProvider.family<IptvSourceStats, String>((ref, accountId) async {
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


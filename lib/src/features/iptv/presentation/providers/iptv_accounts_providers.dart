import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';

/// Wrapper UI-friendly pour manipuler Xtream et Stalker avec une seule liste.
class AnyIptvAccount {
  AnyIptvAccount.xtream(this.xtream) : stalker = null;
  AnyIptvAccount.stalker(this.stalker) : xtream = null;

  final XtreamAccount? xtream;
  final StalkerAccount? stalker;

  String get id => xtream?.id ?? stalker!.id;
  String get alias => xtream?.alias ?? stalker!.alias;
  bool get isStalker => stalker != null;

  String getHost() => xtream?.endpoint.host ?? stalker!.endpoint.host;

  String get sourceUrl =>
      xtream?.endpoint.toRawUrl() ?? stalker!.endpoint.toRawUrl();

  String getUsername() => xtream?.username ?? stalker!.macAddress;

  String get subtitle {
    if (xtream != null) {
      return '${getHost()} • ${xtream!.username}';
    }
    return '${getHost()} • ${stalker!.macAddress} (Stalker)';
  }

  DateTime? getExpiration() {
    if (xtream != null) {
      return xtream!.expirationDate;
    }
    return stalker?.expirationDate;
  }

  bool isActive() {
    if (isStalker) {
      final account = stalker!;
      if (account.status == StalkerAccountStatus.error) return false;
      if (account.status == StalkerAccountStatus.expired) return false;
      final expiration = account.expirationDate;
      if (expiration == null) {
        return account.status == StalkerAccountStatus.active;
      }
      return expiration.isAfter(DateTime.now());
    }

    final account = xtream!;
    if (account.status == XtreamAccountStatus.error) return false;
    if (account.status == XtreamAccountStatus.expired) return false;
    final expiration = account.expirationDate;
    if (expiration == null) {
      return account.status == XtreamAccountStatus.active;
    }
    return expiration.isAfter(DateTime.now());
  }
}

/// Provider combiné pour tous les comptes IPTV locaux.
final allIptvAccountsProvider = FutureProvider<List<AnyIptvAccount>>((
  ref,
) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();

  final xtreamAccounts = await local.getAccounts();
  final stalkerAccounts = await local.getStalkerAccounts();

  return [
    ...xtreamAccounts.map(AnyIptvAccount.xtream),
    ...stalkerAccounts.map(AnyIptvAccount.stalker),
  ];
});

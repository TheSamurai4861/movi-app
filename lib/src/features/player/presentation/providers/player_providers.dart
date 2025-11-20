import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'package:movi/src/features/player/data/repositories/media_kit_video_player_repository.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';

final videoPlayerRepositoryProvider = Provider<MediaKitVideoPlayerRepository>((ref) {
  return MediaKitVideoPlayerRepository();
});

final xtreamStreamUrlBuilderProvider = Provider<XtreamStreamUrlBuilder>((ref) {
  final locator = ref.watch(slProvider);
  final iptvLocal = locator<IptvLocalRepository>();
  final vault = locator<CredentialsVault>();
  final networkExecutor = locator<NetworkExecutor>();
  return XtreamStreamUrlBuilderImpl(
    iptvLocal: iptvLocal,
    vault: vault,
    networkExecutor: networkExecutor,
  );
});
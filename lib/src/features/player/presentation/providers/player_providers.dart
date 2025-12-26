import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'dart:io';

import 'package:movi/src/features/player/data/repositories/media_kit_video_player_repository.dart';
import 'package:movi/src/features/player/data/repositories/picture_in_picture_repository_impl.dart';
import 'package:movi/src/features/player/data/repositories/system_control_repository_impl.dart';
import 'package:movi/src/features/player/domain/repositories/picture_in_picture_repository.dart';
import 'package:movi/src/features/player/domain/repositories/system_control_repository.dart';
import 'package:movi/src/features/player/domain/repositories/video_player_repository.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';

final videoPlayerRepositoryProvider =
    Provider.autoDispose<VideoPlayerRepository>((ref) {
      final locator = ref.watch(slProvider);
      final logger = locator<AppLogger>();

      // UA par défaut "compatible IPTV" (override possible via --dart-define MOVI_STREAM_USER_AGENT=...).
      const defaultStreamUserAgent = 'VLC/3.0.20 LibVLC/3.0.20';

      final repo = MediaKitVideoPlayerRepository(
        logger: logger,
        streamUserAgent: defaultStreamUserAgent,
      );
      // Sur Windows, le backend texture peut encore être en train de peindre
      // quand Riverpod déclenche la libération (ex: navigation rapide / hot restart).
      // On décale la libération à la prochaine frame pour éviter des callbacks texture invalides.
      ref.onDispose(() {
        // `instanceOrNull` n'existe pas sur toutes les versions de Flutter.
        // Best-effort: si la binding n'est pas initialisée, on dispose immédiatement.
        try {
          WidgetsBinding.instance.addPostFrameCallback((_) => repo.dispose());
        } catch (_) {
          repo.dispose();
        }
      });
      return repo;
    });

final videoControllerProvider = Provider.autoDispose<VideoController>((ref) {
  final repo =
      ref.watch(videoPlayerRepositoryProvider) as MediaKitVideoPlayerRepository;
  final controller = VideoController(repo.player);
  return controller;
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

final systemControlRepositoryProvider =
    Provider<SystemControlRepository>((ref) {
  return SystemControlRepositoryImpl();
});

final pictureInPictureRepositoryProvider =
    Provider.autoDispose<PictureInPictureRepository>((ref) {
  // Détecter la plateforme et retourner la bonne implémentation
  if (Platform.isAndroid || Platform.isIOS) {
    final repo = PictureInPictureRepositoryImpl();
    ref.onDispose(() => repo.dispose());
    return repo;
  } else {
    // No-op implementation pour les autres plateformes (Windows, etc.)
    return _NoOpPictureInPictureRepository();
  }
});

/// No-op implementation pour les plateformes non supportées
class _NoOpPictureInPictureRepository implements PictureInPictureRepository {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<void> enter() async {}

  @override
  Future<void> exit() async {}

  @override
  Stream<bool> get isActiveStream => Stream.value(false);

  @override
  dynamic get windowController => null;

  @override
  void dispose() {}
}

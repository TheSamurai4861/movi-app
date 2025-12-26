import 'package:equatable/equatable.dart';
import 'package:movi/src/core/performance/domain/performance_profile.dart';

class PerformanceTuning extends Equatable {
  const PerformanceTuning({
    required this.profile,
    required this.tmdbMaxConcurrent,
    required this.homeHeroPrefetchNextFull,
    required this.homeHeroPrecacheNextImage,
    required this.iptvInitialSyncDelay,
    required this.iptvConnectSyncDelay,
  });

  factory PerformanceTuning.fromProfile(PerformanceProfile profile) {
    return switch (profile) {
      PerformanceProfile.lowResources => PerformanceTuning(
        profile: profile,
        tmdbMaxConcurrent: 3,
        homeHeroPrefetchNextFull: false,
        homeHeroPrecacheNextImage: false,
        iptvInitialSyncDelay: const Duration(seconds: 20),
        iptvConnectSyncDelay: const Duration(seconds: 2),
      ),
      PerformanceProfile.normal => PerformanceTuning(
        profile: profile,
        tmdbMaxConcurrent: 8,
        homeHeroPrefetchNextFull: true,
        homeHeroPrecacheNextImage: true,
        iptvInitialSyncDelay: Duration.zero,
        iptvConnectSyncDelay: Duration.zero,
      ),
    };
  }

  final PerformanceProfile profile;

  bool get isLowResources => profile.isLowResources;

  /// NetworkExecutor concurrency for `concurrencyKey: 'tmdb'`.
  final int tmdbMaxConcurrent;

  /// Allow background full hydration of the *next* hero item (cache warm-up).
  final bool homeHeroPrefetchNextFull;

  /// Precache next hero image (smoother transitions, more memory).
  final bool homeHeroPrecacheNextImage;

  /// Delay before the first IPTV sync tick at app startup.
  final Duration iptvInitialSyncDelay;

  /// Delay before launching the background IPTV sync after `connect()`.
  final Duration iptvConnectSyncDelay;

  @override
  List<Object?> get props => [
    profile,
    tmdbMaxConcurrent,
    homeHeroPrefetchNextFull,
    homeHeroPrecacheNextImage,
    iptvInitialSyncDelay,
    iptvConnectSyncDelay,
  ];
}

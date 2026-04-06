import 'package:flutter/foundation.dart';

import 'package:movi/src/features/welcome/domain/enum.dart';

enum TunnelStage {
  preparingSystem,
  authRequired,
  profileRequired,
  sourceRequired,
  preloadingHome,
  readyForHome,
}

enum TunnelExecutionMode { cloud, localFirst }

enum TunnelLoadingState { idle, inProgress, completed }

@immutable
final class TunnelState {
  const TunnelState({
    required this.stage,
    required this.executionMode,
    required this.loadingState,
    required this.reasonCode,
    required this.hasSession,
    required this.hasSelectedProfile,
    required this.hasSelectedSource,
    required this.hasCatalogReady,
    required this.hasHomePreloaded,
    required this.hasLibraryReady,
    required this.profilesCount,
    required this.sourcesCount,
    required this.isShadowMode,
    this.legacyDestination,
    this.selectedProfileId,
    this.selectedSourceId,
  });

  final TunnelStage stage;
  final TunnelExecutionMode executionMode;
  final TunnelLoadingState loadingState;
  final String reasonCode;
  final bool hasSession;
  final bool hasSelectedProfile;
  final bool hasSelectedSource;
  final bool hasCatalogReady;
  final bool hasHomePreloaded;
  final bool hasLibraryReady;
  final int profilesCount;
  final int sourcesCount;
  final bool isShadowMode;
  final BootstrapDestination? legacyDestination;
  final String? selectedProfileId;
  final String? selectedSourceId;

  bool get isReadyForHome => stage == TunnelStage.readyForHome;

  TunnelState copyWith({
    TunnelStage? stage,
    TunnelExecutionMode? executionMode,
    TunnelLoadingState? loadingState,
    String? reasonCode,
    bool? hasSession,
    bool? hasSelectedProfile,
    bool? hasSelectedSource,
    bool? hasCatalogReady,
    bool? hasHomePreloaded,
    bool? hasLibraryReady,
    int? profilesCount,
    int? sourcesCount,
    bool? isShadowMode,
    Object? legacyDestination = _sentinel,
    Object? selectedProfileId = _sentinel,
    Object? selectedSourceId = _sentinel,
  }) {
    return TunnelState(
      stage: stage ?? this.stage,
      executionMode: executionMode ?? this.executionMode,
      loadingState: loadingState ?? this.loadingState,
      reasonCode: reasonCode ?? this.reasonCode,
      hasSession: hasSession ?? this.hasSession,
      hasSelectedProfile: hasSelectedProfile ?? this.hasSelectedProfile,
      hasSelectedSource: hasSelectedSource ?? this.hasSelectedSource,
      hasCatalogReady: hasCatalogReady ?? this.hasCatalogReady,
      hasHomePreloaded: hasHomePreloaded ?? this.hasHomePreloaded,
      hasLibraryReady: hasLibraryReady ?? this.hasLibraryReady,
      profilesCount: profilesCount ?? this.profilesCount,
      sourcesCount: sourcesCount ?? this.sourcesCount,
      isShadowMode: isShadowMode ?? this.isShadowMode,
      legacyDestination: identical(legacyDestination, _sentinel)
          ? this.legacyDestination
          : legacyDestination as BootstrapDestination?,
      selectedProfileId: identical(selectedProfileId, _sentinel)
          ? this.selectedProfileId
          : selectedProfileId as String?,
      selectedSourceId: identical(selectedSourceId, _sentinel)
          ? this.selectedSourceId
          : selectedSourceId as String?,
    );
  }

  static const _sentinel = Object();

  static const empty = TunnelState(
    stage: TunnelStage.preparingSystem,
    executionMode: TunnelExecutionMode.localFirst,
    loadingState: TunnelLoadingState.idle,
    reasonCode: 'tunnel_idle',
    hasSession: false,
    hasSelectedProfile: false,
    hasSelectedSource: false,
    hasCatalogReady: false,
    hasHomePreloaded: false,
    hasLibraryReady: false,
    profilesCount: 0,
    sourcesCount: 0,
    isShadowMode: false,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TunnelState &&
        other.stage == stage &&
        other.executionMode == executionMode &&
        other.loadingState == loadingState &&
        other.reasonCode == reasonCode &&
        other.hasSession == hasSession &&
        other.hasSelectedProfile == hasSelectedProfile &&
        other.hasSelectedSource == hasSelectedSource &&
        other.hasCatalogReady == hasCatalogReady &&
        other.hasHomePreloaded == hasHomePreloaded &&
        other.hasLibraryReady == hasLibraryReady &&
        other.profilesCount == profilesCount &&
        other.sourcesCount == sourcesCount &&
        other.isShadowMode == isShadowMode &&
        other.legacyDestination == legacyDestination &&
        other.selectedProfileId == selectedProfileId &&
        other.selectedSourceId == selectedSourceId;
  }

  @override
  int get hashCode => Object.hash(
    stage,
    executionMode,
    loadingState,
    reasonCode,
    hasSession,
    hasSelectedProfile,
    hasSelectedSource,
    hasCatalogReady,
    hasHomePreloaded,
    hasLibraryReady,
    profilesCount,
    sourcesCount,
    isShadowMode,
    legacyDestination,
    selectedProfileId,
    selectedSourceId,
  );
}

final class TunnelStateRegistry extends ChangeNotifier {
  TunnelStateRegistry({TunnelState? initial})
    : _state = initial ?? TunnelState.empty;

  TunnelState _state;

  TunnelState get state => _state;

  void update(TunnelState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    notifyListeners();
  }
}

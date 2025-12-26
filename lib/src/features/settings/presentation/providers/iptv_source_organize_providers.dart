import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';

class IptvPlaylistOrganizeItem {
  const IptvPlaylistOrganizeItem({
    required this.playlistId,
    required this.type,
    required this.title,
    required this.position,
    required this.isVisible,
  });

  final String playlistId;
  final XtreamPlaylistType type;
  final String title;
  final int position;
  final bool isVisible;

  IptvPlaylistOrganizeItem copyWith({int? position, bool? isVisible}) {
    return IptvPlaylistOrganizeItem(
      playlistId: playlistId,
      type: type,
      title: title,
      position: position ?? this.position,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class IptvSourceOrganizeState {
  const IptvSourceOrganizeState({
    this.isLoading = false,
    this.error,
    this.items = const [],
  });

  final bool isLoading;
  final String? error;
  final List<IptvPlaylistOrganizeItem> items;

  IptvSourceOrganizeState copyWith({
    bool? isLoading,
    String? error,
    List<IptvPlaylistOrganizeItem>? items,
  }) {
    return IptvSourceOrganizeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
    );
  }
}

class IptvSourceOrganizeController extends Notifier<IptvSourceOrganizeState> {
  IptvSourceOrganizeController(this._accountId);

  final String _accountId;

  late final IptvLocalRepository _local;

  @override
  IptvSourceOrganizeState build() {
    _local = ref.read(slProvider)<IptvLocalRepository>();
    // IMPORTANT: déclencher le chargement après l'initialisation du provider,
    // sinon `state` n'est pas encore disponible et Riverpod lève une exception.
    Future.microtask(_load);
    return const IptvSourceOrganizeState(isLoading: true);
  }

  Future<void> _load() async {
    state = const IptvSourceOrganizeState(isLoading: true);
    try {
      final playlists = await _local.getPlaylists(_accountId);
      final settings = await _local.getPlaylistSettings(_accountId);
      final merged = await _ensureSettingsAndMerge(
        playlists: playlists,
        settings: settings,
      );

      state = state.copyWith(
        isLoading: false,
        items: merged.items,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<({List<IptvPlaylistOrganizeItem> items})>
  _ensureSettingsAndMerge({
    required List<XtreamPlaylist> playlists,
    required List<XtreamPlaylistSettings> settings,
  }) async {
    final now = DateTime.now();
    final byId = {for (final s in settings) s.playlistId: s};

    int maxMovies = -1;
    int maxSeries = -1;
    int maxGlobal = -1;
    for (final s in settings) {
      if (s.type == XtreamPlaylistType.movies && s.position > maxMovies) {
        maxMovies = s.position;
      } else if (s.type == XtreamPlaylistType.series && s.position > maxSeries) {
        maxSeries = s.position;
      }
      if (s.globalPosition > maxGlobal) {
        maxGlobal = s.globalPosition;
      }
    }

    final toUpsert = <XtreamPlaylistSettings>[];
    final keepIds = <String>{};
    for (final pl in playlists) {
      keepIds.add(pl.id);
      if (byId.containsKey(pl.id)) continue;

      final nextPos = pl.type == XtreamPlaylistType.movies
          ? (++maxMovies)
          : (++maxSeries);
      final nextGlobal = ++maxGlobal;
      toUpsert.add(
        XtreamPlaylistSettings(
          accountId: _accountId,
          playlistId: pl.id,
          type: pl.type,
          position: nextPos,
          globalPosition: nextGlobal,
          isVisible: true,
          updatedAt: now,
        ),
      );
    }

    await _local.upsertPlaylistSettingsBatch(toUpsert);
    await _local.deletePlaylistSettingsNotIn(
      accountId: _accountId,
      playlistIds: keepIds,
    );

    // Si aucune config n'existait auparavant, on initialise un ordre par défaut
    // identique à l'accueil historique: intercalé films/séries au départ.
    if (settings.isEmpty && toUpsert.isNotEmpty) {
      final movies = toUpsert
          .where((e) => e.type == XtreamPlaylistType.movies)
          .toList(growable: false)
        ..sort((a, b) => a.position.compareTo(b.position));
      final series = toUpsert
          .where((e) => e.type == XtreamPlaylistType.series)
          .toList(growable: false)
        ..sort((a, b) => a.position.compareTo(b.position));

      final orderedIds = <String>[];
      final maxLen = movies.length > series.length ? movies.length : series.length;
      for (var i = 0; i < maxLen; i++) {
        if (i < movies.length) orderedIds.add(movies[i].playlistId);
        if (i < series.length) orderedIds.add(series[i].playlistId);
      }
      await _local.reorderPlaylistsGlobal(
        accountId: _accountId,
        orderedPlaylistIds: orderedIds,
      );

      final globalById = <String, int>{
        for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
      };
      for (var i = 0; i < toUpsert.length; i++) {
        final id = toUpsert[i].playlistId;
        final gp = globalById[id];
        if (gp != null) {
          toUpsert[i] = toUpsert[i].copyWith(globalPosition: gp);
        }
      }
    }

    final nextSettings = <XtreamPlaylistSettings>[
      ...settings.where((s) => keepIds.contains(s.playlistId)),
      ...toUpsert,
    ];
    final nextById = {for (final s in nextSettings) s.playlistId: s};

    final items = <IptvPlaylistOrganizeItem>[];
    for (final pl in playlists) {
      final s = nextById[pl.id];
      if (s == null) continue;
      final item = IptvPlaylistOrganizeItem(
        playlistId: pl.id,
        type: pl.type,
        title: _cleanPlaylistTitle(pl.title),
        position: s.position,
        isVisible: s.isVisible,
      );
      items.add(item);
    }

    // Tri selon l'ordre affiché sur l'accueil.
    items.sort((a, b) {
      final sa = nextById[a.playlistId];
      final sb = nextById[b.playlistId];
      final ga = sa?.globalPosition ?? 1 << 30;
      final gb = sb?.globalPosition ?? 1 << 30;
      final c = ga.compareTo(gb);
      return c != 0 ? c : a.title.compareTo(b.title);
    });

    return (items: items);
  }

  String _cleanPlaylistTitle(String raw) {
    final idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      return raw.substring(idx + 1);
    }
    return raw;
  }

  Future<void> toggleVisibility({
    required String playlistId,
    required bool isVisible,
  }) async {
    await _local.setPlaylistVisibility(
      accountId: _accountId,
      playlistId: playlistId,
      isVisible: isVisible,
    );

    final updated = state.items
        .map(
          (e) => e.playlistId == playlistId
              ? e.copyWith(isVisible: isVisible)
              : e,
        )
        .toList(growable: false);
    state = state.copyWith(items: updated);

    _emitIptvChanged();
  }

  Future<void> reorder({
    required int oldIndex,
    required int newIndex,
  }) async {
    final list = List<IptvPlaylistOrganizeItem>.from(state.items);
    if (list.isEmpty) return;

    var targetIndex = newIndex;
    if (oldIndex < newIndex) targetIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(targetIndex, moved);

    final orderedIds = list.map((e) => e.playlistId).toList(growable: false);

    final moviesIds = <String>[];
    final seriesIds = <String>[];
    for (final item in list) {
      if (item.type == XtreamPlaylistType.movies) {
        moviesIds.add(item.playlistId);
      } else {
        seriesIds.add(item.playlistId);
      }
    }

    await Future.wait([
      _local.reorderPlaylistsGlobal(
        accountId: _accountId,
        orderedPlaylistIds: orderedIds,
      ),
      _local.reorderPlaylists(
        accountId: _accountId,
        type: XtreamPlaylistType.movies,
        orderedPlaylistIds: moviesIds,
      ),
      _local.reorderPlaylists(
        accountId: _accountId,
        type: XtreamPlaylistType.series,
        orderedPlaylistIds: seriesIds,
      ),
    ]);

    // Met à jour l'état local (positions par type recalculées).
    final moviePos = <String, int>{};
    for (var i = 0; i < moviesIds.length; i++) {
      moviePos[moviesIds[i]] = i;
    }
    final seriesPos = <String, int>{};
    for (var i = 0; i < seriesIds.length; i++) {
      seriesPos[seriesIds[i]] = i;
    }

    final updated = <IptvPlaylistOrganizeItem>[];
    for (final it in list) {
      final pos = it.type == XtreamPlaylistType.movies
          ? (moviePos[it.playlistId] ?? it.position)
          : (seriesPos[it.playlistId] ?? it.position);
      updated.add(it.copyWith(position: pos));
    }

    state = state.copyWith(items: updated);

    _emitIptvChanged();
  }

  Future<void> setAllVisibleAll({
    required bool isVisible,
  }) async {
    await Future.wait([
      _local.setAllPlaylistsVisibility(
        accountId: _accountId,
        type: XtreamPlaylistType.movies,
        isVisible: isVisible,
      ),
      _local.setAllPlaylistsVisibility(
        accountId: _accountId,
        type: XtreamPlaylistType.series,
        isVisible: isVisible,
      ),
    ]);

    state = state.copyWith(
      items: state.items
          .map((e) => e.copyWith(isVisible: isVisible))
          .toList(growable: false),
    );

    _emitIptvChanged();
  }

  void _emitIptvChanged() {
    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
  }

}

final iptvSourceOrganizeControllerProvider =
    NotifierProvider.family<
      IptvSourceOrganizeController,
      IptvSourceOrganizeState,
      String
    >((accountId) => IptvSourceOrganizeController(accountId));

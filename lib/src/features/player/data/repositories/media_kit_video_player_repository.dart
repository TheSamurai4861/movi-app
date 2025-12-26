import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/repositories/video_player_repository.dart';
import 'package:movi/src/features/player/domain/value_objects/player_active_tracks.dart';
import 'package:movi/src/features/player/domain/value_objects/player_tracks.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/src/features/player/data/repositories/stream_url_probe.dart';

/// Implémentation du VideoPlayerRepository avec media_kit
class MediaKitVideoPlayerRepository implements VideoPlayerRepository {
  MediaKitVideoPlayerRepository({
    Player? player,
    AppLogger? logger,
    String? streamUserAgent,
  })  : _logger = logger,
        _streamUserAgent = streamUserAgent {
    _player = player ?? Player();
    _attachDebugStreams();
  }

  late final Player _player;
  final AppLogger? _logger;
  final String? _streamUserAgent;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Player get player => _player;

  @override
  Future<void> open(VideoSource source) async {
    final headers = _buildStreamHeaders(source.url);
    final resolvedUrl = await _resolveStreamUrl(source.url, headers: headers);
    _logger?.debug(
      '[Player] open url=${_maskStreamUrl(resolvedUrl)} headers=$headers',
    );
    await _player.open(Media(resolvedUrl, httpHeaders: headers), play: true);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seekForward(int seconds) async {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    await _player.seek(newPosition);
  }

  @override
  Future<void> seekBackward(int seconds) async {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition - Duration(seconds: seconds);
    await _player.seek(newPosition);
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(toEngineVolume(volume));
  }

  @override
  Future<void> setSubtitlesEnabled(bool enabled) async {
    if (enabled) {
      // Active la première piste de sous-titres disponible
      final tracks = _player.state.tracks.subtitle;
      if (tracks.isNotEmpty) {
        await _player.setSubtitleTrack(tracks.first);
      }
    } else {
      // Désactive les sous-titres au niveau du moteur
      await _player.setSubtitleTrack(SubtitleTrack.no());
    }
  }

  @override
  Future<void> setSubtitleTrack(int? trackId) async {
    if (trackId == null) {
      // Désactiver les sous-titres
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    final tracks = _player.state.tracks.subtitle;
    if (tracks.isEmpty) return;

    final track = tracks.firstWhere(
      (t) => t.id == trackId.toString(),
      orElse: () => tracks.first,
    );
    await _player.setSubtitleTrack(track);
  }

  @override
  Future<void> setActiveSubtitleTrack(int? trackId) =>
      setSubtitleTrack(trackId);

  @override
  Future<void> setAudioTrack(int? trackId) async {
    if (trackId == null) {
      return;
    }
    final tracks = _player.state.tracks.audio;
    if (tracks.isEmpty) return;

    final track = tracks.firstWhere(
      (t) => t.id == trackId.toString(),
      orElse: () => tracks.first,
    );
    await _player.setAudioTrack(track);
  }

  @override
  Future<PlayerActiveTracks> getActiveTracks() async {
    final audioIds = _player.state.tracks.audio
        .map((t) => int.tryParse(t.id))
        .whereType<int>()
        .toList(growable: false);
    final subtitleIds = _player.state.tracks.subtitle
        .map((t) => int.tryParse(t.id))
        .whereType<int>()
        .toList(growable: false);

    final activeAudioId = int.tryParse(_player.state.track.audio.id);
    final activeSubtitle = _player.state.track.subtitle;
    final isNone = activeSubtitle.id == SubtitleTrack.no().id;
    final activeSubtitleId = isNone ? null : int.tryParse(activeSubtitle.id);

    return PlayerActiveTracks(
      audioTrackIds: audioIds,
      subtitleTrackIds: subtitleIds,
      activeAudioTrackId: activeAudioId,
      activeSubtitleTrackId: activeSubtitleId,
    );
  }

  @override
  Stream<PlayerTracks> get tracksStream => _player.stream.tracks.map((tracks) {
    final audio = tracks.audio
        .map(
          (t) => TrackInfo(
            type: TrackType.audio,
            id: int.tryParse(t.id) ?? 0,
            title: t.title,
            language: t.language,
          ),
        )
        .toList(growable: false);
    final subs = tracks.subtitle
        .map(
          (t) => TrackInfo(
            type: TrackType.subtitle,
            id: int.tryParse(t.id) ?? 0,
            title: t.title,
            language: t.language,
          ),
        )
        .toList(growable: false);

    final activeAudioId = int.tryParse(_player.state.track.audio.id);
    final activeSubtitle = _player.state.track.subtitle;
    final isNone = activeSubtitle.id == SubtitleTrack.no().id;
    final activeSubtitleId = isNone ? null : int.tryParse(activeSubtitle.id);

    return PlayerTracks(
      audioTracks: audio,
      subtitleTracks: subs,
      activeAudioTrackId: activeAudioId,
      activeSubtitleTrackId: activeSubtitleId,
    );
  });

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
  }

  static double toEngineVolume(double domainVolume) {
    final clamped = domainVolume.clamp(0.0, 1.0);
    return (clamped * 100).roundToDouble();
  }

  void _attachDebugStreams() {
    // Les streams media_kit aident énormément à diagnostiquer les erreurs de lecture IPTV.
    // On log en best-effort; aucun impact fonctionnel si le logger n'est pas fourni.
    _subscriptions.add(
      _player.stream.error.listen((msg) {
        _logger?.error('[Player] error: $msg');
      }),
    );
    _subscriptions.add(
      _player.stream.log.listen((log) {
        // Trop verbeux en général; on log uniquement les niveaux "warning/error" côté mpv.
        final level = log.level.toLowerCase();
        if (level.contains('error') ||
            level.contains('warn') ||
            level.contains('fatal')) {
          _logger?.warn('[Player] mpv(${log.level}): ${log.text}');
        }
      }),
    );
    _subscriptions.add(
      _player.stream.completed.listen((done) {
        if (done) {
          _logger?.warn('[Player] completed=true (end of stream)');
        }
      }),
    );
  }

  Map<String, String>? _buildStreamHeaders(String url) {
    // Certains providers IPTV bloquent des User-Agent "exotiques".
    // On met un UA par défaut, et on permet override via dart-define.
    const overrideUa = String.fromEnvironment('MOVI_STREAM_USER_AGENT');
    final ua = (overrideUa.isNotEmpty ? overrideUa : _streamUserAgent)?.trim();
    if (ua == null || ua.isEmpty) return null;

    return <String, String>{
      'User-Agent': ua,
      'Accept': '*/*',
    };
  }

  Future<String> _resolveStreamUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return url;

    // Si on a une extension explicite, certains panels peuvent être stricts.
    // On fait un probe minimal (Range: 0-0) et fallback vers l'URL sans extension si on obtient 404/410.
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final match = RegExp(r'^(\d+)\.([A-Za-z0-9]{1,5})$').firstMatch(last);
    if (match == null) return url;

    final probe1 = await _probeHttpUrl(url, headers: headers);
    if (probe1.statusCode == 301 ||
        probe1.statusCode == 302 ||
        probe1.statusCode == 307 ||
        probe1.statusCode == 308) {
      final loc = probe1.location;
      if (loc != null && loc.isNotEmpty) {
        final redirected = _resolveRedirect(url, loc);
        if (redirected != null) {
          _logger?.debug(
            '[Player] redirect ${probe1.statusCode}: ${_maskStreamUrl(url)} -> ${_maskStreamUrl(redirected)}',
          );
          return redirected;
        }
      }
    }

    if (probe1.statusCode == 404 || probe1.statusCode == 410) {
      final withoutExt = uri.replace(
        pathSegments: [
          ...uri.pathSegments.take(uri.pathSegments.length - 1),
          match.group(1)!,
        ],
      );
      final url2 = withoutExt.toString();
      final probe2 = await _probeHttpUrl(url2, headers: headers);
      if (probe2.statusCode >= 200 && probe2.statusCode < 300) {
        _logger?.warn(
          '[Player] stream URL fallback: ${_maskStreamUrl(url)} -> ${_maskStreamUrl(url2)} (status ${probe1.statusCode} -> ${probe2.statusCode})',
        );
        return url2;
      }

      // Fallback extensions (panels parfois incohérents sur container_extension).
      final originalExt = (match.group(2) ?? '').toLowerCase();
      const commonExts = <String>['mp4', 'mkv', 'm3u8', 'ts'];
      for (final ext in commonExts) {
        if (ext == originalExt) continue;
        final candidate = uri.replace(
          pathSegments: [
            ...uri.pathSegments.take(uri.pathSegments.length - 1),
            '${match.group(1)}.$ext',
          ],
        );
        final candidateUrl = candidate.toString();
        final probe = await _probeHttpUrl(candidateUrl, headers: headers);
        if (probe.statusCode >= 200 && probe.statusCode < 300) {
          _logger?.warn(
            '[Player] stream URL ext fallback: ${_maskStreamUrl(url)} -> ${_maskStreamUrl(candidateUrl)} (status ${probe1.statusCode} -> ${probe.statusCode})',
          );
          return candidateUrl;
        }
      }
    }

    return url;
  }

  Future<({int statusCode, String? location})> _probeHttpUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    // Best-effort: jamais bloquant.
    final allowBadCertificates = (() {
      bool allow = false;
      assert(() {
        allow = true;
        return true;
      }());
      return allow;
    })();

    final result = await probeStreamUrl(
      url,
      headers: headers,
      allowBadCertificates: allowBadCertificates,
    );

    final status = result.statusCode;
    final loc = result.location;
    if (status > 0) {
      _logger?.debug(
        '[Player] probe ${_maskStreamUrl(url)} -> status=$status location=${loc ?? "-"}',
      );
    } else if (result.error != null) {
      _logger?.debug(
        '[Player] probe failed ${_maskStreamUrl(url)}: ${result.error}',
      );
    }

    return (statusCode: status, location: loc);
  }

  String? _resolveRedirect(String fromUrl, String location) {
    final from = Uri.tryParse(fromUrl);
    if (from == null) return null;
    final loc = Uri.tryParse(location);
    if (loc == null) return null;
    if (loc.hasScheme) return loc.toString();
    // Relative redirect
    return from.resolveUri(loc).toString();
  }

  String _maskStreamUrl(String url) {
    // Masquage best-effort: on cache les segments username/password (2 segments après /movie/ ou /series/).
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final segments = uri.pathSegments.toList(growable: true);
    final int movieIdx = segments.indexOf('movie');
    final int seriesIdx = segments.indexOf('series');
    final int liveIdx = segments.indexOf('live');
    final int idx = movieIdx >= 0 ? movieIdx : (seriesIdx >= 0 ? seriesIdx : liveIdx);
    if (idx >= 0) {
      if (segments.length > idx + 1) segments[idx + 1] = '***';
      if (segments.length > idx + 2) segments[idx + 2] = '***';
    }

    return uri.replace(pathSegments: segments).toString();
  }
}

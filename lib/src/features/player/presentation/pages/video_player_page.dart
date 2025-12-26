import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
// import removed
import 'package:movi/src/features/player/domain/repositories/video_player_repository.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/presentation/widgets/video_player_controls.dart';
import 'package:movi/src/features/player/presentation/widgets/track_selection_menu.dart';
import 'package:movi/src/features/player/presentation/widgets/video_fit_mode_selection_menu.dart';
import 'package:movi/src/features/player/domain/value_objects/video_fit_mode.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_remote_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/player/presentation/providers/player_providers.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/src/features/player/presentation/utils/track_label_formatter.dart';
import 'package:movi/src/features/player/application/services/next_episode_service.dart';
import 'package:movi/src/features/player/application/usecases/adjust_brightness.dart';
import 'package:movi/src/features/player/application/usecases/adjust_volume.dart';
import 'package:movi/src/features/player/application/usecases/reset_brightness.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/player/application/usecases/enter_picture_in_picture.dart';
import 'package:movi/src/features/player/application/usecases/exit_picture_in_picture.dart';
import 'package:movi/src/features/player/application/usecases/auto_enter_picture_in_picture.dart';
import 'dart:io';

/// Page de lecture vidéo avec contrôles personnalisés
class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key, this.videoSource});

  final VideoSource? videoSource;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ProviderSubscription<VideoPlayerRepository> _playerRepositorySub;
  late final ProviderSubscription<VideoController> _videoControllerSub;
  late final VideoPlayerRepository _playerRepository;
  late final VideoController _videoController;
  Timer? _hideControlsTimer;
  late final AnimationController _controlsAnimationController;
  late final Animation<double> _controlsOpacityAnimation;
  bool _showControls = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  bool _hasSubtitles = false;
  bool _subtitlesEnabled = false;
  List<TrackInfo> _subtitleTracks = [];
  List<TrackInfo> _audioTracks = [];
  TrackInfo? _currentSubtitleTrack;
  TrackInfo? _currentAudioTrack;
  final GlobalKey _controlsKey = GlobalKey();
  bool _tracksInitialized = false;
  bool _resumePositionApplied = false;
  VideoSource? _currentVideoSource;
  final List<StreamSubscription> _subscriptions = [];
  VideoFitMode _currentVideoFitMode = VideoFitMode.contain;

  // Variables pour la détection des gestes verticaux
  double? _gestureStartY;
  double? _gestureStartX;
  double _initialBrightness = 0.5;
  double _initialVolume = 0.5;
  double _lastAppliedBrightness = 0.5;
  double _lastAppliedVolume = 0.5;
  bool _isGestureActive = false;
  bool _isBrightnessControl = false;
  DateTime? _lastUpdateTime;
  static const _updateThrottleMs = 50;

  // PiP state
  bool _isPipSupported = false;
  bool _isPipActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // IMPORTANT: L'ouverture du média est déclenchée post-frame plus bas
    // pour éviter les courses avec l'initialisation du VideoController.

    // Forcer le mode paysage
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Masquer la barre de statut et la barre de navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Garder les providers autoDispose vivants pendant toute la durée de vie de la page.
    // `listenManual` est safe dans initState (contrairement à `watch`).
    _playerRepositorySub = ref.listenManual(
      videoPlayerRepositoryProvider,
      (previous, next) => _playerRepository = next,
      fireImmediately: true,
    );
    _videoControllerSub = ref.listenManual(
      videoControllerProvider,
      (previous, next) => _videoController = next,
      fireImmediately: true,
    );

    // Animation d'opacité pour les contrôles
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupListeners();
    _showControlsWithAnimation();
    _startHideControlsTimer();

    // Initialiser le VideoSource actuel
    _currentVideoSource = widget.videoSource;

    // Initialiser le mode d'affichage vidéo depuis les préférences
    _initializeVideoFitMode();

    // Initialiser le PiP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializePip();
      }
    });

    // IMPORTANT: on déclenche l'ouverture post-frame pour éviter des courses pendant
    // le 1er montage (et laisser les listeners s'installer correctement).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentVideoSource != null) {
        unawaited(_openGuarded(_currentVideoSource!));
      }
    });
  }

  Future<void> _openGuarded(VideoSource source) async {
    final profile = ref.read(currentProfileProvider);
    final hasRestrictions =
        profile != null && (profile.isKid || profile.pegiLimit != null);

    final id = source.contentId?.trim();
    final type = source.contentType;
    final int? tmdbId = source.tmdbId;

    if (hasRestrictions &&
        ((tmdbId != null && tmdbId > 0) || (id != null && id.isNotEmpty)) &&
        (type == ContentType.movie || type == ContentType.series)) {
      final effectiveId = (tmdbId != null && tmdbId > 0)
          ? tmdbId.toString()
          : id!;
      final content = ContentReference(
        id: effectiveId,
        type: type!,
        title: MediaTitle(source.title ?? effectiveId),
      );
      final decision = await ref.read(parental.contentAgeDecisionProvider(content).future);
      if (!mounted) return;
      if (!decision.isAllowed) {
        if (!context.mounted) return;
        final unlocked = await RestrictedContentSheet.show(
          context,
          ref,
          profile: profile,
          reason: decision.reason,
        );
        if (!mounted) return;
        if (!unlocked) {
          if (context.mounted) context.pop();
          return;
        }
      }
    }

    if (!mounted) return;
    await _playerRepository.open(source);
  }

  void _setupListeners() {
    _subscriptions.add(
      _playerRepository.playingStream.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          
        }
      }),
    );

    _subscriptions.add(
      _playerRepository.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
          
        }
      }),
    );

    _subscriptions.add(
      _playerRepository.durationStream.listen((duration) {
        if (mounted && duration != Duration.zero) {
          setState(() => _duration = duration);

          // Appliquer la position de reprise une seule fois quand la durée est disponible
          if (!_resumePositionApplied) {
            // Utiliser la position de reprise du VideoSource actuel si disponible
            if (_currentVideoSource?.resumePosition != null &&
                _currentVideoSource!.resumePosition! < duration) {
              _resumePositionApplied = true;
              _playerRepository.seekTo(_currentVideoSource!.resumePosition!);
            } else {
              // Si pas de position de reprise, commencer depuis le début
              _resumePositionApplied = true;
            }
          }
        }
      }),
    );

    _subscriptions.add(
      _playerRepository.bufferingStream.listen((buffering) {
        if (mounted) {
          setState(() => _isBuffering = buffering);
        }
      }),
    );

    // Écouter les changements de préférences audio et sous-titres
    final prefs = ref.read(slProvider)<PlayerPreferences>();
    _subscriptions.add(
      prefs.preferredAudioLanguageStream.listen((_) async {
        if (!mounted || !_tracksInitialized) return;
        await _applyPreferredTracks();
      }),
    );
    _subscriptions.add(
      prefs.preferredSubtitleLanguageStream.listen((_) async {
        if (!mounted || !_tracksInitialized) return;
        await _applyPreferredTracks();
      }),
    );

    // Mettre à jour les pistes, appliquer les préférences et maintenir les sélections courantes
    _subscriptions.add(
      _playerRepository.tracksStream.listen((tracks) async {
        if (!mounted) return;

        setState(() {
          _hasSubtitles = tracks.subtitleTracks.isNotEmpty;
          _subtitleTracks = tracks.subtitleTracks
              .where((t) => TrackLabelFormatter.formatTrackLabel(t).isNotEmpty)
              .toList(growable: false);
          _audioTracks = tracks.audioTracks
              .where((t) => TrackLabelFormatter.formatTrackLabel(t).isNotEmpty)
              .toList(growable: false);

          if (tracks.audioTracks.isNotEmpty && _currentAudioTrack == null) {
            _currentAudioTrack = tracks.audioTracks.first;
          } else if (_currentAudioTrack != null &&
              tracks.audioTracks.isNotEmpty) {
            final foundAudio = tracks.audioTracks.firstWhere(
              (t) => t.id == _currentAudioTrack!.id,
              orElse: () => tracks.audioTracks.first,
            );
            _currentAudioTrack = foundAudio;
          }

          if (tracks.subtitleTracks.isNotEmpty) {
            final activeId = tracks.activeSubtitleTrackId;
            if (activeId != null) {
              final foundSubtitle = tracks.subtitleTracks.firstWhere(
                (t) => t.id == activeId,
                orElse: () => tracks.subtitleTracks.first,
              );
              _currentSubtitleTrack = foundSubtitle;
              _subtitlesEnabled = true;
            } else {
              _currentSubtitleTrack = null;
              _subtitlesEnabled = false;
            }
          } else {
            _currentSubtitleTrack = null;
            _subtitlesEnabled = false;
          }
        });

        if (!_tracksInitialized) {
          await _applyPreferredTracks();
          _tracksInitialized = true;
        }
      }),
    );
  }

  /// Applique les préférences de langue pour les pistes audio et sous-titres
  Future<void> _applyPreferredTracks() async {
    if (!mounted) return;

    try {
      if (_audioTracks.isEmpty && _subtitleTracks.isEmpty) return;

      final prefs = ref.read(slProvider)<PlayerPreferences>();
      final preferredAudio = prefs.preferredAudioLanguage;
      final preferredSubtitle = prefs.preferredSubtitleLanguage;

      if (preferredAudio != null && preferredAudio.isNotEmpty) {
        final normalizedPref = TrackLabelFormatter.normalizeLanguageCode(
          preferredAudio,
        );
        final match = _audioTracks.firstWhere(
          (t) =>
              TrackLabelFormatter.normalizeLanguageCode(t.language) ==
                  normalizedPref ||
              TrackLabelFormatter.getLanguageCode(t) == normalizedPref,
          orElse: () => _audioTracks.first,
        );
        await _playerRepository.setAudioTrack(match.id);
        if (mounted) {
          setState(() {
            _currentAudioTrack = match;
          });
        }
      } else if (_audioTracks.isNotEmpty && _currentAudioTrack == null) {
        if (mounted) {
          setState(() {
            _currentAudioTrack = _audioTracks.first;
          });
        }
      }

      if (preferredSubtitle != null && preferredSubtitle.isNotEmpty) {
        final normalizedPref = TrackLabelFormatter.normalizeLanguageCode(
          preferredSubtitle,
        );
        final match = _subtitleTracks.firstWhere(
          (t) =>
              TrackLabelFormatter.normalizeLanguageCode(t.language) ==
                  normalizedPref ||
              TrackLabelFormatter.getLanguageCode(t) == normalizedPref,
          orElse: () => _subtitleTracks.first,
        );
        await _playerRepository.setActiveSubtitleTrack(match.id);
        if (mounted) {
          setState(() {
            _currentSubtitleTrack = match;
            _subtitlesEnabled = true;
          });
        }
      } else {
        await _playerRepository.setActiveSubtitleTrack(null);
        if (mounted) {
          setState(() {
            _currentSubtitleTrack = null;
            _subtitlesEnabled = false;
          });
        }
      }
    } catch (e) {
      // Ignorer les erreurs si le player a été disposé
      if (mounted) {
        // Log l'erreur si nécessaire, mais ne pas la propager
      }
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      // Démarrer le timer même si pas encore en lecture
      _hideControlsTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _showControls) {
          // Masquer seulement si en lecture, sinon attendre
          if (_isPlaying) {
            _hideControlsWithAnimation();
          } else {
            // Si pas encore en lecture, relancer le timer
            _startHideControlsTimer();
          }
        }
      });
    }
  }

  void _showControlsWithAnimation() {
    setState(() => _showControls = true);
    _controlsAnimationController.forward();
    _startHideControlsTimer();
  }

  void _hideControlsWithAnimation() {
    _controlsAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onVerticalDragStart(DragStartDetails details) async {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Ignorer les gestes trop petits
    if (screenHeight < 100) return;

    _gestureStartX = details.globalPosition.dx;
    _gestureStartY = details.globalPosition.dy;
    _isGestureActive = true;

    // Déterminer si on contrôle la luminosité (gauche) ou le volume (droite)
    _isBrightnessControl = _gestureStartX! < screenWidth / 2;

    // Récupérer les valeurs initiales
    final systemControlRepo =
        ref.read(systemControlRepositoryProvider);
    if (_isBrightnessControl) {
      _initialBrightness = await systemControlRepo.getBrightness();
      _lastAppliedBrightness = _initialBrightness;
    } else {
      _initialVolume = await systemControlRepo.getVolume();
      _lastAppliedVolume = _initialVolume;
    }

    _lastUpdateTime = DateTime.now();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (!mounted || !_isGestureActive || _gestureStartY == null) return;

    final now = DateTime.now();
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMilliseconds < _updateThrottleMs) {
      return; // Throttling
    }
    _lastUpdateTime = now;

    final screenHeight = MediaQuery.of(context).size.height;
    final currentY = details.globalPosition.dy;
    final totalDeltaY = _gestureStartY! - currentY;

    // Ignorer les gestes trop petits (seuil de 5 pixels)
    if (totalDeltaY.abs() < 5) return;

    // Calculer le delta total en pourcentage avec sensibilité moyenne (facteur 0.5)
    final totalDeltaPercent = (totalDeltaY / screenHeight) * 0.5;

    // Calculer la nouvelle valeur cible
    double targetValue;
    if (_isBrightnessControl) {
      targetValue = (_initialBrightness + totalDeltaPercent).clamp(0.0, 1.0);
      // Calculer seulement la différence depuis la dernière valeur appliquée
      final deltaToApply = targetValue - _lastAppliedBrightness;
      if (deltaToApply.abs() < 0.01) return; // Ignorer les changements trop petits

      final systemControlRepo = ref.read(systemControlRepositoryProvider);
      final adjustBrightness = AdjustBrightness(systemControlRepo);
      await adjustBrightness.call(deltaToApply);
      _lastAppliedBrightness = targetValue;
    } else {
      targetValue = (_initialVolume + totalDeltaPercent).clamp(0.0, 1.0);
      // Calculer seulement la différence depuis la dernière valeur appliquée
      final deltaToApply = targetValue - _lastAppliedVolume;
      if (deltaToApply.abs() < 0.01) return; // Ignorer les changements trop petits

      final systemControlRepo = ref.read(systemControlRepositoryProvider);
      final adjustVolume = AdjustVolume(systemControlRepo);
      await adjustVolume.call(deltaToApply);
      _lastAppliedVolume = targetValue;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isGestureActive = false;
    _gestureStartY = null;
    _gestureStartX = null;
    _lastUpdateTime = null;
    _lastAppliedBrightness = 0.5;
    _lastAppliedVolume = 0.5;
  }

  void _onScreenTap(TapDownDetails details) {
    // Ignorer les taps si un geste vertical est actif
    if (_isGestureActive) return;

    // Vérifier si le tap est hors des contrôles
    if (_showControls) {
      final RenderBox? controlsBox =
          _controlsKey.currentContext?.findRenderObject() as RenderBox?;

      if (controlsBox != null) {
        final localPosition = controlsBox.globalToLocal(details.globalPosition);
        final isInsideControls = controlsBox.size.contains(localPosition);

        if (!isInsideControls) {
          // Tap hors des contrôles, les masquer avec animation d'opacité
          _hideControlsWithAnimation();
          return;
        }
        // Tap sur les contrôles, ne rien faire (les contrôles gèrent leurs propres clics)
        return;
      }

      // Si les contrôles sont affichés et qu'on tape sur l'écran, les masquer avec animation
      _hideControlsWithAnimation();
    } else {
      // Si les contrôles sont masqués, les afficher avec animation
      _showControlsWithAnimation();
    }
  }

  void _onDoubleTap(TapDownDetails details) {
    // Vérifier si le double tap est hors des contrôles
    final RenderBox? controlsBox =
        _controlsKey.currentContext?.findRenderObject() as RenderBox?;

    if (controlsBox != null) {
      final localPosition = controlsBox.globalToLocal(details.globalPosition);
      final isInsideControls = controlsBox.size.contains(localPosition);

      if (isInsideControls) {
        // Double tap sur les contrôles, ne rien faire
        return;
      }
    }

    // Double tap sur l'écran : gauche = -10s, droite = +10s
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final isLeftSide = tapX < screenWidth / 2;

    if (isLeftSide) {
      _seekBackward(10);
    } else {
      _seekForward(10);
    }

    // Afficher les contrôles après le double tap
    _showControlsWithAnimation();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _playerRepository.pause();
    } else {
      await _playerRepository.play();
    }
    _startHideControlsTimer();
  }

  Future<void> _seekForward(int seconds) async {
    await _playerRepository.seekForward(seconds);
    _startHideControlsTimer();
  }

  Future<void> _seekBackward(int seconds) async {
    await _playerRepository.seekBackward(seconds);
    _startHideControlsTimer();
  }

  Future<void> _onSeek(double value) async {
    final position = _duration * value;
    await _playerRepository.seekTo(position);
    _startHideControlsTimer();
  }

  Future<void> _restart() async {
    await _playerRepository.seekTo(Duration.zero);
    _startHideControlsTimer();
  }

  Future<void> _goToNextEpisode() async {
    final source = widget.videoSource;
    if (source == null ||
        source.contentType != ContentType.series ||
        source.contentId == null ||
        source.season == null ||
        source.episode == null) {
      return;
    }

    final locator = ref.read(slProvider);
    final iptvLocal = locator<IptvLocalRepository>();
    final builder = ref.read(xtreamStreamUrlBuilderProvider);
    final activeSourceIds =
        ref.read(asp.appStateControllerProvider).preferredIptvSourceIds;

    final vmAsync = ref.read(
      tvDetailProgressiveControllerProvider(source.contentId!),
    );
    final vm = vmAsync.value;
    if (vm == null || vm.seasons.isEmpty) {
      if (!mounted) return;
      final logger = ref.read(slProvider)<AppLogger>();
      logger.warn(
        'Series data unavailable for next episode',
        category: 'Player',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorSeriesDataUnavailable,
          ),
        ),
      );
      return;
    }

    final nextService = NextEpisodeService(
      iptvLocal: iptvLocal,
      urlBuilder: builder,
    );
    final result = await nextService.computeNext(
      current: source,
      seasons: vm.seasons,
      seriesId: source.contentId!,
      seriesTitle: vm.title,
      poster: source.poster ?? vm.poster,
      activeSourceIds: activeSourceIds,
    );

    if (result.error != null) {
      if (!mounted) return;
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error('Failed to compute next episode', result.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorNextEpisodeFailed),
        ),
      );
      return;
    }

    final nextVideoSource = result.source!;

    // Mettre à jour le VideoSource actuel
    if (mounted) {
      setState(() {
        _currentVideoSource = nextVideoSource;
        _resumePositionApplied = false;
        _tracksInitialized = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }

    await _playerRepository.open(nextVideoSource);
  }

  Future<void> _showSubtitleMenu() async {
    if (_subtitleTracks.isEmpty) return;

    // Ne pas masquer les contrôles pendant la sélection
    _hideControlsTimer?.cancel();

    // S'assurer que le player continue de jouer
    final wasPlaying = _isPlaying;

    await showModalBottomSheet<TrackInfo?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SubtitleTrackSelectionMenu(
        tracks: _subtitleTracks,
        currentTrack: _currentSubtitleTrack,
        onTrackSelected: (track) async {
          try {
            await _playerRepository.setActiveSubtitleTrack(track.id);
            if (mounted) {
              setState(() {
                _currentSubtitleTrack = track;
                _subtitlesEnabled = true;
              });
            }
          } catch (e) {
            // Ignorer les erreurs si le player a été disposé
          }
        },
        onDisable: () async {
          // Désactiver les sous-titres
          await _playerRepository.setActiveSubtitleTrack(null);
          if (mounted) {
            setState(() {
              _currentSubtitleTrack = null;
              _subtitlesEnabled = false;
            });
          }
        },
      ),
    );

    // S'assurer que le player continue de jouer après la sélection
    if (mounted && wasPlaying && !_isPlaying) {
      try {
        await _playerRepository.play();
      } catch (e) {
        // Ignorer les erreurs si le player a été disposé
      }
    }

    // Relancer le timer après la sélection
    if (mounted) {
      _startHideControlsTimer();
    }
  }

  Future<void> _showAudioMenu() async {
    if (_audioTracks.isEmpty) return;

    // Ne pas masquer les contrôles pendant la sélection
    _hideControlsTimer?.cancel();

    // S'assurer que le player continue de jouer
    final wasPlaying = _isPlaying;

    await showModalBottomSheet<TrackInfo?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AudioTrackSelectionMenu(
        tracks: _audioTracks,
        currentTrack: _currentAudioTrack,
        onTrackSelected: (track) async {
          try {
            await _playerRepository.setAudioTrack(track.id);
            if (mounted) {
              setState(() {
                _currentAudioTrack = track;
              });
            }
          } catch (e) {
            // Ignorer les erreurs si le player a été disposé
          }
        },
      ),
    );

    // S'assurer que le player continue de jouer après la sélection
    if (mounted && wasPlaying && !_isPlaying) {
      try {
        await _playerRepository.play();
      } catch (e) {
        // Ignorer les erreurs si le player a été disposé
      }
    }

    // Relancer le timer après la sélection
    if (mounted) {
      _startHideControlsTimer();
    }
  }

  void _initializeVideoFitMode() {
    final prefs = ref.read(slProvider)<PlayerPreferences>();
    final initialMode = prefs.preferredVideoFitMode ?? VideoFitMode.contain;
    if (mounted) {
      setState(() {
        _currentVideoFitMode = initialMode;
      });
    }

    // S'abonner aux changements
    _subscriptions.add(
      prefs.preferredVideoFitModeStreamWithInitial.listen((value) {
        if (!mounted) return;
        final mode = VideoFitMode.fromValue(value);
        if (mode != null && mode != _currentVideoFitMode) {
          setState(() {
            _currentVideoFitMode = mode;
          });
        }
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Quand l'app passe en background, entrer automatiquement en PiP si la vidéo est en lecture
      if (_isPlaying && !_isPipActive && _isPipSupported) {
        final pipRepo = ref.read(pictureInPictureRepositoryProvider);
        final autoEnterUseCase = AutoEnterPictureInPicture(pipRepo);
        unawaited(autoEnterUseCase.call(_isPlaying));
      }
    }
  }

  Future<void> _initializePip() async {
    // PiP désactivé sur Windows
    if (Platform.isWindows) {
      _isPipSupported = false;
      return;
    }

    final pipRepo = ref.read(pictureInPictureRepositoryProvider);
    _isPipSupported = await pipRepo.isSupported();

    // Écouter les changements d'état PiP
    _subscriptions.add(
      pipRepo.isActiveStream.listen((isActive) async {
        if (mounted) {
          setState(() {
            _isPipActive = isActive;
          });
        }
      }),
    );
  }

  Future<void> _onPictureInPicture() async {
    final pipRepo = ref.read(pictureInPictureRepositoryProvider);
    if (_isPipActive) {
      final exitUseCase = ExitPictureInPicture(pipRepo);
      await exitUseCase();
    } else {
      final enterUseCase = EnterPictureInPicture(pipRepo);
      await enterUseCase();
    }
    _startHideControlsTimer();
  }

  Future<void> _showVideoFitModeMenu() async {
    // Ne pas masquer les contrôles pendant la sélection
    _hideControlsTimer?.cancel();

    // S'assurer que le player continue de jouer
    final wasPlaying = _isPlaying;

    await showModalBottomSheet<VideoFitMode?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => VideoFitModeSelectionMenu(
        currentMode: _currentVideoFitMode,
        onModeSelected: (mode) async {
          try {
            final prefs = ref.read(slProvider)<PlayerPreferences>();
            await prefs.setPreferredVideoFitMode(mode);
            if (mounted) {
              setState(() {
                _currentVideoFitMode = mode;
              });
            }
          } catch (e) {
            // Ignorer les erreurs si le player a été disposé
          }
        },
      ),
    );

    // S'assurer que le player continue de jouer après la sélection
    if (mounted && wasPlaying && !_isPlaying) {
      try {
        await _playerRepository.play();
      } catch (e) {
        // Ignorer les erreurs si le player a été disposé
      }
    }

    // Relancer le timer après la sélection
    if (mounted) {
      _startHideControlsTimer();
    }
  }

  void _onChromecast() {
    // Nécessite l'ajout d'un package comme flutter_cast ou cast_framework
    // et la configuration des services Google Cast
    if (mounted) {
      final logger = ref.read(slProvider)<AppLogger>();
      logger.info('Chromecast tapped', category: 'Player');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.featureComingSoon),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _startHideControlsTimer();
  }

  Future<void> _onBack(BuildContext context) async {
    // Sauvegarder l'historique et synchroniser en parallèle sans bloquer la navigation
    // Utiliser le VideoSource actuel (peut être mis à jour lors du changement d'épisode)
    final videoSource = _currentVideoSource ?? widget.videoSource;

    // Si la vidéo est en lecture et que le PiP est supporté, entrer en PiP au lieu de fermer
    if (_isPlaying && _isPipSupported && !_isPipActive) {
      // Pour PiP, on doit attendre avant de naviguer
      try {
        final pipRepo = ref.read(pictureInPictureRepositoryProvider);
        final autoEnterUseCase = AutoEnterPictureInPicture(pipRepo);
        await autoEnterUseCase.call(_isPlaying);
        // Ne pas fermer le player, laisser le PiP actif
        return;
      } catch (_) {
        // En cas d'erreur, continuer avec la fermeture normale
      }
    }

    // Naviguer immédiatement sans attendre
    if (context.mounted) {
      context.pop();
    }

    // Déclencher toutes les opérations en parallèle en arrière-plan
    if (videoSource?.contentId != null &&
        videoSource?.contentType != null &&
        _duration > Duration.zero) {
      // Sauvegarder l'historique en arrière-plan
      unawaited(
        () async {
          try {
            // Utiliser le repository hybride (local + Supabase si disponible)
            final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
            await historyRepo.upsertPlay(
              contentId: videoSource!.contentId!,
              type: videoSource.contentType!,
              title: videoSource.title ?? '',
              poster: videoSource.poster,
              position: _position,
              duration: _duration,
              season: videoSource.season,
              episode: videoSource.episode,
              userId: ref.read(currentUserIdProvider),
            );

            // Invalider les providers pour rafraîchir la liste
            ref.invalidate(homeInProgressProvider);
            ref.invalidate(libraryPlaylistsProvider);
          } catch (_) {
            // Ignorer les erreurs
          }
        }(),
      );
    }

    // Mettre en pause en arrière-plan
    unawaited(
      () async {
        try {
          await _playerRepository.pause();
        } catch (_) {
          // Ignorer les erreurs
        }
      }(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Best-effort: éviter une lecture qui continue en arrière-plan.
    try {
      unawaited(_playerRepository.pause());
    } catch (_) {}

    // Sauvegarder l'historique de l'épisode actuel avant de fermer
    // (au cas où l'app se ferme sans passer par _onBack)
    // C'est l'épisode qu'on regarde actuellement qui sera sauvegardé
    // et qui sera repris lors de la prochaine ouverture
    final videoSource = _currentVideoSource ?? widget.videoSource;
    if (videoSource?.contentId != null &&
        videoSource?.contentType != null &&
        _duration > Duration.zero) {
      try {
        // Utiliser le repository hybride (local + Supabase si disponible)
        final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
        // Fire-and-forget : on ne peut pas attendre dans dispose()
        historyRepo
            .upsertPlay(
              contentId: videoSource!.contentId!,
              type: videoSource.contentType!,
              title: videoSource.title ?? '',
              poster: videoSource.poster,
              position: _position,
              duration: _duration,
              season: videoSource.season,
              episode: videoSource.episode,
              userId: ref.read(currentUserIdProvider),
            )
            .catchError((_) {
              // Ignorer les erreurs silencieusement
            });
      } catch (_) {
        // Ignorer les erreurs
      }
    }

    _hideControlsTimer?.cancel();
    _controlsAnimationController.dispose();

    // Annuler toutes les subscriptions avant de disposer le player
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Relâcher nos subscriptions manuelles (déclenche l'autoDispose des providers).
    _videoControllerSub.close();
    _playerRepositorySub.close();

    // Restaurer uniquement le mode vertical pour le reste de l'app
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Libérer le contrôle de la luminosité pour permettre les modifications système
    try {
      final systemControlRepo = ref.read(systemControlRepositoryProvider);
      final resetBrightness = ResetBrightness(systemControlRepo);
      unawaited(resetBrightness.call());
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }

    // Restaurer la barre de statut
    if (defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    // Le provider autoDispose gère la libération du player et du controller
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser le VideoSource actuel (peut être mis à jour lors du changement d'épisode)
    final videoSource =
        _currentVideoSource ??
        widget.videoSource ??
        (GoRouterState.of(context).extra as VideoSource?);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBack(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: _onScreenTap,
          onDoubleTapDown: _onDoubleTap,
          onVerticalDragStart: _onVerticalDragStart,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vidéo (sans contrôles natifs)
              LayoutBuilder(
                builder: (context, constraints) {
                  final videoWidget = Video(
                    controller: _videoController,
                    controls: NoVideoControls,
                  );

                  if (_currentVideoFitMode == VideoFitMode.contain) {
                    // Pour contain, on centre la vidéo et on la laisse prendre sa taille naturelle
                    // Le Video widget gère déjà son aspect ratio
                    return Center(child: videoWidget);
                  } else {
                    // Pour cover, on utilise Transform.scale pour remplir l'écran
                    // On calcule un facteur d'échelle basé sur les dimensions de l'écran
                    // pour garantir que la vidéo couvre tout l'écran
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;
                    final screenAspectRatio = screenWidth / screenHeight;
                    
                    // Calculer un facteur d'échelle qui garantit la couverture
                    // En supposant que la vidéo a un aspect ratio standard (16:9 = 1.78)
                    // Si l'écran est plus large que 16:9, on doit agrandir verticalement
                    // Si l'écran est plus étroit que 16:9, on doit agrandir horizontalement
                    final standardVideoAspectRatio = 16 / 9; // ~1.78
                    double scale;
                    if (screenAspectRatio > standardVideoAspectRatio) {
                      // Écran plus large : agrandir verticalement
                      scale = screenHeight / (screenWidth / standardVideoAspectRatio);
                    } else {
                      // Écran plus étroit : agrandir horizontalement
                      scale = screenWidth / (screenHeight * standardVideoAspectRatio);
                    }
                    // Utiliser un facteur minimum de 1.2 et maximum de 3.0
                    final finalScale = scale.clamp(1.2, 3.0);
                    
                    return ClipRect(
                      child: Center(
                        child: Transform.scale(
                          scale: finalScale,
                          child: videoWidget,
                        ),
                      ),
                    );
                  }
                },
              ),

              // Indicateur de chargement
              if (_isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Contrôles avec animation d'opacité
              if (_showControls)
                FadeTransition(
                  opacity: _controlsOpacityAnimation,
                  child: VideoPlayerControls(
                    key: _controlsKey,
                    title: videoSource?.title ?? '',
                    subtitle: videoSource?.subtitle,
                    isPlaying: _isPlaying,
                    position: _position,
                    duration: _duration,
                    hasSubtitles: _hasSubtitles,
                    subtitlesEnabled: _subtitlesEnabled,
                    onBack: () => _onBack(context),
                    onPlayPause: _togglePlayPause,
                    onSeekForward10: () => _seekForward(10),
                    onSeekForward30: () => _seekForward(30),
                    onSeekBackward10: () => _seekBackward(10),
                    onSeekBackward30: () => _seekBackward(30),
                    onSeek: _onSeek,
                    onToggleSubtitles: _showSubtitleMenu,
                    onAudio: _showAudioMenu,
                    onChromecast: _onChromecast,
                    onVideoFitMode: _showVideoFitModeMenu,
                    formatDuration: _formatDuration,
                    hasAudioTracks: _audioTracks.isNotEmpty,
                    onRestart: _restart,
                    onNextEpisode:
                        videoSource?.contentType == ContentType.series
                        ? _goToNextEpisode
                        : null,
                    isSeries: videoSource?.contentType == ContentType.series,
                    onPictureInPicture: _onPictureInPicture,
                    isPipSupported: _isPipSupported,
                    isPipActive: _isPipActive,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

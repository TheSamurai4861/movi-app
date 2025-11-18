import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movi/src/features/player/data/repositories/media_kit_video_player_repository.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/presentation/widgets/video_player_controls.dart';
import 'package:movi/src/features/player/presentation/widgets/track_selection_menu.dart';

/// Page de lecture vidéo avec contrôles personnalisés
class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({
    super.key,
    this.videoSource,
  });

  final VideoSource? videoSource;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage>
    with SingleTickerProviderStateMixin {
  late final MediaKitVideoPlayerRepository _playerRepository;
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
  List<SubtitleTrack> _subtitleTracks = [];
  List<AudioTrack> _audioTracks = [];
  SubtitleTrack? _currentSubtitleTrack;
  AudioTrack? _currentAudioTrack;
  final GlobalKey _controlsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Forcer le mode paysage
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Masquer la barre de statut et la barre de navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _playerRepository = MediaKitVideoPlayerRepository();
    _videoController = VideoController(_playerRepository.player);

    // Animation d'opacité pour les contrôles
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));

    _setupListeners();
    _showControlsWithAnimation();
    _startHideControlsTimer();

    if (widget.videoSource != null) {
      _playerRepository.open(widget.videoSource!);
    }
  }

  void _setupListeners() {
    _playerRepository.player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _playerRepository.player.stream.position.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _playerRepository.player.stream.duration.listen((duration) {
      if (mounted && duration != Duration.zero) {
        setState(() => _duration = duration);
      }
    });

    _playerRepository.player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() => _isBuffering = buffering);
      }
    });

    _playerRepository.player.stream.tracks.listen((tracks) {
      if (mounted) {
        setState(() {
          _hasSubtitles = tracks.subtitle.isNotEmpty;
          _subtitleTracks = tracks.subtitle;
          _audioTracks = tracks.audio;
        });
      }
    });
    
    // Mettre à jour les pistes actuelles quand les tracks changent
    _playerRepository.player.stream.tracks.listen((tracks) {
      if (mounted) {
        // Trouver la piste de sous-titres actuellement sélectionnée
        // En comparant avec les pistes disponibles
        SubtitleTrack? currentSubtitle;
        if (_currentSubtitleTrack != null) {
          currentSubtitle = tracks.subtitle.firstWhere(
            (t) => t.id == _currentSubtitleTrack!.id,
            orElse: () => tracks.subtitle.firstOrNull ?? tracks.subtitle.first,
          );
        }
        
        // Trouver la piste audio actuellement sélectionnée
        AudioTrack? currentAudio;
        if (_currentAudioTrack != null) {
          currentAudio = tracks.audio.firstWhere(
            (t) => t.id == _currentAudioTrack!.id,
            orElse: () => tracks.audio.firstOrNull ?? tracks.audio.first,
          );
        }
        
        setState(() {
          _currentSubtitleTrack = currentSubtitle;
          _currentAudioTrack = currentAudio;
          _subtitlesEnabled = currentSubtitle != null;
        });
      }
    });
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

  void _onScreenTap(TapDownDetails details) {
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

  Future<void> _showSubtitleMenu() async {
    if (_subtitleTracks.isEmpty) return;
    
    // Ne pas masquer les contrôles pendant la sélection
    _hideControlsTimer?.cancel();
    
    // S'assurer que le player continue de jouer
    final wasPlaying = _isPlaying;
    
    await showModalBottomSheet<SubtitleTrack?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SubtitleTrackSelectionMenu(
        tracks: _subtitleTracks,
        currentTrack: _currentSubtitleTrack,
        onTrackSelected: (track) async {
          await _playerRepository.player.setSubtitleTrack(track);
        },
        onDisable: () async {
          // Désactiver les sous-titres
          // Note: media_kit ne supporte pas directement null, donc on garde l'état local
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
      await _playerRepository.play();
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
    
    await showModalBottomSheet<AudioTrack?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AudioTrackSelectionMenu(
        tracks: _audioTracks,
        currentTrack: _currentAudioTrack,
        onTrackSelected: (track) async {
          await _playerRepository.player.setAudioTrack(track);
        },
      ),
    );
    
    // S'assurer que le player continue de jouer après la sélection
    if (mounted && wasPlaying && !_isPlaying) {
      await _playerRepository.play();
    }
    
    // Relancer le timer après la sélection
    if (mounted) {
      _startHideControlsTimer();
    }
  }

  void _onChromecast() {
    // TODO: Implémenter Chromecast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chromecast à venir')),
    );
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controlsAnimationController.dispose();
    
    // Restaurer les orientations par défaut
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Restaurer la barre de statut
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _playerRepository.dispose();
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
    final videoSource = widget.videoSource ??
        (GoRouterState.of(context).extra as VideoSource?);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onScreenTap,
        onDoubleTapDown: _onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vidéo (sans contrôles natifs)
            Center(
              child: Video(
                controller: _videoController,
                controls: NoVideoControls,
              ),
            ),

            // Indicateur de chargement
            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
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
                  onBack: () => context.pop(),
                  onPlayPause: _togglePlayPause,
                  onSeekForward10: () => _seekForward(10),
                  onSeekForward30: () => _seekForward(30),
                  onSeekBackward10: () => _seekBackward(10),
                  onSeekBackward30: () => _seekBackward(30),
                  onSeek: _onSeek,
                  onToggleSubtitles: _showSubtitleMenu,
                  onAudio: _showAudioMenu,
                  onChromecast: _onChromecast,
                  formatDuration: _formatDuration,
                  hasAudioTracks: _audioTracks.isNotEmpty,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


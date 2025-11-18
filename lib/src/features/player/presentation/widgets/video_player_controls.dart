import 'package:flutter/material.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/theme/app_colors.dart';

/// Widget de contrôles du player vidéo
class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({
    super.key,
    required this.title,
    this.subtitle,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.hasSubtitles,
    required this.subtitlesEnabled,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeekForward10,
    required this.onSeekForward30,
    required this.onSeekBackward10,
    required this.onSeekBackward30,
    required this.onSeek,
    required this.onToggleSubtitles,
    this.onAudio,
    required this.onChromecast,
    required this.formatDuration,
    this.hasAudioTracks = false,
  });

  final String title;
  final String? subtitle;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool hasSubtitles;
  final bool subtitlesEnabled;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward10;
  final VoidCallback onSeekForward30;
  final VoidCallback onSeekBackward10;
  final VoidCallback onSeekBackward30;
  final void Function(double) onSeek;
  final VoidCallback onToggleSubtitles;
  final VoidCallback? onAudio;
  final VoidCallback onChromecast;
  final String Function(Duration) formatDuration;
  final bool hasAudioTracks;

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    // Empêcher la propagation du tap aux widgets parents
    return GestureDetector(
      onTap: () {
        // Ne rien faire, empêcher la propagation
      },
      behavior: HitTestBehavior.opaque,
      child: _buildControls(context, progress),
    );
  }

  Widget _buildControls(BuildContext context, double progress) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF000000), Color(0x00000000)],
              ),
            ),
          ),
        ),

        // Gradient bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xFF000000)],
              ),
            ),
          ),
        ),

        // Titre centré au-dessus de l'écran
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),

        // Top bar avec boutons retour et Chromecast
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Bouton retour
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(AppAssets.iconBack),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quitter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bouton Chromecast
                  GestureDetector(
                    onTap: onChromecast,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(AppAssets.iconChromecast),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Contrôles centraux (play/pause, avancer/reculer)
        Center(
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reculer 30s
                _ControlButton(
                  icon: AppAssets.iconReculer,
                  label: '30 s',
                  onTap: onSeekBackward30,
                ),
                const SizedBox(width: 16),
                // Reculer 10s
                _ControlButton(
                  icon: AppAssets.iconReculer,
                  label: '10 s',
                  onTap: onSeekBackward10,
                ),
                const SizedBox(width: 24),
                // Play/Pause (aligné verticalement avec les autres boutons)
                _ControlButton(
                  icon: isPlaying ? AppAssets.iconPause : AppAssets.iconPlay,
                  label: '',
                  onTap: onPlayPause,
                  isLarge: true,
                ),
                const SizedBox(width: 24),
                // Avancer 10s
                _ControlButton(
                  icon: AppAssets.iconAvancer,
                  label: '+ 10 s',
                  onTap: onSeekForward10,
                ),
                const SizedBox(width: 16),
                // Avancer 30s
                _ControlButton(
                  icon: AppAssets.iconAvancer,
                  label: '+ 30 s',
                  onTap: onSeekForward30,
                ),
              ],
            ),
          ),
        ),

        // Bottom bar avec progress bar et contrôles
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: onSeek,
                        activeColor: AppColors.accent,
                        inactiveColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Temps et contrôles
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Temps actuel
                        Text(
                          formatDuration(position),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          ' : ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        // Temps total
                        Text(
                          formatDuration(duration),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Bouton audio
                        if (hasAudioTracks)
                          GestureDetector(
                            onTap: onAudio,
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset(AppAssets.iconAudio),
                            ),
                          ),
                        const SizedBox(width: 16),
                        // Bouton sous-titres
                        GestureDetector(
                          onTap: onToggleSubtitles,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset(
                              hasSubtitles && subtitlesEnabled
                                  ? AppAssets.iconSubtitles
                                  : AppAssets.iconSubtitlesDesactive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLarge = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final buttonSize = isLarge ? 64.0 : 48.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Image.asset(icon),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

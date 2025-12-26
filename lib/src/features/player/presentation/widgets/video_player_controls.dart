import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

/// Widget de contrôles du player vidéo
class VideoPlayerControls extends ConsumerWidget {
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
    this.onVideoFitMode,
    required this.formatDuration,
    this.hasAudioTracks = false,
    this.onRestart,
    this.onNextEpisode,
    this.isSeries = false,
    this.onPictureInPicture,
    this.isPipSupported = false,
    this.isPipActive = false,
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
  final VoidCallback? onVideoFitMode;
  final String Function(Duration) formatDuration;
  final bool hasAudioTracks;
  final VoidCallback? onRestart;
  final VoidCallback? onNextEpisode;
  final bool isSeries;
  final VoidCallback? onPictureInPicture;
  final bool isPipSupported;
  final bool isPipActive;

  /// Extrait le titre à afficher : pour les séries, affiche "SXX EXX - Titre série"
  String _getDisplayTitle() {
    if (!isSeries) {
      return title;
    }

    // Pour les séries, extraire "SXX EXX - Titre série" du titre complet
    // Format attendu : "Titre série - SXX EXX - Titre épisode" ou "Titre série - SXX EXX"
    final parts = title.split(' - ');
    if (parts.length >= 2) {
      // Le premier élément est le titre de la série
      final seriesTitle = parts[0].trim();

      // Chercher la partie qui contient "SXX EXX"
      for (int i = 1; i < parts.length; i++) {
        final regex = RegExp(r'S(\d{2})E(\d{2})');
        final match = regex.firstMatch(parts[i]);
        if (match != null) {
          final season = match.group(1);
          final episode = match.group(2);
          // Retourner "SXX EXX - Titre série"
          return 'S$season E$episode - $seriesTitle';
        }
      }
    }

    // Si le format n'est pas reconnu, retourner le titre original
    return title;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    // Empêcher la propagation du tap aux widgets parents
    return GestureDetector(
      onTap: () {
        // Ne rien faire, empêcher la propagation
      },
      behavior: HitTestBehavior.opaque,
      child: _buildControls(context, ref, progress),
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, double progress) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
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
                  _getDisplayTitle(),
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
                  _IconButton(onTap: onBack, iconAsset: AppAssets.iconBack),
                  const Spacer(),
                  // Bouton resize (mode d'affichage)
                  if (onVideoFitMode != null)
                    _IconButton(
                      onTap: onVideoFitMode,
                      iconAsset: AppAssets.iconResize,
                    ),
                  if (onVideoFitMode != null) const SizedBox(width: 24),
                  // Bouton Chromecast
                  _IconButton(
                    onTap: onChromecast,
                    iconAsset: AppAssets.iconChromecast,
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
                  label: AppLocalizations.of(context)!.controlRewind30,
                  onTap: onSeekBackward30,
                ),
                const SizedBox(width: 16),
                // Reculer 10s
                _ControlButton(
                  icon: AppAssets.iconReculer,
                  label: AppLocalizations.of(context)!.controlRewind10,
                  onTap: onSeekBackward10,
                ),
                const SizedBox(width: 24),
                // Play/Pause (remonté de 6px)
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: _ControlButton(
                    icon: isPlaying ? AppAssets.iconPause : AppAssets.iconPlay,
                    label: '',
                    onTap: onPlayPause,
                    isLarge: true,
                  ),
                ),
                const SizedBox(width: 24),
                // Avancer 10s
                _ControlButton(
                  icon: AppAssets.iconAvancer,
                  label: AppLocalizations.of(context)!.controlForward10,
                  onTap: onSeekForward10,
                ),
                const SizedBox(width: 16),
                // Avancer 30s
                _ControlButton(
                  icon: AppAssets.iconAvancer,
                  label: AppLocalizations.of(context)!.controlForward30,
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
                        activeColor: accentColor,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
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
                          style: TextStyle(fontSize: 14, color: Colors.white),
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
                        // Bouton "Episode suivant" (séries uniquement)
                        if (isSeries && onNextEpisode != null)
                          GestureDetector(
                            onTap: onNextEpisode,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.actionNextEpisode,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Transform.rotate(
                                  angle: 3.14159, // 180 degrés en radians
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Image.asset(AppAssets.iconBack),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Espacement entre "Episode suivant" et "Recommencer" : 24px si les deux existent
                        if (isSeries &&
                            onNextEpisode != null &&
                            onRestart != null)
                          const SizedBox(width: 24),
                        // Bouton "Recommencer"
                        if (onRestart != null)
                          GestureDetector(
                            onTap: onRestart,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.actionRestart,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Image.asset(AppAssets.iconReculer),
                                ),
                              ],
                            ),
                          ),
                        // Espacement avant le bouton audio : 36px
                        if (onRestart != null)
                          const SizedBox(width: 36)
                        else if (isSeries && onNextEpisode != null)
                          const SizedBox(width: 36),
                        // Bouton audio
                        if (hasAudioTracks)
                          _IconButton(
                            onTap: onAudio,
                            iconAsset: AppAssets.iconAudio,
                          ),
                        const SizedBox(width: 24),
                        // Bouton sous-titres
                        _IconButton(
                          onTap: hasSubtitles ? onToggleSubtitles : null,
                          iconAsset: hasSubtitles
                              ? AppAssets.iconSubtitles
                              : AppAssets.iconSubtitlesDesactive,
                        ),
                        // Bouton PiP (si supporté)
                        if (isPipSupported) ...[
                          const SizedBox(width: 24),
                          _IconButton(
                            onTap: onPictureInPicture,
                            icon: Icons.picture_in_picture,
                            iconColor: isPipActive ? accentColor : Colors.white,
                          ),
                        ],
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

/// Widget pour les boutons d'icônes avec zone de clic optimisée.
///
/// Fournit une zone de clic minimale de 48x48 pixels (recommandation Material Design)
/// avec une icône de 28px centrée.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.onTap,
    this.iconAsset,
    this.icon,
    // ignore: unused_element_parameter
    this.iconSize = 28.0,
    this.iconColor,
  }) : assert(
         iconAsset != null || icon != null,
         'Either iconAsset or icon must be provided',
       );

  final VoidCallback? onTap;
  final String? iconAsset;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(10),
        child: Center(
          child: iconAsset != null
              ? SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(iconAsset!),
                )
              : Icon(icon, size: iconSize, color: iconColor ?? Colors.white),
        ),
      ),
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
              color: Colors.white.withValues(alpha: 0.2),
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

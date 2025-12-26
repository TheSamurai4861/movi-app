import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/parental/application/services/child_profile_rating_preload_service.dart';
import 'package:movi/src/core/state/app_state_provider.dart';

class ChildProfilePreloadPage extends ConsumerStatefulWidget {
  const ChildProfilePreloadPage({
    super.key,
    required this.preloadService,
    required this.onComplete,
    this.onSkip,
  });

  final ChildProfileRatingPreloadService preloadService;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  @override
  ConsumerState<ChildProfilePreloadPage> createState() =>
      _ChildProfilePreloadPageState();
}

class _ChildProfilePreloadPageState
    extends ConsumerState<ChildProfilePreloadPage> {
  PreloadProgress? _progress;

  @override
  void initState() {
    super.initState();
    widget.preloadService.progress.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
          if (progress.phase == PreloadPhase.completed) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                widget.onComplete();
              }
            });
          }
        }
      },
      onError: (error) {
        // En cas d'erreur, continuer quand même
        if (mounted) {
          widget.onComplete();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(currentAccentColorProvider);
    final progress = _progress;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Icône ou animation
              Icon(
                Icons.child_care,
                size: 64,
                color: accentColor,
              ),
              const SizedBox(height: 32),
              // Titre
              Text(
                'Sécurisation du contenu',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vérification des classifications d\'âge...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Phase actuelle
              if (progress != null) ...[
                Text(
                  _getPhaseText(progress.phase),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Barre de progression globale
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.overallProgress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                // Compteurs
                _buildCounters(theme, progress),
                const SizedBox(height: 24),
                // Estimation du temps
                if (progress.estimatedSecondsRemaining != null)
                  Text(
                    _formatTimeRemaining(progress.estimatedSecondsRemaining!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ] else ...[
                // Indicateur de chargement initial
                CircularProgressIndicator(
                  color: accentColor,
                ),
              ],
              const Spacer(),
              // Bouton "Passer" (optionnel)
              if (widget.onSkip != null && progress != null)
                TextButton(
                  onPressed: widget.onSkip,
                  child: const Text('Passer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounters(ThemeData theme, PreloadProgress progress) {
    return Column(
      children: [
        _buildCounterRow(
          theme,
          'Films',
          progress.moviesProcessed,
          progress.moviesTotal,
        ),
        const SizedBox(height: 12),
        _buildCounterRow(
          theme,
          'Séries',
          progress.seriesProcessed,
          progress.seriesTotal,
        ),
      ],
    );
  }

  Widget _buildCounterRow(
    ThemeData theme,
    String label,
    int processed,
    int total,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Text(
          '$processed / $total',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getPhaseText(PreloadPhase phase) {
    switch (phase) {
      case PreloadPhase.resolvingIds:
        return 'Résolution des identifiants...';
      case PreloadPhase.fetchingRatings:
        return 'Récupération des classifications...';
      case PreloadPhase.completed:
        return 'Terminé';
    }
  }

  String _formatTimeRemaining(int seconds) {
    if (seconds < 60) {
      return 'Environ $seconds seconde${seconds > 1 ? 's' : ''} restante${seconds > 1 ? 's' : ''}';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return 'Environ $minutes minute${minutes > 1 ? 's' : ''} restante${minutes > 1 ? 's' : ''}';
    }
    return 'Environ $minutes min $remainingSeconds sec restantes';
  }
}


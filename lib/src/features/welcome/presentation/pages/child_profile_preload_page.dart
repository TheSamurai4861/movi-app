import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
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
  StreamSubscription<PreloadProgress>? _progressSubscription;
  PreloadProgress? _progress;
  bool _completionTriggered = false;

  @override
  void initState() {
    super.initState();
    _startPreload();
  }

  @override
  void dispose() {
    unawaited(_progressSubscription?.cancel());
    super.dispose();
  }

  void _startPreload() {
    _progressSubscription = widget.preloadService.preloadRatings().listen(
      _handleProgress,
      onError: _handleError,
    );
  }

  void _handleProgress(PreloadProgress progress) {
    if (!mounted) {
      return;
    }

    setState(() {
      _progress = progress;
    });

    if (progress.phase == PreloadPhase.completed) {
      _scheduleCompletion();
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _scheduleCompletion();
  }

  void _scheduleCompletion() {
    if (_completionTriggered) {
      return;
    }
    _completionTriggered = true;

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = ref.watch(currentAccentColorProvider);
    final progress = _progress;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.child_care, size: 64, color: accentColor),
              const SizedBox(height: 32),
              Text(
                l10n.childPreloadTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.childPreloadSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (progress != null) ...[
                Text(
                  _getPhaseText(progress.phase),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
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
                _buildCounters(theme, progress),
                const SizedBox(height: 24),
                if (progress.estimatedSecondsRemaining != null)
                  Text(
                    _formatTimeRemaining(progress.estimatedSecondsRemaining!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ] else ...[
                CircularProgressIndicator(color: accentColor),
              ],
              const Spacer(),
              if (widget.onSkip != null && progress != null)
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(l10n.childPreloadSkip),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounters(ThemeData theme, PreloadProgress progress) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildCounterRow(
          theme,
          l10n.moviesTitle,
          progress.moviesProcessed,
          progress.moviesTotal,
        ),
        const SizedBox(height: 12),
        _buildCounterRow(
          theme,
          l10n.seriesTitle,
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
        Text(label, style: theme.textTheme.bodyMedium),
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
    final l10n = AppLocalizations.of(context)!;
    switch (phase) {
      case PreloadPhase.resolvingIds:
        return l10n.childPreloadPhaseResolvingIds;
      case PreloadPhase.fetchingRatings:
        return l10n.childPreloadPhaseFetchingRatings;
      case PreloadPhase.completed:
        return l10n.childPreloadPhaseCompleted;
    }
  }

  String _formatTimeRemaining(int seconds) {
    final l10n = AppLocalizations.of(context)!;
    if (seconds < 60) {
      return l10n.childPreloadEtaSeconds(seconds);
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (remainingSeconds == 0) {
      return l10n.childPreloadEtaMinutes(minutes);
    }

    return l10n.childPreloadEtaMinutesSeconds(minutes, remainingSeconds);
  }
}

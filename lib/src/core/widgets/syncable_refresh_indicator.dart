import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';

/// Widget RefreshIndicator qui déclenche la synchronisation complète
/// (bibliothèque, profils, sources IPTV, préférences) au lieu de juste
/// rafraîchir le contenu local de la page.
///
/// Usage:
/// ```dart
/// SyncableRefreshIndicator(
///   child: ListView(...),
/// )
/// ```
class SyncableRefreshIndicator extends ConsumerWidget {
  const SyncableRefreshIndicator({
    super.key,
    required this.child,
    this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.0,
  });

  /// Le widget scrollable à envelopper
  final Widget child;

  /// Callback optionnel appelé après la synchronisation
  final Future<void> Function()? onRefresh;

  /// Distance depuis le haut où l'indicateur apparaît
  final double displacement;

  /// Offset depuis le bord
  final double edgeOffset;

  /// Couleur de l'indicateur
  final Color? color;

  /// Couleur de fond de l'indicateur
  final Color? backgroundColor;

  /// Épaisseur du trait de l'indicateur
  final double strokeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncController = ref.read(libraryCloudSyncControllerProvider.notifier);
    final accentColor = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: () async {
        // Déclencher la synchronisation complète
        await syncController.syncNow(reason: 'pull-to-refresh');

        // Appeler le callback optionnel
        if (onRefresh != null) {
          await onRefresh!();
        }
      },
      displacement: displacement,
      edgeOffset: edgeOffset,
      color: color ?? accentColor,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      child: child,
    );
  }
}

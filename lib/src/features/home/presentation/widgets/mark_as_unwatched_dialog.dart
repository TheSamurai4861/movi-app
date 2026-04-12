import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_remote_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Affiche un dialog pour marquer un média comme non vu.
void showMarkAsUnwatchedDialog(
  BuildContext context,
  WidgetRef ref,
  String contentId,
  ContentType type,
) {
  final triggerFocusNode = FocusManager.instance.primaryFocus;
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MarkAsUnwatchedSheet(
      ref: ref,
      contentId: contentId,
      type: type,
      triggerFocusNode: triggerFocusNode,
    ),
  );
}

class _MarkAsUnwatchedSheet extends StatefulWidget {
  const _MarkAsUnwatchedSheet({
    required this.ref,
    required this.contentId,
    required this.type,
    required this.triggerFocusNode,
  });

  final WidgetRef ref;
  final String contentId;
  final ContentType type;
  final FocusNode? triggerFocusNode;

  @override
  State<_MarkAsUnwatchedSheet> createState() => _MarkAsUnwatchedSheetState();
}

class _MarkAsUnwatchedSheetState extends State<_MarkAsUnwatchedSheet> {
  late final FocusNode _markActionFocusNode = FocusNode(
    debugLabel: 'mark_as_unwatched_action',
  );

  @override
  void dispose() {
    _markActionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _markAsUnwatched() async {
    Navigator.pop(context);
    final historyRepo = widget.ref.read(
      hybridPlaybackHistoryRepositoryProvider,
    );
    final userId = widget.ref.read(currentUserIdProvider);
    await historyRepo.remove(widget.contentId, widget.type, userId: userId);
    unawaited(
      widget.ref
          .read(libraryCloudSyncControllerProvider.notifier)
          .syncNow(reason: 'auto'),
    );
    widget.ref.invalidate(hp.homeInProgressProvider);
    widget.ref.invalidate(libraryPlaylistsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      initialFocusNode: _markActionFocusNode,
      fallbackFocusNode: _markActionFocusNode,
      debugLabel: 'MarkAsUnwatchedSheet',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetActionTile(
              focusNode: _markActionFocusNode,
              icon: Icons.visibility_off,
              label: 'Marquer comme non vu',
              onPressed: _markAsUnwatched,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MoviFocusableAction(
      focusNode: focusNode,
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.01 : 1,
          borderRadius: BorderRadius.circular(16),
          backgroundColor: state.focused
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderColor: state.focused
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.transparent,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const SizedBox(width: 4),
              Icon(icon, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

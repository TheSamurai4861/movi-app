import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/widgets/movi_focusable.dart';

enum LibraryFilterType { playlists, sagas, artistes }

class LibraryFilterPills extends ConsumerWidget {
  const LibraryFilterPills({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final LibraryFilterType? activeFilter;
  final ValueChanged<LibraryFilterType?> onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    return Row(
      children: [
        if (activeFilter != null) ...[
          MoviFocusableAction(
            onPressed: () => onFilterChanged(null),
            semanticLabel:
                AppLocalizations.of(context)!.libraryClearFilterSemanticLabel,
            builder: (context, state) {
              return MoviFocusFrame(
                scale: state.focused ? 1.04 : 1,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: state.focused ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        // Pills de filtre
        _FilterPill(
          label: AppLocalizations.of(context)!.libraryPlaylistsFilter,
          isActive: activeFilter == LibraryFilterType.playlists,
          accentColor: accentColor,
          onTap: () => onFilterChanged(
            activeFilter == LibraryFilterType.playlists
                ? null
                : LibraryFilterType.playlists,
          ),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: AppLocalizations.of(context)!.librarySagasFilter,
          isActive: activeFilter == LibraryFilterType.sagas,
          accentColor: accentColor,
          onTap: () => onFilterChanged(
            activeFilter == LibraryFilterType.sagas
                ? null
                : LibraryFilterType.sagas,
          ),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: AppLocalizations.of(context)!.libraryArtistsFilter,
          isActive: activeFilter == LibraryFilterType.artistes,
          accentColor: accentColor,
          onTap: () => onFilterChanged(
            activeFilter == LibraryFilterType.artistes
                ? null
                : LibraryFilterType.artistes,
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactiveBg = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0.72);
    final focusBg = isActive
        ? accentColor
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return MoviFocusableAction(
      onPressed: onTap,
      semanticLabel: label,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.04 : 1,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: state.focused
                  ? focusBg
                  : (isActive ? accentColor : inactiveBg),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: state.focused
                    ? Colors.white
                    : (isActive ? accentColor : Colors.white30),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

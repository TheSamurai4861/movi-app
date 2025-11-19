import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

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
          // Pill avec close pour annuler le filtre
          GestureDetector(
            onTap: () => onFilterChanged(null),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? accentColor : Colors.white30,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

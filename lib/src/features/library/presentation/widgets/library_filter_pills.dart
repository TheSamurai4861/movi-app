import 'package:flutter/material.dart';

enum LibraryFilterType {
  playlists,
  sagas,
  artistes,
}

class LibraryFilterPills extends StatelessWidget {
  const LibraryFilterPills({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final LibraryFilterType? activeFilter;
  final ValueChanged<LibraryFilterType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (activeFilter != null) ...[
          // Pill avec close pour annuler le filtre
          GestureDetector(
            onTap: () => onFilterChanged(null),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2160AB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Pills de filtre
        _FilterPill(
          label: 'Playlists',
          isActive: activeFilter == LibraryFilterType.playlists,
          onTap: () => onFilterChanged(
            activeFilter == LibraryFilterType.playlists
                ? null
                : LibraryFilterType.playlists,
          ),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: 'Sagas',
          isActive: activeFilter == LibraryFilterType.sagas,
          onTap: () => onFilterChanged(
            activeFilter == LibraryFilterType.sagas
                ? null
                : LibraryFilterType.sagas,
          ),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: 'Artistes',
          isActive: activeFilter == LibraryFilterType.artistes,
          onTap: () => onFilterChanged(
            activeFilter == LibraryFilterType.artistes
                ? null
                : LibraryFilterType.artistes,
          ),
        ),
      ],
    );
  }

  String _getFilterLabel(LibraryFilterType type) {
    switch (type) {
      case LibraryFilterType.playlists:
        return 'Playlists';
      case LibraryFilterType.sagas:
        return 'Sagas';
      case LibraryFilterType.artistes:
        return 'Artistes';
    }
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2160AB) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? const Color(0xFF2160AB) : Colors.white30,
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


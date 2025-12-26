import 'package:flutter/material.dart';

import 'package:movi/src/core/profile/presentation/ui/profile_color_palette.dart';

/// SÃƒÆ’Ã‚Â©lecteur de couleurs pour les profils.
/// - UI-only (pas de Riverpod, pas de repo).
class ProfileColorPicker extends StatelessWidget {
  const ProfileColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(profileColorOptions.length, (index) {
        final (color, _) = profileColorOptions[index];
        final isSelected = index == selectedIndex;

        return GestureDetector(
          onTap: () => onSelected(index),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }),
    );
  }
}

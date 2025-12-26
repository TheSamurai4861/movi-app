import 'package:flutter/material.dart';

/// Affiche un avatar de profil (cercle colorÃƒÆ’Ã‚Â©) + un label.
///
/// Utilisable:
/// - dans le dialog de crÃƒÆ’Ã‚Â©ation
/// - dans le welcome picker
/// - dans une page "manage profiles"
class ProfileAvatarChip extends StatelessWidget {
  const ProfileAvatarChip({
    super.key,
    required this.color,
    required this.label,
    this.size = 80,
    this.selected = false,
    this.selectedBorderColor,
    this.icon = Icons.person,
  });

  final Color color;
  final String label;
  final double size;
  final bool selected;
  final Color? selectedBorderColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final borderColor = selectedBorderColor ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: borderColor, width: 3) : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 2,
                      color: color.withValues(alpha: 0.35),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

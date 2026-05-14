import 'package:flutter/material.dart';

/// Affiche un avatar de profil (cercle coloré) + un libellé.
///
/// Utilisable :
/// - dans le dialogue de création ;
/// - dans le sélecteur welcome ;
/// - dans une page « manage profiles ».
///
/// Si [avatarInitial] est renseigné, la première lettre (un seul graphème) est
/// affichée à la place de l’icône (alignement maquettes boot Figma).
class ProfileAvatarChip extends StatelessWidget {
  const ProfileAvatarChip({
    super.key,
    required this.color,
    required this.label,
    this.size = 80,
    this.selected = false,
    this.selectedBorderColor,
    this.icon = Icons.person,
    this.avatarInitial,
  });

  final Color color;
  final String label;
  final double size;
  final bool selected;
  final Color? selectedBorderColor;
  final IconData icon;

  /// Texte dont on affiche la première lettre dans le disque (ex. prénom).
  /// Si null ou vide, [icon] est utilisée.
  final String? avatarInitial;

  static String? _firstLetter(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final first = t.runes.first;
    return String.fromCharCode(first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = selectedBorderColor ?? Colors.white;
    final letter = _firstLetter(avatarInitial);
    final double letterFontSize = (size * 0.42).clamp(18.0, 32.0);

    final Widget diskChild = letter != null
        ? Center(
            child: Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontSize: letterFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : Icon(icon, color: Colors.white, size: size * 0.5);

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
          ),
          child: diskChild,
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

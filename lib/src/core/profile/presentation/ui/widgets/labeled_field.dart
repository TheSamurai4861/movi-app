import 'package:flutter/material.dart';

/// Champ avec label, version locale au module `core/profile`.
///
/// Pourquoi ici ?
/// - On ÃƒÆ’Ã‚Â©vite une dÃƒÆ’Ã‚Â©pendance `core -> features/welcome`.
/// - On garde un style cohÃƒÆ’Ã‚Â©rent sur les dialogs du module profile.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

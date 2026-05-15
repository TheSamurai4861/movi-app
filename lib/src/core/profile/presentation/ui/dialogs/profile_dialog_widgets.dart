import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_focusable.dart';

/// Tokens focus alignés sur les sélecteurs de la page Paramètres principale.
abstract final class ProfileDialogFocusTokens {
  static const double selectorBorderRadius = 12;
  static const double selectorPaddingH = 10;
  static const double selectorPaddingV = 6;
  static const double selectorFocusScale = 1.02;
  static const double selectorFocusBackgroundAlpha = 0.18;
  static const double pegiFocusBackgroundAlpha = 0.5;
  static const double switchFocusPaddingH = 6;
  static const double switchFocusPaddingV = 4;
}

ButtonStyle profileDialogPrimaryButtonStyle(Color accentColor) {
  return FilledButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

ButtonStyle profileDialogDestructiveButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.red.withValues(alpha: 0.18),
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.red),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

/// Badge PEGI avec focus accent à 50 % d'opacité.
class ProfileDialogPegiBadge extends StatelessWidget {
  const ProfileDialogPegiBadge({
    super.key,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onPressed,
    this.focusNode,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MoviFocusableAction(
      focusNode: focusNode,
      onPressed: enabled ? onPressed : null,
      enabled: enabled && onPressed != null,
      semanticLabel: label,
      builder: (context, state) {
        final focused = state.focused;
        return MoviFocusFrame(
          scale: focused ? ProfileDialogFocusTokens.selectorFocusScale : 1,
          borderRadius: BorderRadius.circular(
            ProfileDialogFocusTokens.selectorBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ProfileDialogFocusTokens.selectorPaddingH,
            vertical: ProfileDialogFocusTokens.selectorPaddingV,
          ),
          backgroundColor: focused
              ? accentColor.withValues(
                  alpha: ProfileDialogFocusTokens.pegiFocusBackgroundAlpha,
                )
              : selected
              ? accentColor
              : const Color(0xFF2C2C2E),
          borderColor: selected ? accentColor : Colors.white24,
          borderWidth: 1,
          child: Text(
            label,
            style: TextStyle(
              color: selected || focused ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: selected || focused ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}

/// Switch profil enfant avec halo focus accent (comme Paramètres).
class ProfileDialogFocusedSwitch extends StatelessWidget {
  const ProfileDialogFocusedSwitch({
    super.key,
    required this.focusNode,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final FocusNode focusNode;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return MoviFocusFrame(
          scale: focused ? ProfileDialogFocusTokens.selectorFocusScale : 1,
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsets.symmetric(
            horizontal: ProfileDialogFocusTokens.switchFocusPaddingH,
            vertical: ProfileDialogFocusTokens.switchFocusPaddingV,
          ),
          backgroundColor: focused
              ? accentColor.withValues(
                  alpha: ProfileDialogFocusTokens.selectorFocusBackgroundAlpha,
                )
              : Colors.transparent,
          child: Switch(
            focusNode: focusNode,
            value: value,
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

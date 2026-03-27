// lib/src/features/shell/presentation/navigation/shell_shortcuts.dart

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';

/// Intent: sélectionner un onglet précis.
class ShellSelectTabIntent extends Intent {
  const ShellSelectTabIntent(this.tab);
  final ShellTab tab;
}

/// Wrap Shortcuts + Actions pour le Shell.
///
/// Choix validés par toi :
/// - PC: oui
/// - Raccourcis: Ctrl + 1/2/3/4 uniquement
/// - Pas de chiffres seuls
/// - Désactivés quand l’utilisateur est en train d’écrire
/// - API: utilise ShellTab plutôt que index
///
/// La navigation type télécommande (flèches / Enter / Escape) est gérée
/// globalement au niveau de l'application.
class ShellShortcuts extends StatelessWidget {
  const ShellShortcuts({
    super.key,
    required this.onSelectTab,
    required this.child,
  });

  /// Callback quand on sélectionne un onglet.
  final ValueChanged<ShellTab> onSelectTab;

  /// UI à wrapper.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{
      // Ctrl + 1..4 (digits)
      const SingleActivator(LogicalKeyboardKey.digit1, control: true):
          const ShellSelectTabIntent(ShellTab.home),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true):
          const ShellSelectTabIntent(ShellTab.search),
      const SingleActivator(LogicalKeyboardKey.digit3, control: true):
          const ShellSelectTabIntent(ShellTab.library),
      const SingleActivator(LogicalKeyboardKey.digit4, control: true):
          const ShellSelectTabIntent(ShellTab.settings),

      // Ctrl + numpad 1..4
      const SingleActivator(LogicalKeyboardKey.numpad1, control: true):
          const ShellSelectTabIntent(ShellTab.home),
      const SingleActivator(LogicalKeyboardKey.numpad2, control: true):
          const ShellSelectTabIntent(ShellTab.search),
      const SingleActivator(LogicalKeyboardKey.numpad3, control: true):
          const ShellSelectTabIntent(ShellTab.library),
      const SingleActivator(LogicalKeyboardKey.numpad4, control: true):
          const ShellSelectTabIntent(ShellTab.settings),
    };

    final actions = <Type, Action<Intent>>{
      ShellSelectTabIntent: CallbackAction<ShellSelectTabIntent>(
        onInvoke: (intent) {
          if (_isTextInputFocused()) return null;
          onSelectTab(intent.tab);
          return null;
        },
      ),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(actions: actions, child: child),
    );
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;

    // Compatible avec plus de versions Flutter :
    // Si le focus actuel est dans un EditableText (TextField, etc.), on coupe les shortcuts.
    return ctx.findAncestorStateOfType<EditableTextState>() != null;
  }
}

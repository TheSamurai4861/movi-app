import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';

class MoviRemoteNavigation extends ConsumerStatefulWidget {
  const MoviRemoteNavigation({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MoviRemoteNavigation> createState() =>
      _MoviRemoteNavigationState();
}

class _MoviRemoteNavigationState extends ConsumerState<MoviRemoteNavigation> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'MoviRemoteNavigation',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: widget.child,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_hasModifierPressed()) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        (key == LogicalKeyboardKey.backspace && !_isTextInputFocused())) {
      unawaited(_handleBackNavigation());
      return KeyEventResult.handled;
    }

    if (_isTextInputFocused()) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null) return KeyEventResult.ignored;

      Actions.maybeInvoke<ActivateIntent>(focusContext, const ActivateIntent());
      return KeyEventResult.handled;
    }

    final direction = switch (key) {
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      _ => null,
    };

    if (direction == null) return KeyEventResult.ignored;

    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null) {
      _focusNode.requestFocus();
      FocusScope.of(context).nextFocus();
      return KeyEventResult.handled;
    }

    final moved = focusedNode.focusInDirection(direction);
    if (!moved) {
      if (direction == TraversalDirection.left ||
          direction == TraversalDirection.up) {
        focusedNode.previousFocus();
      } else {
        focusedNode.nextFocus();
      }
    }

    return KeyEventResult.handled;
  }

  bool _isTextInputFocused() {
    return FocusDirectionalNavigation.isEditableTextFocused();
  }

  bool _hasModifierPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed;
  }

  Future<void> _handleBackNavigation() async {
    final didPop = await Navigator.maybePop(context);
    if (!mounted) return;
    if (!didPop) {
      ref.read(shellFocusCoordinatorProvider).focusSidebar();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        return;
      }

      final selectedTab = ref.read(selectedTabProvider);
      final focusCoordinator = ref.read(shellFocusCoordinatorProvider);
      final restored = focusCoordinator.focusTabEntry(selectedTab);
      if (!restored) {
        focusCoordinator.focusSidebar();
      }
    });
  }
}

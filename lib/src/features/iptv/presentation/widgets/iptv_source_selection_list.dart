import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';

/// Liste de sélection de source IPTV réutilisable entre onboarding et réglages.
class IptvSourceSelectionList extends StatelessWidget {
  const IptvSourceSelectionList({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    this.padding = const EdgeInsets.all(12),
    this.itemFocusNodes,
    this.onFirstItemUp,
    this.onLastItemDown,
    this.focusVerticalAlignment = 0.22,
  });

  final List<AnyIptvAccount> accounts;
  final String? selectedId;
  final ValueChanged<AnyIptvAccount> onSelected;
  final EdgeInsetsGeometry padding;
  final List<FocusNode>? itemFocusNodes;
  final VoidCallback? onFirstItemUp;
  final VoidCallback? onLastItemDown;
  final double focusVerticalAlignment;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final account = accounts[index];
        final isSelected = account.id == selectedId;
        final tile = _IptvSourceTile(
          account: account,
          isSelected: isSelected,
          focusNode: itemFocusNodes != null && index < itemFocusNodes!.length
              ? itemFocusNodes![index]
              : null,
          onTap: () => onSelected(account),
          focusVerticalAlignment: focusVerticalAlignment,
        );
        return Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) {
              return KeyEventResult.ignored;
            }
            switch (event.logicalKey) {
              case LogicalKeyboardKey.arrowUp:
                if (index == 0) {
                  onFirstItemUp?.call();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              case LogicalKeyboardKey.arrowDown:
                if (index == accounts.length - 1) {
                  onLastItemDown?.call();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              case LogicalKeyboardKey.arrowLeft:
              case LogicalKeyboardKey.arrowRight:
                return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: tile,
        );
      },
    );
  }
}

class _IptvSourceTile extends StatelessWidget {
  const _IptvSourceTile({
    required this.account,
    required this.isSelected,
    required this.onTap,
    this.focusNode,
    required this.focusVerticalAlignment,
  });

  final AnyIptvAccount account;
  final bool isSelected;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final double focusVerticalAlignment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return MoviEnsureVisibleOnFocus(
      verticalAlignment: focusVerticalAlignment,
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onTap,
        semanticLabel: account.alias,
        builder: (context, state) {
          final focused = state.focused;
          return MoviFocusFrame(
            scale: focused ? 1.01 : 1,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: focused
                    ? cs.surfaceContainerHighest
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: focused ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.alias,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.sourceUrl,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.statusActive,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

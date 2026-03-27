import 'package:flutter/material.dart';

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
  });

  final List<AnyIptvAccount> accounts;
  final String? selectedId;
  final ValueChanged<AnyIptvAccount> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final account = accounts[index];
        final isSelected = account.id == selectedId;
        return _IptvSourceTile(
          account: account,
          isSelected: isSelected,
          onTap: () => onSelected(account),
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
  });

  final AnyIptvAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MoviFocusableAction(
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
              color: focused ? cs.surfaceContainerHighest : Colors.transparent,
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(account.subtitle),
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
                      'Active',
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
    );
  }
}

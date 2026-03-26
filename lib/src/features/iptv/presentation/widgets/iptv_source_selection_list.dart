import 'package:flutter/material.dart';

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
        final cs = Theme.of(context).colorScheme;

        return ListTile(
          title: Text(
            account.alias,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(account.subtitle),
          trailing: isSelected
              ? Container(
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
                )
              : null,
          onTap: () => onSelected(account),
        );
      },
    );
  }
}

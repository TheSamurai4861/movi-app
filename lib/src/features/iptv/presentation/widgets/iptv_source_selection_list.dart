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

        return ListTile(
          title: Text(account.alias),
          subtitle: Text(account.subtitle),
          trailing: isSelected ? const Icon(Icons.check) : null,
          leading: account.isStalker
              ? const Icon(Icons.router, color: Colors.orange)
              : const Icon(Icons.live_tv, color: Colors.blue),
          onTap: () => onSelected(account),
        );
      },
    );
  }
}

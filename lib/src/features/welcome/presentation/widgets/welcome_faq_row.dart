import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';

class WelcomeFaqRow extends StatelessWidget {
  const WelcomeFaqRow({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                AppLocalizations.of(context)!.faqLabel,
                style: t.bodyLarge?.copyWith(color: c.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.message, this.showBack = true});

  final String message;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 44,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface),
                ),
                if (showBack) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed:
                        Navigator.of(context).canPop() ? context.pop : null,
                    child: Text(AppLocalizations.of(context)!.actionBack),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

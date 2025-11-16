import 'package:flutter/material.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/l10n/app_localizations.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navLibrary)),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.libraryHeader, style: context.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppLocalizations.of(context)!.libraryDataInfo,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.libraryEmpty,
                    style: context.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

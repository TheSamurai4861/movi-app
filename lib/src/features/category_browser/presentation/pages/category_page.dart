import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/features/category_browser/presentation/providers/category_providers.dart';
import 'package:movi/src/features/category_browser/presentation/widgets/category_grid.dart';
import 'package:movi/src/features/category_browser/presentation/widgets/category_header.dart';
import 'package:movi/src/core/widgets/syncable_refresh_indicator.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key, this.args});

  final CategoryPageArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = args?.title ?? 'Catégorie';
    final visibleKey = args?.categoryKey;
    final CategoryState categoryState = (visibleKey != null)
        ? ref.watch(categoryControllerProvider(visibleKey))
        : const CategoryState(items: <ContentReference>[]);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            CategoryHeader(title: title),
            const SizedBox(height: 32),
            Expanded(
              child: SyncableRefreshIndicator(
                onRefresh: () async {
                  // Rafraîchir aussi le contenu local après la sync
                  if (visibleKey != null) {
                    ref.invalidate(categoryControllerProvider(visibleKey));
                  }
                },
                child: _buildBody(context, ref, categoryState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, CategoryState state) {
    final l10n = AppLocalizations.of(context)!;

    // Cas sans clé visible: afficher simplement un état vide scrollable.
    if (state.items.isEmpty && !state.isLoading && state.error == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                l10n.categoryEmpty,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                l10n.categoryLoadFailed,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      );
    }

    return CategoryGrid(
      items: state.items,
      hasMore: state.hasMore,
      isLoadingMore: state.isLoading && state.items.isNotEmpty,
      onLoadMore: state.hasMore && !state.isLoading
          ? () {
              final visibleKey = args?.categoryKey;
              if (visibleKey != null) {
                ref
                    .read(categoryControllerProvider(visibleKey).notifier)
                    .fetchNextPage();
              }
            }
          : null,
    );
  }
}

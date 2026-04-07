import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/features/category_browser/presentation/providers/category_providers.dart';
import 'package:movi/src/features/category_browser/presentation/widgets/category_grid.dart';
import 'package:movi/src/features/category_browser/presentation/widgets/category_header.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key, this.args});

  final CategoryPageArgs? args;

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'CategoryBack');
  final FocusNode _firstItemFocusNode = FocusNode(
    debugLabel: 'CategoryFirstItem',
  );
  final FocusNode _retryFocusNode = FocusNode(debugLabel: 'CategoryRetry');
  final FocusNode _loadMoreFocusNode = FocusNode(
    debugLabel: 'CategoryLoadMore',
  );

  @override
  void dispose() {
    _backFocusNode.dispose();
    _firstItemFocusNode.dispose();
    _retryFocusNode.dispose();
    _loadMoreFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args?.title ?? 'Catégorie';
    final visibleKey = widget.args?.categoryKey;
    final CategoryState categoryState = visibleKey != null
        ? ref.watch(categoryControllerProvider(visibleKey))
        : const CategoryState(items: <ContentReference>[]);

    final initialFocusNode =
        categoryState.error != null && categoryState.items.isEmpty
        ? _retryFocusNode
        : categoryState.items.isNotEmpty
        ? _firstItemFocusNode
        : _backFocusNode;

    return MoviRouteFocusBoundary(
      restorePolicy: MoviFocusRestorePolicy(
        initialFocusNode: initialFocusNode,
        fallbackFocusNode: _backFocusNode,
      ),
      requestInitialFocusOnMount: true,
      onUnhandledBack: () {
        if (!mounted) return false;
        Navigator.of(context).maybePop();
        return true;
      },
      debugLabel: 'CategoryRouteFocus',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              CategoryHeader(
                title: title,
                onBack: () => Navigator.of(context).maybePop(),
                backFocusNode: _backFocusNode,
              ),
              Expanded(
                child: SyncableRefreshIndicator(
                  onRefresh: () async {
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
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, CategoryState state) {
    final l10n = AppLocalizations.of(context)!;
    final visibleKey = widget.args?.categoryKey;

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
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.categoryLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          Center(
            child: MoviPrimaryButton(
              label: l10n.actionRetry,
              focusNode: _retryFocusNode,
              expand: false,
              onPressed: visibleKey == null
                  ? null
                  : () =>
                        ref.invalidate(categoryControllerProvider(visibleKey)),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        CategoryGrid(
          items: state.items,
          backFocusNode: _backFocusNode,
          firstItemFocusNode: _firstItemFocusNode,
          loadMoreFocusNode: _loadMoreFocusNode,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoading && state.items.isNotEmpty,
          onLoadMore: state.hasMore && !state.isLoading && visibleKey != null
              ? () => ref
                    .read(categoryControllerProvider(visibleKey).notifier)
                    .fetchNextPage()
              : null,
        ),
      ],
    );
  }
}

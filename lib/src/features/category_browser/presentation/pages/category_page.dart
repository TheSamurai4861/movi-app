import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
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
  int _lastWheelLoadMs = 0;

  KeyEventResult _handleBackKeyEvent(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (!mounted) return KeyEventResult.ignored;
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _backFocusNode.dispose();
    _firstItemFocusNode.dispose();
    _retryFocusNode.dispose();
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

    return FocusRegionScope(
      regionId: AppFocusRegionId.categoryPrimary,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () => initialFocusNode,
        resolveFallbackEntryNode: () => _backFocusNode,
      ),
      exitMap: FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
      }),
      requestFocusOnMount: true,
      debugLabel: 'CategoryRegion',
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => _handleBackKeyEvent(event, context),
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
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (visibleKey == null) return false;
            if (!state.hasMore || state.isLoading) return false;
            if (notification is! ScrollUpdateNotification) return false;

            // On desktop: wheel/trackpad => dragDetails == null.
            if (notification.dragDetails != null) return false;
            final delta = notification.scrollDelta;
            if (delta == null || delta <= 0) return false;
            if (notification.metrics.extentAfter > 320) return false;

            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastWheelLoadMs < 450) return false;
            _lastWheelLoadMs = now;
            ref
                .read(categoryControllerProvider(visibleKey).notifier)
                .fetchNextPage();
            return false;
          },
          child: CategoryGrid(
            items: state.items,
            backFocusNode: _backFocusNode,
            firstItemFocusNode: _firstItemFocusNode,
            hasMore: state.hasMore,
            isLoadingMore: state.isLoading && state.items.isNotEmpty,
            onLoadMore: state.hasMore && !state.isLoading && visibleKey != null
                ? () => ref
                      .read(categoryControllerProvider(visibleKey).notifier)
                      .fetchNextPage()
                : null,
          ),
        ),
      ],
    );
  }
}

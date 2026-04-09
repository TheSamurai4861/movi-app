// lib/src/features/search/presentation/widgets/watch_providers_grid.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/search/presentation/models/provider_results_args.dart';

class WatchProvidersGrid extends ConsumerStatefulWidget {
  const WatchProvidersGrid({
    super.key,
    this.horizontalPadding = 20,
    this.maxContentWidth = double.infinity,
    this.firstItemFocusNode,
    this.onFirstItemLeft,
    this.focusVerticalAlignment = 0.22,
    this.focusRequestId,
    this.focusRequestColumn,
  });

  final double horizontalPadding;
  final double maxContentWidth;
  final FocusNode? firstItemFocusNode;
  final VoidCallback? onFirstItemLeft;
  final double focusVerticalAlignment;
  final int? focusRequestId;
  final int? focusRequestColumn;

  @override
  ConsumerState<WatchProvidersGrid> createState() => _WatchProvidersGridState();
}

class _WatchProvidersGridState extends ConsumerState<WatchProvidersGrid> {
  final Map<int, FocusNode> _providerFocusNodes = <int, FocusNode>{};

  void _syncFocusNodes(List<WatchProvider> providers) {
    final usesExternalFirst = widget.firstItemFocusNode != null;
    final activeIds = <int>{};

    for (var index = 0; index < providers.length; index++) {
      if (!(usesExternalFirst && index == 0)) {
        activeIds.add(providers[index].providerId);
      }
    }

    final staleIds = _providerFocusNodes.keys
        .where((id) => !activeIds.contains(id))
        .toList(growable: false);
    for (final id in staleIds) {
      _providerFocusNodes.remove(id)?.dispose();
    }
  }

  FocusNode _focusNodeFor(WatchProvider provider, {required bool isFirstItem}) {
    if (isFirstItem && widget.firstItemFocusNode != null) {
      return widget.firstItemFocusNode!;
    }
    return _providerFocusNodes.putIfAbsent(
      provider.providerId,
      () => FocusNode(debugLabel: 'Provider-${provider.providerId}'),
    );
  }

  int _lastRowAlignedIndex({
    required int itemCount,
    required int columns,
    required int column,
  }) {
    final lastRowStart = ((itemCount - 1) ~/ columns) * columns;
    return math.min(lastRowStart + column, itemCount - 1);
  }

  void _applyPendingFocusRequest(
    List<WatchProvider> providers,
    int columns,
    int? requestColumn,
  ) {
    if (widget.focusRequestId == null || requestColumn == null) return;
    if (providers.isEmpty) return;

    final targetIndex = _lastRowAlignedIndex(
      itemCount: providers.length,
      columns: columns,
      column: requestColumn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final node = _focusNodeFor(
        providers[targetIndex],
        isFirstItem: targetIndex == 0,
      );
      if (!node.canRequestFocus || node.context == null) {
        return;
      }
      node.requestFocus();
    });
  }

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  int _columnCount(ScreenType screenType, double width, int itemCount) {
    final maxColumns = switch (screenType) {
      ScreenType.mobile => 2,
      ScreenType.tablet => 3,
      ScreenType.desktop => 4,
      ScreenType.tv => 5,
    };
    final minTileWidth = switch (screenType) {
      ScreenType.mobile => 150.0,
      ScreenType.tablet => 180.0,
      ScreenType.desktop => 220.0,
      ScreenType.tv => 220.0,
    };
    final computed = ((width + 16) / (minTileWidth + 16)).floor();
    return math.max(1, math.min(itemCount, computed.clamp(2, maxColumns)));
  }

  @override
  void dispose() {
    for (final node in _providerFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = _screenTypeFor(context);
    final providersAsync = ref.watch(watchProvidersProvider);

    return providersAsync.when(
      data: (providers) {
        if (providers.isEmpty) {
          return const SizedBox.shrink();
        }

        _syncFocusNodes(providers);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                  child: Text(
                    AppLocalizations.of(context)!.searchByProvidersTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = _columnCount(
                        screenType,
                        constraints.maxWidth,
                        providers.length,
                      );
                      _applyPendingFocusRequest(
                        providers,
                        columns,
                        widget.focusRequestColumn,
                      );
                      final aspectRatio = switch (screenType) {
                        ScreenType.mobile => 2.0,
                        ScreenType.tablet => 2.05,
                        ScreenType.desktop => 2.15,
                        ScreenType.tv => 2.2,
                      };

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: providers.length,
                        itemBuilder: (context, index) {
                          final card = _WatchProviderCard(
                            provider: providers[index],
                            focusNode: _focusNodeFor(
                              providers[index],
                              isFirstItem: index == 0,
                            ),
                            focusVerticalAlignment:
                                widget.focusVerticalAlignment,
                          );
                          final decoratedCard =
                              index % columns != 0 ||
                                  widget.onFirstItemLeft == null
                              ? card
                              : Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) {
                                    if (event is! KeyDownEvent) {
                                      return KeyEventResult.ignored;
                                    }
                                    if (event.logicalKey !=
                                        LogicalKeyboardKey.arrowLeft) {
                                      return KeyEventResult.ignored;
                                    }
                                    widget.onFirstItemLeft!.call();
                                    return KeyEventResult.handled;
                                  },
                                  child: card,
                                );
                          return decoratedCard;
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: 16,
        ),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Carte représentant un provider.
class _WatchProviderCard extends ConsumerWidget {
  const _WatchProviderCard({
    required this.provider,
    this.focusNode,
    this.focusVerticalAlignment,
  });

  final WatchProvider provider;
  final FocusNode? focusNode;
  final double? focusVerticalAlignment;

  Color _getProviderColor(int providerId) {
    // Palette de couleurs par défaut pour les providers connus
    final colorMap = <int, Color>{
      8: const Color(0xFFE50914), // Netflix (rouge)
      337: const Color(0xFF113CCF), // Disney+ (bleu)
      119: const Color(0xFF87CEEB), // Amazon Prime Video (bleu clair)
      350: const Color(0xFF4A4A4A), // Apple TV+ (gris moins foncé)
      1899: const Color(0xFF4A4A4A), // HBO Max (gris moins foncé)
      283: const Color(0xFFF47521), // Crunchyroll (orange)
    };

    return colorMap[providerId] ?? const Color(0xFF2C2C2E);
  }

  /// Génère une couleur plus foncée à partir d'une couleur de base
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Réduire la luminosité à environ 60-70% de la valeur originale
    return hsl.withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = _getProviderColor(provider.providerId);
    final popularMediaAsync = ref.watch(
      providerPopularMediaProvider(provider.providerId),
    );

    return MoviFocusableAction(
      focusNode: focusNode,
      ensureVisibleVerticalAlignment: focusVerticalAlignment,
      onPressed: () {
        context.push(
          AppRouteNames.providerResults,
          extra: ProviderResultsArgs(
            providerId: provider.providerId,
            providerName: provider.providerName,
          ),
        );
      },
      semanticLabel: provider.providerName,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.03 : 1,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [backgroundColor, _darkenColor(backgroundColor)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.focused ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  popularMediaAsync.when(
                    data: (popularMedia) {
                      if (popularMedia?.backdropUrl == null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned.fill(
                        child: Image.network(
                          popularMedia!.backdropUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        provider.providerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

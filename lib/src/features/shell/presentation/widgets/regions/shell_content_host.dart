// lib/src/features/shell/presentation/widgets/regions/shell_content_host.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Héberge le contenu des onglets du "Shell" (Home / Search / Library / Settings)
/// avec une politique de rétention optimisée :
///
/// - Certains onglets sont "keep-alive" : ils restent montés et conservent
///   leur état widget (scroll, controllers, etc.).
/// - Les autres onglets sont "éphémères" : ils sont reconstruits à chaque
///   navigation vers eux (reset complet).
///
/// Pour garantir un reset complet (UI + providers Riverpod), les onglets
/// éphémères sont montés sous un ProviderContainer dédié, recréé à chaque entrée.
class ShellContentHost extends StatefulWidget {
  const ShellContentHost({
    super.key,
    required this.selectedIndex,
    required this.pageBuilders,
    this.keepAliveIndices = const {0, 1}, // par défaut : Home + Search
    this.showEphemeralSwitchLoading = true,
    this.loadingLabel,
  }) : assert(pageBuilders.length > 0, 'pageBuilders ne peut pas être vide.');

  /// Onglet sélectionné (index des destinations).
  final int selectedIndex;

  /// Builders des pages, dans le même ordre que les destinations du Shell.
  final List<WidgetBuilder> pageBuilders;

  /// Indices des onglets qui doivent conserver leur état (keep alive).
  final Set<int> keepAliveIndices;

  /// Si true : affiche un overlay de chargement quand on entre sur un onglet
  /// éphémère, au moins jusqu'à la prochaine frame.
  final bool showEphemeralSwitchLoading;

  /// Label d’accessibilité (localisé) pour l'overlay de chargement.
  /// Exemple : AppLocalizations.of(context)!.loading
  /// Si null => aucun texte “brut” n’est injecté.
  final String? loadingLabel;

  @override
  State<ShellContentHost> createState() => _ShellContentHostState();
}

class _ShellContentHostState extends State<ShellContentHost> {
  /// Cache des pages keep-alive (lazy build).
  final Map<int, Widget> _keepAliveCache = <int, Widget>{};

  /// Ordre stable des indices keep-alive, utilisé par l'IndexedStack.
  late List<int> _keepAliveOrder;

  /// Conteneur Riverpod dédié aux pages éphémères.
  ProviderContainer? _ephemeralContainer;

  /// L'index actuellement monté en mode éphémère (si applicable).
  int? _ephemeralIndex;

  /// Overlay de chargement pendant les switches vers un onglet éphémère.
  bool _showEphemeralLoading = false;

  /// Pour forcer un remount côté widget (key) quand on ré-entre sur un onglet éphémère.
  int _ephemeralGeneration = 0;

  @override
  void initState() {
    super.initState();
    _keepAliveOrder = _sortedKeepAlive(widget.keepAliveIndices);
    _ensureEphemeralContainerIfNeeded(initial: true);
  }

  @override
  void didUpdateWidget(covariant ShellContentHost oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_setEquals(oldWidget.keepAliveIndices, widget.keepAliveIndices)) {
      _keepAliveOrder = _sortedKeepAlive(widget.keepAliveIndices);
    }

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _handleTabChange(from: oldWidget.selectedIndex, to: widget.selectedIndex);
    }
  }

  void _handleTabChange({required int from, required int to}) {
    final toIsKeepAlive = widget.keepAliveIndices.contains(to);
    final fromIsKeepAlive = widget.keepAliveIndices.contains(from);

    if (!fromIsKeepAlive) {
      _disposeEphemeralContainer();
    }

    if (!toIsKeepAlive) {
      _createEphemeralContainerFor(to);
      _maybeShowEphemeralSwitchLoading();
    } else {
      if (mounted) {
        setState(() => _showEphemeralLoading = false);
      }
    }
  }

  void _ensureEphemeralContainerIfNeeded({required bool initial}) {
    final isKeepAlive = widget.keepAliveIndices.contains(widget.selectedIndex);
    if (isKeepAlive) return;

    _createEphemeralContainerFor(widget.selectedIndex);
    if (initial) {
      _maybeShowEphemeralSwitchLoading();
    }
  }

  void _createEphemeralContainerFor(int index) {
    final parent = ProviderScope.containerOf(context, listen: false);

    _ephemeralContainer = ProviderContainer(parent: parent);
    _ephemeralIndex = index;
    _ephemeralGeneration++;
  }

  void _disposeEphemeralContainer() {
    _ephemeralIndex = null;
    _showEphemeralLoading = false;

    final c = _ephemeralContainer;
    _ephemeralContainer = null;
    c?.dispose();
  }

  void _maybeShowEphemeralSwitchLoading() {
    if (!widget.showEphemeralSwitchLoading) return;

    if (mounted) {
      setState(() => _showEphemeralLoading = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stillEphemeral =
          !widget.keepAliveIndices.contains(widget.selectedIndex);
      if (!stillEphemeral) return;
      setState(() => _showEphemeralLoading = false);
    });
  }

  List<int> _sortedKeepAlive(Set<int> indices) {
    final list = indices.toList()..sort();
    return list;
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  Widget _getKeepAlivePage(int index) {
    return _keepAliveCache.putIfAbsent(
      index,
      () => Builder(builder: widget.pageBuilders[index]),
    );
  }

  @override
  void dispose() {
    _disposeEphemeralContainer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedIndex;
    final isKeepAliveSelected = widget.keepAliveIndices.contains(selected);

    final keepAliveZone = Offstage(
      offstage: !isKeepAliveSelected,
      child: IndexedStack(
        index: _indexInKeepAliveOrder(selected),
        children: _keepAliveOrder.map(_getKeepAlivePage).toList(growable: false),
      ),
    );

    Widget ephemeralZone = const SizedBox.shrink();
    if (!isKeepAliveSelected) {
      final container = _ephemeralContainer;
      if (container == null || _ephemeralIndex != selected) {
        _disposeEphemeralContainer();
        _createEphemeralContainerFor(selected);
        _maybeShowEphemeralSwitchLoading();
      }

      final effectiveContainer = _ephemeralContainer!;
      ephemeralZone = UncontrolledProviderScope(
        container: effectiveContainer,
        child: KeyedSubtree(
          key: ValueKey('ephemeral-$selected-$_ephemeralGeneration'),
          child: Builder(builder: widget.pageBuilders[selected]),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            children: [
              keepAliveZone,
              if (!isKeepAliveSelected) Positioned.fill(child: ephemeralZone),
            ],
          ),
        ),
        if (_showEphemeralLoading)
          _ShellSwitchLoadingOverlay(label: widget.loadingLabel),
      ],
    );
  }

  int _indexInKeepAliveOrder(int selectedIndex) {
    final pos = _keepAliveOrder.indexOf(selectedIndex);
    return pos >= 0 ? pos : 0;
  }
}

class _ShellSwitchLoadingOverlay extends StatelessWidget {
  const _ShellSwitchLoadingOverlay({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final overlayColor =
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.78);

    final overlay = Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: DecoratedBox(
          decoration: BoxDecoration(color: overlayColor),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    // Aucun texte "brut" si label == null.
    if (label == null || label!.trim().isEmpty) {
      return overlay;
    }

    return Semantics(
      label: label,
      child: overlay,
    );
  }
}

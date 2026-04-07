import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/notifications/local_notification_gateway.dart';
import 'package:movi/src/core/notifications/local_notification_gateway_provider.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/features/series_tracking/presentation/providers/series_tracking_providers.dart';

class SeriesTrackingBootstrapper extends ConsumerStatefulWidget {
  const SeriesTrackingBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SeriesTrackingBootstrapper> createState() =>
      _SeriesTrackingBootstrapperState();
}

class _SeriesTrackingBootstrapperState
    extends ConsumerState<SeriesTrackingBootstrapper>
    with WidgetsBindingObserver {
  static const Duration _minIntervalBetweenRefreshes = Duration(minutes: 10);

  StreamSubscription<SeriesNotificationNavigationIntent>? _navigationSub;
  Timer? _scheduled;
  DateTime? _lastRefreshAt;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduled?.cancel();
    _navigationSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    }
  }

  Future<void> _initialize() async {
    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
    );
    if (!hasPremium) return;

    final gateway = ref.read(localNotificationGatewayProvider);
    await gateway.initialize();
    _navigationSub ??= gateway.navigationIntents.listen(_handleIntent);
    _scheduleRefresh(force: true);
  }

  void _scheduleRefresh({bool force = false}) {
    _scheduled?.cancel();
    _scheduled = Timer(
      force ? const Duration(milliseconds: 200) : const Duration(seconds: 1),
      () => _refreshIfNeeded(force: force),
    );
  }

  Future<void> _refreshIfNeeded({bool force = false}) async {
    if (!mounted) return;
    if (_refreshing) return;

    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
    );
    if (!hasPremium) return;

    final now = DateTime.now();
    final last = _lastRefreshAt;
    if (!force &&
        last != null &&
        now.difference(last) < _minIntervalBetweenRefreshes) {
      return;
    }

    _refreshing = true;
    _lastRefreshAt = now;
    try {
      await ref
          .read(seriesTrackingToggleProvider.notifier)
          .refreshAllTrackedSeriesStatuses();
    } finally {
      _refreshing = false;
    }
  }

  void _handleIntent(SeriesNotificationNavigationIntent intent) {
    if (!mounted) return;
    context.pushNamed(
      AppRouteIds.tvById,
      pathParameters: {'id': intent.seriesId},
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

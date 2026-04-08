import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/logging/logger.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeSafely());
    });
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
    if (!hasPremium || !mounted) return;

    final gateway = ref.read(localNotificationGatewayProvider);
    try {
      await gateway.initialize();
      if (!mounted) return;
      _navigationSub ??= gateway.navigationIntents.listen(_handleIntent);
    } catch (error, stackTrace) {
      _logBootstrapWarning(
        action: 'notifications_initialize',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!mounted) return;
    _scheduleRefresh(force: true);
  }

  void _scheduleRefresh({bool force = false}) {
    _scheduled?.cancel();
    _scheduled = Timer(
      force ? const Duration(milliseconds: 200) : const Duration(seconds: 1),
      () => unawaited(_refreshIfNeededSafely(force: force)),
    );
  }

  Future<void> _initializeSafely() async {
    try {
      await _initialize();
    } catch (error, stackTrace) {
      _logBootstrapWarning(
        action: 'bootstrap_initialize',
        error: error,
        stackTrace: stackTrace,
      );
    }
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

  Future<void> _refreshIfNeededSafely({bool force = false}) async {
    try {
      await _refreshIfNeeded(force: force);
    } catch (error, stackTrace) {
      _logBootstrapWarning(
        action: force ? 'refresh_forced' : 'refresh',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _logBootstrapWarning({
    required String action,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final message =
        '[SeriesTrackingBootstrapper][WARN] action=$action '
        'result=degraded errorType=${error.runtimeType}';
    if (kDebugMode) {
      debugPrint('$message error=$error');
    }
    unawaited(
      LoggingService.log(
        message,
        level: LogLevel.warn,
        category: 'series_tracking',
        error: error,
        stackTrace: stackTrace,
      ),
    );
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

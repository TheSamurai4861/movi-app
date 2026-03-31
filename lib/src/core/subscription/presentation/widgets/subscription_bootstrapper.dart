import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';

class SubscriptionBootstrapper extends ConsumerStatefulWidget {
  const SubscriptionBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SubscriptionBootstrapper> createState() =>
      _SubscriptionBootstrapperState();
}

class _SubscriptionBootstrapperState extends ConsumerState<SubscriptionBootstrapper>
    with WidgetsBindingObserver {
  static const Duration _minIntervalBetweenRefreshes = Duration(seconds: 15);

  DateTime? _lastRefreshAt;
  bool _refreshing = false;
  Timer? _scheduled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Best-effort: refresh shortly after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRefresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduled?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    }
  }

  void _scheduleRefresh() {
    _scheduled?.cancel();
    _scheduled = Timer(const Duration(milliseconds: 250), _refreshIfNeeded);
  }

  Future<void> _refreshIfNeeded() async {
    if (!mounted) return;
    if (_refreshing) return;

    final now = DateTime.now();
    final last = _lastRefreshAt;
    if (last != null && now.difference(last) < _minIntervalBetweenRefreshes) {
      return;
    }

    _refreshing = true;
    _lastRefreshAt = now;
    try {
      final refreshSubscription = ref.read(refreshSubscriptionUseCaseProvider);
      await refreshSubscription();
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionOffersProvider);
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


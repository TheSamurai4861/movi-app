import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';

typedef PremiumGateBuilder = Widget Function(BuildContext context);

class PremiumFeatureGate extends ConsumerWidget {
  const PremiumFeatureGate({
    super.key,
    required this.feature,
    required this.unlockedBuilder,
    required this.lockedBuilder,
  });

  final PremiumFeature feature;
  final PremiumGateBuilder unlockedBuilder;
  final PremiumGateBuilder lockedBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref
        .watch(canAccessPremiumFeatureProvider(feature))
        .maybeWhen(data: (value) => value, orElse: () => false);

    if (!hasPremium) {
      return lockedBuilder(context);
    }
    return unlockedBuilder(context);
  }
}

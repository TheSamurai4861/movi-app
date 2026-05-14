import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/startup/presentation/boot_screen_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

final bootScreenMapperProvider = Provider<BootScreenMapper>((ref) {
  return const BootScreenMapper();
});

/// Projection read-only of the current launch state for boot UI surfaces.
///
/// This provider must stay pure: no navigation, no logging, no storage/network
/// access and no launch runner calls.
final bootScreenModelProvider = Provider<BootScreenModel>((ref) {
  final launchState = ref.watch(appLaunchStateProvider);
  final mapper = ref.watch(bootScreenMapperProvider);
  return mapper.fromLaunchState(launchState);
});

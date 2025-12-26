import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';

/// Current selected [Profile] if available.
///
/// Returns null if:
/// - profiles are not loaded yet
/// - no profile is selected
/// - selected profile id is not found in the loaded list
final currentProfileProvider = Provider<Profile?>((ref) {
  final selectedId = ref.watch(selectedProfileIdProvider)?.trim();
  if (selectedId == null || selectedId.isEmpty) return null;

  final profilesAsync = ref.watch(profilesControllerProvider);
  return profilesAsync.maybeWhen(data: (profiles) {
    for (final p in profiles) {
      if (p.id == selectedId) return p;
    }
    return null;
  }, orElse: () => null);
});

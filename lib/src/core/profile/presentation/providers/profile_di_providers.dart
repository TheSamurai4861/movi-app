import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/application/services/selected_profile_service.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

/// DI: expose SelectedProfilePreferences depuis ton service locator.
/// (InitialisÃƒÆ’Ã‚Â© au dÃƒÆ’Ã‚Â©marrage via DI.)
final selectedProfilePreferencesProvider = Provider<SelectedProfilePreferences>(
  (ref) => ref.watch(slProvider)<SelectedProfilePreferences>(),
);

/// DI: service applicatif "profil sÃƒÆ’Ã‚Â©lectionnÃƒÆ’Ã‚Â©".
final selectedProfileServiceProvider = Provider<SelectedProfileService>((ref) {
  final prefs = ref.watch(selectedProfilePreferencesProvider);
  return SelectedProfileService(prefs);
});

/// DI: repository mÃƒÆ’Ã‚Â©tier.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ref.watch(slProvider)<ProfileRepository>();
});

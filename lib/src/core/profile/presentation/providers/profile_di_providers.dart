import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/application/services/selected_profile_service.dart';

import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/profile/data/datasources/supabase_profile_datasource.dart';
import 'package:movi/src/core/profile/data/repositories/supabase_profile_repository.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';

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

/// DI: datasource Supabase (I/O brut).
final supabaseProfileDatasourceProvider = Provider<SupabaseProfileDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is null (not initialized).');
  }
  return SupabaseProfileDatasource(client);
});

/// DI: repository mÃƒÆ’Ã‚Â©tier (contrat -> impl Supabase).
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is null (not initialized).');
  }

  final ds = ref.watch(supabaseProfileDatasourceProvider);
  return SupabaseProfileRepository(
    client,
    datasource: ds,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/controllers/profiles_controller.dart';

/// Source de vÃƒÂ©ritÃƒÂ© (state) : liste des profils.
///
/// UI: `ref.watch(profilesControllerProvider)` -> `AsyncValue<List<Profile>>`
final profilesControllerProvider =
    AsyncNotifierProvider<ProfilesController, List<Profile>>(
  ProfilesController.new,
);

/// Alias pratique si tu veux un provider Ã¢â‚¬Å“profilesAsyncÃ¢â‚¬Â.
final profilesAsyncProvider = Provider<AsyncValue<List<Profile>>>((ref) {
  return ref.watch(profilesControllerProvider);
});
